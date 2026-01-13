# OpenTelemetry Collector - Application Node

Bu dizin, uygulama sunucularında çalışacak hafif OpenTelemetry Collector konfigürasyonunu içerir.

## Özellikler

- **Hafif Yapı**: Sadece OpenTelemetry Collector (Agent Mode)
- **Düşük Kaynak Kullanımı**: ~256MB memory limit
- **Otomatik Yönlendirme**: Tüm telemetri verileri merkezi node'a gönderilir
- **Retry Mekanizması**: Ağ kesintilerinde veri kaybını önler
- **Host Metrics Toplama**: CPU, Memory, Disk, Network, Process metrikleri otomatik toplanır (30s interval)

## Kurulum

### 1. Konfigürasyon

`.env` dosyası oluşturun:
```bash
cp .env.example .env
```

`.env` dosyasını düzenleyin ve monitoring node'un **LAN üzerindeki IP adresi veya hostname**'ini girin:
```bash
# Monitoring node'un LAN IP'si
MONITORING_NODE_HOST=192.168.1.100

# VEYA hostname kullanarak
MONITORING_NODE_HOST=monitoring-server
```

**Not:** Bu collector host network modunda çalışır, böylece LAN üzerindeki diğer makinelerle doğrudan iletişim kurabilir.

### 2. Deployment

```bash
docker-compose up -d
```

## Portlar

- **4317**: OTLP gRPC receiver (uygulamalarınız buraya bağlanacak)
- **4318**: OTLP HTTP receiver
- **8888**: Collector kendi metrikleri
- **13133**: Health check endpoint

## Uygulamalarınızdan Bağlantı

Uygulamalarınızı şu endpoint'e yönlendirin:

```bash
# gRPC
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# HTTP
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

## Kontrol

```bash
# Container durumu
docker-compose ps

# Logları görüntüle
docker-compose logs -f

# Health check
curl http://localhost:13133
```

## Toplanan Metrikler

Collector otomatik olarak şu sistem metriklerini toplar:

### CPU Metrikleri
- CPU kullanımı (state: user, system, idle, iowait)
- CPU load average (1m, 5m, 15m)

### Memory Metrikleri
- Memory kullanımı (used, free, cached, buffered)
- Memory utilization (%)

### Disk Metrikleri
- Disk I/O (read/write bytes)
- Disk operations (read/write operations)
- Disk I/O time

### Network Metrikleri
- Network I/O (transmit/receive bytes)
- Network packets (transmit/receive)
- Network errors
- Network connections (by state)

### Process Metrikleri
- Process count (by status)
- Process creation rate

### Filesystem Metrikleri
- Filesystem usage (by mount point)
- Filesystem utilization (%)

### Paging/Swap Metrikleri
- Swap usage
- Paging operations

**Not:** Tüm metrikler `host_name` label'ı ile etiketlenir, böylece Grafana'da her node ayrı ayrı görülebilir.

## Veri Akışı

```
Host Metrics + Uygulamalar → Collector (Agent) → Merkezi Monitoring Node
        ↓
  localhost:4317/4318
```
