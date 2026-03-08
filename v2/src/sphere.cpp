#include "../include/sphere.hpp"
#include <cmath>

Sphere::Sphere(const Point3& center, double radius, const Color& color)
    : center(center), radius(radius), color(color) {}

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
    rec.color = color;
    Vec3 outward_normal = (rec.p - center) / radius;
    rec.set_face_normal(r, outward_normal);

    return true;
}