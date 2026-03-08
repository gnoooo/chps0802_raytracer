#ifndef SPHERE_H
#define SPHERE_H

#include "hittable.hpp"

/**
 * @brief Sphère : objet Hittable défini par un centre, un rayon et une couleur
 */
class Sphere : public Hittable {
public:
    Point3 center;
    double radius;
    Color  color;

    Sphere(const Point3& center, double radius, const Color& color);

    bool hit(const Ray& r, double t_min, double t_max, HitRecord& rec) const override;
};

#endif // SPHERE_H