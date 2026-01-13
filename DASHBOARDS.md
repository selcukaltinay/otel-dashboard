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
- **Kapsam**: CPU, Memory, Network, Disk I/O ve Health Metrics.

### 2. Global Process Observer
**URL**: http://localhost:3000/d/global-process-observer

Dağıtık process analizi.
- **Global Search**: Tüm nodlardaki processler içinde regex ile arama yapabilirsiniz.
- **Top Consumers**: Hangi node'da çalıştığı fark etmeksizin, tüm sistemdeki en çok kaynak tüketen processleri sıralar.
- **Process Grid**: Node bilgisiyle birlikte detaylı process tablosu.

### 3. Collector Health
**URL**: http://localhost:3000/d/collector-health

OpenTelemetry Ajanlarının (Collector) kendi sağlık durumunu izler.
- **Memory RSS**: Ajanların bellek kullanımı.
- **Queue Size & Export Rate**: Veri gönderim performansı ve darboğazlar.
- **Failures**: Paket kaybı veya iletim hataları.

## Kurulum
Dashboardları aktif etmek için Grafana'yı yeniden başlatın:
```bash
docker restart grafana
```
