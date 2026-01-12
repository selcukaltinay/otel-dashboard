# OpenTelemetry Monitoring Dashboards

Sisteminiz için kapsamlı monitoring dashboardları hazırlandı.

## Erişim Bilgileri

- **Grafana**: http://localhost:3000
  - Kullanıcı: `admin`
  - Şifre: `admin`

- **Prometheus**: http://localhost:9090
- **Zipkin**: http://localhost:9411

## Hazır Dashboardlar

### 1. OpenTelemetry - System Overview
**URL**: http://localhost:3000/d/otel-system-overview

Tüm sistemin genel durumunu tek bakışta görüntüleyin:
- CPU kullanımı (özet ve core bazında)
- Memory kullanımı
- Load average (1m, 5m, 15m)
- Process sayıları ve durumları
- Network trafiği (RX/TX)
- Disk I/O
- Process creation rate

**Kullanım Alanı**: Sistem sağlığının hızlı kontrolü, genel durum izleme

### 2. OpenTelemetry - Host Metrics
**URL**: http://localhost:3000/d/otel-host-metrics

Detaylı host metrikleri:
- **CPU**:
  - Core bazında kullanım
  - Ortalama CPU yüzdesi (gauge)
  - Load average
- **Memory**:
  - Kullanım grafiği (used/free)
  - Memory yüzdesi (gauge)
  - Memory dağılımı (pie chart)
- **Disk**:
  - I/O byte rates
  - IOPS (operations/sec)
  - Filesystem kullanımı (tablo)
- **Process**:
  - Aktif process sayısı
  - Process durumları

**Kullanım Alanı**: Sistem resource analizi, performans optimizasyonu

### 3. OpenTelemetry - Network Monitoring
**URL**: http://localhost:3000/d/otel-network-monitoring

Kapsamlı network metrikleri:
- **Traffic**:
  - Byte/sec (RX/TX - mirror grafik)
  - Packet/sec (RX/TX)
- **Errors & Drops**:
  - Network errors (interface bazında)
  - Dropped packets
- **Connections**:
  - TCP connection states (timeline)
  - TCP connection distribution (pie chart)
- **Interface Summary**:
  - Tüm network interface'lerin özet tablosu
  - RX/TX rates
  - Error counts

**Kullanım Alanı**: Network sorunlarını tespit, bandwidth analizi, connection tracking

### 4. Host Metrics Overview
**URL**: http://localhost:3000/d/otel-host-overview

Basitleştirilmiş host metrikleri görünümü

### 5. Network Metrics
**URL**: http://localhost:3000/d/otel-network-metrics

Network metriklerinin alternatif görünümü

### 6. Process & Load Metrics
**URL**: http://localhost:3000/d/otel-process-metrics

Process ve load detayları

## Mevcut Metrikler

Prometheus'ta şu metrikler mevcut:

### CPU Metrikleri
- `otel_system_cpu_time_seconds_total` - CPU zamanı (state bazında: idle, user, system, etc.)
- `otel_system_cpu_load_average_1m` - 1 dakika load average
- `otel_system_cpu_load_average_5m` - 5 dakika load average
- `otel_system_cpu_load_average_15m` - 15 dakika load average

### Memory Metrikleri
- `otel_system_memory_usage_bytes` - Memory kullanımı (state: used, free)
- `otel_system_paging_usage_bytes` - Paging/Swap kullanımı
- `otel_system_paging_operations_total` - Paging operasyonları
- `otel_system_paging_faults_total` - Page faults

### Disk Metrikleri
- `otel_system_disk_io_bytes_total` - Disk I/O (direction: read, write)
- `otel_system_disk_operations_total` - Disk operasyonları
- `otel_system_disk_io_time_seconds_total` - I/O zamanı
- `otel_system_disk_operation_time_seconds_total` - Operasyon zamanı
- `otel_system_filesystem_usage_bytes` - Filesystem kullanımı
- `otel_system_filesystem_inodes_usage` - Inode kullanımı

