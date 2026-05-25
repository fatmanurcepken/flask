# 🚀 Flask Task Manager — Production-Grade DevOps Pipeline

> Basit bir CRUD Task Manager uygulamasını temel alarak, yerel geliştirmeden başlayıp Kubernetes deployment'ı ve CI/CD süreçlerine kadar **tamamen otomatize edilmiş, production-ready bir DevOps pipeline'ı** inşa ettiğim uçtan uca proje çalışmam.

---

## 📖 İçindekiler
1. [Proje Özeti](#1-proje-özeti)
2. [Kullandığım Teknolojiler](#2-kullandığım-teknolojiler)
3. [Kurulum](#3-kurulum)
4. [Nasıl Çalıştırılır?](#4-nasıl-çalıştırılır)
5. [API Uç Noktaları](#5-api-uç-noktaları)
6. [Mimari](#6-mimari)
7. [Tasarım Kararları](#7-tasarım-kararları)


---

## 1. Proje Özeti

Bu projede, temel bir görev yöneticisi olan `flask-mongodb` reposunu alarak etrafında eksiksiz bir DevOps ekosistemi tasarladım. 

Amacım, yerel ortamda çalışan basit bir uygulamanın production-grade standartlara getirilerek otomatik deploy edilen ve ölçeklenebilir bir sisteme nasıl dönüştürüldüğünü göstermektir. 

**Uygulamayı Production Ortamına Hazırlarken Neler Yaptım?**
Orijinal kodlar doğrudan canlı ortama çıkmaya uygun değildi, bu nedenle uygulamada çeşitli iyileştirmeler gerçekleştirdim:
- **Konfigürasyon Yönetimi:** Kod içine yazılmış olan veritabanı bağlantı bilgilerini ve gizli anahtarları dışarı çıkardım.
- **Güvenlik:** Şifreleri `.env` ve Kubernetes Secret nesneleri aracılığıyla yönetilebilir hale getirdim.
- **Hata Yönetimi ve Dayanıklılık:** Veritabanına bağlantı başarısızlıklarına karşı 5 tekrarlı bir `retry` mekanizması ekledim.
- **Health Check:** Kubernetes ve Docker süreçlerinin uygulamanın sağlığını denetleyebilmesi için `/health` uç noktasını oluşturdum.
- **Production Sunucusu:** Flask'ın varsayılan geliştirme sunucusu yerine, eşzamanlı istekleri yönetebilmesi için 4 worker ile çalışan **Gunicorn** entegrasyonu sağladım.

---

## 2. Kullandığım Teknolojiler

Süreci tasarlarken kullandığım ana teknolojiler şunlardır:

- **Uygulama Katmanı:** Python 3.11, Flask 3.1.1, Gunicorn, MongoDB 7.0
- **Konteyner & Orkestrasyon:** Docker, Docker Compose, Kubernetes, Helm
- **CI/CD & Otomasyon:** Jenkins, PowerShell Scripting, Git
- **Kod Kalitesi:** Flake8

![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-3.1.1-lightgrey?logo=flask)
![MongoDB](https://img.shields.io/badge/MongoDB-7.0-green?logo=mongodb&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Minikube-326CE5?logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-Chart-0F1689?logo=helm&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins&logoColor=white)

---

## 3. Kurulum

### Ön Gereksinimler
Projeyi yerel ortamınızda test edebilmeniz için aşağıdaki araçların kurulu olması gerekmektedir:

| Araç | Minimum Versiyon | Kullanım Amacı |
|------|----------|------|
| Docker Desktop | 20.10+ | Konteynerleri çalıştırmak için |
| Minikube | 1.30+ | Yerel K8s kümesini ayağa kaldırmak için |
| kubectl | 1.20+ | Kubernetes ile iletişim kurmak için |
| Helm | 3.0+ | Paket yönetimi ve deployment için |
| Git | 2.0+ | Versiyon kontrolü |

> **Not:** Eğer Minikube ve kubectl sisteminizde kurulu değilse, projeye dahil ettiğim otomasyon scriptleri bu araçların kurulumunu otomatik olarak gerçekleştirmektedir.

### Proje Dosya Ağacı
Projenin dizin yapısını, inceleyenler için anlaşılır ve modüler olacak şekilde organize ettim:

```text
flask-mongodb/
│── app/                            # Uygulama kodları ve multi-stage Dockerfile
│   ├── app.py                      # Production-ready Flask
│   ├── Dockerfile                  # Optimizasyonlu multi-stage build dosyası
│   └── requirements.txt            # Sabitlenmiş bağımlılıklar
│
├── docker-compose.yml              # Yerel testler için orkestrasyon dosyası
├── .env                            # Ortam değişkenleri ve yapılandırmalar
├── .dockerignore                   # Build sürecinden dışlanan dosyalar
│
├── k8s/                            # Temel Kubernetes manifestleri
│   ├── namespace.yaml, secret.yaml, configmap.yaml
│   └── deployment ve service yaml dosyaları
│
├── helm/flask-mongodb/             # Esnek deployment için tasarladığım Helm Chart
│   ├── values.yaml                 # Dinamik parametre yönetimi
│   └── templates/                  # K8s şablonları
│
├── Jenkinsfile                     # CI/CD pipeline tanımı
│
└── scripts/                        # Kurulum ve deploy otomasyon betikleri
    ├── setup-minikube.ps1          # K8s ortamını hazırlar
    ├── setup-jenkins.ps1           # Gerekli araçları içeren Jenkins'i başlatır
    └── deploy-app.ps1              # K8s'e manuel deploy işlemini yapar
```

---

## 4. Nasıl Çalıştırılır?

### Seçenek 1: Docker Compose ile Hızlı Başlangıç

Kubernetes kullanmadan projeyi hızlıca yerel ortamda çalıştırmak isterseniz:

```bash
# 1. Repoyu klonlayın
git clone https://github.com/fatmanurcepken/flask.git
cd flask

# 2. Servisleri başlatın
docker compose up -d

# 3. Uygulamaya erişin
# -> http://localhost:5000
```
Kapatmak için `docker compose down` komutunu kullanabilirsiniz. Veritabanını da silmek isterseniz komuta `-v` parametresini ekleyebilirsiniz.

### Seçenek 2: Kubernetes Üzerinde Çalıştırma

Hazırladığım otomasyon scriptini kullanarak tüm K8s ortamını tek komutla kurabilir ve uygulamayı deploy edebilirsiniz:
```powershell
.\scripts\setup-minikube.ps1

# Uygulamaya erişmek için:
minikube service flask-app-flask-service -n flask-mongodb
```

Ortamı manuel olarak kurmak isterseniz aşağıdaki adımları izlenebili:
```bash
minikube start --driver=docker --memory=4096 --cpus=2
helm upgrade --install flask-app ./helm/flask-mongodb -n flask-mongodb --create-namespace
minikube service flask-app-flask-service -n flask-mongodb
```

---

## 5. API Uç Noktaları

Uygulama Jinja2 şablonları ile Server-Side Rendered olarak çalışmaktadır. Temel HTTP endpoint yapısı şu şekildedir:

| Metot | Endpoint | İşlev |
|-------|----------|-------------|
| `GET` | `/` veya `/tasks` | Tüm görevleri veritabanından çeker ve listeler. |
| `POST` | `/add` | Yeni bir görev oluşturur ve MongoDB'ye kaydeder. |
| `POST` | `/update/<id>` | İlgili görevin tamamlanma durumunu günceller. |
| `POST` | `/delete/<id>` | Seçilen görevi veritabanından siler. |
| `GET` | `/health` | **Yeni eklenen uç nokta.** K8s probe'ları için veritabanı bağlantısını kontrol edip sistemin sağlık durumunu döner. |

---

## 6. Mimari

### CI/CD Pipeline Akışı

Uygulamanın kaynak koddan canlı ortama ulaşma süreci şu şekildedir:
```text
 Kodu Yaz -> Lint -> Build -> Push -> Deploy
  │          │         │        │        │
   │          │         │        │        └── Helm ile Kubernetes Deploy
  │          │         │        └── Docker Hub'a Gönderim
  │          │         └── Multi-stage Docker Build
   │          └── flake8 ile Kod Analizi
  └── Flask + MongoDB Uygulaması
```

### Uygulama ve Kubernetes Mimarisi

```text
┌──────────────┐         ┌──────────────┐
│   Tarayıcı   │  HTTP   │    Flask     │
│              │────────▶│   Gunicorn   │
│              │  :5000  │  4 worker    │
└──────────────┘         └──────┬───────┘
                                │ pymongo
                         ┌──────▼───────┐
                         │   MongoDB    │
                         │    7.0       │
                         │  :27017      │
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │   Kalıcı     │
                         │   PVC Vol    │
                         └──────────────┘
```

### 6.1 Dockerization Detayları
Dockerfile tasarımında optimizasyon sağlamak amacıyla **Multi-stage build** yapısını kullandım.
- **Builder Stage:** Bağımlılıkların indirilip derlendiği aşama (~400MB)
- **Runtime Stage:** Yalnızca çalışan kodların ve kurulu kütüphanelerin alındığı son aşama (~140MB).
Ayrıca `.dockerignore` dosyasıyla build context boyutunu küçülttüm ve güvenlik sıkılaştırması amacıyla konteynerin `root` yerine kısıtlı yetkilere sahip `appuser` kullanıcısıyla çalışmasını sağladım.

Docker compose konfigürasyonunda ise, Flask servisinin stabil bir şekilde başlaması için yalnızca MongoDB'nin ayakta olmasını değil, `service_healthy` kuralıyla bağlantı kabul edecek duruma gelmesini şart koştum.

### 6.2 Kubernetes ve Helm Uygulamaları
Helm Chart tasarımında production standartlarını sağlamak için çeşitli özellikler entegre ettim:
- **Esneklik:** İmaj versiyonundan pod sayısına kadar tüm değerlerin `values.yaml` üzerinden yönetilebilmesini sağladım.
- **Init Container:** Flask pod'u başlarken önce init container devreye girerek MongoDB'nin hazır olmasını bekler, böylece bağlantı hatalarını önler.
- **Health Probes:** Pod'ların sağlığını sürekli izleyerek çökme durumunda K8s'in otomatik olarak pod'u yeniden başlatmasını sağladım.
- **Rolling Update:** Deployment stratejisinde `maxUnavailable: 0` değerini kullanarak yeni sürüm güncellemeleri sırasında sıfır kesinti olmasını garantiledim.
- **Resource Management:** Her pod için CPU ve bellek limitleri atayarak küme kaynaklarının güvenliğini sağladım.


### 6.3 CI/CD Pipeline
 `Jenkinsfile`, Git üzerinden tetiklendiğinde 4 aşamalı bir süreç çalıştırır:
1. **Lint:** `flake8` aracılığıyla kod standartlarını ve yazım hatalarını denetler.
2. **Build:** Multi-stage build işlemini gerçekleştirir ve oluşturulan imajı izlenebilirliği sağlamak adına Git Commit SHA'ı ile etiketler.
3. **Push:** Etiketlenen imajı Jenkins credential yöneticisinden aldığı gizli kimlik bilgileriyle güvenli bir şekilde Docker Hub' a gönderir.
4. **Deploy:** Hedef Kubernetes kümesinde Helm upgrade işlemini tetikleyerek yeni imajın dağıtımını yapar.

---

## 7. Tasarım Kararları

Projedeki teknik tercihleri yaparken odaklandığım noktalar şunlardır:

- **Flask Geliştirme Sunucusu Yerine Gunicorn:** Flask' ın varsayılan sunucusu tek thread üzerinde çalıştığı için production ortamı için uygun değildir. Bunun yerine uygulamayı 4 worker process ile çalışan Gunicorn arkasına konumlandırarak eşzamanlı trafik karşılama kapasitesini artırdım.
- **Alpine Yerine Python-Slim İmaj Tercihi:** Alpine tabanlı imajlar boyut olarak avantajlı olsa da `musl libc` kullanmaları nedeniyle `pymongo` gibi C uzantılı kütüphanelerin derlenmesinde sorunlara yol açabilmektedir. Bu nedenle `glibc` tabanlı, kararlı ve daha güvenilir olan `python:3.11-slim` imajını tercih ettim.
- **Ham K8s Yaml vs Helm:** Projede temel K8s manifestleri de var ama parametrik yapılandırma, sürüm yönetimi ve rollback gibi özellikler sunduğu için ana deployment yöntemi olarak Helm'i tercih ettim.
- **CI Aracı Olarak Jenkins:** GitLab CI veya GitHub Actions gibi daha modern ve kolay alternatifler bulunmasına rağmen, altyapı otomasyonu ve self-hosted bir CI/CD sunucusunun yönetimindeki yetkinliğimi göstermek amacıyla Jenkins'i tercih ettim.

---


