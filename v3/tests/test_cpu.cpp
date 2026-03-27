// Tests unitaires v3 CPU

#include <iostream>
#include <cmath>
#include <vector>
#include <memory>

#include "../include/vec3.hpp"
#include "../include/ray.hpp"
#include "../include/camera.hpp"
#include "../include/sphere.hpp"
#include "../include/hittable_list.hpp"
#include "../include/light.hpp"
#include "../include/lambertcolor.hpp"
#include "../include/metal.hpp"
#include "../include/constantcolor.hpp"


static int g_pass = 0, g_fail = 0;

#define CHECK(cond, msg) do {                                               \
    if (cond) { std::cout << "  PASS : " << (msg) << "\n"; ++g_pass; }     \
    else       { std::cerr << "  FAIL : " << (msg) << "\n"; ++g_fail; }    \
} while(0)

static bool near_eq(double a, double b, double eps = 1e-9) {
    return std::abs(a - b) < eps;
}
static bool vec_eq(const Vec3& a, const Vec3& b, double eps = 1e-9) {
    return near_eq(a.x, b.x, eps) && near_eq(a.y, b.y, eps) && near_eq(a.z, b.z, eps);
}

// Vec3
void test_vec3() {
    std::cout << "\n[ Vec3 ]\n";
    Vec3 a(1, 2, 3), b(4, 5, 6);

    CHECK(vec_eq(a + b, Vec3(5, 7, 9)),                              "operator+");
    CHECK(vec_eq(a - b, Vec3(-3, -3, -3)),                           "operator-");
    CHECK(vec_eq(a * b, Vec3(4, 10, 18)),                            "operator* (composante)");
    CHECK(vec_eq(2.0 * a, Vec3(2, 4, 6)),                            "operator* (scalaire gauche)");
    CHECK(vec_eq(a * 2.0, Vec3(2, 4, 6)),                            "operator* (scalaire droit)");
    CHECK(vec_eq(a / 2.0, Vec3(0.5, 1.0, 1.5)),                     "operator/");
    CHECK(vec_eq(-a, Vec3(-1, -2, -3)),                              "operateur- unaire");
    CHECK(near_eq(dot(a, b), 32.0),                                  "dot product");
    CHECK(vec_eq(cross(Vec3(1,0,0), Vec3(0,1,0)), Vec3(0,0,1)),     "cross product");
    CHECK(near_eq(a.length_squared(), 14.0),                         "length_squared");
    CHECK(near_eq(a.length(), std::sqrt(14.0)),                      "length");
    CHECK(vec_eq(unit_vector(Vec3(3, 0, 0)), Vec3(1, 0, 0)),        "unit_vector");

    Vec3 c = a;
    c += b;
    CHECK(vec_eq(c, Vec3(5, 7, 9)),                                  "operator+=");
    c *= 2.0;
    CHECK(vec_eq(c, Vec3(10, 14, 18)),                               "operator*=");
}

// Ray
void test_ray() {
    std::cout << "\n[ Ray ]\n";
    Ray r(Point3(1, 2, 3), Vec3(0, 0, -1));

    CHECK(vec_eq(r.origin(),    Point3(1, 2, 3)), "origin()");
    CHECK(vec_eq(r.direction(), Vec3(0, 0, -1)),  "direction()");
    CHECK(vec_eq(r.at(0.0),    Point3(1, 2, 3)), "at(0)");
    CHECK(vec_eq(r.at(2.0),    Point3(1, 2, 1)), "at(2)");
    CHECK(vec_eq(r.at(1.0),    Point3(1, 2, 2)), "at(1) interpolation");
}

