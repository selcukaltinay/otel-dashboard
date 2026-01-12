#!/bin/bash

# Bu script offline ortamda çalıştırılmalıdır
# Export edilmiş tar dosyalarını Docker'a load eder (Tüm monitoring stack)

set -e

echo "==========================================="
echo "Monitoring Stack Image Load"
echo "==========================================="
echo ""

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dizin kontrolü
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MONITORING_NODE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$MONITORING_NODE_DIR")"
IMAGES_DIR="$PROJECT_DIR/images"

if [ ! -d "$IMAGES_DIR" ]; then
    echo -e "${RED}HATA: $IMAGES_DIR dizini bulunamadı!${NC}"
    exit 1
fi

# Docker kontrolü
if ! command -v docker &> /dev/null; then
    echo -e "${RED}HATA: Docker kurulu değil!${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}HATA: Docker daemon çalışmıyor!${NC}"
    exit 1
fi

# Monitoring node için gerekli image'lar
declare -a REQUIRED_IMAGES=(
    "otel-collector.tar"
    "prometheus.tar"
    "zipkin.tar"
    "grafana.tar"
)

# Image dosyalarının varlığını kontrol et
echo -e "${YELLOW}Gerekli image'lar kontrol ediliyor...${NC}"
for img in "${REQUIRED_IMAGES[@]}"; do
    if [ ! -f "$IMAGES_DIR/$img" ]; then
        echo -e "${RED}HATA: $IMAGES_DIR/$img dosyası bulunamadı!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} $img bulundu"
done
echo ""

echo -e "${YELLOW}Image'lar yükleniyor...${NC}"
echo ""

# Her tar dosyasını load et
for img in "${REQUIRED_IMAGES[@]}"; do
    tar_file="$IMAGES_DIR/$img"
    echo -e "${YELLOW}[$img] Load ediliyor...${NC}"

    if docker load -i "$tar_file"; then
        echo -e "${GREEN}[$img] Load başarılı${NC}"
    else
        echo -e "${RED}[$img] Load HATALI${NC}"
        exit 1
    fi
    echo ""
done

echo -e "${GREEN}==========================================="
echo -e "Tüm image'lar başarıyla yüklendi!"
echo -e "===========================================${NC}"
echo ""
echo "Yüklenen image'lar:"
docker images | grep -E "otel|prometheus|zipkin|grafana" | head -20
echo ""
echo -e "${YELLOW}Sonraki adım:${NC} ./scripts/deploy.sh scriptini çalıştırın."
