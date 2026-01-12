# Multi-Node Monitoring Setup

OpenTelemetry monitoring sistemi artık birden fazla node'u destekliyor.

## 🎯 Özellikler

✅ **Node-Based Filtering**: Tek node, birkaç node veya tüm node'ları görüntüleyin  
✅ **Node Identification**: Her node'a benzersiz isim atanır (`node_name` label)  
✅ **Comparison Views**: Node'ları yan yana karşılaştırın  
✅ **Summary Table**: Tüm node'ların özet durumu tek tabloda  
✅ **Auto-Discovery**: Yeni node'lar otomatik olarak dashboard'a eklenir  

## 📊 Multi-Node Dashboard

**URL**: http://localhost:3000/d/otel-multi-node

### Dashboard Bileşenleri

1. **Node Filter** (Üst kısımda)
   - `All` - Tüm node'ları göster
   - `node-01` - Sadece bu node'u göster
   - Birden fazla seçim yapılabilir

2. **CPU Usage by Node**
   - Her node'un CPU kullanımı ayrı çizgi
   - Legend'da last, mean, max değerler

3. **Memory Usage by Node**
   - Node bazlı memory kullanımı

4. **Load Average by Node**
   - 1m ve 5m load average'ları
   - Threshold line'lar (sarı: 2, kırmızı: 4)

5. **Network Traffic by Node**
   - RX/TX traffic (mirror grafik)
   - Node bazlı toplam network trafiği

6. **Nodes Summary Table**
   - Tüm node'ların anlık durumu
   - CPU %, Memory %, Load, Process count
   - Gauge görünümü (renk kodlu)

## 🔧 Yeni Node Ekleme

### 1. Node Klasörünü Kopyalayın

```bash
# Mevcut app-node'u kopyalayın
cp -r /home/satech/work/otel/app-node /home/satech/work/otel/app-node-02
cd /home/satech/work/otel/app-node-02
```

### 2. Node Adını Ayarlayın

`.env` dosyasını düzenleyin:

```bash
cat > .env << 'ENVEOF'
MONITORING_NODE_HOST=otel-collector-gateway
NODE_NAME=node-02
ENVEOF
```

### 3. Port Çakışmasını Önleyin

`docker-compose.yml`'deki portları değiştirin:

```yaml
ports:
  - "24317:4317"   # OTLP gRPC receiver (node-01: 14317)
  - "24318:4318"   # OTLP HTTP receiver (node-01: 14318)
  - "28888:8888"   # Prometheus metrics (node-01: 18888)
  - "23134:13133" # health_check (node-01: 13134)
```

Container adını da değiştirin:

```yaml
container_name: otel-collector-agent-02  # node-01: otel-collector-agent
```

### 4. Node'u Başlatın

```bash
docker compose up -d
```

### 5. Doğrulama

```bash
# Container çalışıyor mu?
docker ps | grep otel-collector-agent-02

# Node Prometheus'ta görünüyor mu?
curl -s "http://localhost:9090/api/v1/query?query=otel_system_cpu_load_average_1m" | grep node-02

# Grafana'da dashboard'u açın ve "Node" filtresinde node-02'yi görüyor musunuz?
```

## 📝 Node İsimlendirme Kuralları

Önerilen format:
- **Coğrafi**: `us-east-1`, `eu-west-2`
- **Fonksiyonel**: `web-server-01`, `db-primary`, `cache-01`
- **Hybrid**: `prod-us-web-01`, `staging-db-01`

## 🎨 Dashboard Kullanımı

### Tek Node Görüntüleme

1. Dashboard'u açın: http://localhost:3000/d/otel-multi-node
2. Üstteki "Node" dropdown'ından bir node seçin
3. Tüm paneller otomatik güncellenir

### Birden Fazla Node Karşılaştırma

1. "Node" dropdown'ı açın
2. Birden fazla node seçin (örn: node-01, node-02)
3. Her grafik node'ları ayrı çizgiler ile gösterir
4. Legend'dan node'ları göster/gizle yapabilirsiniz

### Tüm Node'ları Görüntüleme

1. "Node" dropdown'dan "All" seçin
2. Summary table tüm node'ları gösterir
3. Grafikler tüm node'ların çizgilerini gösterir

## 🔍 Troubleshooting

### Node Dashboard'da Görünmüyor

```bash
# 1. Label'ı kontrol edin
curl -s "http://localhost:9090/api/v1/query?query=otel_system_cpu_load_average_1m" | grep node_name

# 2. Collector loglarını kontrol edin
docker logs otel-collector-agent-02 --tail 50

# 3. Gateway collector'a veri gidiyor mu?
docker logs otel-collector-gateway --tail 50 | grep ResourceMetrics
```

### Port Çakışması

```bash
# Kullanılan portları kontrol edin
docker ps --format 'table {{.Names}}\t{{.Ports}}'

# Çakışma varsa docker-compose.yml'deki portları değiştirin
```

### NODE_NAME Environment Variable Ayarlanmamış

```bash
# Container içindeki env var'ları kontrol edin
docker exec otel-collector-agent-02 env | grep NODE_NAME

# Yoksa .env dosyasını kontrol edin ve container'ı yeniden başlatın
docker compose down && docker compose up -d
```

## 📈 Metrikler ve Label'lar

Her metrik şu label'lara sahip:
- `node_name` - Node identifier (örn: node-01, node-02)
- `service_instance_id` - Service instance ID (node_name ile aynı)
- `environment` - Deployment environment (örn: production)
- `deployment_environment` - Deployment environment (örn: production)

### Örnek PromQL Queries

```promql
# Belirli bir node'un CPU kullanımı
100 - (avg by (node_name) (rate(otel_system_cpu_time_seconds_total{node_name="node-01",state="idle"}[1m])) * 100)

# Tüm node'ların memory kullanımı
otel_system_memory_usage_bytes{state="used"} / (otel_system_memory_usage_bytes{state="used"} + otel_system_memory_usage_bytes{state="free"})

# En yüksek CPU kullanan node
topk(1, 100 - (avg by (node_name) (rate(otel_system_cpu_time_seconds_total{state="idle"}[1m])) * 100))

# Node sayısı
count(count by (node_name) (otel_system_cpu_load_average_1m))
```

## 🚀 Toplu Node Deployment

Birden fazla node'u hızlıca deploy etmek için script:

```bash
#!/bin/bash
# deploy-nodes.sh

BASE_DIR="/home/satech/work/otel"
START_NODE=2
END_NODE=5

for i in $(seq $START_NODE $END_NODE); do
  NODE_DIR="$BASE_DIR/app-node-$(printf "%02d" $i)"
  
  # Kopyala
  cp -r "$BASE_DIR/app-node" "$NODE_DIR"
  
  # .env oluştur
  cat > "$NODE_DIR/.env" << EOF
MONITORING_NODE_HOST=otel-collector-gateway
NODE_NAME=node-$(printf "%02d" $i)
