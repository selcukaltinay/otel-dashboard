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

## Network Mimarisi

Bu implementasyon **host network** modunu kullanır:
- Docker bridge network kullanılmaz
- Tüm servisler doğrudan host üzerinde çalışır
- App node ve monitoring node **farklı fiziksel makinelerde** çalışır
- Makineler LAN üzerinden birbirlerini görürler

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

**1. Dosyaları monitoring sunucusuna kopyalayın:**
```bash
# Sadece monitoring-node klasörünü kopyalayın
scp -r /home/satech/work/otel/monitoring-node user@monitoring-server:/opt/
```

**2. Monitoring sunucusunda:**
```bash
cd /opt/monitoring-node

# Stack'i başlat (host network modunda)
docker-compose up -d

# Servislerin durumunu kontrol edin
docker-compose ps
```

**Not:** Tüm servisler host network modunda çalıştığından, firewall yapılandırmasına gerek yoktur (firewall kapalıysa). Eğer firewall aktifse, port 4317 ve 3000'i açmanız gerekebilir.

### Adım 4: App Node Kurulumu (Her Uygulama Sunucusunda)

**1. Dosyaları app sunucusuna kopyalayın:**
```bash
# Sadece app-node klasörünü kopyalayın
scp -r /home/satech/work/otel/app-node user@app-server:/opt/
```

**2. App sunucusunda:**
```bash
cd /opt/app-node

# .env dosyası oluştur ve monitoring node adresini ayarla
cp .env.example .env
nano .env
# MONITORING_NODE_HOST değerini monitoring sunucunun LAN IP'si veya hostname'i ile değiştirin
# Örnek: MONITORING_NODE_HOST=192.168.1.100
# Örnek: MONITORING_NODE_HOST=monitoring-server

# Collector'ı başlat (host network modunda)
docker-compose up -d

# Durumu kontrol edin
docker-compose ps
docker-compose logs -f
```

**Not:** NODE_NAME otomatik olarak makinenin hostname'inden alınır, elle ayarlamanıza gerek yok.

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
