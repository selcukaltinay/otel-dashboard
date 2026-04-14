# NETWORK ALTYAPISI VALİDASYON CHECKLIST
**Broadcast Haberleşme — IGMP Snooping Disabled**

---

**AŞAMA:** SYS Uygulama Öncesi (Pre-Application)  
**DURUM:** Bu checklist'in tamamı SYS uygulamalarının başlatılmasından **önce** tamamlanmalı ve onaylanmalıdır.

---

## BAŞLANGIÇ KOŞULLARI VE YÜRÜTME KURALLARI

Bu checklist, SYS uygulamaları (servisler, middleware, veritabanları, uygulama katmanı bileşenleri) başlatılmadan önce eksiksiz tamamlanmalıdır. Checklist tamamlanmadan SYS uygulamaları **kesinlikle başlatılmamalıdır**. Ağ katmanında tespit edilemeyen bir sorun, uygulama seviyesinde belirsiz ve teşhisi çok daha zor hatalara dönüşür.

Tüm bölümlerdeki kontrol maddeleri **PASS** durumunda olmalıdır. FAIL olan maddeler için root cause belirlenmeli, düzeltme yapılmalı ve ilgili bölüm baştan koşulmalıdır. Checklist sonuç raporu **Network Ekibi** tarafından imzalanmalı ve **Proje Teknik Yöneticisine** teslim edilmelidir. SYS ekibi, uygulamaları ancak bu onay dokümanını aldıktan sonra başlatabilir.

Checklist yürütülürken ağ üzerinde **hiçbir SYS uygulama trafiği** bulunmamalıdır. Testler izole altyapı üzerinde yapılmalıdır. Checklist sırasında üçüncü parti trafik üreten servisler durdurulmalı veya trafiklerinin test sonuçlarını etkilemeyeceği doğrulanmalıdır.

Her bölümü yürüten kişi adını, tarihini ve sonucunu (PASS/FAIL) kaydetmelidir. FAIL maddelerinde açıklama ve alınan aksiyon not edilmelidir. Tüm test çıktıları (komut çıktıları, ekran görüntüleri) arşivlenmelidir.

---

## 0. TOPOLOJİ, ENVANTER VE DNS DOĞRULAMA

**Amaç:** Projenin tasarım dokümanlarındaki topoloji, IP planı ve DNS kayıtlarının fiili ortamla birebir örtüştüğünü kanıtlamak. Bu proje önceki projelerin konfigürasyonları temel alınarak oluşturulduğundan, miras konfigürasyon kalıntılarının tespit ve temizliğini garanti altına almak. Bu bölüm FAIL olursa sonraki tüm bölümlerin sonuçları güvenilmezdir.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Proje kapsamındaki tüm düğüm hostname'lerini listele. Her biri için `dig +short <hostname>` veya `nslookup <hostname>` çalıştır. Dönen IP adreslerinin proje dokümanındaki IP planıyla birebir eşleştiğini doğrula.
- [ ] Önceki projeden kopyalanan switch konfigürasyonlarında mevcut projeye ait olmayan VLAN, ACL, route veya port konfigürasyonlarının temizlendiğini doğrula.
- [ ] Her sunucuda `ip neigh show` (ARP tablosu) ile aynı VLAN'daki diğer düğümlerin görüldüğünü doğrula.
- [ ] Tüm düğümler arasında `traceroute` çalıştır. Paketin beklenen hop'lardan geçtiğini, beklenmeyen bir routing olmadığını doğrula.
- [ ] Proje IP planı ile fiili durumu karşılaştıran bir matris oluştur: **[Hostname | Beklenen IP | DNS Çözümlenen IP | Fiili IP (ip addr) | Eşleşme Durumu]**

---

## 1. FİZİKSEL KATMAN

