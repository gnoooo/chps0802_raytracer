#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "hittable.hpp"
#include <vector>
#include <memory>

/**
 * @brief Conteneur de la scène (liste de tous les objets Hittable)
 *
 * Pour ajouter un objet :
 *   world.add(std::make_shared<Sphere>(...));
 */
class HittableList : public Hittable {
public:
    std::vector<std::shared_ptr<Hittable>> objects;

    HittableList() = default;

    void clear() { objects.clear(); }

    void add(std::shared_ptr<Hittable> object) {
        objects.push_back(std::move(object));
    }

    /// Retourne true si le rayon touche au moins un objet (conserve le plus proche)
    bool hit(const Ray& r, double t_min, double t_max, HitRecord& rec) const override;
};

#endif // HITTABLE_LIST_H
