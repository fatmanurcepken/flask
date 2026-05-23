# Kubernetes Yerel Kurulum ve Dağıtım Rehberi

## Flask + MongoDB — Minikube ile Kubernetes Ortamı

---

## İçindekiler

1. [Ön Koşullar](#1-ön-koşullar)
2. [Minikube Kurulumu](#2-minikube-kurulumu)
3. [Docker Image Build](#3-docker-image-build)
4. [YAML Manifesto ile Kurulum](#4-yaml-manifesto-ile-kurulum)
5. [Helm Chart ile Kurulum](#5-helm-chart-ile-kurulum)
6. [Uygulamaya Erişim](#6-uygulamaya-erişim)
7. [Faydalı Komutlar](#7-faydalı-komutlar)
8. [Sorun Giderme](#8-sorun-giderme)
9. [Mimari Özeti](#9-mimari-özeti)

---

## 1. Ön Koşullar

Aşağıdaki araçların kurulu olduğundan emin olun:

| Araç | Sürüm | Kurulum |
|------|-------|---------|
| Docker Desktop | 4.x+ | [docker.com](https://www.docker.com/products/docker-desktop) |
| Minikube | 1.30+ | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |
| kubectl | 1.27+ | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Helm | 3.12+ | [helm.sh](https://helm.sh/docs/intro/install/) — (Helm Chart için) |

### Windows'ta Winget ile Hızlı Kurulum

```powershell
# Tümünü tek seferde kur
winget install Kubernetes.minikube Kubernetes.kubectl Helm.Helm
```

### Kurulum Doğrulama

```powershell
docker version
minikube version
kubectl version --client
helm version
```

---

## 2. Minikube Kurulumu

### 2.1 Otomatik Kurulum (Önerilen)

Projenin kök dizininden scripti çalıştırın:

```powershell
# Scripti çalıştırma izni ver
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Kurulum scriptini çalıştır
.\scripts\setup-minikube.ps1
```

### 2.2 Manuel Kurulum

#### Adım 1: Minikube'ü Başlat

```powershell
minikube start `
  --driver=docker `
  --memory=4096 `
  --cpus=2 `
  --kubernetes-version=stable `
  --addons=ingress
```

**Parametrelerin Anlamı:**

| Parametre | Değer | Açıklama |
|-----------|-------|----------|
| `--driver` | `docker` | Docker Desktop'ı VM motoru olarak kullanır |
| `--memory` | `4096` | Kubernetes cluster'ına ayrılan RAM (MB) |
| `--cpus` | `2` | CPU çekirdeği sayısı |
| `--kubernetes-version` | `stable` | Kararlı Kubernetes sürümü |
| `--addons=ingress` | — | NGINX Ingress Controller ekler |

#### Adım 2: Durumu Kontrol Et

```powershell
# Cluster durumu
minikube status

# Node durumu
kubectl get nodes

# Cluster bilgileri
kubectl cluster-info
```

Beklenen çıktı:
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

---

## 3. Docker Image Build

### Neden `minikube image build`?

Minikube, kendi içinde ayrı bir Docker daemon çalıştırır.  
`docker build` yaptığınızda image **host makinenize** oluşur, Minikube göremez.  
`minikube image build` ise image'ı **doğrudan Minikube'ün içine** yükler.

```powershell
# Projenin kök dizininde (flask-mongodb/) çalıştırın
minikube image build -t flask-app:latest ./app

# Image'ın yüklendiğini doğrula
minikube image ls | Select-String "flask-app"
```

> **Not:** Dockerfile'da her değişiklik sonrası bu komutu tekrar çalıştırın.

---

## 4. YAML Manifesto ile Kurulum

### Dosya Yapısı

```
k8s/
├── namespace.yaml          ← Namespace tanımı
├── secret.yaml             ← MongoDB şifresi, Flask secret key
├── configmap.yaml          ← Port, hostname, ortam ayarları
├── mongodb/
│   ├── pvc.yaml            ← Kalıcı depolama talebi (1Gi)
│   ├── deployment.yaml     ← MongoDB Pod tanımı
│   └── service.yaml        ← Cluster-içi erişim (ClusterIP)
└── flask-app/
    ├── deployment.yaml     ← Flask/Gunicorn Pod tanımı
    └── service.yaml        ← Dışarıdan erişim (NodePort:30500)
```

### Sıralı Uygulama

**Önemli:** Kaynakları sırayla oluşturun. Bağımlılıklar nedeniyle sıra önemlidir.

```powershell
# 1. Namespace (önce namespace oluşturulmalı)
kubectl apply -f k8s/namespace.yaml

# 2. Secret ve ConfigMap (Deployment'lardan önce olmalı)
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml

# 3. MongoDB kaynakları
kubectl apply -f k8s/mongodb/pvc.yaml
kubectl apply -f k8s/mongodb/deployment.yaml
kubectl apply -f k8s/mongodb/service.yaml

# 4. Flask uygulama kaynakları
kubectl apply -f k8s/flask-app/deployment.yaml
kubectl apply -f k8s/flask-app/service.yaml
```

### Tek Komutla Tüm Kaynaklar (Alternatif)

```powershell
# Tüm k8s/ dizinini recursive olarak uygula
kubectl apply -R -f k8s/
```

### Durumu Kontrol Et

```powershell
# Tüm kaynakları gör
kubectl get all -n flask-mongodb

# Pod'ların hazır olmasını bekle
kubectl wait --for=condition=Ready pod -l app=flask-app -n flask-mongodb --timeout=300s
kubectl wait --for=condition=Ready pod -l app=mongodb -n flask-mongodb --timeout=300s
```

---

## 5. Helm Chart ile Kurulum

### Helm Chart Nedir?

Helm, Kubernetes için "paket yöneticisi"dir. Tüm YAML dosyalarını parametrize  
ederek tek bir komutla kurulum yapmanızı sağlar.

```
helm/flask-mongodb/
├── Chart.yaml              ← Chart metadata (isim, sürüm)
├── values.yaml             ← Varsayılan değerler
└── templates/              ← Go template YAML dosyaları
    ├── _helpers.tpl        ← Yardımcı fonksiyonlar
    ├── namespace.yaml
    ├── secret.yaml
    ├── configmap.yaml
    ├── mongodb-pvc.yaml
    ├── mongodb-deployment.yaml
    ├── mongodb-service.yaml
    ├── flask-deployment.yaml
    └── flask-service.yaml
```

### 5.1 Template Önizleme (Dry Run)

Gerçekten uygulamadan önce oluşturulacak YAML'ı görmek için:

```powershell
helm template flask-app ./helm/flask-mongodb --debug
```

### 5.2 Chart Doğrulama (Lint)

```powershell
helm lint ./helm/flask-mongodb
```

### 5.3 Kurulum

```powershell
# Varsayılan değerlerle kur
helm install flask-app ./helm/flask-mongodb

# Namespace'i otomatik oluşturarak kur
helm install flask-app ./helm/flask-mongodb --create-namespace --namespace flask-mongodb
```

### 5.4 Özelleştirilmiş Kurulum

```powershell
# Komut satırından değer override et
helm install flask-app ./helm/flask-mongodb `
  --set secrets.mongoRootPassword="GucluSifre123!" `
  --set flask.replicas=3 `
  --set mongodb.persistence.size="5Gi"
```

### 5.5 Production Values Dosyası ile Kurulum

`production-values.yaml` dosyası oluşturun:

```yaml
flask:
  replicas: 3
  image:
    pullPolicy: Always
  resources:
    limits:
      memory: "512Mi"
      cpu: "1000m"

mongodb:
  persistence:
    size: "10Gi"

secrets:
  mongoRootPassword: "ÜretilmişGüçlüŞifre"
  flaskSecretKey: "ÜretilmişFlaskAnahtarı"
```

```powershell
helm install flask-app ./helm/flask-mongodb -f production-values.yaml
```

### 5.6 Güncelleme ve Kaldırma

```powershell
# Güncelleme (yeni image veya değer değişikliği)
helm upgrade flask-app ./helm/flask-mongodb

# Kurulu release'leri listele
helm list -A

# Release detayları
helm status flask-app

# Kaldırma (namespace ve PVC dahil değil)
helm uninstall flask-app
```

---

## 6. Uygulamaya Erişim

### YAML Manifesto ile

```powershell
# Tarayıcıda otomatik aç (NodePort:30500)
minikube service flask-app-service -n flask-mongodb

# URL'i al (tarayıcıda kendiniz açmak için)
minikube service flask-app-service -n flask-mongodb --url
```

### Helm Chart ile

```powershell
minikube service flask-app-flask-service -n flask-mongodb
```

### Minikube Dashboard

```powershell
minikube dashboard
```

Dashboard'da şunları görebilirsiniz:
- Pod'ların durumu (Running, Pending, CrashLoopBackOff)
- Log'lar
- Kaynak kullanımı (CPU/Memory)
- Deployment geçmişi

---

## 7. Faydalı Komutlar

### Pod Yönetimi

```powershell
# Tüm pod'ları listele
kubectl get pods -n flask-mongodb

# Pod detayları (event'lar ve durum)
kubectl describe pod <pod-adı> -n flask-mongodb

# Pod log'larını takip et
kubectl logs -f deployment/flask-app -n flask-mongodb

# Pod'a shell bağlantısı (debugging için)
kubectl exec -it <pod-adı> -n flask-mongodb -- /bin/bash
```

### Deployment Yönetimi

```powershell
# Deployment durumunu izle
kubectl rollout status deployment/flask-app -n flask-mongodb

# Önceki versiyona geri dön
kubectl rollout undo deployment/flask-app -n flask-mongodb

# Deployment'ı yeniden başlat (image pull yapmadan)
kubectl rollout restart deployment/flask-app -n flask-mongodb
```

### Kaynak Kullanımı

```powershell
# Pod'ların CPU/Memory kullanımı (metrics-server gerekli)
minikube addons enable metrics-server
kubectl top pods -n flask-mongodb
```

### Temizleme

```powershell
# Sadece kaynakları sil (namespace ve PVC dahil)
kubectl delete namespace flask-mongodb

# Minikube'ü durdur (sil değil, veriler korunur)
minikube stop

# Minikube'ü tamamen sil (tüm veriler silinir!)
minikube delete
```

---

## 8. Sorun Giderme

### Pod "Pending" durumunda kalıyor

```powershell
kubectl describe pod <pod-adı> -n flask-mongodb
```

**Olası nedenler:**
- Yetersiz kaynak (memory/CPU): `minikube start --memory=4096` ile daha fazla kaynak ver
- PVC oluşturulamıyor: `kubectl get pvc -n flask-mongodb` ile PVC durumunu kontrol et

### Pod "CrashLoopBackOff" hatası

```powershell
# Hata log'larını gör
kubectl logs <pod-adı> -n flask-mongodb --previous

# MongoDB bağlantı hatası ise:
# 1. MongoDB pod'unun çalıştığından emin ol
kubectl get pods -n flask-mongodb
# 2. Secret'taki şifrelerin doğru olduğunu kontrol et
kubectl get secret flask-mongodb-secret -n flask-mongodb -o jsonpath='{.data.MONGO_INITDB_ROOT_PASSWORD}' | base64 -d
```

### Image bulunamıyor ("ImagePullBackOff")

```powershell
# Image'ın Minikube'de olduğunu doğrula
minikube image ls | Select-String "flask-app"

# Image yoksa yeniden build et
minikube image build -t flask-app:latest ./app

# deployment.yaml'da imagePullPolicy: Never olduğundan emin ol
```

### MongoDB'ye bağlanılamıyor

```powershell
# MongoDB service'inin var olduğunu kontrol et
kubectl get service -n flask-mongodb

# MongoDB pod'unun Running durumda olduğunu kontrol et
kubectl get pods -n flask-mongodb -l app=mongodb

# initContainer log'larını gör
kubectl logs <flask-pod-adı> -c wait-for-mongodb -n flask-mongodb
```

---

## 9. Mimari Özeti

### Docker Compose → Kubernetes Karşılaştırması

| Docker Compose | Kubernetes | Açıklama |
|----------------|------------|----------|
| `services.app` | `Deployment` | Container tanımı |
| `services.mongodb` | `Deployment` | Container tanımı |
| `env_file: .env` | `Secret` + `ConfigMap` | Environment değişkenleri |
| `depends_on: service_healthy` | `initContainer` | Başlangıç sırası |
| `healthcheck` | `livenessProbe` + `readinessProbe` | Sağlık kontrolü |
| `volumes: mongodb-data` | `PVC` | Kalıcı depolama |
| `ports: "5000:5000"` | `NodePort Service` | Port erişimi |
| `networks: app-network` | Kubernetes DNS | Servis keşfi |
| `restart: always` | `restartPolicy` | Otomatik yeniden başlatma |

### Kubernetes Kaynak Hiyerarşisi

```
Namespace: flask-mongodb
│
├── Secret: flask-mongodb-secret
│   ├── MONGO_INITDB_ROOT_USERNAME
│   ├── MONGO_INITDB_ROOT_PASSWORD
│   └── FLASK_SECRET_KEY
│
├── ConfigMap: flask-mongodb-config
│   ├── MONGO_HOST
│   ├── MONGO_PORT
│   └── MONGO_DB_NAME
│
├── PersistentVolumeClaim: mongodb-pvc (1Gi)
│   └── PersistentVolume (Minikube tarafından otomatik oluşturulur)
│
├── Deployment: mongodb (1 replica)
│   └── Pod → Container: mongo:7.0
│       └── /data/db → PVC
│
├── Service: mongodb-service (ClusterIP:27017)
│
├── Deployment: flask-app (2 replica)
│   └── Pod → initContainer (wait-for-mongodb)
│           → Container: flask-app:latest
│
└── Service: flask-app-service (NodePort:30500)
```