**Amaç:** Sunucu NIC'lerinin beklenen hız ve duplex modunda hatasız link verdiğini, uçtan uca MTU tutarlılığının sağlandığını ve fiziksel katmanda (kablo, SFP, port) herhangi bir hata kaynağı bulunmadığını doğrulamak. Fiziksel katmandaki bir sorun, üst katmanlarda intermittent ve teşhisi güç semptomlara dönüşür.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Her sunucunun `hostname -I` çıktısı ile DNS'ten çözümlenen IP'nin tutarlı olduğunu doğrula.
- [ ] Sunucuların `/etc/resolv.conf` veya `systemd-resolved` konfigürasyonunun doğru DNS sunucusunu gösterdiğini kontrol et.
- [ ] Tüm sunucularda `ethtool <interface>` çalıştır. NIC'lerin 1000 Mbps Full Duplex modunda link verdiğini doğrula.
- [ ] `ethtool -S <interface>` ile rx_errors, tx_errors, rx_dropped, tx_dropped, rx_crc_errors sayaçlarının sıfır olduğunu kontrol et. Sıfır değilse kablo, SFP veya switch port seviyesinde fiziksel sorun var demektir.
- [ ] `ip link show <interface>` ile tüm uçlarda MTU değerlerinin tutarlı olduğunu doğrula.
- [ ] `ping -M do -s 1472 <HEDEF_IP>` ile path üzerinde fragmentation olmadan paket geçtiğini teyit et.
- [ ] `ethtool -i <interface>` ile NIC firmware ve driver sürümlerinin tüm node'larda aynı olduğunu kontrol et.

---

## 2. BACKBONE SWITCH

**Amaç:** Backbone switch'in firmware, CPU, bellek ve port sağlığının stabil olduğunu; spanning-tree topolojisinin beklenen durumda olduğunu ve tüm uplink'lerin hatasız çalıştığını doğrulamak. Backbone switch tüm inter-switch trafiğinin geçiş noktası olduğundan, bu katmandaki herhangi bir anomali tüm VLAN'ları etkiler.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] `show version` ile firmware sürümünü kontrol et, güncel ve tutarlı olduğunu doğrula.
- [ ] `show processes cpu history` ile CPU kullanım geçmişini kontrol et, anormal spike olmadığını doğrula.
- [ ] `show memory statistics` ile bellek durumunu kontrol et, kapasite aşımı olmadığını doğrula.
- [ ] `show interface status` ile tüm uplink portlarının connected, beklenen hızda ve full duplex olduğunu doğrula.
- [ ] `show interface <UPLINK_INTF>` çıktısında CRC, error, drop, discard sayaçlarının sıfır olduğunu kontrol et.
- [ ] `show spanning-tree summary` ile topology'nin stabil olduğunu, root bridge'in beklenen switch olduğunu ve topology change sayacının artmadığını doğrula.
- [ ] Port-channel varsa `show etherchannel summary` ile tüm üyelerin aktif olduğunu kontrol et.
- [ ] `show mac address-table count` ile MAC tablosu kapasitesinin aşılmadığını teyit et.

---

## 3. KENAR (ACCESS) SWITCH

**Amaç:** Sunucuların doğrudan bağlı olduğu kenar switch portlarının doğru VLAN'a atandığını, beklenen hız ve duplex'te hatasız çalıştığını ve storm control konfigürasyonunun broadcast trafik ihtiyacıyla uyumlu olduğunu doğrulamak. Yanlış VLAN ataması veya düşük storm control eşiği, uygulama trafiğinin sessizce kesilmesine neden olur.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] `show version` ile firmware sürümünü kontrol et, backbone switch ile uyumlu olduğunu doğrula.
- [ ] `show interface status` ile sunucu portlarının 1000 Mbps Full Duplex connected olduğunu doğrula.
- [ ] `show interface <INTF>` çıktısında CRC, error, drop, discard sayaçlarının sıfır olduğunu kontrol et.
- [ ] `show vlan brief` ile sunucu portlarının doğru VLAN'a atandığını doğrula.
- [ ] `show storm-control broadcast` ile storm control eşiğinin konfigüre edildiğini ve uygulama trafiğini bloklamayacak seviyede olduğunu doğrula.
- [ ] `show mac address-table dynamic vlan <VLAN_ID>` ile VLAN'daki tüm sunucuların MAC adreslerinin öğrenildiğini kontrol et.

---

## 4. IGMP SNOOPING DEVRE DIŞI DOĞRULAMA

