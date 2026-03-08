#include <cmath>
#include <cstdlib>
#include "../include/vec3.hpp"

// Constructeurs
Vec3::Vec3() : x(0), y(0), z(0) {}

Vec3::Vec3(double e0, double e1, double e2) : x(e0), y(e1), z(e2) {}

// Opérateurs unaires
Vec3 Vec3::operator-() const {
    return Vec3(-x, -y, -z);
}

Vec3& Vec3::operator+=(const Vec3 &v) {
    x += v.x;
    y += v.y;
    z += v.z;
    return *this;
}

Vec3& Vec3::operator*=(const double t) {
    x *= t;
    y *= t;
    z *= t;
    return *this;
}

Vec3& Vec3::operator/=(const double t) {
    return *this *= 1/t;
}

// Méthodes de longueur
/**
 * @brief Calcule la longueur du vecteur
 * @return double Longueur du vecteur
 */
double Vec3::length() const {
    return std::sqrt(length_squared());
}

/**
 * @brief Calcule la longueur au carré du vecteur
 * @return double Longueur au carré du vecteur
 */
double Vec3::length_squared() const {
    return x*x + y*y + z*z;
}

// Méthode statique random
/**
 * @brief Génère un vecteur aléatoire avec des composantes dans l'intervalle [a, b]
 * @param a Valeur minimale des composantes
 * @param b Valeur maximale des composantes
 * @return Vec3 Vecteur aléatoire généré
 */
Vec3 Vec3::random(double a, double b) {
    return Vec3(
        a + (b-a)*rand()/(RAND_MAX+1.0),
        a + (b-a)*rand()/(RAND_MAX+1.0),
        a + (b-a)*rand()/(RAND_MAX+1.0)
    );
}

// Opérateurs arithmétiques
Vec3 operator+(const Vec3 &u, const Vec3 &v) {
    return Vec3(u.x + v.x, u.y + v.y, u.z + v.z);
}

Vec3 operator-(const Vec3 &u, const Vec3 &v) {
    return Vec3(u.x - v.x, u.y - v.y, u.z - v.z);
}

Vec3 operator*(const Vec3 &u, const Vec3 &v) {
    return Vec3(u.x * v.x, u.y * v.y, u.z * v.z);
}

Vec3 operator*(double t, const Vec3 &v) {
    return Vec3(t * v.x, t * v.y, t * v.z);
}

Vec3 operator*(const Vec3 &v, double t) {
    return t * v;
}

Vec3 operator/(Vec3 v, double t) {
    return (1/t) * v;
}

// Fonctions utilitaires
/**
 * @brief Calcule le produit scalaire de deux vecteurs
 * @param u Premier vecteur
 * @param v Deuxième vecteur
 * @return double Résultat du produit scalaire
 */
double dot(const Vec3 &u, const Vec3 &v) {
    return u.x*v.x + u.y*v.y + u.z*v.z;
}

/**
 * @brief Calcule le produit vectoriel de deux vecteurs
 * @param u Premier vecteur
 * @param v Deuxième vecteur
 * @return Vec3 Résultat du produit vectoriel
 */
Vec3 cross(const Vec3 &u, const Vec3 &v) {
    return Vec3(
        u.y*v.z - u.z*v.y,
        u.z*v.x - u.x*v.z,
        u.x*v.y - u.y*v.x
    );
}

/**
 * @brief Calcule le vecteur unitaire d'un vecteur donné
 * @param v Vecteur d'entrée
 * @return Vec3 Vecteur unitaire résultant
 */
Vec3 unit_vector(Vec3 v) {
    return v / v.length();
}

// Fonction d'écriture de couleur
/**
 * @brief Écrit la couleur d'un pixel dans le flux de sortie
 * @param out Flux de sortie
 * @param pixel_color Couleur du pixel
 */
void write_color(std::ostream &out, Color pixel_color) {
    // Clamp et conversion en entier [0, 255]
    int ir = static_cast<int>(255.999 * std::fmax(0.0, std::fmin(1.0, pixel_color.x)));
    int ig = static_cast<int>(255.999 * std::fmax(0.0, std::fmin(1.0, pixel_color.y)));
    int ib = static_cast<int>(255.999 * std::fmax(0.0, std::fmin(1.0, pixel_color.z)));
    out << ir << ' ' << ig << ' ' << ib << '\n';
}
