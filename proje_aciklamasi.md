# 🏗️ Flask-MongoDB Projesi — Komple Mülakat Rehberi

> Bu doküman, projenin her aşamasını **hiç yazılım bilmeyen birine** bile anlatabilecek düzeyde açıklar. Mülakatınızda "Bu projeyi bize anlatır mısın?" diye sorulduğunda bu rehberi referans alın.

---

## 📖 İçindekiler

1. [Projeye Genel Bakış — "Bu Proje Ne?"](#1-projeye-genel-bakış)
2. [Mülakat Görevi ve Teknoloji Seçimlerim](#2-mülakat-görevi-ve-teknoloji-seçimlerim)
3. [Büyük Resim — 5 Adımlık Evrim](#3-büyük-resim--5-adımlık-evrim)
4. [Adım 1: Uygulama Katmanı (Flask + MongoDB)](#4-adım-1-uygulama-katmanı)
5. [Adım 2: Docker ile Konteynerleştirme](#5-adım-2-docker-ile-konteynerleştirme)
6. [Adım 3: Docker Compose ile Orkestrasyon](#6-adım-3-docker-compose-ile-orkestrasyon)
7. [Adım 4: Kubernetes ile Ölçekleme ve Yönetim](#7-adım-4-kubernetes-ile-ölçekleme-ve-yönetim)
8. [Adım 5: Jenkins ile CI/CD Pipeline](#8-adım-5-jenkins-ile-cicd-pipeline)
9. [Proje Dosya Haritası — Her Dosya Ne İşe Yarar?](#9-proje-dosya-haritası)
10. [Mülakatta Sorulabilecek Sorular ve Cevapları](#10-mülakatta-sorulabilecek-sorular)
11. [Özet: Bir Cümlede Her Teknoloji](#11-özet)

---

## 1. Projeye Genel Bakış

### Bu proje ne?
Bir **Görev Yöneticisi (Task Manager)** web uygulaması. Kullanıcılar tarayıcı üzerinden:
- ✅ Yeni görev oluşturabilir (Create)
- 📝 Görevlerin açıklamasını güncelleyebilir (Update)
- 🗑️ Görev silebilir (Delete)
- 🔄 Tüm görevleri sıfırlayabilir (Reset)

Bu işlemlere yazılımda **CRUD** denir: **C**reate, **R**ead, **U**pdate, **D**elete.

### Ama önemli olan uygulama değil, altyapısı!

Bu projenin asıl değeri, basit bir web uygulamasının **profesyonel dünyada nasıl canlıya alındığını** (deploy edildiğini) uçtan uca göstermesidir. Yani bu proje şu soruyu cevaplıyor:

> *"Bir yazılımcı kodunu yazıp 'bitti' dedi. Peki bu kod, gerçek dünyada kullanıcılara nasıl ulaşır?"*

---

## 2. Mülakat Görevi ve Teknoloji Seçimlerim

Bu bölümde, mülakatta "Neden bu projeyi veya bu aracı seçtin?" diye sorduklarında kendi kelimelerinizle verebileceğiniz doğal ve rahat cevapları hazırladım:

### 2.1. Neden Python & Flask Projesini Seçtim?
* **Cevap:** "Verilen seçenekler arasında Java Spring Petclinic de vardı ama o proje çok büyük ve ağırdı. Benim buradaki asıl amacım altyapı ve DevOps süreçlerini göstermekti. Bu yüzden daha sade ve anlaşılır olan Python (Flask) projesini seçtim. Böylece karmaşık kodlar arasında boğulmadan Docker, Kubernetes ve CI/CD kısımlarına odaklanabildim."
* **Koda Ne Kattım?** "Uygulamayı olduğu gibi almadım, biraz da geliştirdim. Mesela şifreler kodun içinde açıkça duruyordu, onları gizledim. Veritabanı bağlantısı koparsa diye uygulamanın tekrar tekrar bağlanmayı denemesi için ufak bir kod ekledim (retry). Ayrıca Kubernetes'in uygulamanın sağlıklı çalışıp çalışmadığını anlaması için `/health` adında bir kontrol noktası yazdım."

### 2.2. Neden Docker ve Docker Compose?
* **Cevap:** "Benden uygulamayı Dockerize etmem istenmişti. Ben hem Flask uygulamasını hem de MongoDB veritabanını tek bir komutla ayağa kaldırabilmek için Docker Compose kullandım. Bu sayede projeyi indiren biri hiçbir ayarla uğraşmadan anında çalıştırabiliyor. İmaj boyutunu küçük tutmaya ve konteyneri güvenlik için yetkisiz (non-root) kullanıcıyla çalıştırmaya özen gösterdim."

### 2.3. Neden Minikube?
* **Cevap:** "Lokalde Kubernetes çalıştırmak için Kind veya K3s gibi alternatifler de var ama Minikube bana en stabil ve dokümantasyonu en bol olanı gibi geldi. Özellikle eklenti desteği çok iyi. Ayrıca benden otomasyon yeteneklerimi de göstermem istenmişti, ben de Minikube'ü tek tıkla kuran bir PowerShell script'i yazdım."

### 2.4. Neden Düz YAML Değil de Helm?
* **Cevap:** "Aslında düz YAML dosyaları (manifest) yazıp geçebilirdim. Ama Helm kullanarak tüm projeyi (uygulama ve veritabanı dahil) tek bir yerden yönetilebilir bir paket haline getirmek istedim. Bu sayede `values.yaml` dosyasından her şeyi çok kolay değiştirebiliyorum. Kustomize yerine Helm seçmemin sebebi de Helm'in daha derli toplu bir paket yöneticisi olması."

### 2.5. Neden GitLab/GitHub Actions Yerine Jenkins?
* **Cevap:** "GitHub Actions kullanmak benim için çok daha kolay olurdu, sadece bir YAML dosyası yazmam yeterliydi. Ama ben kendimi zorlamak ve Jenkins'i sıfırdan kurup yapılandırabildiğimi göstermek istedim. Jenkins'in içine Docker ve Kubernetes araçlarını kurduğumuz özel bir imaj hazırladık. Bu benim için harika bir öğrenme süreci oldu."

### 2.6. Ekstra Puan İsteklerini Nasıl Yaptım?
* "Görevde istenen **Ekstra Puan** maddelerinin hepsini yapmaya çalıştım. Örneğin kodun direkt çalıştırılması yerine production'a (canlıya) uygun olması için Gunicorn ekledim. Projenin adım adım nasıl çalışacağını anlatan detaylı bir README dosyası hazırladım. Son olarak da K8s ve Jenkins kurulumu için elle kurmak yerine otomasyon scriptleri yazdım."

---

## 3. Büyük Resim — 5 Adımlık Evrim

Bu projeyi **bir restoranın evrimleşme hikayesi** olarak düşünebilirsiniz:

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROJENİN EVRİM HARİTASI                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Adım 1: UYGULAMA                                              │
│  🍳 Evinizde yemek yapıyorsunuz (Flask + MongoDB)              │
│  Dosyalar: run.py, classes.py, templates/                       │
│       ↓                                                         │
│  Adım 2: DOCKER                                                │
│  📦 Yemeği paketleyip her yerde aynı tadı garanti ediyorsunuz   │
│  Dosyalar: Dockerfile, .dockerignore, requirements.txt          │
│       ↓                                                         │
│  Adım 3: DOCKER COMPOSE                                        │
│  🏪 Küçük bir restoran açıyorsunuz (mutfak + salon bir arada)   │
│  Dosyalar: docker-compose.yml, .env                             │
│       ↓                                                         │
│  Adım 4: KUBERNETES                                             │
│  🏢 Restoran zinciri kuruyorsunuz (franchise yönetimi)           │
│  Dosyalar: k8s/, helm/                                          │
│       ↓                                                         │
│  Adım 5: JENKINS CI/CD                                         │
│  🤖 Robot şef: Tarif değişince tüm şubeleri otomatik günceller  │
│  Dosyalar: Jenkinsfile, scripts/                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Adım 1: Uygulama Katmanı

### 🧠 Temel Kavramlar

#### Flask Nedir?
**Flask**, Python programlama diliyle yazılmış bir **web çatısıdır (framework)**. Web sitesi yapmak için gereken temel araçları sağlar.

**Gerçek Hayat Analojisi:** Flask bir **mutfak tezgahıdır**. Tezgahın kendisi yemek yapmaz ama üzerinde her şeyi hazırlayabilirsiniz. Django gibi başka frameworkler ise hazır mutfak robotlarıdır — çok şey yapar ama karmaşıktır. Flask minimal ve esnektir.

#### MongoDB Nedir?
**MongoDB**, verileri saklayan bir **veritabanıdır**. Klasik veritabanları (MySQL, PostgreSQL) verileri Excel tablosu gibi satır ve sütunlarla saklar. MongoDB ise **JSON formatında belge (document)** olarak saklar.

**Gerçek Hayat Analojisi:** 
- SQL veritabanı = **Excel tablosu** (sabit sütunlar, her satır aynı formatta)
- MongoDB = **Dosya dolabı** (her dosya farklı bilgiler içerebilir, esnek yapı)

Bir görev (task) MongoDB'de şöyle saklanır:
```json
{
    "id": 0,
    "title": "Raporu hazırla",
    "shortdesc": "Haftalık satış raporu",
    "priority": 1
}
```

### 📁 Dosyalar ve Rolleri

#### [run.py](file:///c:/Users/Fatmanur/flask-mongodb/run.py) — Uygulamanın Orijinal Hali
Bu, projenin **başlangıç noktası**. Sadece kendi bilgisayarınızda çalışır (`python run.py` ile). Önemli satırları:

```python
app = Flask(__name__)                     # Flask uygulaması oluştur
client = MongoClient('localhost:27017')   # MongoDB'ye bağlan
db = client.TaskManager                   # "TaskManager" veritabanını seç
```

> [!WARNING]
> `localhost:27017` ifadesi "kendi bilgisayarımdaki 27017 numaralı porttan bağlan" demektir. Bu sadece MongoDB sizin bilgisayarınızda çalışırken işe yarar. Docker ortamında **çalışmaz** (çünkü her container izole bir bilgisayar gibidir).

#### [classes.py](file:///c:/Users/Fatmanur/flask-mongodb/classes.py) — Form Tanımları
Web sayfasındaki formları (metin kutuları, butonlar) tanımlar:

```python
class CreateTask(FlaskForm):
    title = StringField('Task Title')        # Başlık metin kutusu
    shortdesc = StringField('Short Description')  # Açıklama metin kutusu
    priority = IntegerField('Priority')      # Öncelik sayı kutusu
    create = SubmitField('Create')           # "Oluştur" butonu
```

**FlaskForm** = Flask-WTF kütüphanesinden gelen form sınıfı. Hem HTML formunu otomatik oluşturur, hem de **CSRF koruması** sağlar.

> [!NOTE]
> **CSRF (Cross-Site Request Forgery)** Nedir?
> Bir saldırganın sizin adınıza sahte form göndermesini engelleyen güvenlik mekanizmasıdır. Flask-WTF her forma gizli bir token (şifre) ekler. Form gönderildiğinde bu token kontrol edilir. Token yoksa veya yanlışsa → "Bu formu sen göndermedin!" deyip reddeder.

#### [home.html](file:///c:/Users/Fatmanur/flask-mongodb/app/templates/home.html) — Kullanıcı Arayüzü
Kullanıcının tarayıcıda gördüğü sayfa. **Jinja2** şablon motoru ile Python verileri HTML'e gömülür:

```html
{% for i in data %}
    ID = {{ i["id"] }}
    Title = {{ i["title"] }}
{% endfor %}
```

`{{ ... }}` = Python'dan gelen değişkeni buraya yaz.
`{% ... %}` = Python mantığı (döngü, koşul) çalıştır.

---

## 5. Adım 2: Docker ile Konteynerleştirme

### 🧠 Docker Nedir?

**Gerçek Hayat Analojisi:** Bir yemeğin tarifini düşünün. Siz evinizde güzel bir pasta yaptınız. Arkadaşınıza tarifi verdiniz ama o farklı fırın kullanıyor, farklı un markası alıyor ve pasta aynı çıkmıyor.

**Docker = Pastayı, fırınıyla ve malzemeleriyle birlikte paketleyip göndermek.**

Docker, uygulamanızı çalışması için gereken **her şeyle birlikte** (işletim sistemi, kütüphaneler, ayarlar) bir **konteyner (container)** içine paketler. Bu konteyner nereye götürülürse götürülsün **aynı şekilde çalışır**.

#### Temel Docker Terimleri

| Terim | Gerçek Hayat Karşılığı | Açıklama |
|-------|----------------------|----------|
| **Image (İmaj)** | Bir yemeğin tarifi/kalıbı | Uygulamanın "şablonu". Tek başına çalışmaz, ondan container üretilir |
| **Container** | Tarifle yapılmış yemek | Image'dan oluşturulan çalışan uygulama. Birden fazla container aynı image'dan oluşturulabilir |
| **Dockerfile** | Tarif kitabı | Image'ın nasıl oluşturulacağını adım adım anlatan dosya |
| **Registry** | Yemek tarifi paylaşım sitesi | Image'ların saklandığı uzak depo (Docker Hub, AWS ECR) |
| **Volume** | Buzdolabı | Container silinse bile verilerin kaybolmamasını sağlayan kalıcı depolama |

### 📁 Dosyalar ve Rolleri

#### [Dockerfile](file:///c:/Users/Fatmanur/flask-mongodb/app/Dockerfile) — Uygulama Tarif Kitabı

Bu dosya **Multi-Stage Build** kullanır. İki aşamalı bir yapıdır:

```
┌─────────────────────────────────────────────────────┐
│ STAGE 1: BUILDER (Aşçı Mutfağı)                    │
│                                                     │
│  FROM python:3.11-slim AS builder                   │
│  ├── requirements.txt kopyala                       │
│  └── pip install ile kütüphaneleri kur              │
│       (Flask, pymongo, gunicorn vb.)                │
│                                                     │
│  ⚠️ Bu aşamada gcc, make gibi derleme              │
│     araçları da yüklenir (boyut: ~400MB)            │
└──────────────────┬──────────────────────────────────┘
                   │ Sadece kurulu kütüphaneleri kopyala
                   ▼
┌─────────────────────────────────────────────────────┐
│ STAGE 2: RUNTIME (Servis Alanı)                     │
│                                                     │
│  FROM python:3.11-slim AS runtime                   │
│  ├── Non-root user oluştur (güvenlik)               │
│  ├── Builder'dan sadece kütüphaneleri al            │
│  ├── Uygulama kodlarını kopyala                     │
│  └── Gunicorn ile çalıştır                          │
│                                                     │
│  ✅ Derleme araçları YOK (boyut: ~140MB)            │
│  ✅ Saldırı yüzeyi minimal                          │
└─────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Neden Multi-Stage Build?**
> Bir pasta yaparken mutfak tezgahı, mikser, tartı kullanırsınız. Ama pastayı servis ederken bunları masaya koymaz, sadece pastayı koyarsınız. Multi-stage build de aynı mantık: Derleme (build) için gereken ağır araçlar son ürüne dahil edilmez. Bu sayede image boyutu **~400MB yerine ~140MB** olur.

#### Dockerfile'daki Kritik Kavramlar:

**1. `python:3.11-slim` nedir?**
Python'un resmi Docker image'ı. `slim` = gereksiz paketlerin çıkarıldığı hafif versiyon. Alpine (~50MB) daha küçük ama bazı Python kütüphaneleriyle uyumsuzluk yaşatabilir.

**2. Non-root user neden önemli?**
```dockerfile
RUN groupadd --system appgroup && \
    useradd --system --no-create-home --gid appgroup appuser
USER appuser
```
Container'lar varsayılan olarak `root` (yönetici) kullanıcısıyla çalışır. Eğer bir saldırgan container'a sızarsa root yetkisiyle sisteme zarar verebilir. Non-root user ile yetki minimuma indirilir.

**3. Gunicorn nedir?**
```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app.app:app"]
```
Flask'ın kendi sunucusu (development server) sadece geliştirme içindir — aynı anda tek bir isteği işler. **Gunicorn** ise production WSGI sunucusudur:
- 4 worker (işçi) = Aynı anda 4 istek işlenebilir
- `0.0.0.0` = Her yerden erişime açık (container dışından da)
- `app.app:app` = "app klasörü içindeki app.py dosyasındaki app nesnesi"

#### [.dockerignore](file:///c:/Users/Fatmanur/flask-mongodb/.dockerignore) — "Bunu Paketleme" Listesi
`.gitignore` gibi ama Docker için. Image'a girmemesi gereken dosyaları belirtir:

```
.venv          # Sanal ortam - container kendi Python'unu kullanır
.git           # Git geçmişi - gereksiz ağırlık
.env           # Şifreler - güvenlik riski!
__pycache__    # Python cache - gereksiz
```

> [!CAUTION]
> `.env` dosyası Docker image'ına **kesinlikle** dahil edilmemelidir! İçinde şifreler vardır. Image Docker Hub'a yüklenirse herkes şifrelerinizi görebilir. Şifreler `docker-compose.yml` üzerinden runtime'da enjekte edilir.

#### [requirements.txt (app/)](file:///c:/Users/Fatmanur/flask-mongodb/app/requirements.txt) — Bağımlılık Listesi
Uygulamanın çalışması için gereken Python kütüphaneleri:

```
Flask==3.1.1        # Web framework
Flask-WTF==1.2.2    # Form yönetimi + CSRF koruması
pymongo==4.11.3     # MongoDB Python sürücüsü
gunicorn==23.0.0    # Production web sunucusu
```

> [!TIP]
> **Versiyon pinleme** (`==3.1.1`) kritiktir. `Flask` yazarsanız her build'de farklı versiyon gelebilir ve uygulamanız bozulabilir. `Flask==3.1.1` yazarsanız her zaman aynı versiyonu indirir.

---

## 6. Adım 3: Docker Compose ile Orkestrasyon

### 🧠 Docker Compose Nedir?

Uygulamanız iki parçadan oluşuyor: Flask (web) + MongoDB (veritabanı). Her birini ayrı ayrı `docker run` ile başlatmak, aralarındaki ağ bağlantısını kurmak zahmetlidir.

**Docker Compose = Tek komutla tüm servisleri ayağa kaldıran orkestra şefi.**

```
docker compose up    →  Hem Flask hem MongoDB aynı anda başlar
docker compose down  →  Her şey durur
```

**Gerçek Hayat Analojisi:** Bir restoran açıyorsunuz. Mutfak (MongoDB) ve salon (Flask) ayrı bölümlerdir ama aynı binanın içindedir ve aralarında bir servis kapısı (network) vardır.

### 📁 Dosyalar ve Rolleri

#### [docker-compose.yml](file:///c:/Users/Fatmanur/flask-mongodb/docker-compose.yml) — Orkestra Partitürü

Bu dosya 3 ana bölümden oluşur:

**1. Services (Servisler) — Kim çalışacak?**
```yaml
services:
  app:          # Flask uygulaması
    build: ./app
    ports: ["5000:5000"]
    depends_on:
      mongodb:
        condition: service_healthy   # ← KRITIK!

  mongodb:      # Veritabanı
    image: mongo:7.0
    volumes:
      - mongodb-data:/data/db        # Kalıcı depolama
    healthcheck:
      test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping')"]
```

**2. Volumes (Kalıcı Depolama) — Veriler nerede saklanacak?**
```yaml
volumes:
  mongodb-data:
    driver: local
```

**3. Networks (Ağ) — Servisler birbirini nasıl bulacak?**
```yaml
networks:
  app-network:
    driver: bridge
```

#### Kritik Kavramlar:

**`depends_on` + `condition: service_healthy`**
```
Sorun: Flask başlar → MongoDB henüz hazır değil → Flask çöker!
Çözüm: MongoDB "Ben hazırım!" diyene kadar Flask'ı BAŞLATMA.

Healthcheck: Her 10 saniyede "MongoDB, yaşıyor musun?" diye sorar.
MongoDB "Evet!" deyince Flask başlatılır.
```

**`volumes: mongodb-data:/data/db`**
```
Sorun: Container silinince içindeki tüm veri kaybolur!
Çözüm: Volume = harici disk. Container ölse bile veriler volume'da kalır.

docker compose down     → Veriler KORUNUR ✅
docker compose down -v  → Veriler SİLİNİR ❌ (dikkat!)
```

**Docker DNS — Servisler Birbirini Nasıl Bulur?**
```
Flask kodu: MONGO_HOST = 'mongodb'
Docker DNS: "mongodb" → 172.18.0.3 (MongoDB container'ının IP'si)

Böylece IP adresi yazmaya gerek yok!
Container yeniden başlasa bile Docker DNS otomatik güncellenir.
```

#### [.env](file:///c:/Users/Fatmanur/flask-mongodb/.env) — Gizli Ayarlar Dosyası

```bash
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=securepassword123
MONGO_HOST=mongodb        # Docker servisi adı (localhost DEĞİL!)
FLASK_SECRET_KEY=your-super-secret-key
FLASK_DEBUG=0              # Production'da debug KAPALI!
```

> [!CAUTION]
> Bu dosya **Git'e ASLA gönderilmemelidir**! `.gitignore`'a eklenmeli. Production'da şifreler **HashiCorp Vault**, **AWS Secrets Manager** veya **Kubernetes Secrets** ile yönetilir.

#### [app/app.py](file:///c:/Users/Fatmanur/flask-mongodb/app/app.py) — Production Versiyonu

`run.py`'nin Docker ortamına uyarlanmış hali. Temel farklar:

| Özellik | run.py (Development) | app/app.py (Production) |
|---------|---------------------|------------------------|
| MongoDB adresi | `localhost:27017` | `os.environ.get('MONGO_HOST')` |
| Şifreler | Kodda yazılı | Environment variable'lardan |
| Hata yönetimi | Yok | Retry mekanizması (5 deneme) |
| Health check | Yok | `/health` endpoint'i |
| Sunucu | Flask dev server | Gunicorn |

**Retry (Yeniden Deneme) Mekanizması:**
```python
def connect_to_mongo(max_retries=5, retry_delay=3):
    for attempt in range(1, max_retries + 1):
        try:
            client = MongoClient(MONGO_URI)
            client.admin.command('ping')     # "MongoDB, yaşıyor musun?"
            return client[MONGO_DB]
        except ConnectionFailure:
            time.sleep(retry_delay)          # 3 saniye bekle, tekrar dene
```

> **Neden?** Ağ geçici olarak kesilebilir, MongoDB yeniden başlatılabilir. Hemen hata vermek yerine birkaç kez daha denemek production'da kritiktir.

---

## 7. Adım 4: Kubernetes ile Ölçekleme ve Yönetim

### 🧠 Kubernetes (K8s) Nedir?

Docker Compose tek bir bilgisayarda güzel çalışır. Ama ya uygulamanıza günde 1 milyon kişi girerse? Tek bilgisayar yetmez!

**Kubernetes = Binlerce container'ı yöneten devasa bir fabrika müdürü.**

**Gerçek Hayat Analojisi:**
- Docker Compose = **Tek bir restoran** (1 şef, 1 garson)
- Kubernetes = **Restoran zinciri yönetimi** (McDonald's gibi)
  - Hangi şubede kaç şef çalışacak? → **Replica sayısı**
  - Bir şef hastalanırsa yerine yenisi gelsin → **Self-healing**
  - Bayramda daha fazla şef çalışsın → **Auto-scaling**
  - Menü değişince tüm şubelere dağıtılsın → **Rolling update**

#### Temel Kubernetes Terimleri

```
┌────────────────────────────────────────────────────────────────┐
│ KUBERNETES MİMARİSİ                                            │
│                                                                │
│  Cluster (Küme) = Tüm fabrika                                 │
│  ├── Node (Düğüm) = Bir fabrika binası (fiziksel/sanal makine)│
│  │   ├── Pod = En küçük çalışma birimi (1+ container içerir)  │
│  │   │   └── Container = Çalışan uygulama                     │
│  │   └── Pod                                                   │
│  └── Node                                                      │
│                                                                │
│  Deployment = "2 adet Flask pod'u çalışsın" talimatı          │
│  Service = "Bu pod'lara şu kapıdan ulaşılsın" yönlendirmesi   │
│  ConfigMap = Hassas olmayan ayarlar (veritabanı adı gibi)      │
│  Secret = Hassas ayarlar (şifreler) — base64 ile şifreli      │
│  PVC = Kalıcı disk talebi (MongoDB verisi için)               │
│  Namespace = İzole çalışma alanı ("flask-mongodb" odası)       │
└────────────────────────────────────────────────────────────────┘
```

#### Minikube Nedir?
Gerçek Kubernetes kümesi (cluster) için birden fazla sunucu gerekir. **Minikube** ise kendi bilgisayarınızda tek düğümlü (single-node) bir Kubernetes kümesi çalıştırır — geliştirme ve öğrenme amaçlı.

### Helm — Kubernetes'in Paket Yöneticisi

```
pip install flask    →  Python'a Flask kur
helm install flask-app ./helm/flask-mongodb  →  Kubernetes'e uygulamayı kur
```

Kubernetes'te bir uygulamayı kurmak için 5-10 adet YAML dosyası gerekir. **Helm**, bunları tek bir paket (chart) haline getirir ve **şablonlarla** (templates) parametrik hale getirir.

### 📁 Dosyalar ve Rolleri

#### Helm Chart Yapısı

```
helm/flask-mongodb/
├── Chart.yaml          ← Chart kimlik kartı (isim, versiyon)
├── values.yaml         ← Ayarlanabilir değerler (düğmeler)
└── templates/          ← Kubernetes YAML şablonları
    ├── _helpers.tpl         ← Yardımcı fonksiyonlar
    ├── namespace.yaml       ← İzole çalışma alanı
    ├── secret.yaml          ← Şifreler (base64)
    ├── configmap.yaml       ← Ayarlar
    ├── flask-deployment.yaml    ← Flask pod yönetimi
    ├── flask-service.yaml       ← Flask'a dışarıdan erişim
    ├── mongodb-deployment.yaml  ← MongoDB pod yönetimi
    ├── mongodb-service.yaml     ← MongoDB'ye iç erişim
    └── mongodb-pvc.yaml         ← Kalıcı disk talebi
```

#### [values.yaml](file:///c:/Users/Fatmanur/flask-mongodb/helm/flask-mongodb/values.yaml) — Kontrol Paneli

Bu dosya, tüm ayarların merkezi. Farklı ortamlar için farklı değerler kullanılabilir:

```yaml
flask:
  replicas: 2              # Kaç tane Flask kopyası çalışsın?
  image:
    repository: fatmanurcepken/flask-app   # Docker Hub'daki imaj
    tag: "latest"                           # Hangi versiyon?
  resources:
    requests:
      memory: "128Mi"      # Minimum 128MB RAM garantisi
      cpu: "100m"          # Minimum %10 CPU garantisi
    limits:
      memory: "256Mi"      # Maksimum 256MB RAM (aşarsa öldürülür!)
      cpu: "500m"          # Maksimum %50 CPU

mongodb:
  replicas: 1              # Veritabanı her zaman TEK kopya
  image:
    repository: mongo
    tag: "7.0"
  persistence:
    size: "1Gi"            # 1GB kalıcı disk
```

> [!TIP]
> `helm install flask-app ./helm/flask-mongodb --set flask.replicas=5`
> Bu komutla values.yaml'ı değiştirmeden replica sayısını 5 yapabilirsiniz. Farklı ortamlar (dev, staging, production) için farklı değerler kullanılır.

#### [flask-deployment.yaml](file:///c:/Users/Fatmanur/flask-mongodb/helm/flask-mongodb/templates/flask-deployment.yaml) — Flask Pod Yönetimi

Önemli parçaları:

**1. initContainer — MongoDB'yi Bekle**
```yaml
initContainers:
  - name: wait-for-mongodb
    image: busybox:1.36
    command:
      - sh
      - -c
      - |
        until nc -z flask-app-mongodb-service 27017; do
          echo "MongoDB henüz hazır değil. 3 saniye bekleniyor..."
          sleep 3
        done
        echo "MongoDB hazır!"
```
Ana container başlamadan önce çalışır. MongoDB'ye bağlantı testi yapar. Başarılı olunca Flask pod'u başlar.

**2. Liveness & Readiness Probe — Sağlık Kontrolü**
```yaml
livenessProbe:        # "Yaşıyor mu?" → Ölmüşse yeniden başlat
  httpGet:
    path: /health
    port: 5000

readinessProbe:       # "Hazır mı?" → Hazır değilse trafik gönderme
  httpGet:
    path: /health
    port: 5000
```

**3. Rolling Update Stratejisi**
```yaml
strategy:
  type: RollingUpdate
  maxSurge: 1          # Güncelleme sırasında en fazla 1 EKSTRA pod
  maxUnavailable: 0    # Güncelleme sırasında HİÇ pod kapatılmasın
```
Bu sayede uygulama güncellenirken **zero-downtime** (sıfır kesinti) sağlanır. Eski pod'lar yeni pod'lar hazır olana kadar çalışmaya devam eder.

#### Service Tipleri

| Tip | Analoji | Açıklama |
|-----|---------|----------|
| **ClusterIP** | İç telefon hattı | Sadece cluster içinden erişilebilir (MongoDB için ideal) |
| **NodePort** | Dışa açık kapı | Dış dünyadan belirli bir port üzerinden erişilebilir (Flask için) |
| **LoadBalancer** | Resepsiyon masası | Cloud'da otomatik yük dengeleyici oluşturur |

---

## 8. Adım 5: Jenkins ile CI/CD Pipeline

### 🧠 CI/CD Nedir?

**CI (Continuous Integration) = Sürekli Entegrasyon**
Geliştirici kodu GitHub'a gönderdiğinde otomatik olarak test edilmesi.

**CD (Continuous Deployment) = Sürekli Dağıtım**
Testler başarılıysa otomatik olarak canlıya alınması.

**Gerçek Hayat Analojisi:**
```
GELENEKSEL YÖNTEM (Manuel):
Aşçı (Geliştirici) tarifi yazar → Kendisi test eder → Kendisi pişirir
→ Kendisi paketler → Kendisi teslim eder
⏱️ Saatler sürer, hata riski yüksek

CI/CD YÖNTEMI (Otomatik):
Aşçı tarifi yazar → Robot tarifi kontrol eder → Robot pişirir
→ Robot paketler → Robot teslim eder
⏱️ Dakikalar sürer, hata riski düşük
```

### Jenkins Nedir?
**Jenkins**, CI/CD süreçlerini otomatize eden açık kaynaklı bir araçtır. Bir "robot uşak" gibi düşünün: siz kodu gönderirsiniz, o gerisini halleder.

### 📁 Dosyalar ve Rolleri

#### [Jenkinsfile](file:///c:/Users/Fatmanur/flask-mongodb/Jenkinsfile) — Robot Uşağın Görev Listesi

Jenkinsfile, **pipeline'ı** (boru hattını) tanımlar. Her adım bir "stage" (aşama):

```
┌─────────────────────────────────────────────────────────────┐
│                    JENKINS PIPELINE                          │
│                                                             │
│  Stage 1: LINT / TEST                                       │
│  ┌─────────────────────────────────────────┐                │
│  │ flake8 app/ --exit-zero                 │                │
│  │ "Kodda yazım hatası var mı kontrol et"  │                │
│  └─────────────────┬───────────────────────┘                │
│                    ▼                                         │
│  Stage 2: BUILD DOCKER IMAGE                                │
│  ┌─────────────────────────────────────────┐                │
│  │ docker build -t fatmanurcepken/flask-app│                │
│  │ "Uygulamayı Docker paketine dönüştür"   │                │
│  └─────────────────┬───────────────────────┘                │
│                    ▼                                         │
│  Stage 3: PUSH TO DOCKER HUB                               │
│  ┌─────────────────────────────────────────┐                │
│  │ docker push fatmanurcepken/flask-app    │                │
│  │ "Paketi internetteki depoya yükle"      │                │
│  └─────────────────┬───────────────────────┘                │
│                    ▼                                         │
│  Stage 4: DEPLOY TO KUBERNETES                              │
│  ┌─────────────────────────────────────────┐                │
│  │ helm upgrade --install flask-app        │                │
│  │ "Yeni versiyonu canlıya al"             │                │
│  └─────────────────────────────────────────┘                │
│                                                             │
│  ✅ SUCCESS → "Harika! Deploy tamamlandı"                    │
│  ❌ FAILURE → "Lütfen logları kontrol edin"                  │
└─────────────────────────────────────────────────────────────┘
```

#### Jenkinsfile Detaylı Açıklama:

**Stage 1 — Lint (Kod Kalite Kontrolü):**
```groovy
sh 'flake8 app/ --exit-zero'
```
`flake8` = Python kod standartlarını kontrol eden araç. "Satır çok uzun", "kullanılmayan import var" gibi uyarılar verir. `--exit-zero` = Uyarı olsa bile pipeline'ı durdurmaz.

**Stage 2 — Docker Image Build:**
```groovy
env.COMMIT_SHA = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
sh "docker build -t fatmanurcepken/flask-app:${env.COMMIT_SHA} -f app/Dockerfile ."
```
Her Git commit'inin benzersiz kimliğini (SHA) alır ve bunu etiket (tag) olarak kullanır. Böylece hangi kod versiyonunun çalıştığı her zaman bilinir. (`a884536` gibi)

**Stage 3 — Docker Hub'a Gönderme:**
```groovy
withCredentials([usernamePassword(credentialsId: "docker-hub-credentials", ...)]) {
    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
    sh "docker push fatmanurcepken/flask-app:${env.COMMIT_SHA}"
}
```
Jenkins'in **Credentials** deposundan Docker Hub şifresini güvenli şekilde alır. Şifre log'larda `****` olarak maskelenir.

**Stage 4 — Kubernetes'e Deploy:**
```groovy
sh """
sed -i 's/127.0.0.1/host.docker.internal/g' /tmp/.kube/config
sed -i 's/certificate-authority-data:.*/insecure-skip-tls-verify: true/g' /tmp/.kube/config
helm upgrade --install flask-app ./helm/flask-mongodb --namespace flask-mongodb --create-namespace
"""
```
Jenkins container'ı, ana bilgisayardaki Minikube'e bağlanmak için kubeconfig dosyasındaki adresi düzenler. Sonra Helm ile uygulamayı Kubernetes'e kurar/günceller.

> [!NOTE]
> `host.docker.internal` = Docker container içinden ana bilgisayara (host) erişmek için kullanılan özel adres. Container'ın `localhost`'u kendi kendisini gösterir, host makinesini değil!

#### [setup-jenkins.ps1](file:///c:/Users/Fatmanur/flask-mongodb/scripts/setup-jenkins.ps1) — Jenkins Kurulum Scripti

Bu PowerShell scripti özel bir Jenkins Docker imajı oluşturur. Normal Jenkins'te Docker, kubectl ve Helm yoktur. Bu script:

1. **Özel Dockerfile oluşturur:** Jenkins + Docker CLI + kubectl + Helm + Python/flake8
2. **İmajı derler:** `docker build -t ci-jenkins`
3. **Container'ı başlatır:** Host Docker soketini ve kubeconfig'i bağlar

```
Jenkins Container İçi:
├── Jenkins         → CI/CD yönetimi
├── Docker CLI      → Image build/push
├── kubectl         → Kubernetes yönetimi
├── Helm            → Chart deploy
├── Python + flake8 → Kod kontrolü
└── Host bağlantıları:
    ├── /var/run/docker.sock  → Host Docker'ına erişim
    └── /var/jenkins_home/.kube → Kubernetes config
```

---

## 9. Proje Dosya Haritası

```
flask-mongodb/
│
├── 📄 run.py                    ← Orijinal uygulama (sadece lokal)
├── 📄 classes.py                ← Form tanımları (Flask-WTF)
├── 📄 requirements.txt          ← Temel Python bağımlılıkları
├── 📁 templates/                ← Orijinal HTML şablonları
│
├── 📁 app/                      ← 🐳 Docker için hazırlanmış uygulama
│   ├── 📄 app.py                ← Production-ready uygulama kodu
│   ├── 📄 classes.py            ← Form tanımları (kopyası)
│   ├── 📄 Dockerfile            ← Multi-stage build tarifi
│   ├── 📄 requirements.txt      ← Pinlenmiş bağımlılıklar + gunicorn
│   └── 📁 templates/
│       └── 📄 home.html         ← Kullanıcı arayüzü
│
├── 📄 docker-compose.yml        ← 🎼 Çoklu servis orkestrasyonu
├── 📄 .env                      ← 🔐 Gizli ayarlar (Git'e gitmez!)
├── 📄 .dockerignore             ← 🚫 Docker build'den hariç tutulanlar
│
├── 📁 k8s/                      ← ☸️ Ham Kubernetes YAML dosyaları
│   ├── 📄 namespace.yaml
│   ├── 📄 secret.yaml
│   ├── 📄 configmap.yaml
│   ├── 📁 flask-app/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── 📁 mongodb/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── pvc.yaml
│
├── 📁 helm/flask-mongodb/       ← ⎈ Helm Chart (parametrik K8s)
│   ├── 📄 Chart.yaml            ← Chart kimlik kartı
│   ├── 📄 values.yaml           ← Merkezi ayar dosyası
│   └── 📁 templates/            ← Go template ile dinamik YAML
│       ├── 📄 _helpers.tpl
│       ├── 📄 flask-deployment.yaml
│       ├── 📄 flask-service.yaml
│       ├── 📄 mongodb-deployment.yaml
│       ├── 📄 mongodb-service.yaml
│       ├── 📄 mongodb-pvc.yaml
│       ├── 📄 configmap.yaml
│       ├── 📄 secret.yaml
│       └── 📄 namespace.yaml
│
├── 📄 Jenkinsfile               ← 🤖 CI/CD pipeline tanımı
│
├── 📁 scripts/                  ← 🛠️ Otomasyon scriptleri
│   ├── 📄 setup-minikube.ps1    ← Minikube + K8s kurulumu
│   ├── 📄 setup-jenkins.ps1     ← Jenkins kurulumu
│   └── 📄 deploy-app.ps1       ← Uygulama deploy scripti
│
└── 📁 docs/                     ← 📚 Dokümantasyon
    └── 📄 kubernetes-setup.md
```

---

## 10. Mülakatta Sorulabilecek Sorular

### S: "Docker ile sanal makine (VM) arasındaki fark nedir?"

| Özellik | Sanal Makine (VM) | Docker Container |
|---------|-------------------|-----------------|
| Boyut | GB'larca (tam OS) | MB'larca (sadece uygulama) |
| Başlama süresi | Dakikalar | Saniyeler |
| İzolasyon | Tam (hypervisor) | Proses düzeyinde (kernel paylaşımı) |
| Kaynak kullanımı | Yüksek | Düşük |
| Analoji | Her daire için ayrı bina | Aynı binada ayrı daireler |

### S: "Neden `localhost` yerine servis adı kullanıyorsunuz?"
Docker'da her container izole bir "mini bilgisayar" gibidir. Container'ın `localhost`'u kendi kendisini gösterir, başka container'ları değil. Docker Compose'da servisler birbirini isimle bulur. `mongodb` yazdığımızda Docker DNS sistemi bunu otomatik olarak MongoDB container'ının IP adresine çevirir.

### S: "Health check neden önemli?"
Production'da yük dengeleyiciler (load balancer) veya Kubernetes, uygulamanın sağlıklı çalışıp çalışmadığını kontrol eder. Eğer yanıt alamazsa:
- **Liveness probe başarısız** → Pod'u öldürüp yenisini başlatır (self-healing)
- **Readiness probe başarısız** → O pod'a trafik göndermez

### S: "Helm neden var? Doğrudan kubectl apply kullanamaz mıyız?"
`kubectl apply` ile ham YAML dosyalarını uygulayabiliriz (k8s/ klasöründekiler). Ama Helm şu avantajları sağlar:
1. **Parametrizasyon:** `values.yaml` ile dev/staging/prod farklı ayarlar
2. **Tek komutla kurulum:** `helm install` tüm kaynakları oluşturur
3. **Sürüm yönetimi:** `helm rollback` ile önceki versiyona dönüş
4. **Şablon motoru:** Tekrarlanan YAML kodunu ortadan kaldırır

### S: "CI/CD pipeline'ınızda neler oluyor?"
1. **Lint:** flake8 ile Python kod kalite kontrolü
2. **Build:** Dockerfile ile Docker image oluşturma (commit SHA ile etiketleme)
3. **Push:** Image'ı Docker Hub'a güvenli şekilde gönderme (credentials maskeleme)
4. **Deploy:** Helm ile Kubernetes'e rolling update (sıfır kesinti)

### S: "Multi-stage build nedir ve neden kullanıyorsunuz?"
Dockerfile'da iki aşama var:
- **Builder aşaması:** Kütüphaneleri derler (gcc, make gibi araçlarla)
- **Runtime aşaması:** Sadece derlenmiş kütüphaneleri ve uygulama kodunu alır

Sonuç: Derleme araçları son image'da yer almaz → **Daha küçük image** (~140MB vs ~400MB) + **Daha güvenli** (saldırı yüzeyi azalır).

### S: "Rolling Update nedir?"
Uygulamanın yeni versiyonunu canlıya alırken **hiç kesinti yaşatmadan** güncelleme yapmaktır:
1. Yeni pod başlatılır (eski pod'lar çalışmaya devam eder)
2. Yeni pod sağlık kontrolünü geçer
3. Trafik yeni pod'a yönlendirilir
4. Eski pod kapatılır

`maxSurge: 1` = En fazla 1 ekstra pod oluşturulabilir
`maxUnavailable: 0` = Güncelleme sırasında hiçbir pod kapanmaz

### S: "Neden non-root user kullanıyorsunuz?"
Güvenlik prensibi: **En az yetki ilkesi (Principle of Least Privilege)**. Root ile çalışan bir container hack'lenirse saldırgan host sisteme erişebilir. Non-root user ile yetki sınırlandırılır.

### S: "`k8s/` ve `helm/` klasörlerinin farkı ne?"
- `k8s/` = **Düz YAML dosyaları.** Her ortam için ayrı dosya gerekir.
- `helm/` = **Şablonlu (template) YAML dosyaları.** Tek bir chart, farklı `values.yaml` dosyalarıyla her ortama uyarlanabilir. Production'da Helm tercih edilir.

---

## 11. Özet

| Teknoloji | Bir Cümlede | Projedeki Karşılığı |
|-----------|------------|---------------------|
| **Flask** | Python web framework'ü | Görev yöneticisi uygulaması |
| **MongoDB** | NoSQL veritabanı | Görevlerin saklandığı yer |
| **Docker** | Uygulama paketleme aracı | Dockerfile ile image oluşturma |
| **Docker Compose** | Çoklu container yöneticisi | Flask + MongoDB'yi birlikte çalıştırma |
| **Kubernetes** | Container orkestrasyon platformu | Ölçekleme, self-healing, zero-downtime |
| **Minikube** | Lokal Kubernetes kümesi | Geliştirme ortamında K8s simülasyonu |
| **Helm** | Kubernetes paket yöneticisi | Parametrik deployment |
| **Jenkins** | CI/CD otomasyon aracı | Kod → Test → Build → Push → Deploy |
| **Gunicorn** | Production Python web sunucusu | Flask'ı production'da çalıştırma |
| **flake8** | Python kod kalite aracı | Kod standartları kontrolü |

---

> [!IMPORTANT]
> **Mülakatınızda bu projeyi anlatırken şu akışı takip edin:**
> 1. "Bu bir Task Manager uygulaması ama asıl değeri **DevOps altyapısı**."
> 2. Basit bir `run.py`'den başlayıp → Docker → Docker Compose → Kubernetes → CI/CD'ye **evrimleştirdim.**
> 3. Her adımda production best practice'leri uyguladım: Multi-stage build, non-root user, health checks, secrets management, rolling updates, vb.
> 4. Sonuç: **Tek bir Git push ile kod otomatik olarak test edilir, paketlenir ve canlıya alınır.**
