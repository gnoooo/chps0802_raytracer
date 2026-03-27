#ifndef MATERIAL_HPP
#define MATERIAL_HPP

// #include "hittable.hpp"
#include "ray.hpp"
#include "vec3.hpp"
#include "light.hpp"

#include <vector>

class HitRecord;
class HittableList;

class Material {
public:
    virtual ~Material() = default;

   virtual bool scatter(
    const Ray& r_in,
    const HitRecord& rec,
    Vec3& attenuation,
    Ray& scattered
   ) const = 0;

   virtual Color shade(const HitRecord& rec, const std::vector<PointLight>& lights, const HittableList& world) const = 0;
};

#endif // MATERIAL_HPP
