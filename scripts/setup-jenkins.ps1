Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Jenkins CI/CD Kurulumu Başlıyor... " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

$existingJenkins = docker ps -a -q -f name=jenkins-server
if ($existingJenkins) {
    Write-Host "[*] Eski Jenkins container'ı durduruluyor ve siliniyor..." -ForegroundColor Yellow
    docker stop jenkins-server | Out-Null
    docker rm jenkins-server | Out-Null
}

$dockerfileContent = @"
FROM jenkins/jenkins:lts-jdk17
USER root

RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://dl.k8s.io/release/`$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm get_helm.sh

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:`$PATH"
RUN pip install --no-cache-dir flake8

USER jenkins
"@

$dockerfilePath = "Dockerfile.jenkins"
Set-Content -Path $dockerfilePath -Value $dockerfileContent

Write-Host "[*] Özel Jenkins imajı (ci-jenkins) derleniyor..." -ForegroundColor Cyan
docker build -t ci-jenkins -f $dockerfilePath .

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] İmaj derleme başarısız oldu." -ForegroundColor Red
    exit 1
}
Remove-Item $dockerfilePath

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

Start-Sleep -Seconds 10

Write-Host "=======================================================" -ForegroundColor Green
Write-Host " Jenkins başarıyla başlatıldı!" -ForegroundColor Green
Write-Host " URL: http://localhost:8085" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "Jenkins ilk kurulum şifreniz:" -ForegroundColor Yellow
docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
Write-Host ""
Write-Host "NOT: Şifre görünmüyorsa birkaç saniye bekleyip tekrar deneyin:"
Write-Host "docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword"
