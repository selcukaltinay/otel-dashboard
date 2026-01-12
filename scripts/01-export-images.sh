#!/bin/bash

# Bu script internet erişimi olan ortamda çalıştırılmalıdır
# Container image'larını pull edip tar dosyaları olarak export eder

set -e

echo "==================================="
echo "OpenTelemetry Stack Image Export"
echo "==================================="
echo ""

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Image listesi
declare -A IMAGES=(
    ["otel-collector"]="otel/opentelemetry-collector:latest"
    ["prometheus"]="prom/prometheus:latest"
    ["zipkin"]="openzipkin/zipkin:latest"
    ["grafana"]="grafana/grafana:latest"
)

# Dizinleri oluştur
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGES_DIR="$PROJECT_DIR/images"

mkdir -p "$IMAGES_DIR"

echo -e "${BLUE}Bu script şu image'ları indirecek:${NC}"
for name in "${!IMAGES[@]}"; do
    echo "  - ${IMAGES[$name]}"
done
echo ""

echo -e "${YELLOW}Image'lar pull ediliyor...${NC}"
echo ""

# Her image'ı pull et ve export et
for name in "${!IMAGES[@]}"; do
    image="${IMAGES[$name]}"
    tar_file="$IMAGES_DIR/${name}.tar"

    echo -e "${YELLOW}[$name] Pulling: $image${NC}"
    if docker pull "$image"; then
        echo -e "${GREEN}[$name] Pull başarılı${NC}"

        echo -e "${YELLOW}[$name] Export ediliyor: $tar_file${NC}"
        if docker save -o "$tar_file" "$image"; then
            file_size=$(du -h "$tar_file" | cut -f1)
            echo -e "${GREEN}[$name] Export başarılı (Boyut: $file_size)${NC}"
        else
            echo -e "${RED}[$name] Export HATALI${NC}"
            exit 1
        fi
    else
        echo -e "${RED}[$name] Pull HATALI${NC}"
        exit 1
    fi
    echo ""
done

echo -e "${GREEN}==================================="
echo -e "Tüm image'lar başarıyla export edildi!"
echo -e "===================================${NC}"
echo ""
echo -e "${BLUE}Export edilen dosyalar:${NC}"
ls -lh "$IMAGES_DIR"/*.tar
echo ""
echo -e "${YELLOW}Toplam boyut:${NC} $(du -sh "$IMAGES_DIR" | cut -f1)"
echo ""
echo -e "${GREEN}Sonraki adımlar:${NC}"
echo "1. Tüm proje dizinini offline ortama kopyalayın"
echo "2. App node'larda: cd app-node && ./scripts/deploy.sh"
echo "3. Monitoring node'da: cd monitoring-node && ./scripts/deploy.sh"
