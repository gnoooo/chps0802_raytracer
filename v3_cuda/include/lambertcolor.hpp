#ifndef LAMBERT_COLOR_HPP
#define LAMBERT_COLOR_HPP

#include "material.hpp"
#include "hittable.hpp"
#include "hittable_list.hpp"
#include "light.hpp"
#include "vec3.hpp"

class LambertColor : public Material {
public:
    Color color;
    constexpr static double AMBIENT = 0.08;

    LambertColor(const Color& c): color(c) {}

    bool scatter(
        const Ray& r_in,
        const HitRecord& rec,
        Vec3& attenuation,
        Ray& scattered
    ) const {
        attenuation = color;
        return false;
    };

    Color shade(const HitRecord& rec,
                const std::vector<PointLight>& lights,
                const HittableList& world) const
    {
        Color result = color * AMBIENT;

        for (const auto& light : lights) {
            Vec3 to_light = light.position - rec.p;
            double dist = to_light.length();
            Vec3 dir = to_light / dist;

            Ray shadow_ray(rec.p, dir);
            HitRecord shadow_rec;
            if (world.hit(shadow_ray, 0.001, dist - 0.001, shadow_rec))
                continue; // ombre

            double diffuse = std::max(0.0, dot(rec.normal, dir));
            result += color * light.color * diffuse * light.intensity;
        }

        return result;
    }
};

#endif // LAMBERT_COLOR_HPP