**Amaç:** Broadcast haberleşme yapılan VLAN'larda IGMP snooping'in devre dışı olduğunu, bu değişikliğin diğer VLAN'ları etkilemediğini ve storm control eşiklerinin IGMP snooping kapalıyken artacak broadcast/multicast yüke göre hesaplandığını doğrulamak. IGMP snooping açık kalırsa, multicast grup üyeliği olmayan hedeflere broadcast/multicast trafik ulaşmaz ve uygulama haberleşmesi sessizce kopar.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Tüm backbone ve kenar switch'lerde `show ip igmp snooping` çalıştır, global durumu kontrol et.
- [ ] `show ip igmp snooping vlan <VLAN_ID>` ile broadcast haberleşme yapılan VLAN'larda IGMP snooping'in disabled olduğunu doğrula.
- [ ] Diğer VLAN'lardaki IGMP snooping durumunun etkilenmediğini kontrol et.
- [ ] Storm control eşiklerinin IGMP snooping kapalıyken oluşacak ek broadcast ve multicast yüke göre hesaplandığını teyit et.

---

## 5. ZAMAN SENKRONİZASYONU

**Amaç:** Tüm düğümler arasında saat senkronizasyonunun 1 ms (NTP) veya mikrosaniye (PTP) hassasiyetinde olduğunu doğrulamak. Zaman sapması; log korelasyonunu bozar, dağıtık sistemlerde ordering hatalarına yol açar ve zamana duyarlı protokollerde veri kaybına veya tutarsızlığa neden olur.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Tüm sunucularda `chronyc tracking` veya `ntpq -p` çalıştır, NTP/PTP senkronizasyon durumunu kontrol et.
- [ ] Atomik saat veya GPS referans kullanılıyorsa NTP sunucusunun stratum 1 olduğunu doğrula.
- [ ] Tüm node'larda saat offset'inin 1 ms altında olduğunu kontrol et.
- [ ] `chronyc sources -v` ile referans kaynağın erişilebilir ve stabil olduğunu, kaynaklar arası sapmanın 1 ms altında kaldığını doğrula.
- [ ] PTP kullanılıyorsa `ptp4l` ve `phc2sys` servislerinin çalıştığını doğrula.
- [ ] PTP offset'inin mikrosaniye seviyesinde olduğunu `pmc -u -b 0 'GET CURRENT_DATA_SET'` ile kontrol et.
- [ ] Switch'lerin PTP transparent/boundary clock olarak konfigüre edildiğini doğrula (PTP varsa).

---

## 6. LINUX KERNEL VE OS NETWORK TUNING

**Amaç:** Sunucu işletim sistemlerinin ağ yığını parametrelerinin (buffer boyutları, backlog, ring buffer, NUMA affinity, interrupt coalescing) yüksek throughput ve yüksek PPS senaryolarına uygun yapılandırıldığını doğrulamak. Varsayılan kernel parametreleri genellikle genel amaçlıdır ve yoğun ağ trafiğinde darboğaz oluşturur. Bu bölüm performans testlerinden ÖNCE uygulanmalıdır, aksi halde test sonuçları tuning öncesi değerleri yansıtır.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] `sysctl net.core.rmem_max` değerini doğrula.
- [ ] `sysctl net.core.wmem_max` değerini doğrula.
- [ ] `sysctl net.core.netdev_max_backlog` değerini doğrula.
- [ ] `/proc/net/softnet_stat` çıktısının 2. sütunundaki drop sayacını baseline olarak kaydet. Test sonrasında artış olup olmadığını karşılaştır.
- [ ] `ethtool -g <interface>` ile NIC ring buffer boyutlarını kontrol et. Mevcut değerler maksimum desteklenen değerlerde değilse `ethtool -G <interface> rx <MAX> tx <MAX>` ile artır.
- [ ] `cat /sys/class/net/<interface>/device/numa_node` ile NIC'in NUMA node'unu öğren. Uygulamanın aynı NUMA node üzerinde çalışacağını doğrula.
- [ ] `ethtool -c <interface>` ile NIC interrupt coalescing ayarlarını kontrol et. Yüksek PPS senaryolarında adaptive modda olması önerilir.

---

## 7. TCP THROUGHPUT TESTİ

