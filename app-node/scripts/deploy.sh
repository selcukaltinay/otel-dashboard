#!/bin/bash

# Bu script offline ortamda çalıştırılmalıdır
# Docker Compose ile OTel Collector'ı başlatır

set -e

echo "==========================================="
echo "OpenTelemetry Collector Deployment"
echo "==========================================="
echo ""

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dizin kontrolü
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NODE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$APP_NODE_DIR"

# .env dosyası kontrolü
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}UYARI: .env dosyası bulunamadı!${NC}"
    echo -e "${YELLOW}.env.example dosyasından .env oluşturuluyor...${NC}"
    cp .env.example .env
    echo ""
    echo -e "${RED}ÖNEMLİ: .env dosyasını düzenleyip MONITORING_NODE_HOST değerini ayarlayın!${NC}"
    echo -e "${YELLOW}Şu komutu çalıştırın: nano .env${NC}"
    echo ""
    read -p "Devam etmek için Enter'a basın (veya Ctrl+C ile iptal edin)..."
fi

# Docker Compose kontrolü
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}HATA: docker-compose kurulu değil!${NC}"
    exit 1
fi

# Docker Compose komutunu belirle
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${YELLOW}Collector başlatılıyor...${NC}"
echo ""

# Önceki container'ı durdur (varsa)
$DOCKER_COMPOSE down 2>/dev/null || true

# Stack'i başlat
$DOCKER_COMPOSE up -d

echo ""
echo -e "${GREEN}==========================================="
echo -e "Collector başarıyla başlatıldı!"
echo -e "===========================================${NC}"
echo ""

# Container durumunu göster
echo -e "${BLUE}Container Durumu:${NC}"
$DOCKER_COMPOSE ps
echo ""

# Konfigürasyonu göster
echo -e "${BLUE}Konfigürasyon:${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}Monitoring Node:${NC} $(grep MONITORING_NODE_HOST .env | cut -d'=' -f2)"
fi
echo ""

# Endpoint bilgileri
echo -e "${BLUE}Application Endpoint'leri:${NC}"
echo -e "${GREEN}• OTLP gRPC:${NC} http://localhost:4317"
echo -e "${GREEN}• OTLP HTTP:${NC}  http://localhost:4318"
echo -e "${GREEN}• Health Check:${NC} http://localhost:13133"
echo -e "${GREEN}• Metrics:${NC} http://localhost:8888/metrics"
echo ""

echo -e "${YELLOW}Uygulamalarınızdan bağlantı için:${NC}"
echo "export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317"
echo ""

echo -e "${BLUE}Yararlı Komutlar:${NC}"
echo "  Logları görüntüle: $DOCKER_COMPOSE logs -f"
echo "  Container'ı durdur: $DOCKER_COMPOSE down"
echo "  Container'ı yeniden başlat: $DOCKER_COMPOSE restart"
echo "  Health check: curl http://localhost:13133"
echo ""

# Health check
echo -e "${YELLOW}Health check yapılıyor...${NC}"
sleep 3
if curl -s http://localhost:13133 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Collector sağlıklı çalışıyor!${NC}"
else
    echo -e "${YELLOW}⚠ Health check başarısız. Container loglarını kontrol edin: $DOCKER_COMPOSE logs${NC}"
fi
echo ""
