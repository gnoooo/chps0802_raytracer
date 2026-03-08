#ifndef SPHERE_H
#define SPHERE_H

#include "ray.hpp"

/**
 * @brief Calcule si un rayon intersecte une sphère et retourne la valeur de t pour l'intersection
 * @param center Centre de la sphère
 * @param radius Rayon de la sphère
 * @param r Rayon à tester
 * @return double Valeur de t pour l'intersection, ou -1.0 si pas d'intersection
 */
double hit_sphere(const Point3& center, double radius, const Ray& r);

#endif // SPHERE_H
