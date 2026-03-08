#ifndef VEC3_H
#define VEC3_H

#include <iostream>

class Vec3 {
public:
    double x, y, z;

    Vec3();
    Vec3(double e0, double e1, double e2);

    Vec3 operator-() const;
    Vec3& operator+=(const Vec3 &v);
    Vec3& operator*=(const double t);
    Vec3& operator/=(const double t);

    double length() const;
    double length_squared() const;

    static Vec3 random(double a=0, double b=1);
};

// Opérateurs arithmétiques
Vec3 operator+(const Vec3 &u, const Vec3 &v);
Vec3 operator-(const Vec3 &u, const Vec3 &v);
Vec3 operator*(const Vec3 &u, const Vec3 &v);
Vec3 operator*(double t, const Vec3 &v);
Vec3 operator*(const Vec3 &v, double t);
Vec3 operator/(Vec3 v, double t);

// Fonctions utilitaires
double dot(const Vec3 &u, const Vec3 &v);
Vec3 cross(const Vec3 &u, const Vec3 &v);
Vec3 unit_vector(Vec3 v);

// Alias de types
using Point3 = Vec3;  // 3D point
using Color = Vec3;   // RGB color

// Fonction pour écrire la couleur
void write_color(std::ostream &out, Color pixel_color);

#endif // VEC3_H