**Amaç:** Sunucular arasındaki TCP bant genişliğinin fiziksel link kapasitesine yakın (≥940 Mbps) olduğunu, tek akış ve çoklu paralel akışlarda performansın korunduğunu ve çift yönlü trafikte bant genişliğinin düşmediğini doğrulamak. TCP throughput, uygulama katmanının kullanabileceği efektif kapasiteyi temsil eder.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Hedef sunucuda `iperf3 -s -p 5201` ile sunucu modda iperf başlat. İstemci sunucudan `iperf3 -c <HEDEF_IP> -p 5201 -t 60 -i 5` ile 60 saniyelik TCP testi çalıştır. Throughput'un 940 Mbps üzerinde olduğunu doğrula.
- [ ] Çıktıdaki retransmit sütununu kontrol et. Retransmit sayısının sıfır veya sıfıra çok yakın olduğunu doğrula. Yüksek retransmit varsa switch port hataları, buffer yetersizliği veya duplex mismatch kontrol et.
- [ ] `iperf3 -c <HEDEF_IP> -t 60 -P 8` ile 8 paralel akışla testi tekrarla. Toplam throughput'un düşmediğini doğrula.
- [ ] `iperf3 -c <HEDEF_IP> -t 60 --bidir` ile çift yönlü test yap. Her iki yönde de bant genişliğinin korunduğunu doğrula.

---

## 8. TCP LATENCY TESTİ

**Amaç:** Aynı switch ve farklı switch'ler üzerindeki sunucular arasındaki ağ gecikmesinin beklenen eşiklerde (aynı switch ≤0.5 ms, backbone üzerinden ≤0.7 ms) olduğunu ve jitter'ın minimum seviyede kaldığını doğrulamak. Beklenenden yüksek gecikme, yanlış topoloji, STP suboptimal path veya QoS misconfiguration göstergesidir.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Aynı switch üzerindeki sunucular arasında `ping -c 100 -i 0.01 <HEDEF_IP>` ile 100 ICMP paketi gönder. Ortalama RTT'nin 0.5 ms altında, jitter'ın 0.1 ms altında olduğunu doğrula.
- [ ] Backbone switch üzerinden geçen node'lar arasında aynı testi tekrarla. Ek gecikmenin 0.2 ms'i aşmadığını doğrula.
- [ ] RTT beklenenin üzerindeyse switch QoS konfigürasyonunu, spanning-tree topology'sini ve ara katman cihazlarını kontrol et.

---

## 9. BROADCAST ÖN KONTROLLER

**Amaç:** Broadcast testlerine başlamadan önce tüm düğümlerde broadcast adresinin, subnet mask'ın, kernel parametrelerinin ve firewall kurallarının broadcast trafiğine uygun yapılandırıldığını doğrulamak. Bu ön koşullar sağlanmadan yapılan broadcast testleri, altyapı sorununu değil konfigürasyon hatasını ölçer.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Tüm sunucularda `ip addr show <interface>` ile broadcast adresinin doğru tanımlı olduğunu doğrula.
- [ ] Subnet mask'ın tüm node'larda tutarlı olduğunu kontrol et. Farklı subnet mask farklı broadcast adresi demektir ve haberleşme kopar.
- [ ] `sysctl net.ipv4.conf.<interface>.rp_filter` değerinin 0 veya 2 olduğunu doğrula.
- [ ] `iptables -L -n` ile firewall'da broadcast trafiğinin bloklanmadığını kontrol et.
- [ ] `sysctl net.ipv4.icmp_echo_ignore_broadcasts` değerini kontrol et ve uygulamanın ihtiyacına göre ayarlandığını doğrula.

---

## 10. BROADCAST THROUGHPUT TESTİ

**Amaç:** Broadcast adresine gönderilen UDP trafiğin tüm alıcı düğümlere kayıpsız, beklenen throughput'ta (≥940 Mbps) ve kabul edilebilir jitter seviyesinde (<1 ms) ulaştığını doğrulamak. IGMP snooping kapalı olduğundan broadcast trafiğin VLAN'daki tüm portlara iletildiğini teyit etmek.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Alıcı node'larda `iperf -s -u -B <BROADCAST_ADDR> -p 5001 -i 5` ile broadcast adresinde dinlemeye başlat.
- [ ] Gönderici node'dan `iperf -c <BROADCAST_ADDR> -u -t 60 -i 5 -b 1000M -p 5001` ile broadcast adresine 1000 Mbps hedefli UDP trafik gönder.
- [ ] Tüm alıcı node'larda throughput'un 940 Mbps üzerinde olduğunu, packet loss'un %0 olduğunu ve jitter'ın 1 ms altında kaldığını doğrula.
- [ ] Kayıp görülüyorsa bandwidth'i 900, 800 Mbps şeklinde kademe kademe düşürerek kayıpsız çalışılan maksimum noktayı bul.
- [ ] Kayıpsız nokta 940 Mbps altındaysa NIC ring buffer, kernel netdev_max_backlog ve switch port istatistiklerini kontrol et.
- [ ] VLAN'daki ilgisiz bir cihazda `tcpdump -i <interface> -c 10 port 5001` ile broadcast trafiğin o cihaza da ulaştığını doğrula. Bu beklenen davranıştır.

