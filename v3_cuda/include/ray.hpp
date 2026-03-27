#ifndef RAY_HPP
#define RAY_HPP

// Adaptation GPU

#include "vec3.hpp"

class Ray {
public:
    Point3 orig; // point o
    Vec3 dir;    // vecteur d

    __host__ __device__ Ray() {}
    __host__ __device__ Ray(const Point3& origin, const Vec3& direction)
        : orig(origin), dir(direction) {}

    __host__ __device__ Point3 origin()    const { return orig; }
    __host__ __device__ Vec3   direction() const { return dir; }
    __host__ __device__ Point3 at(double t) const { return orig + t * dir; }
};

#endif // RAY_HPP
