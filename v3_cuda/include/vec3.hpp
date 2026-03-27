#ifndef VEC3_HPP
#define VEC3_HPP

// Adaptation GPU :
// - __host__ __device__ sur toutes les méthodes utilisées dans les kernels
// - Implémentations inlinées ici (nvcc ne compile pas les .cpp séparément pour le code device, donc on doit tout mettre dans les headers)
// - sqrt/fmax/fmin non qualifiés : disponibles en device, contrairement à std:: (donc on utilise les version CUDA)
// - random() et write_color() restent __host__ (rand/ostream indisponibles côté GPU, donc on les met que pour le CPU)

#include <cmath>
#include <cstdlib>
#include <iostream>

class Vec3 {
public:
    double x, y, z;

    __host__ __device__ Vec3() : x(0), y(0), z(0) {}
    __host__ __device__ Vec3(double e0, double e1, double e2) : x(e0), y(e1), z(e2) {}

    __host__ __device__ Vec3 operator-() const { return Vec3(-x, -y, -z); }

    __host__ __device__ Vec3& operator+=(const Vec3 &v) {
        x += v.x; y += v.y; z += v.z; return *this;
    }
    __host__ __device__ Vec3& operator*=(const double t) {
        x *= t; y *= t; z *= t; return *this;
    }
    __host__ __device__ Vec3& operator/=(const double t) { return *this *= 1/t; }

    __host__ __device__ double length() const { return sqrt(length_squared()); }
    __host__ __device__ double length_squared() const { return x*x + y*y + z*z; }

    // random() que pour le CPU
    static Vec3 random(double a = 0, double b = 1) {
        return Vec3(
            a + (b-a)*rand()/(RAND_MAX+1.0),
            a + (b-a)*rand()/(RAND_MAX+1.0),
            a + (b-a)*rand()/(RAND_MAX+1.0)
        );
    }
};

// Opérateurs arithmétiques
// __host__ et __device__ pour être dispo dans les kernels
__host__ __device__ inline Vec3 operator+(const Vec3 &u, const Vec3 &v) { return Vec3(u.x+v.x, u.y+v.y, u.z+v.z); }
__host__ __device__ inline Vec3 operator-(const Vec3 &u, const Vec3 &v) { return Vec3(u.x-v.x, u.y-v.y, u.z-v.z); }
__host__ __device__ inline Vec3 operator*(const Vec3 &u, const Vec3 &v) { return Vec3(u.x*v.x, u.y*v.y, u.z*v.z); }
__host__ __device__ inline Vec3 operator*(double t, const Vec3 &v)      { return Vec3(t*v.x, t*v.y, t*v.z); }
__host__ __device__ inline Vec3 operator*(const Vec3 &v, double t)      { return t * v; }
__host__ __device__ inline Vec3 operator/(Vec3 v, double t)             { return (1/t) * v; }

// Fonctions utilitaires
__host__ __device__ inline double dot(const Vec3 &u, const Vec3 &v) {
    return u.x*v.x + u.y*v.y + u.z*v.z;
}
__host__ __device__ inline Vec3 cross(const Vec3 &u, const Vec3 &v) {
    return Vec3(
        u.y*v.z - u.z*v.y,
        u.z*v.x - u.x*v.z,
        u.x*v.y - u.y*v.x
    );
}
__host__ __device__ inline Vec3 unit_vector(Vec3 v) { return v / v.length(); }

// __host__ uniquement (boucle avec rand() donc que CPU)
inline Vec3 random_in_unit_sphere() {
    while (true) {
        Vec3 p = Vec3::random(-1, 1);
        if (p.length_squared() >= 1) continue;
        return p;
    }
}

// Alias de types
using Point3 = Vec3;
using Color  = Vec3;

// __host__ uniquement (std::ostream donc que CPU)
inline void write_color(std::ostream &out, Color pixel_color) {
    int ir = static_cast<int>(255.999 * fmax(0.0, fmin(1.0, pixel_color.x)));
    int ig = static_cast<int>(255.999 * fmax(0.0, fmin(1.0, pixel_color.y)));
    int ib = static_cast<int>(255.999 * fmax(0.0, fmin(1.0, pixel_color.z)));
    out << ir << ' ' << ig << ' ' << ib << '\n';
}

#endif // VEC3_HPP
