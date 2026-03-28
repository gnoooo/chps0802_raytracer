#include <cuda_runtime.h>
#include <iostream>
#include <fstream>
#include <string>
#include <memory>
#include <vector>
#include "../include/camera.hpp"
#include "../include/kernels.cuh"

// Adaptation GPU
//
// Les classes Material, HittableList et Sphere de la v3 utilisent des shared_ptr et des méthodes virtuelles
// deux mécanismes qui ne fonctionnent pas en code device CUDA (pas de vtable, pas d'allocateur CPU)
//
// Les types GPU (SphereGPU, LightGPU, HitRecord) et les fonctions device
// (world_hit, ray_color_gpu) sont définis dans kernels.cuh afin d'être
// partagés avec les tests unitaires (test_gpu.cu).



// Kernel CUDA : un thread par pixel (remplace la double boucle for de main())
//
// Shared memory : chaque bloc charge spheres + lights une fois depuis la
// global memory -> tous ses threads relisent depuis le cache L1 partagé
//
// Accès coalescent : fb[j*W + i], i varie sur l'axe rapide -> les 32 threads
// d'un warp écrivent 128 octets contigus (donc une transaction mémoire par warp)

__global__ void render_kernel(unsigned int* fb, int image_width, int image_height, const SphereGPU* d_spheres, int ns, const LightGPU*  d_lights,  int nl)
{
    // Chargement de la scène en shared memory
    __shared__ SphereGPU s_spheres[MAX_SPHERES];
    __shared__ LightGPU  s_lights[MAX_LIGHTS];
    int tid = threadIdx.y * blockDim.x + threadIdx.x;
    int tpb = blockDim.x  * blockDim.y;
    for (int k = tid; k < ns; k += tpb) s_spheres[k] = d_spheres[k];
    for (int k = tid; k < nl; k += tpb) s_lights[k]  = d_lights[k];
    __syncthreads();  // on attend que tous les threads aient fini le chargement

    int i = blockIdx.x * blockDim.x + threadIdx.x;  // colonne
    int j = blockIdx.y * blockDim.y + threadIdx.y;  // ligne (haut -> bas)
    if (i >= image_width || j >= image_height) return;

    // même classe Camera qu'en v3, avec maintenant __host__ __device__ en décorateur
    Camera cam(image_width, image_height);

    // Coordonnées normalisées (même formule que la boucle CPU de la v3) :
    //   u = i / (W-1),  v = j / (H-1)  avec j parcourant [H-1 .. 0]
    // Ici j va de 0 (haut) à H-1 (bas), donc on inverse v
    double u = double(i) / (image_width  - 1);
    double v = double(image_height - 1 - j) / (image_height - 1);

    Ray r = cam.get_ray(u, v);
    Color pixel_color = ray_color_gpu(r, s_spheres, ns, s_lights, nl, 10);

    // Écriture coalescente (ligne-major en i)
    unsigned int ir = (unsigned int)(fmin(fmax(pixel_color.x, 0.0), 1.0) * 255.999);
    unsigned int ig = (unsigned int)(fmin(fmax(pixel_color.y, 0.0), 1.0) * 255.999);
    unsigned int ib = (unsigned int)(fmin(fmax(pixel_color.z, 0.0), 1.0) * 255.999);
    fb[j * image_width + i] = (ir << 16) | (ig << 8) | ib;
}

