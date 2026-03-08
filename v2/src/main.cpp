#include <iostream>
#include <fstream>
#include <memory>
#include "../include/vec3.hpp"
#include "../include/ray.hpp"
#include "../include/hittable_list.hpp"
#include "../include/sphere.hpp"
#include "../include/camera.hpp"

int main() {
    // Paramètres de l'image 
    const int image_width  = 1080;
    const int image_height = 1920;
    const char* output_file = "output/v2/output.ppm";

    // Scène 
    HittableList world;
    world.add(std::make_shared<Sphere>(Point3( 0,  0,   -2.0), 0.9, Color(0.3, 0.8, 0.3)));  // Grande sphère verte
    world.add(std::make_shared<Sphere>(Point3( 0,  0.5, -1.0), 0.3, Color(0.5, 0.8, 1.0)));  // Sphère bleue
    world.add(std::make_shared<Sphere>(Point3( 0, -0.5, -1.0), 0.3, Color(1.0, 0.95, 0.4))); // Sphère jaune

    // Caméra 
    Camera cam(image_width, image_height);

    std::cout << "Raytracer CPU\n";
    std::cout << "Résolution : " << image_width << "x" << image_height << "\n";

    // Rendu 
    std::ofstream out(output_file);
    out << "P3\n" << image_width << ' ' << image_height << "\n255\n";

    for (int j = image_height - 1; j >= 0; --j) {
        for (int i = 0; i < image_width; ++i) {
            double u = double(i) / (image_width - 1);
            double v = double(j) / (image_height - 1);

            Ray       r = cam.get_ray(u, v);
            HitRecord rec;
            Color pixel_color = world.hit(r, 0.001, 1e8, rec)
                                ? rec.color
                                : Color(0, 0, 0);  // fond noir

            write_color(out, pixel_color);
        }
    }

    out.close();
    std::cout << "Terminé ! Fichier : " << output_file << "\n";
    return 0;
}
