# OpenTelemetry Monitoring - Quick Start Guide

## 🚀 Sistem Hazır!

Tüm servisler çalışıyor ve metrikler toplanıyor.

## 📊 Dashboards

### Ana Dashboardlar

1. **System Overview** (Önerilen Başlangıç) 
   http://localhost:3000/d/otel-system-overview
   - Tüm sistem metriklerinin özeti
   - CPU, Memory, Network, Disk tek ekranda

2. **Host Metrics** (Detaylı Analiz)
   http://localhost:3000/d/otel-host-metrics
   - Detaylı CPU, Memory, Disk metrikleri
   - Filesystem tablosu
   - Gauge ve pie chart görünümleri

3. **Network Monitoring** (Network Analizi)
   http://localhost:3000/d/otel-network-monitoring
   - RX/TX traffic (mirror grafik)
   - TCP connection states
   - Errors ve dropped packets
   - Interface summary tablosu

## 🔑 Erişim

```
Grafana:    http://localhost:3000 (admin/admin)
Prometheus: http://localhost:9090
Zipkin:     http://localhost:9411
```

## 📈 Mevcut Metrikler (24 adet)

- **CPU**: Kullanım, load average, core bazında detay
- **Memory**: Used/free, utilization
- **Disk**: I/O bytes, operations, latency, filesystem usage
- **Network**: Traffic, packets, errors, dropped, connections
- **Process**: Count by state, creation rate

## 🛠️ Container'ları Yönetme

```bash
# Tüm servisleri başlat
cd /home/satech/work/otel/monitoring-node
docker compose up -d

cd /home/satech/work/otel/app-node  
docker compose up -d

# Durumu kontrol et
docker ps

# Logları görüntüle
docker logs otel-collector-gateway
docker logs otel-collector-agent
docker logs grafana
docker logs prometheus
```

## 🎯 Dashboard Özellikleri

✅ **Otomatik refresh**: 10 saniye  
✅ **Varsayılan zaman**: Son 15 dakika  
✅ **Threshold'lar**: CPU >80%, Memory >90% için kırmızı  
✅ **Legend'lar**: Last, Max, Mean değerler  
✅ **Responsive**: Tüm ekran boyutlarında çalışır  

## 📖 Detaylı Dokümantasyon

Daha fazla bilgi için:
- [DASHBOARDS.md](DASHBOARDS.md) - Dashboard detayları, metrik listesi
- [README.md](monitoring-node/README.md) - Sistem yapılandırması

## ⚡ Hızlı Sorun Giderme

**Dashboard'da "No Data" görünüyorsa:**
```bash
# Prometheus target'ları kontrol et
open http://localhost:9090/targets

# Collector loglarını kontrol et
docker logs otel-collector-gateway --tail 50
docker logs otel-collector-agent --tail 50
```

**Container çalışmıyorsa:**
```bash
# Yeniden başlat
docker compose restart

# Veya tamamen yeniden oluştur
docker compose down
docker compose up -d
```

## 🎨 Ekran Görüntüleri

Grafana'ya giriş yaptıktan sonra:
1. Sol menüden "Dashboards" seçin
2. "OpenTelemetry - System Overview" dashboard'u açın
3. Canlı metrikleri görüntüleyin

## 🔔 Alerting (Gelecek)

Alert'ler henüz yapılandırılmadı. Eklemek için:
1. Prometheus alerting rules tanımlayın
2. Alertmanager ekleyin  
3. Notification channels yapılandırın (Slack, email, etc.)

## 📊 Mevcut Yapı

```
monitoring-node/
├── otel-collector-gateway (4317:4317, 8889:8889)
├── prometheus (9090:9090)
├── grafana (3000:3000)
└── zipkin (9411:9411)

app-node/
└── otel-collector-agent (14317:4317, 18888:8888)
    ├── Collects: CPU, Memory, Disk, Network, Process metrics
    └── Sends to: otel-collector-gateway
```

## 🚦 Status Check

```bash
# Tüm servislerin durumu
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Grafana dashboards
curl -s http://admin:admin@localhost:3000/api/search?type=dash-db | jq '.[].title'
```

---

**İyi izlemeler! 📊🎉**
