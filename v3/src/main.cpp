#include <iostream>
#include <fstream>
#include <memory>
#include <vector>
#include <algorithm>
#include <chrono>
#include "../include/vec3.hpp"
#include "../include/ray.hpp"
#include "../include/hittable_list.hpp"
#include "../include/sphere.hpp"
#include "../include/camera.hpp"
#include "../include/light.hpp"
#include "../include/metal.hpp"
#include "../include/lambertcolor.hpp"
#include "../include/constantcolor.hpp"


/**
 * @brief Calcule la couleur d'un rayon selon le modèle de Lambert
 *
 * Pour chaque intersection :
 *   - Composante ambiante  : ambient_factor * surface_color
 *   - Composante diffuse   : Somme de max(0, N·L) * surface_color * light_color * intensity
 *     (ignorée si un objet bloque le chemin vers la lumière -> ombre dure)
 *
 * @param r Rayon primaire
 * @param world Liste des objets de la scène
 * @param lights Liste des sources lumineuses
 * @return Color Couleur calculée pour ce pixel
 */
Color ray_color(const Ray& r, const HittableList& world, const std::vector<PointLight>& lights, int depth)
{

    if (depth <= 0) return Color(0,0,0);

    HitRecord rec;
    if (!world.hit(r, 0.001, 1e8, rec)) {
        return Color(0, 0, 0); // fond noir
    }

    Ray scattered;
    Color attenuation(0,0,0);
    bool did_scatter = rec.mat_ptr->scatter(r, rec, attenuation, scattered);

    Color local = rec.mat_ptr->shade(rec, lights, world);

    // Composante réfléchie (si le matériau scatter)
    if (did_scatter) {
        local += attenuation * ray_color(scattered, world, lights, depth - 1);
    }

    return local;
}

int main() {
    // Paramètres de l'image
    const int image_width  = 1080;
    const int image_height = 1920;
    const char* output_file = "output/v3/output.ppm";

    // Scène
    HittableList world;

    auto metal_green = std::make_shared<Metal>(Color(0.3, 0.8, 0.3), 0.1);
    auto lambert_green = std::make_shared<LambertColor>(Color(0.3, 0.8, 0.3));
    auto lambert_blue = std::make_shared<LambertColor>(Color(0.5, 0.8, 1.0));
    auto constant_yellow = std::make_shared<ConstantColor>(Color(1.0, 0.95, 0.4));

    world.add(std::make_shared<Sphere>(Point3( 0,  0,   -2.0), 0.9, metal_green));  // Grande sphère verte
    world.add(std::make_shared<Sphere>(Point3( 0,  0.5, -1.0), 0.3, lambert_blue));  // Sphère bleue
    world.add(std::make_shared<Sphere>(Point3( 0, -0.5, -1.0), 0.3, constant_yellow)); // Sphère jaune

    // Sources lumineuses
    std::vector<PointLight> lights;
    lights.emplace_back(Point3( 3.0,  3.0,  0.0), Color(1.0, 1.0, 1.0), 1.0); // lumière blanche, avant-droite haute
    lights.emplace_back(Point3(-2.0,  1.0, -1.0), Color(0.4, 0.6, 1.0), 0.5); // lumière bleue, avant-gauche

    // Caméra
    Camera cam(image_width, image_height);

    std::cout << "Raytracer CPU (modèle de Lambert)\n";
    std::cout << "Résolution : " << image_width << "x" << image_height << "\n";

    // Rendu
    std::ofstream out(output_file);
    out << "P3\n" << image_width << ' ' << image_height << "\n255\n";

    auto t0 = std::chrono::high_resolution_clock::now();

    for (int j = image_height - 1; j >= 0; --j) {
        if (j % 100 == 0) std::cerr << "\rScanlines restantes : " << j << ' ' << std::flush;
        for (int i = 0; i < image_width; ++i) {
            double u = double(i) / (image_width - 1);
            double v = double(j) / (image_height - 1);

            Ray   r = cam.get_ray(u, v);
            Color pixel_color = ray_color(r, world, lights, 10);
            write_color(out, pixel_color);
        }
    }

    auto t1 = std::chrono::high_resolution_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    std::cout << "Temps CPU  : " << ms << " ms\n";

    out.close();
    std::cerr << "Terminé ! Fichier : " << output_file << "\n";
    return 0;
}
