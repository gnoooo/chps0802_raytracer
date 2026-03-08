#include "../include/camera.hpp"

Camera::Camera(int image_width, int image_height, double viewport_width, double focal_length)
    : img_width(image_width), img_height(image_height)
{
    const double aspect_ratio = double(image_width) / double(image_height);
    const double viewport_height = viewport_width / aspect_ratio;

    origin = Point3(0, 0, 0);
    horizontal = Vec3(viewport_width,  0, 0);
    vertical = Vec3(0, viewport_height, 0);
    lower_left = origin - horizontal / 2.0 - vertical / 2.0 - Vec3(0, 0, focal_length);
}

Ray Camera::get_ray(double u, double v) const {
    Point3 pixel = lower_left + u * horizontal + v * vertical;
    return Ray(origin, pixel - origin);
}
