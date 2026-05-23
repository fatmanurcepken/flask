# =============================================================================
# DOCKERFILE — Production-Grade Multi-Stage Build
# =============================================================================
#
# Multi-Stage Build Nedir?
# ========================
# Dockerfile'da birden fazla FROM komutu kullanarak "stage" (aşama) oluşturuyoruz.
# Her aşama farklı bir base image kullanabilir.
# Son aşama sadece gerçekten gerekli dosyaları içerir.
#
# Avantajları:
# 1. Küçük image boyutu: Build araçları (gcc, make vb.) son image'a dahil edilmez
# 2. Güvenlik: Gereksiz araçlar saldırı yüzeyini artırır
# 3. Hız: Daha küçük image = daha hızlı pull/push
#
# SLIM vs ALPINE FARKI
# ====================
# python:3.11-slim (~120MB):
#   - Debian tabanlı, gereksiz paketler çıkarılmış
#   - glibc kullanır (standart C kütüphanesi)
#   - pymongo gibi C extension'ları sorunsuz derlenir
#   - Production'da en çok tercih edilen seçenek
#
# python:3.11-alpine (~50MB):
#   - Alpine Linux tabanlı, çok küçük
#   - musl libc kullanır (glibc değil!)
#   - Bazı Python paketleri (pymongo, numpy vb.) derleme hatası verebilir
#   - Derleme için ekstra paket kurmak gerekir → avantajı azalır
#   - Production'da dikkatli kullanılmalı
#
# BU PROJEDE NEDEN SLIM?
# pymongo C extension'ları var ve slim ile sorunsuz çalışır.
# Alpine'da ayrıca gcc, musl-dev gibi paketler kurmak gerekir ki bu
# image boyutunu slim'e yaklaştırır ve karmaşıklığı artırır.

# =============================================================================
# STAGE 1: Builder — Bağımlılıkları Derle
# =============================================================================
FROM python:3.11-slim AS builder

# PYTHONDONTWRITEBYTECODE=1
# -------------------------
# Python'un .pyc (bytecode) dosyaları oluşturmasını engeller.
# Container'da bu dosyalar gereksizdir çünkü:
# - Dosya sistemi zaten ephemeral (geçici)
# - Image boyutunu gereksiz yere artırır
# - Hot reload sırasında cache sorunlarına yol açabilir
ENV PYTHONDONTWRITEBYTECODE=1

# PYTHONUNBUFFERED=1
# ------------------
# Python çıktısını (stdout/stderr) buffer'lamaz.
# Docker logs'ta çıktıları ANINDA görmenizi sağlar.
# Buffer'lama açıkken container crash olursa son log satırları kaybolabilir.
ENV PYTHONUNBUFFERED=1

# Çalışma dizinini ayarla
WORKDIR /app

# requirements.txt'i AYRI kopyala
# --------------------------------
# NEDEN AYRI?
# Docker her COPY komutunu ayrı bir "layer" olarak cache'ler.
# requirements.txt değişmediyse, pip install adımı cache'ten gelir.
# Bu sayede sadece kaynak kod değişikliklerinde yeniden build çok hızlı olur.
#
# Eğer tüm dosyaları tek COPY ile kopyalasaydık:
# Herhangi bir dosya değişikliğinde pip install TEK BAŞINA yeniden çalışırdı.
COPY requirements.txt .

# Bağımlılıkları kur
# --no-cache-dir: pip'in indirdiği paketleri cache'lememesini sağlar
# Bu cache normalde /root/.cache/pip/ altında saklanır ve image boyutunu artırır.
# Container'da tekrar pip install yapmayacağımız için cache gereksizdir.
#
# --prefix=/install: Paketleri /install dizinine kur (izole)
# Bu sayede sadece kurulu paketleri son stage'e kopyalayabiliriz.
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# =============================================================================
# STAGE 2: Runtime — Sadece Çalıştırma Ortamı
# =============================================================================
FROM python:3.11-slim AS runtime

# Aynı environment variable'ları runtime'da da ayarla
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Çalışma dizini
WORKDIR /app

# GÜVENLİK: Non-root user oluştur
# ---------------------------------
# Container'lar varsayılan olarak root kullanıcısıyla çalışır.
# Bu ciddi bir güvenlik riskidir:
# - Container escape durumunda saldırgan host'ta root olabilir
# - Gereksiz dosya sistemi erişimi olur
#
# Best practice: Her zaman non-root user kullan.
# --system: Sistem kullanıcısı (giriş yapamaz)
# --no-create-home: Home dizini oluşturma (gereksiz)
RUN groupadd --system appgroup && \
    useradd --system --no-create-home --gid appgroup appuser

# Builder stage'den sadece kurulu Python paketlerini kopyala
# Bu sayede gcc, make gibi build araçları son image'da YER ALMAZ.
COPY --from=builder /install /usr/local

# Uygulama kodlarını kopyala
COPY . .

# Dosya sahipliğini non-root user'a ver
RUN chown -R appuser:appgroup /app

# Non-root user'a geç
USER appuser

# Container'ın hangi portu dinleyeceğini belirt
# EXPOSE sadece dokümantasyon amaçlıdır, gerçek port mapping docker-compose'da yapılır.
# Ama best practice olarak her zaman belirtilmelidir.
EXPOSE 5000

# =============================================================================
# GUNICORN İLE ÇALIŞTIRMA — Production WSGI Server
# =============================================================================
#
# gunicorn parametreleri:
#
# --bind 0.0.0.0:5000
#   Tüm network interface'lerden gelen bağlantıları port 5000'de kabul et.
#   0.0.0.0 = her yerden erişilebilir (container dışından da)
#   127.0.0.1 kullansaydık container dışından ERİŞİLEMEZDİ!
#
# --workers 4
#   4 worker process başlat. Her worker ayrı bir process olarak çalışır.
#   Genel kural: workers = (2 × CPU çekirdek sayısı) + 1
#   4 worker, 2 çekirdekli bir makine için idealdir.
#   Her worker bağımsız olarak istek işleyebilir → paralel processing.
#
# --timeout 120
#   Bir worker 120 saniye içinde yanıt vermezse Gunicorn onu "öldürür" ve
#   yeni bir worker başlatır. Bu, takılmış (stuck) worker'ların
#   kaynakları sonsuza kadar kullanmasını engeller.
#
# --access-logfile -
#   Erişim loglarını stdout'a yaz (- = stdout).
#   Docker logs komutuyla doğrudan görülebilir.
#   Dosyaya yazarsanız container'dan çıkarmak zorlaşır.
#
# --error-logfile -
#   Hata loglarını stdout'a yaz.
#
# app:app
#   İlk 'app' = Python modülü (app.py dosyası)
#   İkinci 'app' = Flask uygulama nesnesi (app = Flask(__name__))
#   Gunicorn bu nesneyi import ederek WSGI server olarak sunar.
#
# NOT: Burada "python app.py" veya "flask run" kullanılmıyor.
# Bunlar SADECE development içindir. Production'da her zaman
# Gunicorn (veya uWSGI) gibi production WSGI server kullanılmalıdır.
CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "4", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app:app"]
