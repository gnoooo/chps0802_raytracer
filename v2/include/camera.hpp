#ifndef CAMERA_H
#define CAMERA_H

#include "ray.hpp"

/**
 * @brief Caméra
 *
 * Encapsule la configuration du viewport et la génération de rayons
 * Utilisation :
 *   Camera cam(image_width, image_height);
 *   Ray r = cam.get_ray(u, v);  // u,v dans [0,1]
 */
class Camera {
public:
    /**
     * @param image_width    Largeur de l'image en pixels
     * @param image_height   Hauteur de l'image en pixels
     * @param viewport_width Largeur du viewport (par défaut 2.0)
     * @param focal_length   Distance focale caméra→plan image (par défaut 1.0)
     */
    Camera(int image_width, int image_height, double viewport_width = 2.0, double focal_length   = 1.0);

    /// Génère un rayon passant par le pixel normalisé (u, v)
    Ray get_ray(double u, double v) const;

    int get_width()  const { return img_width;  }
    int get_height() const { return img_height; }

private:
    int    img_width;
    int    img_height;
    Point3 origin;
    Point3 lower_left;
    Vec3   horizontal;
    Vec3   vertical;
};

#endif // CAMERA_H
