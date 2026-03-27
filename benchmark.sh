#!/usr/bin/env bash
# Usage : ./benchmark.sh [--skip-build]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_BUILD=0
[[ "${1:-}" == "--skip-build" ]] && SKIP_BUILD=1

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

# Run CPU
echo -e "\n${CYAN}[run] CPU${NC}"
CPU_OUTPUT=$(cd "$SCRIPT_DIR" && "$CPU_BIN" 2>/dev/null)
echo "$CPU_OUTPUT"

CPU_MS=$(echo "$CPU_OUTPUT" | grep -oP '(?<=Temps CPU\s{2}: )\S+')
if [[ -z "$CPU_MS" ]]; then
    echo -e "${RED}Impossible de lire le temps CPU.${NC}"; exit 1
fi

# Run GPU
echo -e "\n${CYAN}[run] GPU${NC}"
GPU_OUTPUT=$(cd "$SCRIPT_DIR" && "$GPU_BIN" 2>/dev/null)
echo "$GPU_OUTPUT"

GPU_MS=$(echo "$GPU_OUTPUT" | grep -oP '(?<=Temps GPU\s{2}: )\S+')
if [[ -z "$GPU_MS" ]]; then
    echo -e "${RED}Impossible de lire le temps GPU.${NC}"; exit 1
fi

# Calcul du speedup
SPEEDUP=$(awk "BEGIN { printf \"%.2f\", $CPU_MS / $GPU_MS }")

echo ""
echo -e "${BOLD}Résultats du benchmark${NC}"
printf "\tTemps CPU : %10.2f ms\n" "$CPU_MS"
printf "\tTemps GPU : %10.2f ms\n" "$GPU_MS"
echo -e "${BOLD}\tSpeedup   : ${GREEN}${SPEEDUP}x${NC}"