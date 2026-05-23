<#
.SYNOPSIS
    Kurulum betiği - Docker üzerinde Jenkins çalıştırır ve CI/CD gereksinimlerini kurar.
.DESCRIPTION
    Bu betik, içinde Docker, Helm ve Kubectl yüklü özel bir Jenkins imajı derler 
    ve bu imajı container olarak çalıştırır. Yerel kubeconfig ve Docker soketini bağlar.
#>

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Jenkins CI/CD Kurulumu Başlıyor... " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Mevcut Jenkins container'ı varsa temizle
$existingJenkins = docker ps -a -q -f name=jenkins-server
if ($existingJenkins) {
    Write-Host "[*] Eski Jenkins container'ı durduruluyor ve siliniyor..." -ForegroundColor Yellow
    docker stop jenkins-server | Out-Null
    docker rm jenkins-server | Out-Null
}

# Özel Jenkins imajı için Dockerfile oluşturulması
$dockerfileContent = @"
FROM jenkins/jenkins:lts-jdk17
USER root

# Gerekli temel paketler ve Python kurulumu
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI kurulumu (Host'un docker daemon'una bağlanmak için)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Kubectl kurulumu
RUN curl -LO "https://dl.k8s.io/release/`$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Helm kurulumu
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm get_helm.sh

# Python için sanal ortam (venv) ve flake8 kurulumu
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:`$PATH"
RUN pip install --no-cache-dir flake8

# Docker soketine erişim için jenkins kullanıcısını root grubuna veya docker grubuna eklemek yerine 
# host docker'a erişimde yetki sorunu yaşamamak adına kullanıcı olarak jenkins'e dönüyoruz.
# (Not: Windows'ta Docker Desktop socket'ine erişim için bazen özel yetki gerekir.)
USER jenkins
"@

$dockerfilePath = "Dockerfile.jenkins"
Set-Content -Path $dockerfilePath -Value $dockerfileContent

Write-Host "[*] Özel Jenkins imajı (ci-jenkins) derleniyor. Bu işlem birkaç dakika sürebilir..." -ForegroundColor Cyan
docker build -t ci-jenkins -f $dockerfilePath .

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] İmaj derleme başarısız oldu." -ForegroundColor Red
    exit 1
}
Remove-Item $dockerfilePath

# Host kubeconfig dizinini belirle
$kubeconfigPath = "$env:USERPROFILE\.kube"

Write-Host "[*] Jenkins container'ı başlatılıyor..." -ForegroundColor Cyan
docker run -d `
    -p 8085:8080 `
    -p 50000:50000 `
    --name jenkins-server `
    -v jenkins_data:/var/jenkins_home `
    -v //var/run/docker.sock:/var/run/docker.sock `
    -v "${kubeconfigPath}:/var/jenkins_home/.kube:ro" `
    -u root `
    ci-jenkins

# Container ayağa kalkana kadar kısa bekleme
Start-Sleep -Seconds 10

Write-Host "=======================================================" -ForegroundColor Green
Write-Host " Jenkins başarıyla başlatıldı!" -ForegroundColor Green
Write-Host " URL: http://localhost:8085" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "Jenkins ilk kurulum şifreniz:" -ForegroundColor Yellow
# Şifreyi göstermek için
docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
Write-Host ""
Write-Host "NOT: Eğer şifre yukarıda görünmüyorsa, Jenkins henüz tam olarak hazır olmayabilir."
Write-Host "Birkaç saniye bekleyip şu komutla şifreyi görebilirsiniz:"
Write-Host "docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword"
