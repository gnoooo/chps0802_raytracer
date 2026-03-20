# CHPS0802 : Programmation GPU
Projet de programmation GPU du Master CHPS.

Consignes :
- Première étape du projet:
  - Mettre en places les fonctions utilitaires (Point3D, Vecteur3D, Vue, ... ) que vous jugerez utiles;
  - Définir les objets plans et sphères ainsi que les méthodes nécessaires pour calculer les intersections avec un rayon;
  - Générer les vues;
  - Les enregistrer sous forme d'un fichier *.ppm;
  - Définir pour chaque classe les tests unitaires permettants de valider leur bon fonctionnement.

---

![[_TOC_]]

---

## Prérequis
- G++
- CMake
- Make

## Setup

Nous pouvons créer les makefiles et compiler manuellement chaque versions du projet :

1. Récupération du repo
  ```bash
  git clone https://gitlab.com/gnoooo/chps0802_raytracer
  cd chps0802_raytracer
  ```
2. Makefile et compilation
  ```bash
  cmake -S vX/ -B vX/build
  make -C vX/build
  ./vX/raytracer_cpu
  ```

Ou bien exécuter le script Bash ci-dessous pour automatiquement tout lancer :

TODO
