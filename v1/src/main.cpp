#include <iostream>
#include <fstream>
#include <cmath>
#include "../include/vec3.hpp"
#include "../include/ray.hpp"
#include "../include/sphere.hpp"


/**
 * @brief Calcule la couleur d'un rayon (version de test avec 3 sphères)
 */
Color ray_color(const Ray& r) {
    double closest_t = 1e8;
    Color hit_color = Color(0.0, 0.0, 0.0);  // Fond noir par défaut
    
    // Grande sphère verte (3)
    double t = hit_sphere(Point3(0, 0, -2.0), 0.9, r);
    if (t > 0.0 && t < closest_t) {
        closest_t = t;
        hit_color = Color(0.3, 0.8, 0.3);  // Vert
    }
    
    // Sphère bleue (2)
    t = hit_sphere(Point3(0, 0.5, -1.0), 0.3, r);
    if (t > 0.0 && t < closest_t) {
        closest_t = t;
        hit_color = Color(0.5, 0.8, 1.0);  // Bleu clair
    }
    
    // Sphère jaune (4)
    t = hit_sphere(Point3(0, -0.5, -1.0), 0.3, r);
    if (t > 0.0 && t < closest_t) {
        closest_t = t;
        hit_color = Color(1.0, 0.95, 0.4);  // Jaune
    }
    
    return hit_color;
}

int main() {
    // Paramètres de l'image
    const int image_width = 1080;
    const int image_height = 1920;
    const char* output_file = "output/v1/output.ppm";

    std::cout << "Raytracer CPU, Image de test\n";
    std::cout << "Résolution: " << image_width << "x" << image_height << "\n";

    // Configuration de la caméra
    const double aspect_ratio = double(image_width) / double(image_height);
    const double viewport_width  = 2.0;
    const double viewport_height = viewport_width / aspect_ratio;

    Point3 origin(0, 0, 0);
    Vec3 horizontal(viewport_width, 0, 0);
    Vec3 vertical(0, viewport_height, 0);
    Point3 lower_left(-viewport_width / 2.0, -viewport_height / 2.0, -1);

    // Rendu de l'image
    std::ofstream out(output_file);
    out << "P3\n" << image_width << ' ' << image_height << "\n255\n";

    for (int j = image_height - 1; j >= 0; --j) {
        for (int i = 0; i < image_width; ++i) {
            double u = double(i) / (image_width - 1);
            double v = double(j) / (image_height - 1);
            
            Point3 pixel_position = lower_left + u*horizontal + v*vertical;
            Vec3 direction = pixel_position - origin;
            Ray r(origin, direction);
            Color pixel_color = ray_color(r);
            
            write_color(out, pixel_color);
        }
    }

    out.close();
    std::cout << "Terminé! Fichier: " << output_file << "\n";
    
    return 0;
}
