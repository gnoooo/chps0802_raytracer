// kernels.cuh 
// Structures et fonctions device partagées

#pragma once

#include <cuda_runtime.h>
#include "vec3.hpp"
#include "ray.hpp"

//Types GPU

enum MatType { MAT_LAMBERT, MAT_METAL, MAT_CONSTANT };

// Sphère : géométrie + matériau dans un même struct
struct SphereGPU {
    Point3  center;
    double  radius;
    Color   color;   // albedo (Lambert/Metal) ou couleur fixe (Constant)
    MatType mat;
    double  fuzz;    // uniquement pour MAT_METAL
};

// Source lumineuse (identique à PointLight mais compatible device)
struct LightGPU {
    Point3 position;
    Color  color;
    double intensity;
};

#define MAX_SPHERES 8
#define MAX_LIGHTS  4

// HitRecord

struct HitRecord {
    Point3 p;
    Vec3   normal;
    double t;
    bool   front_face;
    int    sphere_idx;

    __device__ void set_face_normal(const Ray& r, const Vec3& outward_normal) {
        front_face = dot(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal : -outward_normal;
    }
};

// world_hit
// Mélange de Sphere::hit() et HittableList::hit() de la v3 CPU

__device__ inline bool world_hit(const Ray& r, double t_min, double t_max, const SphereGPU* spheres, int n, HitRecord& rec)
{
    HitRecord tmp;
    bool hit_anything = false;
    double closest = t_max;

    for (int i = 0; i < n; ++i) {
        Vec3   oc = r.origin() - spheres[i].center;
        double a  = dot(r.direction(), r.direction());
        double b  = 2.0 * dot(oc, r.direction());
        double c  = dot(oc, oc) - spheres[i].radius * spheres[i].radius;
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

// ray_color_gpu
//
// Portage direct de ray_color() de main.cpp v3 CPU
// La récursion est remplacée par une boucle (pile GPU limitée + évite la divergence de warp sur les rebonds)

__device__ inline Color ray_color_gpu(
    Ray r,
    const SphereGPU* spheres,
    int ns,
    const LightGPU* lights,
    int nl,
    int depth
) {
    Color accumulated(0, 0, 0);
    Color throughput(1, 1, 1);

    for (int d = 0; d < depth; ++d) {
        HitRecord rec;
        if (!world_hit(r, 0.001, 1e8, spheres, ns, rec))
            break; // fond noir

        const SphereGPU& s = spheres[rec.sphere_idx];
        Color local(0, 0, 0);

        if (s.mat == MAT_CONSTANT) {
            local = s.color;

        } else {
            double ambient_factor = (s.mat == MAT_LAMBERT) ? 0.08 : 0.05;
            local = s.color * ambient_factor;

            for (int l = 0; l < nl; ++l) {
                Vec3 to_light = lights[l].position - rec.p;
                double dist = to_light.length();
                Vec3 ld = to_light / dist;

                Ray      shadow_ray(rec.p, ld);
                HitRecord shadow_rec;
                if (world_hit(shadow_ray, 0.001, dist - 0.001, spheres, ns, shadow_rec))
                    continue; // ombre

                if (s.mat == MAT_LAMBERT) {
                    double diffuse = fmax(0.0, dot(rec.normal, ld));
                    local += s.color * lights[l].color * diffuse * lights[l].intensity;
                } else { // MAT_METAL
                    Vec3 view_dir = unit_vector(-r.direction());
                    Vec3 refl_dir = unit_vector(ld) - 2.0 * dot(unit_vector(ld), rec.normal) * rec.normal;
                    double spec = pow(fmax(0.0, dot(view_dir, -refl_dir)), 64.0);
                    local += s.color * lights[l].color * spec * lights[l].intensity;
                }
            }
        }

        accumulated += throughput * local;

        if (s.mat == MAT_METAL) {
            Vec3 reflected = unit_vector(r.direction()) - 2.0 * dot(unit_vector(r.direction()), rec.normal) * rec.normal;
            throughput = throughput * s.color;
            r = Ray(rec.p, reflected);
        } else {
            break;
        }
    }
    return accumulated;
}
