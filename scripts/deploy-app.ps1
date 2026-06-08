Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Uygulama Kubernetes'e Deploy Ediliyor (Helm ile) " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = Join-Path -Path $scriptDir -ChildPath ".."
Set-Location -Path $rootDir

Write-Host "[*] Helm bağımlılıkları güncelleniyor..." -ForegroundColor Yellow
helm dependency update ./helm/flask-mongodb

Write-Host "[*] Deploy işlemi başlatılıyor..." -ForegroundColor Yellow
helm upgrade --install flask-app ./helm/flask-mongodb `
    --namespace flask-mongodb `
    --create-namespace

if ($LASTEXITCODE -eq 0) {
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host " Deploy işlemi başarıyla tamamlandı!" -ForegroundColor Green
    Write-Host " kubectl get pods -n flask-mongodb" -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Green
} else {
    Write-Host "[!] Deploy işlemi sırasında bir hata oluştu." -ForegroundColor Red
    exit 1
}
