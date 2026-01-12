# OpenTelemetry Monitoring Node

Bu dizin, merkezi monitoring sunucusunda çalışacak tam OpenTelemetry stack'ini içerir.

## Özellikler

- **OpenTelemetry Collector** (Gateway Mode): Tüm app node'lardan veri toplar
- **Prometheus**: Metrik depolama ve sorgulama (30 gün retention)
- **Zipkin**: Distributed tracing
- **Grafana**: Görselleştirme ve önceden yapılandırılmış dashboard'lar
  - Host Metrics Overview
  - Network Metrics
  - Process & Load Metrics

## Mimari

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   App Node 1    │         │   App Node 2    │         │   App Node N    │
│                 │         │                 │         │                 │
│  OTel Collector │         │  OTel Collector │         │  OTel Collector │
│    (Agent)      │         │    (Agent)      │         │    (Agent)      │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘
         │                           │                           │
         │          OTLP/gRPC        │                           │
         └───────────────┬───────────┴───────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────────────┐
         │      Monitoring Node (Bu Server)      │
         │                                       │
         │  ┌─────────────────────────────────┐ │
         │  │  OTel Collector (Gateway)       │ │
         │  └──────┬──────────────┬───────────┘ │
         │         │              │             │
         │    ┌────▼────┐    ┌───▼────┐        │
         │    │ Zipkin  │    │Promethe│        │
         │    │         │    │  us    │        │
         │    └────┬────┘    └───┬────┘        │
         │         │             │             │
         │         └──────┬──────┘             │
         │                │                    │
         │          ┌─────▼─────┐              │
         │          │  Grafana  │              │
         │          └───────────┘              │
         └───────────────────────────────────────┘
```

## Kurulum

### Önkoşullar

Bu sunucuda aşağıdakiler kurulu olmalı:
- Docker
- Docker Compose

### Deployment

```bash
./scripts/deploy.sh
```

## Servisler ve Portlar

### OpenTelemetry Collector (Gateway)
- **4317**: OTLP gRPC (app node'lar buraya bağlanır)
- **4318**: OTLP HTTP
- **8888**: Collector internal metrics
- **8889**: Prometheus exporter
- **13133**: Health check
- **55679**: zPages (debug)

### Prometheus
- **9090**: Web UI ve API
- Data retention: 30 gün
- Endpoint: http://localhost:9090

### Zipkin
- **9411**: Web UI ve API
- Storage: In-memory
- Endpoint: http://localhost:9411

### Grafana
- **3000**: Web UI
- Kullanıcı: `admin`
- Şifre: `admin`
- Endpoint: http://localhost:3000

## Firewall Ayarları

App node'lardan gelen trafiğe izin verin:

```bash
# Port 4317'yi aç (OTLP gRPC)
sudo firewall-cmd --permanent --add-port=4317/tcp
sudo firewall-cmd --reload

# veya ufw kullanıyorsanız:
sudo ufw allow 4317/tcp
```

## Kontrol ve Monitoring

### Container Durumları
```bash
docker-compose ps
```

### Logları Görüntüleme
```bash
# Tüm servislerin logları
docker-compose logs -f

# Sadece collector
docker-compose logs -f otel-collector

# Sadece prometheus
docker-compose logs -f prometheus
```

### Health Check
```bash
# Collector health
curl http://localhost:13133/health

# Prometheus health
curl http://localhost:9090/-/healthy

# Grafana health
curl http://localhost:3000/api/health
```

### Veri Akışını Kontrol Etme

1. **Collector'a veri geliyor mu?**
   - zPages: http://localhost:55679/debug/tracez
   - Metrics: http://localhost:8888/metrics

2. **Prometheus veri topluyor mu?**
   - UI: http://localhost:9090
   - Targets: http://localhost:9090/targets

3. **Zipkin trace'leri görüyor mu?**
   - UI: http://localhost:9411

4. **Grafana datasource'ları çalışıyor mu?**
   - UI: http://localhost:3000/datasources

## Yedekleme

Prometheus ve Grafana verilerini yedeklemek için:

```bash
# Volumes'ları yedekle
docker run --rm \
  -v monitoring-node_prometheus-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/prometheus-backup-$(date +%Y%m%d).tar.gz -C /data .

docker run --rm \
  -v monitoring-node_grafana-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/grafana-backup-$(date +%Y%m%d).tar.gz -C /data .
```

## Troubleshooting

### App node'lardan veri gelmiyor
1. Firewall kontrolü: `sudo firewall-cmd --list-ports`
2. Network connectivity: App node'dan `telnet <monitoring-ip> 4317`
3. Collector logs: `docker-compose logs otel-collector`

### Prometheus metrik toplamıyor
1. Targets kontrolü: http://localhost:9090/targets
2. Collector exporter çalışıyor mu: `curl http://localhost:8889/metrics`

### Zipkin trace göstermiyor
1. Collector logs: `docker-compose logs otel-collector | grep zipkin`
2. Zipkin health: `curl http://localhost:9411/health`