// Camera
void test_camera() {
    std::cout << "\n[ Camera ]\n";
    Camera cam(100, 100);

    CHECK(cam.get_width()  == 100, "get_width");
    CHECK(cam.get_height() == 100, "get_height");

    // Rayon central => doit pointer vers -Z
    // viewport 2.0, square => lower_left = (-1,-1,-1)
    // get_ray(0.5, 0.5) => pixel = (-1,-1,-1) + (1,0,0) + (0,1,0) = (0,0,-1)
    // direction = (0,0,-1)
    Ray center = cam.get_ray(0.5, 0.5);
    Vec3 d = unit_vector(center.direction());
    CHECK(near_eq(d.z, -1.0, 1e-6),                              "rayon central pointe vers -Z");
    CHECK(near_eq(d.x, 0.0, 1e-6) && near_eq(d.y, 0.0, 1e-6),  "rayon central : x,y nuls");

    // Tous les rayons partent de l'origine caméra
    CHECK(vec_eq(cam.get_ray(0.0, 0.0).origin(), Point3(0,0,0)), "origine camera (coin bas-gauche)");
    CHECK(vec_eq(cam.get_ray(1.0, 1.0).origin(), Point3(0,0,0)), "origine camera (coin haut-droit)");

    // Rayon coin bas-gauche doit dévier vers (-x,-y,-z)
    Ray corner = cam.get_ray(0.0, 0.0);
    Vec3 cd = unit_vector(corner.direction());
    CHECK(cd.x < 0 && cd.y < 0 && cd.z < 0, "coin bas-gauche : direction negative sur x,y,z");
}

// Sphere::hit
void test_sphere_hit() {
    std::cout << "\n[ Sphere::hit ]\n";
    auto mat = std::make_shared<LambertColor>(Color(1, 0, 0));
    Sphere s(Point3(0, 0, -2), 1.0, mat);

    // Rayon frontal depuis l'origine => face avant à t=1
    // oc=(0,0,2), a=1, b=-4, c=3, disc=4 => t=(-(-4)-2)/2 = 1.0
    Ray r_front(Point3(0,0,0), Vec3(0,0,-1));
    HitRecord rec;
    CHECK(s.hit(r_front, 0.001, 1e8, rec),   "hit (rayon frontal)");
    CHECK(near_eq(rec.t, 1.0, 1e-9),         "t = 1.0 (face avant)");
    CHECK(rec.front_face,                     "front_face = true");
    // Normale doit pointer vers +Z (vers le rayon)
    CHECK(near_eq(rec.normal.z, 1.0, 1e-6),  "normale pointe vers +Z");

    // Rayon décalé qui manque la sphère
    Ray r_miss(Point3(2, 0, 0), Vec3(0, 0, -1));
    HitRecord rec2;
    CHECK(!s.hit(r_miss, 0.001, 1e8, rec2),  "miss (rayon decale)");

    // t_max trop petit => intersection exclue
    HitRecord rec3;
    CHECK(!s.hit(r_front, 0.001, 0.5, rec3), "miss (t_max < t_impact)");

    // t_min > les deux intersections (t=1.0 face avant, t=3.0 face arrière) => miss
    HitRecord rec4;
    CHECK(!s.hit(r_front, 3.5, 1e8, rec4),   "miss (t_min > t_impact far)");

    // Rayon depuis l'intérieur de la sphère → face arrière
    Ray r_inside(Point3(0, 0, -2), Vec3(0, 0, -1));
    HitRecord rec5;
    CHECK(s.hit(r_inside, 0.001, 1e8, rec5), "hit depuis interieur");
    CHECK(!rec5.front_face,                   "front_face = false (interieur)");
}

// HittableList::hit
void test_hittable_list() {
    std::cout << "\n[ HittableList::hit ]\n";
    auto mat = std::make_shared<LambertColor>(Color(1, 0, 0));
    HittableList world;

    // Sphère lointaine (z=-3, face avant t≈2.5) et proche (z=-2, face avant t≈1.5)
    world.add(std::make_shared<Sphere>(Point3(0, 0, -3), 0.5, mat));
    world.add(std::make_shared<Sphere>(Point3(0, 0, -2), 0.5, mat));

    Ray r(Point3(0,0,0), Vec3(0,0,-1));
    HitRecord rec;
    CHECK(world.hit(r, 0.001, 1e8, rec),       "hit (2 spheres dans la scene)");
    CHECK(rec.t < 2.0,                          "sphere la plus proche selectionnee (t<2)");

    // Scène vide => miss
    HittableList empty;
    HitRecord rec2;
    CHECK(!empty.hit(r, 0.001, 1e8, rec2),     "miss (scene vide)");
}