---

## 11. FARKLI PAKET BOYUTLARINDA BROADCAST KAYBI TESTİ

**Amaç:** Broadcast trafiğinin farklı paket boyutlarında (64, 512, 1024, 1400 byte) kayıpsız iletildiğini doğrulamak. Küçük paketler NIC/switch PPS (packets per second) limitini, büyük paketler MTU uyumsuzluğunu ve fragmentation sorunlarını ortaya çıkarır. Uygulama farklı boyutlarda paket üretebileceğinden, tüm senaryolarda kayıpsız çalışma garanti edilmelidir.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Gönderici node'dan `iperf -c <BROADCAST_ADDR> -u -t 30 -b 1000M -l 64 -p 5001` ile 64 byte paket boyutunda broadcast trafik gönder. Alıcılarda lost datagrams sayısını kontrol et.
- [ ] Aynı testi sırasıyla 512, 1024, 1400 byte paket boyutlarında tekrarla. Her boyutta alıcılarda kayıp olup olmadığını kontrol et.
- [ ] Küçük paketlerde kayıp görülüyorsa NIC veya switch PPS limitine takılıyor olabilir. `ethtool -c <interface>` ile interrupt coalescing ayarlarını kontrol et.
- [ ] Büyük paketlerde kayıp görülüyorsa MTU uyumsuzluğu veya fragmentation sorunu olabilir.

---

## 12. BROADCAST STORM CONTROL DOĞRULAMA

**Amaç:** Storm control mekanizmasının yüksek hacimli broadcast trafikte doğru eşikte devreye girdiğini, devreye girdiğinde trafiği sınırladığını ve aynı VLAN'daki diğer normal trafiği olumsuz etkilemediğini doğrulamak. Storm control eşiği, uygulama trafiğini bloklamayacak kadar yüksek ama ağı koruyacak kadar düşük bir değerde olmalıdır.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Gönderici node'dan `iperf -c <BROADCAST_ADDR> -u -t 30 -b 1000M -p 5001` ile yüksek hacimli broadcast trafik gönder.
- [ ] Switch loglarında storm control'ün tetiklenip tetiklenmediğini kontrol et.
- [ ] Storm control tetiklendiyse trafiğin sınırlandırıldığını veya kesildiğini switch port istatistiklerinden doğrula.
- [ ] Storm control devreye girdikten sonra VLAN'daki diğer normal trafiğin etkilenip etkilenmediğini başka bir sunucu çifti arasında eşzamanlı ping veya iperf ile kontrol et.
- [ ] Storm control eşiğinin uygulama trafiğinin üzerinde ama link kapasitesinin altında bir değerde olduğunu teyit et.

---

## 13. BACKBONE-KENAR ARASI BROADCAST GEÇİŞ TESTİ

**Amaç:** Broadcast trafiğinin backbone switch üzerinden farklı kenar switch'lere bağlı sunuculara kayıpsız ve tutarlı performansla ulaştığını doğrulamak. Aynı kenar switch arkasındaki sonuçlarla karşılaştırarak backbone uplink kapasitesinin ve switch buffer'larının broadcast yükünü kaldırabildiğini teyit etmek.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Farklı kenar switch'lere bağlı sunucular arasında broadcast testi yap. Göndericiyi bir kenar switch'e, alıcıları diğer kenar switch'lere bağlı sunuculara kur.
- [ ] `iperf -c <BROADCAST_ADDR> -u -t 60 -b 1000M -p 5001` ile trafik gönder. Alıcılarda throughput ve packet loss değerlerini kontrol et.
- [ ] Backbone switch üzerinde `show interface <UPLINK_INTF>` çıktısında broadcast, output drops sayaçlarının artmadığını kontrol et.
- [ ] Farklı kenar switch arkasındaki alıcılardaki sonuçları aynı kenar switch arkasındaki alıcılarla karşılaştır. Fark varsa backbone uplink kapasitesi veya switch buffer yetersizliğine işaret eder.

