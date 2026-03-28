#!/usr/bin/env bash
# Usage : ./benchmark.sh [--skip-build] [--multi-res]
#   --skip-build  : ne pas recompiler les binaires
#   --multi-res   : tester plusieurs résolutions et afficher un tableau comparatif
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_BUILD=0
MULTI_RES=0
for arg in "$@"; do
    case "$arg" in
        --skip-build) SKIP_BUILD=1 ;;
        --multi-res)  MULTI_RES=1  ;;
        *) echo "Option inconnue : $arg"; echo "Usage: $0 [--skip-build] [--multi-res]"; exit 1 ;;
    esac
done

# Couleurs
RED='\033[0;31m'; 
GREEN='\033[0;32m'; 
CYAN='\033[0;36m'; 
BOLD='\033[1m'; 
NC='\033[0m'

# Build
build() {
    local version="$1" # e.g. "v3" ou "v3_cuda"
    local src_dir="$SCRIPT_DIR/$version"
    local build_dir="$src_dir/build"

    echo -e "${CYAN}[build] $version${NC}"
    # Nettoyer le build dir si le cache pointe vers une autre source
    if [[ -f "$build_dir/CMakeCache.txt" ]]; then
        cached_src=$(grep "^CMAKE_HOME_DIRECTORY" "$build_dir/CMakeCache.txt" 2>/dev/null | cut -d= -f2)
        if [[ "$cached_src" != "$src_dir" ]]; then
            echo -e "${CYAN}[build] cache obsolète, nettoyage de $build_dir${NC}"
            rm -rf "$build_dir"
        fi
    fi
    if ! cmake -S "$src_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-O3" > /dev/null 2>&1; then
        echo -e "${RED}[build] cmake a échoué pour $version${NC}"
        cmake -S "$src_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-O3"
        exit 1
    fi
    if ! make -C "$build_dir" -j"$(nproc)" > /dev/null 2>&1; then
        echo -e "${RED}[build] make a échoué pour $version${NC}"
        make -C "$build_dir" -j"$(nproc)"
        exit 1
    fi
    echo -e "${GREEN}[build] $version, OK${NC}"
}

if [[ $SKIP_BUILD -eq 0 ]]; then
    build v3
    build v3_cuda
fi

# Binaires
CPU_BIN="$SCRIPT_DIR/v3/build/raytracer_cpu"
GPU_BIN="$SCRIPT_DIR/v3_cuda/build/raytracer_gpu"

[[ -x "$CPU_BIN" ]] || { echo -e "${RED}Binaire CPU introuvable : $CPU_BIN${NC}"; exit 1; }
[[ -x "$GPU_BIN" ]] || { echo -e "${RED}Binaire GPU introuvable : $GPU_BIN${NC}"; exit 1; }

# On s'assure que les répertoires de sortie existent
mkdir -p "$SCRIPT_DIR/output/v3" "$SCRIPT_DIR/output/v3_cuda"

# Lance le rendu CPU et GPU pour une résolution donnée
# run_once <width> <height> [verbose=1]  → exporte CPU_MS / GPU_MS
run_once() {
    local W="$1" H="$2" VERBOSE="${3:-1}"

    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "\n${CYAN}[run] CPU ${W}x${H}${NC}"
    fi
    local cpu_out
    cpu_out=$(cd "$SCRIPT_DIR" && "$CPU_BIN" "$W" "$H" 2>/dev/null)
    [[ $VERBOSE -eq 1 ]] && echo "$cpu_out"
    CPU_MS=$(echo "$cpu_out" | grep -oP '(?<=Temps CPU\s{2}: )\S+')
    if [[ -z "$CPU_MS" ]]; then
        echo -e "${RED}Impossible de lire le temps CPU (${W}x${H}).${NC}"; exit 1
    fi

    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "\n${CYAN}[run] GPU ${W}x${H}${NC}"
    fi
    local gpu_out
    gpu_out=$(cd "$SCRIPT_DIR" && "$GPU_BIN" "$W" "$H" 2>/dev/null)
    [[ $VERBOSE -eq 1 ]] && echo "$gpu_out"
    GPU_MS=$(echo "$gpu_out" | grep -oP '(?<=Temps GPU\s{2}: )\S+')
    if [[ -z "$GPU_MS" ]]; then
        echo -e "${RED}Impossible de lire le temps GPU (${W}x${H}).${NC}"; exit 1
    fi
}

if [[ $MULTI_RES -eq 1 ]]; then
    # Résolutions à tester (portrait 9:16)
    RESOLUTIONS=("270 480" "540 960" "1080 1920" "2160 3840" "4320 7680")

    echo ""
    echo -e "${BOLD}Benchmark multi-résolution${NC}"
    printf "%-14s %12s %12s %10s\n" "Résolution" "CPU (ms)" "GPU (ms)" "Speedup"
    printf '%s\n' "$(printf '%-14s %12s %12s %10s' '----------' '--------' '--------' '-------' | tr ' ' '-')"

    for res in "${RESOLUTIONS[@]}"; do
        W=$(echo "$res" | cut -d' ' -f1)
        H=$(echo "$res" | cut -d' ' -f2)
        run_once "$W" "$H" 0
        SP=$(awk "BEGIN { printf \"%.2f\", $CPU_MS / $GPU_MS }")
        printf "%-14s %12.2f %12.2f %10s\n" "${W}x${H}" "$CPU_MS" "$GPU_MS" "${SP}x"
    done
    echo ""
else
    # Mode benchmark standard (résolution par défaut 1080x1920)
    run_once 1080 1920

    # Calcul du speedup
    SPEEDUP=$(awk "BEGIN { printf \"%.2f\", $CPU_MS / $GPU_MS }")

    echo ""
    echo -e "${BOLD}Résultats du benchmark${NC}"
    printf "\tTemps CPU : %10.2f ms\n" "$CPU_MS"
    printf "\tTemps GPU : %10.2f ms\n" "$GPU_MS"
    echo -e "${BOLD}\tSpeedup   : ${GREEN}${SPEEDUP}x${NC}"
fi