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

Options disponibles (combinables) :

| Option | Description |
|---|---|
| `--skip-build` | Saute la compilation si les binaires sont déjà à jour |
| `--multi-res` | Teste plusieurs résolutions et affiche un tableau comparatif |

```bash
./benchmark.sh --skip-build
./benchmark.sh --multi-res
./benchmark.sh --skip-build --multi-res
```

Exemple de sortie (mode standard) :

```
 Résultats du benchmark
  Temps CPU :     455.90 ms
  Temps GPU :       0.18 ms
  Speedup   : 2518.46x
```

Exemple de sortie (mode `--multi-res`) :

```
Benchmark multi-résolution
Résolution       CPU (ms)     GPU (ms)    Speedup
-------------------------------------------------
270x480             12.34         0.08     154.25x
540x960             49.80         0.12     415.00x
1080x1920          455.90         0.18    2532.78x
2160x3840         1823.60         0.64    2849.38x
```

Les images rendues sont écrites dans `output/v3/output_<width>x<height>.ppm` (CPU) et `output/v3_cuda/output_<width>x<height>.ppm` (GPU).

#### Résolution personnalisée

Les binaires acceptent directement une résolution en argument :

```bash
./v3/build/raytracer_cpu 1920 1080          # rendu HD paysage
./v3_cuda/build/raytracer_gpu 3840 2160     # rendu 4K
```

Sans argument, la résolution par défaut `1080×1920` (portrait) est utilisée.

## Tests unitaires

Les tests couvrent : Vec3, Ray, Camera, Sphere::hit, HittableList, LambertColor, ConstantColor, Metal (CPU) et les mêmes primitives côté device CUDA avec des kernels `<<<1,1>>>`.

### v3 CPU

```bash
# Compilation (depuis la racine du repo)
cmake -S v3/ -B v3/build
make -C v3/build test_cpu

# Exécution directe
./v3/build/test_cpu

# Via CTest
ctest --test-dir v3/build --output-on-failure

# Via la cible make dédiée
make -C v3/build run_tests
```

### v3 CUDA

```bash
cmake -S v3_cuda/ -B v3_cuda/build
make -C v3_cuda/build test_gpu

./v3_cuda/build/test_gpu

ctest --test-dir v3_cuda/build --output-on-failure

make -C v3_cuda/build run_tests
```

Exemple de sortie (CPU) :

```
=== Tests unitaires v3 CPU ===

[ Vec3 ]
  PASS : operator+
  ...
[ Sphere::hit ]
  PASS : hit (rayon frontal)
  PASS : t = 1.0 (face avant)
  ...
  PASS : 46
  Tous les tests sont passes !
```