---

## 14. UZUN SÜRELİ DAYANIKLILIK TESTİ

**Amaç:** Ağ altyapısının 1 saatlik kesintisiz broadcast ve TCP trafik altında stabil kaldığını, hiçbir hata sayacının artmadığını, paket kaybı oluşmadığını ve zaman senkronizasyonunun bozulmadığını doğrulamak. Kısa süreli testlerde görülmeyen termal throttling, buffer leak, memory fragmentation ve zamana bağlı drift sorunları ancak uzun süreli yük altında ortaya çıkar.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] Gönderici node'dan `iperf -c <BROADCAST_ADDR> -u -t 3600 -i 30 -b 1000M -p 5001` ile broadcast adresine 1000 Mbps hızında 1 saatlik kesintisiz trafik gönder.
- [ ] Eşzamanlı olarak `iperf3 -c <HEDEF_IP> -t 3600 -i 30 -P 4` ile TCP trafik de gönder.
- [ ] 1 saat boyunca tüm alıcılarda broadcast packet loss'un %0, TCP throughput'un 940 Mbps üzerinde ve retransmit'in artmadığını doğrula.
- [ ] Test sırasında `sar -n DEV 30` ile NIC istatistiklerini, `ethtool -S <interface>` ile hata sayaçlarını, `/proc/net/softnet_stat` ile kernel drop sayaçlarını periyodik kontrol et.
- [ ] VLAN'daki tüm cihazlarda `sar -u 30` ile CPU kullanımını izle. Broadcast trafik her cihazın kerneline ulaşacağı için CPU spike'ları gözlemlenebilir.
- [ ] Testin sonunda başlangıca göre hiçbir hata sayacının artmamış olduğunu doğrula.
- [ ] `chronyc tracking` ile zaman senkronizasyonunun bozulmadığını, offset'in hâlâ 1 ms altında olduğunu doğrula.

---

## 15. FAILOVER TESTİ (BONDING/LACP VARSA)

**Amaç:** Bond/LACP yapılandırmasının bir slave port kaybında trafiği beklenen sürede (≤3 saniye) yedek porta aktardığını, port geri geldiğinde bond'un yeniden dengelendiğini ve failover sürecinde hem unicast hem broadcast trafiğin kabul edilebilir kayıp seviyesinde kaldığını doğrulamak. Failover mekanizması test edilmeden canlıya alınan sistemlerde, ilk port arızasında plansız kesinti yaşanır.

| Yürüten | Tarih | Sonuç (PASS/FAIL) |
|---------|-------|--------------------|
|         |       |                    |

- [ ] `cat /proc/net/bonding/bond0` ile bond arayüzü durumunu doğrula.
- [ ] Bir terminalden `iperf3 -c <HEDEF_IP> -t 120 -i 5` ile sürekli TCP trafik başlat.
- [ ] Trafik akarken `ip link set <interface> down` ile aktif slave'i devre dışı bırak. iperf çıktısında throughput'un 3 saniye içinde geri geldiğini doğrula.
- [ ] 10 saniye sonra `ip link set <interface> up` ile portu tekrar aç. Bond'un yeniden dengelendiğini doğrula.
- [ ] Aynı testi broadcast trafik akarken tekrarla. Failover sırasında broadcast kaybının kabul edilebilir seviyede olduğunu kontrol et.
- [ ] Switch tarafında `show lacp neighbor` ve `show etherchannel summary` ile LACP portlarının durumunu izle.

---

## ONAY

| Alan | Değer |
|------|-------|
| **Tüm Bölümler PASS mı?** | EVET / HAYIR |
| **Hazırlayan (Network Ekibi)** | |
| **İmza** | |
| **Tarih** | |
| **Onaylayan (Proje Teknik Yöneticisi)** | |
| **İmza** | |
| **Tarih** | |
| **SYS Uygulamaları Başlatılabilir mi?** | EVET / HAYIR |

---

> **Not:** Bu checklist PASS olmadan SYS uygulamaları başlatılamaz. FAIL olan her madde için root cause analizi yapılmalı, düzeltme uygulanmalı ve ilgili bölüm baştan koşulmalıdır.