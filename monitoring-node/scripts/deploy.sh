#!/bin/bash

# Bu script offline ortamda çalıştırılmalıdır
# Docker Compose ile tüm monitoring stack'i başlatır

set -e

echo "==========================================="
echo "Monitoring Stack Deployment"
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
MONITORING_NODE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$MONITORING_NODE_DIR"

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

echo -e "${YELLOW}Stack başlatılıyor...${NC}"
echo ""

# Önceki stack'i durdur (varsa)
$DOCKER_COMPOSE down 2>/dev/null || true

# Stack'i başlat
$DOCKER_COMPOSE up -d

echo ""
echo -e "${GREEN}==========================================="
echo -e "Stack başarıyla başlatıldı!"
echo -e "===========================================${NC}"
echo ""

# Container durumlarını göster
echo -e "${BLUE}Container Durumları:${NC}"
$DOCKER_COMPOSE ps
echo ""

# Servis URL'lerini göster
echo -e "${BLUE}Servis URL'leri:${NC}"
echo ""
echo -e "${GREEN}• OpenTelemetry Collector (Gateway):${NC}"
echo "  - OTLP gRPC (App Node'lar buraya bağlanır): http://0.0.0.0:4317"
echo "  - OTLP HTTP: http://localhost:4318"
echo "  - Metrics: http://localhost:8888/metrics"
echo "  - Prometheus Exporter: http://localhost:8889/metrics"
echo "  - Health Check: http://localhost:13133"
echo "  - zPages (Debug): http://localhost:55679/debug/tracez"
echo ""
echo -e "${GREEN}• Prometheus:${NC}"
echo "  - UI: http://localhost:9090"
echo "  - Targets: http://localhost:9090/targets"
echo "  - Retention: 30 gün"
echo ""
echo -e "${GREEN}• Zipkin:${NC}"
echo "  - UI: http://localhost:9411"
echo ""
echo -e "${GREEN}• Grafana:${NC}"
echo "  - UI: http://localhost:3000"
echo "  - Kullanıcı: admin"
echo "  - Şifre: admin"
echo ""

echo -e "${BLUE}Firewall Ayarları:${NC}"
echo "App node'lardan gelen trafiğe izin vermek için:"
echo "  sudo firewall-cmd --permanent --add-port=4317/tcp"
echo "  sudo firewall-cmd --reload"
echo ""
echo "veya ufw kullanıyorsanız:"
echo "  sudo ufw allow 4317/tcp"
echo ""

echo -e "${BLUE}App Node Konfigürasyonu:${NC}"
echo "App node'lardaki .env dosyasında şu ayarı yapın:"
echo "  MONITORING_NODE_HOST=$(hostname -I | awk '{print $1}')"
echo ""

echo -e "${YELLOW}Yararlı Komutlar:${NC}"
echo "  Logları görüntüle: $DOCKER_COMPOSE logs -f"
echo "  Belirli servis logu: $DOCKER_COMPOSE logs -f otel-collector"
echo "  Stack'i durdur: $DOCKER_COMPOSE down"
echo "  Stack'i yeniden başlat: $DOCKER_COMPOSE restart"
echo "  Volumes ile birlikte temizle: $DOCKER_COMPOSE down -v"
echo ""

# Health check
echo -e "${YELLOW}Health check yapılıyor...${NC}"
sleep 5

check_health() {
    local service=$1
    local url=$2
    local name=$3

    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name sağlıklı"
        return 0
    else
        echo -e "${RED}✗${NC} $name yanıt vermiyor (kontrol edin: $DOCKER_COMPOSE logs $service)"
        return 1
    fi
}

check_health "otel-collector" "http://localhost:13133" "OTel Collector"
check_health "prometheus" "http://localhost:9090/-/healthy" "Prometheus"
check_health "zipkin" "http://localhost:9411/health" "Zipkin"
check_health "grafana" "http://localhost:3000/api/health" "Grafana"

echo ""
echo -e "${GREEN}Kurulum tamamlandı!${NC} Grafana'ya giderek dashboard'ları kontrol edebilirsiniz."
echo ""
