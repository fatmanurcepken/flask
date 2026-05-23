# =============================================================================
# setup-minikube.ps1 - Flask + MongoDB Kubernetes Ortami Kurulum Scripti
# =============================================================================
#
# KULLANIM:
#   PowerShell'de calistirmak icin:
#     .\scripts\setup-minikube.ps1
#
# ON KOSULLAR:
#   1. Docker Desktop kurulu ve calisiyor olmali
#   2. Internet baglantisi mevcut olmali
#
# BU SCRIPT NE YAPAR?
#   1. Gerekli araclarin kurulu olup olmadigini kontrol eder
#   2. Minikube'u Docker driver ile baslatir
#   3. Flask uygulama Docker image'ini Minikube'e yukler
#   4. Kubernetes namespace olusturur
#   5. Tum manifestolari uygular (YAML dosyalari)
#   6. Servislerin hazir olmasini bekler
#   7. Uygulamaya tarayicidan nasil erisilecegini gosterir
# =============================================================================

# Hata varsa scripti durdur
$ErrorActionPreference = "Stop"

# Renkli cikti icin yardimci fonksiyonlar
function Write-Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Step  { param($msg) Write-Host "`n========== $msg ==========" -ForegroundColor Magenta }

# =============================================================================
# ADIM 1: On Kosul Kontrolleri
# =============================================================================
Write-Step "On Kosul Kontrolleri"

# Docker kontrolu
Write-Info "Docker kontrol ediliyor..."
try {
    $dockerVersion = docker version --format "{{.Server.Version}}" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker daemon calismiyor" }
    Write-OK "Docker kurulu: v$dockerVersion"
} catch {
    Write-Fail "Docker kurulu degil veya Docker Desktop calismiyor!"
    Write-Warn "Lutfen Docker Desktop'i kurun: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Minikube kontrolu
Write-Info "Minikube kontrol ediliyor..."
$minikubeInstalled = Get-Command minikube -ErrorAction SilentlyContinue
if (-not $minikubeInstalled) {
    Write-Warn "Minikube bulunamadi. Winget ile kuruluyor..."
    try {
        winget install Kubernetes.minikube --silent --accept-package-agreements --accept-source-agreements
        Write-OK "Minikube basariyla kuruldu!"
        # PATH'i guncelle
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Fail "Minikube otomatik kurulamadi."
        Write-Warn "Manuel kurulum: https://minikube.sigs.k8s.io/docs/start/"
        exit 1
    }
} else {
    $minikubeVersion = (minikube version --short) -replace "minikube version: ", ""
    Write-OK "Minikube kurulu: $minikubeVersion"
}

# kubectl kontrolu
Write-Info "kubectl kontrol ediliyor..."
$kubectlInstalled = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $kubectlInstalled) {
    Write-Warn "kubectl bulunamadi. Winget ile kuruluyor..."
    try {
        winget install Kubernetes.kubectl --silent --accept-package-agreements --accept-source-agreements
        Write-OK "kubectl basariyla kuruldu!"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Fail "kubectl otomatik kurulamadi."
        Write-Warn "Manuel kurulum: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
        exit 1
    }
} else {
    $kubectlVersion = (kubectl version --client --output=json | ConvertFrom-Json).clientVersion.gitVersion
    Write-OK "kubectl kurulu: $kubectlVersion"
}

# =============================================================================
# ADIM 2: Minikube Baslatma
# =============================================================================
Write-Step "Minikube Baslatiliyor"

