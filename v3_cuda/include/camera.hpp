#ifndef CAMERA_HPP
#define CAMERA_HPP

// Adaptation GPU 

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
     * @param image_width Largeur de l'image en pixels
     * @param image_height Hauteur de l'image en pixels
     * @param viewport_width Largeur du viewport (par défaut 2.0)
     * @param focal_length Distance focale caméra→plan image (par défaut 1.0)
     */
    __host__ __device__ Camera(int image_width, int image_height, double viewport_width = 2.0, double focal_length = 1.0)
        : img_width(image_width), img_height(image_height)
    {
        const double aspect_ratio = double(image_width) / double(image_height);
        const double viewport_height = viewport_width / aspect_ratio;

        origin = Point3(0, 0, 0);
        horizontal = Vec3(viewport_width,  0, 0);
        vertical = Vec3(0, viewport_height, 0);
        lower_left = origin - horizontal / 2.0 - vertical / 2.0 - Vec3(0, 0, focal_length);
    }

    /// Génère un rayon passant par le pixel normalisé (u, v)
    __host__ __device__ Ray get_ray(double u, double v) const {
        Point3 pixel = lower_left + u * horizontal + v * vertical;
        return Ray(origin, pixel - origin);
    }

    int get_width()  const { return img_width;  }
    int get_height() const { return img_height; }

private:
    int img_width;
    int img_height;
    Point3 origin;
    Point3 lower_left;
    Vec3 horizontal;
    Vec3 vertical;
};

#endif // CAMERA_HPP
