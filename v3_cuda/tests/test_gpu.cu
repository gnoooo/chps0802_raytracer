// Tests unitaires v3 CUDA


#include <cuda_runtime.h>
#include <iostream>
#include <cmath>

#include "../include/vec3.hpp"
#include "../include/ray.hpp"
#include "../include/camera.hpp"
#include "../include/kernels.cuh"

// Host
static int g_pass = 0, g_fail = 0;

#define CHECK_H(cond, msg) do {                                             \
    if (cond) { std::cout << "  PASS : " << (msg) << "\n"; ++g_pass; }     \
    else       { std::cerr << "  FAIL : " << (msg) << "\n"; ++g_fail; }    \
} while(0)

static bool near_eq_h(double a, double b, double eps = 1e-9) {
    return std::abs(a - b) < eps;
}
static bool vec_eq_h(const Vec3& a, const Vec3& b, double eps = 1e-9) {
    return near_eq_h(a.x, b.x, eps) && near_eq_h(a.y, b.y, eps) && near_eq_h(a.z, b.z, eps);
}

// Device
#define CHECK_D(cond, msg, pass_ptr, fail_ptr) do { \
    if (cond) { printf("  PASS : %s\n", (msg)); atomicAdd((pass_ptr), 1); } \
    else       { printf("  FAIL : %s\n", (msg)); atomicAdd((fail_ptr), 1); } \
} while(0)

__device__ bool near_eq_d(double a, double b, double eps = 1e-9) {
    return fabs(a - b) < eps;
}
__device__ bool vec_eq_d(const Vec3& a, const Vec3& b, double eps = 1e-9) {
    return near_eq_d(a.x, b.x, eps) && near_eq_d(a.y, b.y, eps) && near_eq_d(a.z, b.z, eps);
}

// Tests host : Vec3
void test_vec3_host() {
    std::cout << "\n[ Vec3 — host ]\n";
    Vec3 a(1, 2, 3), b(4, 5, 6);

    CHECK_H(vec_eq_h(a + b, Vec3(5, 7, 9)),                              "operator+");
    CHECK_H(vec_eq_h(a - b, Vec3(-3, -3, -3)),                           "operator-");
    CHECK_H(vec_eq_h(a * b, Vec3(4, 10, 18)),                            "operator* (composante)");
    CHECK_H(vec_eq_h(2.0 * a, Vec3(2, 4, 6)),                            "operator* (scalaire gauche)");
    CHECK_H(vec_eq_h(a * 2.0, Vec3(2, 4, 6)),                            "operator* (scalaire droit)");
    CHECK_H(vec_eq_h(a / 2.0, Vec3(0.5, 1.0, 1.5)),                     "operator/");
    CHECK_H(vec_eq_h(-a, Vec3(-1, -2, -3)),                              "operateur- unaire");
    CHECK_H(near_eq_h(dot(a, b), 32.0),                                  "dot product");
    CHECK_H(vec_eq_h(cross(Vec3(1,0,0), Vec3(0,1,0)), Vec3(0,0,1)),     "cross product");
    CHECK_H(near_eq_h(a.length_squared(), 14.0),                         "length_squared");
    CHECK_H(near_eq_h(a.length(), std::sqrt(14.0)),                      "length");
    CHECK_H(vec_eq_h(unit_vector(Vec3(3, 0, 0)), Vec3(1, 0, 0)),        "unit_vector");
}

// Tests host : Ray
void test_ray_host() {
    std::cout << "\n[ Ray — host ]\n";
    Ray r(Point3(1, 2, 3), Vec3(0, 0, -1));

    CHECK_H(vec_eq_h(r.origin(),    Point3(1, 2, 3)), "origin()");
    CHECK_H(vec_eq_h(r.direction(), Vec3(0, 0, -1)),  "direction()");
    CHECK_H(vec_eq_h(r.at(0.0),    Point3(1, 2, 3)), "at(0)");
    CHECK_H(vec_eq_h(r.at(2.0),    Point3(1, 2, 1)), "at(2)");
}

