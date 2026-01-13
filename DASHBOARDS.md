# OpenTelemetry Distributed Monitoring Dashboards

Sistemin dağıtık yapısı için optimize edilmiş, merkezi monitoring dashboardları.

## Erişim Bilgileri

- **Grafana**: http://localhost:3000
  - Kullanıcı: `admin`
  - Şifre: `admin`

## Yeni Dashboardlar

### 1. Distributed Infrastructure
**URL**: http://localhost:3000/d/distributed-infrastructure

Tüm cluster'ın "Node Exporter" tarzı ana görünümü.
- **Multi-Node Visuals**: "All" seçeneğiyle tüm sistemdeki node'ları tek grafikte *ayrı ayrı* (multi-series) görürsünüz. Outlier tespiti için idealdir.
- **System Entropy**: Bağlam değiştirme (Context Switches) ile gizli CPU yükü analizi.
- **Advanced Metrics**: Zombie Process takibi, Memory Breakdown (Used/Cached/Free) ve Disk Latency analizi.
- **Kapsam**: CPU, Memory, Network, Disk I/O ve Health Metrics.

### 2. Global Process Observer
**URL**: http://localhost:3000/d/global-process-observer

Dağıtık process analizi.
- **Top Consumers** (En Üstte): CPU, Memory, Disk I/O ve Top Context Switchers grafikleri (En çok kaynak tüketenler).
- **Cluster Overview**: Toplam/Running/Zombie sayıları ve Process State Dağılımı (Pasta Grafik).
- **🚨 Alerts & Anomalies**:
  - **Recent Restarts**: Son 15 dk içinde başlayan processler.
  - **Memory Pressure**: Saniyede 10'dan fazla Page Fault üreten processler.
  - **Thread/FD Risk**: 500+ Thread veya 1000+ Open FD kullanan processler.
- **Detailed Grid**: Sütunlar: Threads, Open FDs, Disk R/W, **Uptime**, **VSZ (Virtual Mem)**, **Pending Signals**, **Page Faults/s**, **CS/s** ve **Net I/O**.



## Kurulum
Dashboardları aktif etmek için Grafana'yı yeniden başlatın:
```bash
docker restart grafana
```
