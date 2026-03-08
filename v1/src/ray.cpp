#include "../include/ray.hpp"

// Constructeurs
/**
 * @brief Construit un nouveau rayon avec une origine et une direction par défaut 
 */
Ray::Ray() {}

/**
 * @brief Construit un nouveau rayon avec une origine et une direction spécifiées
 * @param origin Origine du rayon
 * @param direction Direction du rayon
 */
Ray::Ray(const Point3& origin, const Vec3& direction) 
    : orig(origin), dir(direction) {}

// Méthodes
/**
 * @brief Retourne l'origine du rayon
 * @return Point3 Origine du rayon
 */
Point3 Ray::origin() const {
    return orig;
}

/**
 * @brief Retourne la direction du rayon
 * @return Vec3 Direction du rayon 
 */
Vec3 Ray::direction() const {
    return dir;
}

/**
 * @brief Calcule le point le long du rayon à un paramètre t donné (p = o + t*d)
 * @param t Valeur fixée du rayon
 * @return Point3 Point le long du rayon à la position t
 */
Point3 Ray::at(double t) const {
    return orig + t * dir;
}