// Tests host : Camera
void test_camera_host() {
    std::cout << "\n[ Camera — host ]\n";
    Camera cam(100, 100);

    CHECK_H(cam.get_width()  == 100, "get_width");
    CHECK_H(cam.get_height() == 100, "get_height");

    // Rayon central → doit pointer vers -Z
    Ray center = cam.get_ray(0.5, 0.5);
    Vec3 d = unit_vector(center.direction());
    CHECK_H(near_eq_h(d.z, -1.0, 1e-6),                              "rayon central pointe vers -Z");
    CHECK_H(near_eq_h(d.x, 0.0, 1e-6) && near_eq_h(d.y, 0.0, 1e-6), "rayon central : x,y nuls");

    // Origine caméra
    CHECK_H(vec_eq_h(cam.get_ray(0.0, 0.0).origin(), Point3(0,0,0)), "origine camera");

    // Coin bas-gauche pointe vers (-x,-y,-z)
    Vec3 cd = unit_vector(cam.get_ray(0.0, 0.0).direction());
    CHECK_H(cd.x < 0 && cd.y < 0 && cd.z < 0, "coin bas-gauche : direction negative sur x,y,z");
}

// Tests device : world_hit
__global__ void test_world_hit_kernel(int* pass, int* fail) {
    printf("\n[ world_hit — device ]\n");

    // Sphère unique en (0,0,-2), rayon 1.0
    SphereGPU spheres[2];
    spheres[0] = { Point3(0,0,-2), 1.0, Color(1,0,0), MAT_LAMBERT, 0.0 };
    spheres[1] = { Point3(0,0,-3), 0.5, Color(0,1,0), MAT_LAMBERT, 0.0 };

    HitRecord rec;

    // Rayon frontal : hit à t=1.0
    // oc=(0,0,2), a=1, b=-4, c=3, disc=4 → t=1.0
    Ray r_front(Point3(0,0,0), Vec3(0,0,-1));
    bool hit = world_hit(r_front, 0.001, 1e8, spheres, 1, rec);
    CHECK_D(hit,                             "hit (rayon frontal)",          pass, fail);
    CHECK_D(near_eq_d(rec.t, 1.0, 1e-9),    "t = 1.0 (face avant)",         pass, fail);
    CHECK_D(rec.front_face,                  "front_face = true",            pass, fail);
    CHECK_D(rec.sphere_idx == 0,             "sphere_idx = 0",               pass, fail);
    CHECK_D(near_eq_d(rec.normal.z, 1.0, 1e-6), "normale pointe vers +Z",   pass, fail);

    // Rayon décalé : miss
    Ray r_miss(Point3(2, 0, 0), Vec3(0, 0, -1));
    HitRecord rec2;
    CHECK_D(!world_hit(r_miss, 0.001, 1e8, spheres, 1, rec2), "miss (rayon decale)", pass, fail);

    // t_max trop petit
    HitRecord rec3;
    CHECK_D(!world_hit(r_front, 0.001, 0.5, spheres, 1, rec3), "miss (t_max < t_impact)", pass, fail);

    // Rayon depuis l'intérieur → face arrière
    Ray r_inside(Point3(0, 0, -2), Vec3(0, 0, -1));
    HitRecord rec4;
    bool hit_inside = world_hit(r_inside, 0.001, 1e8, spheres, 1, rec4);
    CHECK_D(hit_inside,        "hit depuis interieur",          pass, fail);
    CHECK_D(!rec4.front_face,  "front_face = false (interieur)", pass, fail);

    // Deux sphères : sélectionne la plus proche
    HitRecord rec5;
    bool hit2 = world_hit(r_front, 0.001, 1e8, spheres, 2, rec5);
    CHECK_D(hit2,                 "hit (2 spheres)",                         pass, fail);
    CHECK_D(rec5.t < 2.0,         "sphere la plus proche selectionnee (t<2)", pass, fail);
    CHECK_D(rec5.sphere_idx == 0, "sphere_idx pointe la sphere proche",      pass, fail);
}

