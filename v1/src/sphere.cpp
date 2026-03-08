#include "../include/sphere.hpp"
#include <cmath>

/**
 * @brief Teste l'intersection avec une sphère
 * @return distance t si intersection, -1.0 sinon
 */
double hit_sphere(const Point3& center, double radius, const Ray& r) {
    Vec3 oc = r.origin() - center;
    double a = dot(r.direction(), r.direction());
    double b = 2.0 * dot(oc, r.direction());
    double c = dot(oc, oc) - radius * radius;
    double discriminant = b*b - 4*a*c;
    
    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-b - std::sqrt(discriminant)) / (2.0 * a);
    }
}