// LambertColor::shade
void test_lambert_shade() {
    std::cout << "\n[ LambertColor::shade ]\n";
    auto mat = std::make_shared<LambertColor>(Color(1, 0, 0));
    HittableList world; // vide => pas d'ombre

    HitRecord rec;
    rec.p = Point3(0, 0, 0);
    rec.normal = Vec3(0, 0, 1);  // normale vers +Z
    rec.front_face = true;

    // Lumière face à la normale (N.L = 1) => rouge fort
    std::vector<PointLight> lights;
    lights.emplace_back(Point3(0, 0, 100), Color(1, 1, 1), 1.0);
    Color c = mat->shade(rec, lights, world);
    CHECK(c.x > 0.9,                                              "lambert : rouge fort (lumiere en face)");
    CHECK(near_eq(c.y, 0.0, 1e-6),                               "lambert : vert nul (albedo rouge)");
    CHECK(near_eq(c.z, 0.0, 1e-6),                               "lambert : bleu nul (albedo rouge)");

    // Sans lumière => seulement ambiante
    std::vector<PointLight> no_lights;
    Color ambient = mat->shade(rec, no_lights, world);
    CHECK(near_eq(ambient.x, LambertColor::AMBIENT, 1e-9),       "lambert : ambiante seule sans lumiere");

    // Lumière derrière la surface (N.L < 0) => seulement ambiante
    std::vector<PointLight> back_lights;
    back_lights.emplace_back(Point3(0, 0, -100), Color(1, 1, 1), 1.0);
    Color back = mat->shade(rec, back_lights, world);
    CHECK(near_eq(back.x, LambertColor::AMBIENT, 1e-9),          "lambert : ambiante seule (lumiere derriere)");
}

// ConstantColor::shade
void test_constant_shade() {
    std::cout << "\n[ ConstantColor::shade ]\n";
    ConstantColor mat(Color(1.0, 0.95, 0.4));
    HittableList world;

    HitRecord rec;
    rec.p = Point3(0, 0, 0);
    rec.normal = Vec3(0, 1, 0);
    rec.front_face = true;

    // Avec lumière => couleur fixe quand même
    std::vector<PointLight> lights;
    lights.emplace_back(Point3(0, 10, 0), Color(1, 1, 1), 1.0);
    Color c = mat.shade(rec, lights, world);
    CHECK(vec_eq(c, Color(1.0, 0.95, 0.4)), "constant : couleur fixe ignorant lumiere");

    // Sans lumière => même couleur fixe
    std::vector<PointLight> no_lights;
    Color c2 = mat.shade(rec, no_lights, world);
    CHECK(vec_eq(c2, Color(1.0, 0.95, 0.4)), "constant : couleur fixe sans lumiere");
}

// Metal::shade
void test_metal_shade() {
    std::cout << "\n[ Metal::shade ]\n";
    auto mat = std::make_shared<Metal>(Color(0.3, 0.8, 0.3), 0.1);
    HittableList world; // vide => pas d'ombre

    HitRecord rec;
    rec.p = Point3(0, 0, 0);
    rec.normal = Vec3(0, 0, 1);
    rec.front_face = true;
    rec.ray_in = Ray(Point3(0, 0, 1), Vec3(0, 0, -1)); // rayon frontal

    // Sans lumière => seulement ambiante
    std::vector<PointLight> no_lights;
    Color ambient = mat->shade(rec, no_lights, world);
    Color expected = Color(0.3, 0.8, 0.3) * Metal::AMBIENT;
    CHECK(vec_eq(ambient, expected, 1e-9), "metal : ambiante seule sans lumiere");
}

// Main
int main() {
    std::cout << "=== Tests unitaires v3 CPU ===\n";
    test_vec3();
    test_ray();
    test_camera();
    test_sphere_hit();
    test_hittable_list();
    test_lambert_shade();
    test_constant_shade();
    test_metal_shade();

    std::cout << "  PASS : " << g_pass << "\n";
    if (g_fail > 0)
        std::cerr << "  FAIL : " << g_fail << "\n";
    else
        std::cout << "  Tous les tests sont passes !\n";
    return g_fail > 0 ? 1 : 0;
}