# Minikube durumunu kontrol et
$minikubeStatus = minikube status --format "{{.Host}}" 2>&1
if ($minikubeStatus -eq "Running") {
    Write-OK "Minikube zaten calisiyor. Atlaniyor..."
} else {
    Write-Info "Minikube baslatiliyor (driver: docker, memory: 4gb, cpus: 2)..."
    Write-Info "Bu islem ilk seferinde birkac dakika surebilir..."
    
    minikube start `
        --driver=docker `
        --memory=4096 `
        --cpus=2 `
        --kubernetes-version=stable `
        --addons=ingress

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Minikube baslatilamadi!"
        Write-Warn "Sorun giderme icin: minikube delete && minikube start --driver=docker"
        exit 1
    }
    Write-OK "Minikube basariyla baslatildi!"
}

# Cluster bilgilerini goster
Write-Info "Cluster bilgileri:"
kubectl cluster-info

# =============================================================================
# ADIM 3: Docker Image Build ve Minikube'e Yukleme
# =============================================================================
Write-Step "Docker Image Build"

Write-Info "Minikube Docker ortami yapilandiriliyor..."
Write-Info "Projenin kok dizininde (flask-mongodb/) oldugunuzdan emin olun."

Write-Info "Flask uygulama image'i build ediliyor..."
Write-Warn "NOT: Bu komut Minikube Docker ortaminda calisir."
Write-Warn "Lutfen su komutu ayri bir terminalde calistirin:"
Write-Host ""
Write-Host "  minikube image build -t flask-app:latest ./app" -ForegroundColor Yellow
Write-Host ""

$buildChoice = Read-Host "Image build tamamlandi mi? (E/H)"
if ($buildChoice -ne "E" -and $buildChoice -ne "e") {
    Write-Warn "Image build bekleniyor. Lutfen yukaridaki komutu calistirin ve scripti tekrar baslatin."
    exit 0
}

Write-OK "Image build tamamlandi!"

# =============================================================================
# ADIM 4: Kubernetes Manifestolarini Uygula
# =============================================================================
Write-Step "Kubernetes Manifestolari Uygulaniyor"

if (-not (Test-Path ".\k8s")) {
    Write-Fail "k8s/ dizini bulunamadi! Projenin kok dizininde oldugunuzdan emin olun."
    exit 1
}

Write-Info "Namespace olusturuluyor..."
kubectl apply -f .\k8s\namespace.yaml

Write-Info "Secret olusturuluyor..."
kubectl apply -f .\k8s\secret.yaml

Write-Info "ConfigMap olusturuluyor..."
kubectl apply -f .\k8s\configmap.yaml

Write-Info "MongoDB PersistentVolumeClaim olusturuluyor..."
kubectl apply -f .\k8s\mongodb\pvc.yaml

Write-Info "MongoDB Deployment ve Service olusturuluyor..."
kubectl apply -f .\k8s\mongodb\deployment.yaml
kubectl apply -f .\k8s\mongodb\service.yaml

Write-Info "Flask uygulama Deployment ve Service olusturuluyor..."
kubectl apply -f .\k8s\flask-app\deployment.yaml
kubectl apply -f .\k8s\flask-app\service.yaml

Write-OK "Tum kaynaklar olusturuldu!"

# =============================================================================
# ADIM 5: Servislerin Hazir Olmasini Bekle
# =============================================================================
Write-Step "Servisler Kontrol Ediliyor"

Write-Info "MongoDB deployment hazir olana kadar bekleniyor (max 3 dakika)..."
kubectl rollout status deployment/mongodb -n flask-mongodb --timeout=180s
if ($LASTEXITCODE -ne 0) {
    Write-Warn "MongoDB deployment zaman asimina ugradi."
    exit 1
}
Write-OK "MongoDB hazir!"

Write-Info "Flask deployment hazir olana kadar bekleniyor (max 3 dakika)..."
kubectl rollout status deployment/flask-app -n flask-mongodb --timeout=180s
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Flask deployment zaman asimina ugradi."
    exit 1
}
Write-OK "Flask uygulamasi hazir!"

# =============================================================================
# ADIM 6: Durum Ozeti
# =============================================================================
Write-Step "Kurulum Tamamlandi - Durum Ozeti"

Write-Info "Namespace icindeki tum kaynaklar:"
kubectl get all -n flask-mongodb

Write-Host ""
Write-Info "Uygulamaya erismek icin:"
Write-Host "  minikube service flask-app-service -n flask-mongodb" -ForegroundColor Green
Write-Host ""
Write-Info "Dashboard icin:"
Write-Host "  minikube dashboard" -ForegroundColor Green
Write-Host ""
Write-Info "Pod loglarini gormek icin:"
Write-Host "  kubectl logs -f deployment/flask-app -n flask-mongodb" -ForegroundColor Green
Write-Host ""
Write-OK "Kurulum basariyla tamamlandi!"