// main (calqué sur v3)
// Seul changement : la double boucle de rendu est remplacée par un kernel
int main(int argc, char* argv[]) {
    // Paramètres de l'image
    int image_width  = 1080;
    int image_height = 1920;

    if (argc == 3) {
        image_width  = std::stoi(argv[1]);
        image_height = std::stoi(argv[2]);
    } else if (argc != 1) {
        std::cerr << "Usage: " << argv[0] << " [width height]\n";
        return 1;
    }

    std::string output_file = "output/v3_cuda/output_"
        + std::to_string(image_width) + "x" + std::to_string(image_height) + ".ppm";

    // Scène
    // Note : on utilise SphereGPU au lieu de shared_ptr<Sphere>
    SphereGPU h_spheres[] = {
        { Point3( 0,  0,   -2.0), 0.9, Color(0.3, 0.8, 0.3),  MAT_METAL,    0.1 }, // Grande sphère verte
        { Point3( 0,  0.5, -1.0), 0.3, Color(0.5, 0.8, 1.0),  MAT_LAMBERT,  0.0 }, // Sphère bleue
        { Point3( 0, -0.5, -1.0), 0.3, Color(1.0, 0.95, 0.4), MAT_CONSTANT, 0.0 }, // Sphère jaune
    };
    const int ns = 3;

    // Sources lumineuses
    LightGPU h_lights[] = {
        { Point3( 3.0,  3.0,  0.0), Color(1.0, 1.0, 1.0), 1.0 },  // lumière blanche, avant-droite haute
        { Point3(-2.0,  1.0, -1.0), Color(0.4, 0.6, 1.0), 0.5 },  // lumière bleue, avant-gauche
    };
    const int nl = 2;

    // Caméra
    Camera cam(image_width, image_height);

    std::cout << "Raytracer GPU (CUDA)\n";
    std::cout << "Résolution : " << image_width << "x" << image_height << "\n";

    // Allocation device et transfert host vers device
    SphereGPU* d_spheres;
    LightGPU* d_lights;
    unsigned int* d_fb;
    cudaMalloc(&d_spheres, ns * sizeof(SphereGPU));
    cudaMalloc(&d_lights, nl * sizeof(LightGPU));
    cudaMalloc(&d_fb, (size_t)image_width * image_height * sizeof(unsigned int));
    cudaMemcpy(d_spheres, h_spheres, ns * sizeof(SphereGPU), cudaMemcpyHostToDevice);
    cudaMemcpy(d_lights, h_lights, nl * sizeof(LightGPU), cudaMemcpyHostToDevice);

    // Lancement du kernel : bloc 16×16 = 256 threads
    dim3 block(16, 16);
    dim3 grid((image_width + block.x - 1) / block.x, (image_height + block.y - 1) / block.y);

    // Mesure du temps GPU
    cudaEvent_t t0, t1;
    cudaEventCreate(&t0); cudaEventCreate(&t1);
    cudaEventRecord(t0);

    render_kernel<<<grid, block>>>(d_fb, image_width, image_height, d_spheres, ns, d_lights, nl);

    cudaEventRecord(t1);
    cudaEventSynchronize(t1);
    float ms; cudaEventElapsedTime(&ms, t0, t1);
    std::cout << "Temps GPU  : " << ms << " ms\n";

    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::cerr << "CUDA error : " << cudaGetErrorString(err) << "\n";
        return 1;
    }

    // Récupération du framebuffer
    std::vector<unsigned int> h_fb((size_t)image_width * image_height);
    cudaMemcpy(h_fb.data(), d_fb, (size_t)image_width * image_height * sizeof(unsigned int), cudaMemcpyDeviceToHost);

    std::ofstream out(output_file);
    if (!out) {
        std::cerr << "Impossible d'ouvrir le fichier de sortie : " << output_file << "\n";
        return 1;
    }
    out << "P3\n" << image_width << ' ' << image_height << "\n255\n";
    for (int j = 0; j < image_height; ++j) {
        if (j % 100 == 0) std::cerr << "\rScanlines écrites : " << j << ' ' << std::flush;
        for (int i = 0; i < image_width; ++i) {
            unsigned int p = h_fb[j * image_width + i];
            out << ((p >> 16) & 0xFF) << ' ' << ((p >>  8) & 0xFF) << ' ' << ( p & 0xFF) << '\n';
        }
    }
    out.close();

    cudaFree(d_spheres); cudaFree(d_lights); cudaFree(d_fb);
    cudaEventDestroy(t0); cudaEventDestroy(t1);
    std::cerr << "\nTerminé ! Fichier : " << output_file << "\n";
    return 0;
}
