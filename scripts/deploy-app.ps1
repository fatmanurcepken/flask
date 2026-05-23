<#
.SYNOPSIS
    Uygulamayı Minikube (veya yerel Kubernetes) üzerine deploy eder.
.DESCRIPTION
    Helm komutlarını kullanarak, proje kök dizinindeki ./helm/flask-mongodb
    chart'ını Kubernetes cluster'ınıza kurar veya günceller.
#>

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Uygulama Kubernetes'e Deploy Ediliyor (Helm ile) " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Kök dizinde olduğumuzdan emin olmak için scriptin bulunduğu dizinden köke çıkalım
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = Join-Path -Path $scriptDir -ChildPath ".."
Set-Location -Path $rootDir

Write-Host "[*] Helm bağımlılıkları güncelleniyor (Varsa)..." -ForegroundColor Yellow
helm dependency update ./helm/flask-mongodb

Write-Host "[*] Deploy işlemi başlatılıyor..." -ForegroundColor Yellow
# Release adını 'flask-app' olarak, namespace'i de 'flask-mongodb' olarak ayarlıyoruz
# values.yaml içinde namespace.create = true olduğu için kendisi oluşturacaktır
# ancak kural gereği --create-namespace parametresi vermek her zaman daha garantilidir.
helm upgrade --install flask-app ./helm/flask-mongodb `
    --namespace flask-mongodb `
    --create-namespace

if ($LASTEXITCODE -eq 0) {
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host " Deploy işlemi başarıyla tamamlandı!" -ForegroundColor Green
    Write-Host " Pod'ların durumunu kontrol etmek için şu komutu çalıştırabilirsiniz:" -ForegroundColor Green
    Write-Host " kubectl get pods -n flask-mongodb" -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Green
} else {
    Write-Host "[!] Deploy işlemi sırasında bir hata oluştu." -ForegroundColor Red
    exit 1
}
