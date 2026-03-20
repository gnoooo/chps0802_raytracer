#include "../include/sphere.hpp"
#include "../include/material.hpp"
#include <cmath>
#include <memory>

Sphere::Sphere(const Point3& center, double radius, std::shared_ptr<Material> mat)
    : center(center), radius(radius), mat_ptr(mat) {}

bool Sphere::hit(const Ray& r, double t_min, double t_max, HitRecord& rec) const {
    Vec3   oc = r.origin() - center;
    double a  = dot(r.direction(), r.direction());
    double b  = 2.0 * dot(oc, r.direction());
    double c  = dot(oc, oc) - radius * radius;
    double discriminant = b * b - 4 * a * c;

    if (discriminant < 0) return false;

    // Racine la plus proche dans [t_min, t_max]
    double t = (-b - std::sqrt(discriminant)) / (2.0 * a);
    if (t < t_min || t > t_max) {
        t = (-b + std::sqrt(discriminant)) / (2.0 * a);
        if (t < t_min || t > t_max) return false;
    }

    rec.t = t;
    rec.p = r.at(t);
    rec.mat_ptr = mat_ptr;
    Vec3 outward_normal = (rec.p - center) / radius;
    rec.set_face_normal(r, outward_normal);

    return true;
}
