#ifndef SPHERE_HPP
#define SPHERE_HPP

#include "hittable.hpp"
#include <memory>

/**
 * @brief Sphère : objet Hittable défini par un centre, un rayon et une couleur
 */
class Sphere : public Hittable {
public:
    Point3 center;
    double radius;
    std::shared_ptr<Material> mat_ptr;

    Sphere(const Point3& center, double radius, std::shared_ptr<Material> mat);

    bool hit(const Ray& r, double t_min, double t_max, HitRecord& rec) const override;
};

#endif // SPHERE_HPP
