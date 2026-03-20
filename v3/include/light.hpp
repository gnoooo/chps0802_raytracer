#ifndef LIGHT_HPP
#define LIGHT_HPP

#include "vec3.hpp"

/**
 * @brief Source lumineuse ponctuelle
 *
 * Utilisée dans le modèle de Lambert :
 *   diffuse = max(0, dot(N, L)) * surface_color * light_color * intensity
 */
struct PointLight {
    Point3 position;   // Position de la lumière dans l'espace
    Color  color;      // Couleur/teinte de la lumière (composantes dans [0,1])
    double intensity;  // Intensité de la lumière (multiplicateur)

    PointLight(const Point3& pos, const Color& col, double intensity = 1.0)
        : position(pos), color(col), intensity(intensity) {}
};

#endif // LIGHT_HPP
