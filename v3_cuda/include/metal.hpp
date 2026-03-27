#ifndef METAL_HPP
#define METAL_HPP

#include "material.hpp"
#include "hittable.hpp"
#include "vec3.hpp"

#include <cmath>

inline Vec3 reflect(const Vec3& v, const Vec3& n) { return v - 2 * dot(v, n) * n; }

class Metal : public Material {
public:
    Color albedo;
    double fuzz;
    constexpr static double AMBIENT = 0.05;


    Metal(const Color& a, double f) : albedo(a), fuzz(f < 1 ? f : 1) {};

    bool scatter(
        const Ray& r_in,
        const HitRecord& rec,
        Vec3& attenuation,
        Ray& scattered
    ) const {
        Vec3 reflected = reflect(unit_vector(r_in.direction()), rec.normal);
        scattered = Ray(rec.p, reflected + fuzz * random_in_unit_sphere());
        attenuation = albedo;
        return dot(scattered.direction(), rec.normal) > 0;
    };

    Color shade(
        const HitRecord& rec,
        const std::vector<PointLight>& lights,
        const HittableList& world
    ) const {
        Color result = albedo * AMBIENT;

        for (const auto& light : lights) {
            Vec3 to_light = light.position - rec.p;
            double dist = to_light.length();
            Vec3 dir = to_light / dist;

            Ray shadow_ray(rec.p, dir);
            HitRecord shadow_rec;
            if (world.hit(shadow_ray, 0.001, dist - 0.001, shadow_rec))
                continue; // ombre

            Vec3 view_dir = unit_vector(-rec.ray_in.direction());
            Vec3 reflect_dir = reflect(-dir, rec.normal);
            double spec = std::pow(std::max(dot(view_dir, reflect_dir), 0.0), 64); // 64 = brillance

            result += albedo * light.color * spec * light.intensity;
        }

        return result;
    }
};

#endif // METAL_HPP