### Network Metrikleri
- `otel_system_network_io_bytes_total` - Network trafiği (direction: receive, transmit)
- `otel_system_network_packets_total` - Paket sayısı
- `otel_system_network_errors_total` - Network hataları
- `otel_system_network_dropped_total` - Dropped paketler
- `otel_system_network_connections` - TCP/UDP connection sayıları (state bazında)

### Process Metrikleri
- `otel_system_processes_count` - Process sayısı (status: running, sleeping, blocked)
- `otel_system_processes_created_total` - Oluşturulan toplam process sayısı

## Dashboard Özellikleri

### Otomatik Refresh
Tüm dashboardlar 10 saniyede bir otomatik olarak yenilenir.

### Zaman Aralığı
Varsayılan: Son 15 dakika
- Sağ üstten değiştirilebilir
- Önerilen aralıklar: 5m, 15m, 1h, 6h, 24h

### Filtreler ve Variables
Dashboardlar template variables destekler, gelecekte eklenebilir:
- Host/instance bazlı filtreleme
- Environment filtreleme
- Device/interface filtreleme

## Özelleştirme

### Yeni Dashboard Ekleme
1. Dashboard JSON'unu oluşturun
2. `/home/satech/work/otel/monitoring-node/configs/grafana/dashboards/` dizinine kaydedin
3. Grafana'yı yeniden başlatın:
   ```bash
   docker restart grafana
   ```

### Mevcut Dashboard'u Düzenleme
1. Grafana UI'da dashboard'u düzenleyin
2. JSON export edin (Share > Export > Save to file)
3. Dosyayı dashboards dizinine kaydedin

### Threshold Ayarlama
Her panel için threshold'lar Grafana UI'dan ayarlanabilir:
- Panel > Edit > Thresholds
- Örnek: CPU > 80% için kırmızı alarm

## Performans İpuçları

1. **Retention**: Prometheus varsayılan 30 gün veri tutar
2. **Scrape Interval**: 15 saniye (prometheus.yml'de ayarlanabilir)
3. **Collection Interval**: Host metrics 30 saniyede bir toplanır

## Sorun Giderme

### "No Data" Hatası
- Prometheus target'ları kontrol edin: http://localhost:9090/targets
- OTel collector loglarını kontrol edin:
  ```bash
  docker logs otel-collector-gateway
  docker logs otel-collector-agent
  ```

### Yavaş Dashboard
- Zaman aralığını kısaltın
- Rate/increase fonksiyonlarının interval'ini artırın

### Metrik Eksik
- Prometheus'ta metriği aratın: http://localhost:9090/graph
- OTel collector config'i kontrol edin

## Yararlı Prometheus Queries

```promql
# CPU kullanımı yüzdesi
100 - (avg(rate(otel_system_cpu_time_seconds_total{state="idle"}[1m])) * 100)

# Memory kullanımı yüzdesi
otel_system_memory_usage_bytes{state="used"} / 
(otel_system_memory_usage_bytes{state="used"} + otel_system_memory_usage_bytes{state="free"})

# Network throughput (Mbps)
rate(otel_system_network_io_bytes_total[1m]) * 8 / 1000000

# Disk I/O latency
rate(otel_system_disk_io_time_seconds_total[1m]) / 
rate(otel_system_disk_operations_total[1m])
```

## Next Steps

1. **Alerting Ekleyin**:
   - Prometheus alerting rules oluşturun
   - Alertmanager ekleyin
   - Notification channels yapılandırın (Slack, email, etc.)

2. **Long-term Storage**:
   - Prometheus remote write yapılandırın
   - VictoriaMetrics veya Thanos ekleyin

3. **Daha Fazla Metrik**:
   - Application metrikleri ekleyin
   - Custom metrics toplayın
   - Distributed tracing'i aktif edin

4. **Dashboard'ları Genişletin**:
   - Business metrikleri ekleyin
   - SLO/SLI dashboards oluşturun
   - Anomaly detection ekleyin
