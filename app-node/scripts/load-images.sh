#!/bin/bash

# Bu script offline ortamda çalıştırılmalıdır
# Export edilmiş tar dosyalarını Docker'a load eder (Sadece OTel Collector)

set -e

echo "==========================================="
echo "OpenTelemetry Collector Image Load"
echo "==========================================="
echo ""

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dizin kontrolü
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NODE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$APP_NODE_DIR")"
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

# App node için sadece OTel Collector gerekli
REQUIRED_IMAGE="$IMAGES_DIR/otel-collector.tar"

if [ ! -f "$REQUIRED_IMAGE" ]; then
    echo -e "${RED}HATA: $REQUIRED_IMAGE dosyası bulunamadı!${NC}"
    exit 1
fi

echo -e "${YELLOW}OpenTelemetry Collector image'ı yükleniyor...${NC}"
echo ""

if docker load -i "$REQUIRED_IMAGE"; then
    echo -e "${GREEN}Image başarıyla yüklendi!${NC}"
else
    echo -e "${RED}Image yükleme HATALI!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}==========================================="
echo -e "Image başarıyla yüklendi!"
echo -e "===========================================${NC}"
echo ""
echo "Yüklenen image:"
docker images | grep "opentelemetry-collector"
echo ""
echo -e "${YELLOW}Sonraki adım:${NC} ./scripts/deploy.sh scriptini çalıştırın."