// Tests device : ray_color_gpu
__global__ void test_ray_color_kernel(int* pass, int* fail) {
    printf("\n[ ray_color_gpu — device ]\n");

    // Sphère constante jaune en (0,0,-2)
    SphereGPU spheres[1];
    spheres[0] = { Point3(0,0,-2), 1.0, Color(1.0, 0.95, 0.4), MAT_CONSTANT, 0.0 };

    LightGPU lights[1];
    lights[0] = { Point3(0, 10, 0), Color(1,1,1), 1.0 };

    // Rayon manquant = fond noir (0,0,0)
    Ray r_miss(Point3(0,0,0), Vec3(0,0,1));  // vers +Z, pas de sphère
    Color c_miss = ray_color_gpu(r_miss, spheres, 1, lights, 1, 10);
    CHECK_D(near_eq_d(c_miss.x, 0.0, 1e-9) &&
            near_eq_d(c_miss.y, 0.0, 1e-9) &&
            near_eq_d(c_miss.z, 0.0, 1e-9),
            "ray_color_gpu : rayon manquant → (0,0,0)", pass, fail);

    // Sphère constante → retourne sa couleur fixe
    Ray r_hit(Point3(0,0,0), Vec3(0,0,-1));
    Color c_const = ray_color_gpu(r_hit, spheres, 1, lights, 1, 10);
    CHECK_D(near_eq_d(c_const.x, 1.0,  1e-6) &&
            near_eq_d(c_const.y, 0.95, 1e-6) &&
            near_eq_d(c_const.z, 0.4,  1e-6),
            "ray_color_gpu : MAT_CONSTANT retourne couleur fixe", pass, fail);

    // Sphère lambert sans lumière = ambiante seule = color * 0.08
    SphereGPU s_lambert[1];
    s_lambert[0] = { Point3(0,0,-2), 1.0, Color(1,0,0), MAT_LAMBERT, 0.0 };
    Color c_amb = ray_color_gpu(r_hit, s_lambert, 1, lights, 0, 10);  // nl=0 → nolights
    CHECK_D(near_eq_d(c_amb.x, 0.08, 1e-9),
            "ray_color_gpu : MAT_LAMBERT ambiante seule (rouge * 0.08)", pass, fail);

    // Sphère métal sans lumière = ambiante seule = albedo * 0.05
    SphereGPU s_metal[1];
    s_metal[0] = { Point3(0,0,-2), 1.0, Color(0.3, 0.8, 0.3), MAT_METAL, 0.0 };
    Color c_metal = ray_color_gpu(r_hit, s_metal, 1, lights, 0, 10);

    // Un rayon métal rebondit : accumulated = throughput * (albedo*0.05) au d=0,
    // puis throughput *= albedo et le rayon réfléchi part ailleurs (fond noir)
    // Le résultat attendu est albedo*0.05 = (0.015, 0.04, 0.015).
    CHECK_D(near_eq_d(c_metal.x, 0.3 * 0.05, 1e-9),
            "ray_color_gpu : MAT_METAL ambiante seule (r * 0.05)", pass, fail);
}

// Helpers pour exécuter un kernel de test et récupérer les compteurs
static void run_test_kernel(void (*kernel)(int*, int*), int& total_pass, int& total_fail) {
    int *d_pass, *d_fail;
    cudaMalloc(&d_pass, sizeof(int));
    cudaMalloc(&d_fail, sizeof(int));
    cudaMemset(d_pass, 0, sizeof(int));
    cudaMemset(d_fail, 0, sizeof(int));

    kernel<<<1, 1>>>(d_pass, d_fail);
    cudaDeviceSynchronize();

    int h_pass = 0, h_fail = 0;
    cudaMemcpy(&h_pass, d_pass, sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(&h_fail, d_fail, sizeof(int), cudaMemcpyDeviceToHost);

    total_pass += h_pass;
    total_fail += h_fail;

    cudaFree(d_pass);
    cudaFree(d_fail);
}

// Main
int main() {
    std::cout << "=== Tests unitaires v3 CUDA ===\n";

    // Tests host (Vec3 / Ray / Camera)
    test_vec3_host();
    test_ray_host();
    test_camera_host();

    // Tests device (world_hit / ray_color_gpu)
    int device_pass = 0, device_fail = 0;
    run_test_kernel(test_world_hit_kernel, device_pass, device_fail);
    run_test_kernel(test_ray_color_kernel, device_pass, device_fail);

    // Agréger les résultats device avec les résultats host
    g_pass += device_pass;
    g_fail += device_fail;

    std::cout << "  PASS : " << g_pass << "\n";
    if (g_fail > 0)
        std::cerr << "  FAIL : " << g_fail << "\n";
    else
        std::cout << "  Tous les tests sont passes !\n";
    return g_fail > 0 ? 1 : 0;
}
