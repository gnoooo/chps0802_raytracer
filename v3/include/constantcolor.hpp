#ifndef CONSTANT_COLOR_HPP
#define CONSTANT_COLOR_HPP

#include "material.hpp"
#include "hittable.hpp"
#include "vec3.hpp"

class ConstantColor : public Material {
public:
    Color color;

    ConstantColor(const Color& c): color(c) {}

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
        // Couleur constante, ignore lumière et ombre
        return color;
    }
};

#endif // CONSTANT_COLOR_HPP
