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
- G++ (>= 9)
- CMake (>= 3.18)
- Make
- CUDA Toolkit (pour `v3_cuda`)
- GPU NVIDIA compatible (architecture configurée dans `v3_cuda/CMakeLists.txt` : `sm_90` par défaut pour GH200 — adapter si besoin)

## Setup

### Compilation manuelle d'une version

```bash
git clone https://gitlab.com/gnoooo/chps0802_raytracer
cd chps0802_raytracer

# Remplacer vX par v1, v2, v3 ou v3_cuda
cmake -S vX/ -B vX/build
make -C vX/build
./vX/build/raytracer_cpu   # ou raytracer_gpu pour v3_cuda
```

### Benchmark CPU vs GPU (v3 / v3_cuda)

Le script `benchmark.sh` compile les deux versions, les exécute et affiche le speedup automatiquement :

```bash
./benchmark.sh
```

Option `--skip-build` pour sauter la compilation si les binaires sont déjà à jour :

```bash
./benchmark.sh --skip-build
```

Exemple de sortie :

```

 Résultats du benchmark
  Temps CPU   : 8342.17 ms
  Temps GPU   : 48.63 ms
  Speedup     : 171.56x
```

Les images rendues sont écrites dans `output/v3/output.ppm` (CPU) et `output/v3/output_gpu.ppm` (GPU).

