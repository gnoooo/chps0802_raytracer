#!/usr/bin/env bash
# Usage : ./clean.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; 
GREEN='\033[0;32m'; 
CYAN='\033[0;36m'; 
NC='\033[0m'

# Images PPM
echo -e "${CYAN}[clean] images PPM${NC}"
PPM_FILES=$(find "$SCRIPT_DIR/output" -name "*.ppm" 2>/dev/null)
if [[ -n "$PPM_FILES" ]]; then
    echo "$PPM_FILES" | while read -r f; do
        rm -f "$f" && echo "  supprimé : $f"
    done
else
    echo "  aucune image .ppm trouvée"
fi

# Répertoires build
echo -e "${CYAN}[clean] répertoires build${NC}"
for version in v1 v2 v3 v3_cuda; do
    build_dir="$SCRIPT_DIR/$version/build"
    if [[ -d "$build_dir" ]]; then
        rm -rf "$build_dir"
        echo -e "  ${GREEN}supprimé${NC} : $build_dir"
    fi
done

echo -e "${GREEN}Nettoyage terminé.${NC}"
