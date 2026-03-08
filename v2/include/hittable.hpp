#ifndef HITTABLE_H
#define HITTABLE_H

#include "ray.hpp"
#include "vec3.hpp"

/**
 * @brief Enregistre les informations d'une intersection rayon et objet
 */
struct HitRecord {
    Point3 p;         ///< Point d'intersection
    Vec3   normal;    ///< Normale à la surface (toujours orientée vers le rayon)
    Color  color;     ///< Couleur de l'objet (remplacé par Material plus tard)
    double t;         ///< Paramètre du rayon à l'intersection
    bool   front_face; ///< true si le rayon entre dans l'objet

    /// Calcule et stocke la normale orientée selon le sens du rayon
    void set_face_normal(const Ray& r, const Vec3& outward_normal) {
        front_face = dot(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal : -outward_normal;
    }
};

/**
 * @brief Interface commune à tout objet pouvant être touché par un rayon
 */
class Hittable {
public:
    virtual ~Hittable() = default;

    /**
     * @param r       Rayon à tester
     * @param t_min   Borne inférieure du paramètre t valide
     * @param t_max   Borne supérieure du paramètre t valide
     * @param rec     Résultat de l'intersection (rempli si true)
     * @return true   si le rayon touche l'objet dans [t_min, t_max]
     */
    virtual bool hit(const Ray& r, double t_min, double t_max, HitRecord& rec) const = 0;
};

#endif // HITTABLE_H
