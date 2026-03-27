#include <cuda_runtime.h>
#include <iostream>
#include <fstream>
#include <memory>
#include <vector>
#include "../include/vec3.hpp"
#include "../include/ray.hpp"
#include "../include/camera.hpp"
#include "../include/light.hpp"

// Adaptation GPU
//
// Les classes Material, HittableList et Sphere de la v3 utilisent des shared_ptr et des méthodes virtuelles
// deux mécanismes qui ne fonctionnent pas en code device CUDA (pas de vtable, pas d'allocateur CPU)
//
// Donc on va devoir les remplacer par deux structs POD (Plain Old Data) copiables via
// cudaMemcpy, et par une fonction ray_color_gpu() qui porte la même logique de shading que les classes Material de la v3.


enum MatType { MAT_LAMBERT, MAT_METAL, MAT_CONSTANT };

// Sphère : géométrie + matériau dans un même struct sans héritage
struct SphereGPU {
    Point3 center;
    double radius;
    Color color;   // albedo (Lambert/Metal) ou couleur fixe (Constant)
    MatType mat;
    double fuzz;    // uniquement pour MAT_METAL (utile pour la réflection)
};

// Lumière (même données que PointLight car compatible device)
struct LightGPU {
    Point3 position;
    Color  color;
    double intensity;
};

// Tailles max pour la shared mem
#define MAX_SPHERES 8
#define MAX_LIGHTS  4

// Intersection rayon / sphère — même formule que Sphere::hit() en v3
struct HitRecord {
    Point3 p;
    Vec3 normal;
    double  t;
    bool front_face;
    int sphere_idx;

    __device__ void set_face_normal(const Ray& r, const Vec3& outward_normal) {
        front_face = dot(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal : -outward_normal;
    }
};

// Mélange de Sphere::hit() et HittableList::hit()
__device__ bool world_hit(const Ray& r, double t_min, double t_max, const SphereGPU* spheres, int n, HitRecord& rec) {
    HitRecord tmp;
    bool hit_anything = false;
    double closest = t_max;

    for (int i = 0; i < n; ++i) {
        Vec3 oc = r.origin() - spheres[i].center;
        double a = dot(r.direction(), r.direction());
        double b = 2.0 * dot(oc, r.direction());
        double c = dot(oc, oc) - spheres[i].radius * spheres[i].radius;
        double discriminant = b*b - 4*a*c;
        if (discriminant < 0) continue;

        double t = (-b - sqrt(discriminant)) / (2.0*a);
        if (t < t_min || t > closest) {
            t = (-b + sqrt(discriminant)) / (2.0*a);
            if (t < t_min || t > closest) continue;
        }

        hit_anything = true;
        closest = t;
        tmp.t = t;
        tmp.p = r.at(t);
        tmp.sphere_idx = i;
        Vec3 outward = (tmp.p - spheres[i].center) / spheres[i].radius;
        tmp.set_face_normal(r, outward);
    }
    if (hit_anything) rec = tmp;
    return hit_anything;
}

// ray_color : portage direct de main.cpp du v3 cpu
//
// Idem que CPU : intersection -> shade() -> réflexion
// La récursion est remplacée par une boucle parce que c'est pas possible sur GPU 
// (pile GPU limitée, et les boucles évitent la divergence de warp sur les rebonds)

__device__ Color ray_color_gpu(Ray r, const SphereGPU* spheres, int ns, const LightGPU* lights, int nl, int depth)
{
    Color accumulated(0, 0, 0);
    Color throughput(1, 1, 1);   // atténuation cumulée (donc en gros ça équivaut retour récursif)

    for (int d = 0; d < depth; ++d) {
        HitRecord rec;
        if (!world_hit(r, 0.001, 1e8, spheres, ns, rec)) {
            break;  // fond noir
        }

        const SphereGPU& s = spheres[rec.sphere_idx];
        Color local(0, 0, 0);

        if (s.mat == MAT_CONSTANT) {
            // couleur fixe, ignore lumières et ombres
            local = s.color;

        } else {
            // lambert et metal : lumière ambiante + lumière diffuse/spéculaire
            double ambient_factor = (s.mat == MAT_LAMBERT) ? 0.08 : 0.05;
            local = s.color * ambient_factor;

            for (int l = 0; l < nl; ++l) {
                Vec3 to_light = lights[l].position - rec.p;
                double dist = to_light.length();
                Vec3 ld = to_light / dist;

                // On teste l'ombre
                Ray shadow_ray(rec.p, ld);
                HitRecord shadow_rec;
                if (world_hit(shadow_ray, 0.001, dist - 0.001, spheres, ns, shadow_rec))
                    continue;  // objet entre la surface et la lumière = ombre

                if (s.mat == MAT_LAMBERT) {
                    // lambert : diffuse = max(0, N.L)
                    double diffuse = fmax(0.0, dot(rec.normal, ld));
                    local += s.color * lights[l].color * diffuse * lights[l].intensity;

                } else {  // MAT_METAL
                    // metal : spéculaire Phong, ^64
                    Vec3 view_dir = unit_vector(-r.direction());
                    Vec3 refl_dir = unit_vector(ld) - 2.0 * dot(unit_vector(ld), rec.normal) * rec.normal;
                    double spec = pow(fmax(0.0, dot(view_dir, -refl_dir)), 64.0);
                    local += s.color * lights[l].color * spec * lights[l].intensity;
                }
            }
        }

        accumulated += throughput * local;

        // metal : rayon réfléchi avec flou (fuzz)
        if (s.mat == MAT_METAL) {
            Vec3 reflected = unit_vector(r.direction()) - 2.0 * dot(unit_vector(r.direction()), rec.normal) * rec.normal;
            throughput = throughput * s.color;
            r = Ray(rec.p, reflected);   // prochain rayon (pas de flou sur GPU sans RNG ici)
        } else {
            break;  // Lambert et Constant n'ont pas de rebond (scatter() retourne false dans ce cas du coup)
        }
    }
    return accumulated;
}

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
int main() {
    // Paramètres de l'image
    const int image_width  = 1080;
    const int image_height = 1920;
    const char* output_file = "output/v3/output_gpu.ppm";

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

    // Écriture 
    std::ofstream out(output_file);
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
