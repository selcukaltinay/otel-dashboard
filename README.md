# OpenTelemetry Offline Kurulum - Distributed Architecture

Bu dizin, internet erişimi olmayan ortamlarda dağıtık OpenTelemetry mimarisi kurmak için gerekli tüm dosyaları içerir.

## Mimari Genel Bakış

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Nodes                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ App Node 1   │  │ App Node 2   │  │ App Node N   │          │
│  │              │  │              │  │              │          │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │          │
│  │ │   App    │ │  │ │   App    │ │  │ │   App    │ │          │
│  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └────┬─────┘ │          │
│  │      │OTLP   │  │      │OTLP   │  │      │OTLP   │          │
│  │ ┌────▼─────┐ │  │ ┌────▼─────┐ │  │ ┌────▼─────┐ │          │
│  │ │OTel      │ │  │ │OTel      │ │  │ │OTel      │ │          │
│  │ │Collector │ │  │ │Collector │ │  │ │Collector │ │          │
│  │ │ (Agent)  │ │  │ │ (Agent)  │ │  │ │ (Agent)  │ │          │
│  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └────┬─────┘ │          │
│  └──────┼───────┘  └──────┼───────┘  └──────┼───────┘          │
│         │                 │                 │                   │
│         └─────────────────┼─────────────────┘                   │
│                           │ OTLP/gRPC                           │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Monitoring Node (Merkezi)                     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              OpenTelemetry Collector (Gateway)            │ │
│  │                    :4317 (gRPC Receiver)                  │ │
│  └──────────────────────┬────────────────┬───────────────────┘ │
│                         │                │                     │
│              ┌──────────▼──────┐  ┌──────▼──────────┐          │
│              │    Zipkin       │  │   Prometheus    │          │
│              │  (Traces)       │  │   (Metrics)     │          │
│              │    :9411        │  │     :9090       │          │
│              └──────────┬──────┘  └──────┬──────────┘          │
│                         │                │                     │
│                         └────────┬───────┘                     │
│                                  │                             │
│                         ┌────────▼──────────┐                  │
│                         │     Grafana       │                  │
│                         │  (Visualization)  │                  │
│                         │      :3000        │                  │
│                         └───────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
```

## Dizin Yapısı

```
otel/
├── images/                     # Container image tar dosyaları (export sonrası)
│   ├── otel-collector.tar
│   ├── grafana.tar
│   ├── zipkin.tar
│   └── prometheus.tar
│
├── app-node/                   # Uygulama sunucularına kurulacak
│   ├── configs/
│   │   └── otel-collector/
│   │       └── config.yaml     # Agent mode config
│   ├── scripts/
│   │   ├── load-images.sh      # Image yükleme
│   │   └── deploy.sh           # Deployment
│   ├── docker-compose.yml      # Sadece OTel Collector
│   ├── .env.example
│   └── README.md
│
├── monitoring-node/            # Merkezi monitoring sunucusuna kurulacak
│   ├── configs/
│   │   ├── otel-collector/
│   │   │   └── config.yaml     # Gateway mode config
│   │   ├── grafana/
│   │   │   ├── datasources.yaml
│   │   │   └── dashboards.yaml
│   │   ├── prometheus/
│   │   │   └── prometheus.yml
│   │   └── zipkin/
│   ├── scripts/
│   │   ├── load-images.sh      # Image yükleme
│   │   └── deploy.sh           # Deployment
│   ├── docker-compose.yml      # Tam stack
│   └── README.md
│
├── scripts/
│   └── 01-export-images.sh     # İnternet olan ortamda image export
│
└── README.md                   # Bu dosya
```

## Kurulum Adımları

### Adım 1: İnternet Erişimi Olan Ortamda (Hazırlık)

```bash
cd /home/satech/work/otel

# Tüm container image'larını indir ve export et
./scripts/01-export-images.sh
```

Bu script şu image'ları indirir:
- `otel/opentelemetry-collector:latest`
- `prom/prometheus:latest`
- `openzipkin/zipkin:latest`
- `grafana/grafana:latest`

Image'lar `images/` dizinine tar dosyaları olarak kaydedilir.

### Adım 2: Offline Ortama Taşıma

Tüm `/home/satech/work/otel` dizinini USB, harici disk veya ağ aktarımı ile offline ortama kopyalayın.

### Adım 3: Monitoring Node Kurulumu (Merkezi Sunucu)

```bash
cd /home/satech/work/otel/monitoring-node

# Image'ları yükle
./scripts/load-images.sh

# Stack'i başlat
./scripts/deploy.sh
```

**Önemli:** Firewall ayarlarını yapmayı unutmayın! App node'lardan port 4317'ye erişime izin verin.

```bash
# firewalld kullanıyorsanız:
sudo firewall-cmd --permanent --add-port=4317/tcp
sudo firewall-cmd --reload

# ufw kullanıyorsanız:
sudo ufw allow 4317/tcp
```

### Adım 4: App Node Kurulumu (Her Uygulama Sunucusunda)

```bash
cd /home/satech/work/otel/app-node

# .env dosyası oluştur ve monitoring node IP'sini ayarla
cp .env.example .env
nano .env
# MONITORING_NODE_HOST=192.168.1.100 (monitoring node'un IP'si)

# Image'ı yükle
./scripts/load-images.sh

# Collector'ı başlat
./scripts/deploy.sh
```

## Servisler ve Portlar

### Monitoring Node

| Servis | Port | Açıklama |
|--------|------|----------|
| OTel Collector (Gateway) | 4317 | OTLP gRPC (App node'lar buraya bağlanır) |
| OTel Collector (Gateway) | 4318 | OTLP HTTP |
| OTel Collector | 8888 | Internal metrics |
| OTel Collector | 8889 | Prometheus exporter |
| OTel Collector | 13133 | Health check |
| OTel Collector | 55679 | zPages (debug) |
| Prometheus | 9090 | Web UI |
| Zipkin | 9411 | Web UI |
| Grafana | 3000 | Web UI (admin/admin) |

### App Node

| Servis | Port | Açıklama |
|--------|------|----------|
| OTel Collector (Agent) | 4317 | OTLP gRPC (Uygulamalar buraya bağlanır) |
| OTel Collector (Agent) | 4318 | OTLP HTTP |
| OTel Collector | 8888 | Internal metrics |
| OTel Collector | 13133 | Health check |

## Uygulamalardan Bağlantı

App node'da çalışan uygulamalarınızda:

```bash
# Environment variables
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_SERVICE_NAME=my-application
export OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production
```

## Veri Akışı

```
Uygulama → App Node Collector → Monitoring Node Collector → Prometheus/Zipkin → Grafana
  (OTLP)      (Agent Mode)         (Gateway Mode)            (Storage)     (Visualization)
```

1. **Uygulamalar** telemetri verilerini `localhost:4317`'ye gönderir
2. **App Node Collector** verileri alır, işler ve monitoring node'a iletir
3. **Monitoring Node Collector** verileri Prometheus ve Zipkin'e yönlendirir
4. **Grafana** Prometheus ve Zipkin'den veri çekerek görselleştirir

## Detaylı Dokümantasyon

- [app-node/README.md](app-node/README.md) - App node detaylı kurulum ve yapılandırma
- [monitoring-node/README.md](monitoring-node/README.md) - Monitoring node detaylı kurulum ve yapılandırma
