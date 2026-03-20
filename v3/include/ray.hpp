#ifndef RAY_HPP
#define RAY_HPP

#include "vec3.hpp"


class Ray {
public:
    Point3 orig; // point o
    Vec3 dir;    // vecteur d

    Ray();
    Ray(const Point3& origin, const Vec3& direction);

    Point3 origin() const;
    Vec3 direction() const;
    Point3 at(double t) const;
};

#endif // RAY_HPP
