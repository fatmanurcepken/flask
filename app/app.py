"""
Flask Task Manager — Production-Ready Version
===============================================
Bu dosya, mevcut run.py'nin Docker ortamında çalışacak şekilde
yeniden yapılandırılmış halidir.

Temel Farklar:
1. MongoDB bağlantısı environment variable'lardan okunur (hardcoded değil)
2. SECRET_KEY environment variable'dan gelir
3. 'localhost' yerine Docker service name ('mongodb') kullanılır
4. Gunicorn ile çalışacak şekilde yapılandırılmıştır
5. Hata yönetimi ve bağlantı retry mekanizması eklenmiştir
"""

import os
import time
from flask import Flask, render_template, redirect
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
from classes import *

# =============================================================================
# UYGULAMA YAPILANDIRMASI
# =============================================================================

app = Flask(__name__)

# SECRET_KEY: Flask'ın CSRF koruması ve session yönetimi için gereklidir.
# Production'da bu değer .env dosyasından okunmalı, hardcoded OLMAMALIDIR.
# os.environ.get() ile environment variable okunur, yoksa fallback değer kullanılır.
app.config.update(dict(
    SECRET_KEY=os.environ.get('FLASK_SECRET_KEY', 'fallback-dev-secret-key')
))

# =============================================================================
# MONGODB BAĞLANTISI
# =============================================================================

# Environment variable'lardan MongoDB bağlantı bilgilerini oku.
# Bu değerler .env dosyasında tanımlanır ve docker-compose tarafından container'a enjekte edilir.
#
# NEDEN 'localhost' KULLANMIYORUZ?
# --------------------------------
# Docker'da her container kendi izole network namespace'ine sahiptir.
# 'localhost' her zaman container'ın kendisini işaret eder, dışarıdaki MongoDB'yi değil.
# Docker Compose'da servisler birbirini "service name" ile bulur.
# Yani 'mongodb' yazdığımızda, Docker DNS sistemi bunu otomatik olarak
# MongoDB container'ının IP adresine çözümler.

MONGO_HOST = os.environ.get('MONGO_HOST', 'mongodb')
MONGO_PORT = os.environ.get('MONGO_PORT', '27017')
MONGO_USER = os.environ.get('MONGO_INITDB_ROOT_USERNAME', 'admin')
MONGO_PASS = os.environ.get('MONGO_INITDB_ROOT_PASSWORD', 'securepassword123')
MONGO_DB = os.environ.get('MONGO_DB_NAME', 'TaskManager')

# MongoDB Connection String formatı:
# mongodb://kullanici:sifre@host:port/veritabani?authSource=admin
#
# authSource=admin: Kimlik doğrulamanın 'admin' veritabanında yapılacağını belirtir.
# Bu, MONGO_INITDB_ROOT_USERNAME ile oluşturulan kullanıcının
# 'admin' veritabanında tanımlı olmasından kaynaklanır.
MONGO_URI = (
    f"mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:{MONGO_PORT}"
    f"/{MONGO_DB}?authSource=admin"
)


def connect_to_mongo(max_retries=5, retry_delay=3):
    """
    MongoDB'ye bağlantı kurar. Bağlantı başarısız olursa belirli sayıda tekrar dener.

    NEDEN RETRY MEKANİZMASI?
    -------------------------
    Docker Compose'da depends_on + healthcheck kullanıyoruz ama bu %100 garanti değildir.
    MongoDB container'ı "healthy" olabilir ama yoğun yük altında geçici olarak
    bağlantı reddedebilir. Retry mekanizması bu tür geçici sorunları çözer.

    Production'da bu tür resilience pattern'ları kritiktir:
    - Network geçici olarak kesilebilir
    - MongoDB restart olabilir
    - DNS çözümleme gecikmesi olabilir

    Args:
        max_retries: Maksimum deneme sayısı (varsayılan 5)
        retry_delay: Denemeler arası bekleme süresi - saniye (varsayılan 3)

    Returns:
        MongoDB database nesnesi
    """
    for attempt in range(1, max_retries + 1):
        try:
            # MongoClient oluştur
            client = MongoClient(
                MONGO_URI,
                # serverSelectionTimeoutMS: MongoDB sunucusunu bulmak için
                # maksimum bekleme süresi (milisaniye)
                serverSelectionTimeoutMS=5000
            )
            # Bağlantıyı doğrula — bu komut gerçekten sunucuya bağlanmayı dener
            client.admin.command('ping')
            print(f"[INFO] MongoDB bağlantısı başarılı! (Deneme {attempt}/{max_retries})")
            return client[MONGO_DB]
        except ConnectionFailure as e:
            print(
                f"[WARN] MongoDB bağlantısı başarısız (Deneme {attempt}/{max_retries}): {e}"
            )
            if attempt < max_retries:
                print(f"[INFO] {retry_delay} saniye sonra tekrar denenecek...")
                time.sleep(retry_delay)
            else:
                print("[ERROR] MongoDB'ye bağlanılamadı! Maksimum deneme sayısına ulaşıldı.")
                raise


# Uygulama başlatılırken MongoDB'ye bağlan
db = connect_to_mongo()

# =============================================================================
# VERİTABANI BAŞLANGIÇ AYARLARI
# =============================================================================

# Task ID sayacını kontrol et, yoksa oluştur
# Bu sayaç her yeni task için benzersiz bir ID üretmek için kullanılır.
if db.settings.count_documents({'name': 'task_id'}) <= 0:
    print("[INFO] task_id sayacı bulunamadı, oluşturuluyor...")
    db.settings.insert_one({'name': 'task_id', 'value': 0})

# =============================================================================
# YARDIMCI FONKSİYONLAR
# =============================================================================


def updateTaskID(value):
    """Task ID sayacını verilen değer kadar artırır."""
    task_id = db.settings.find_one()['value']
    task_id += value
    db.settings.update_one(
        {'name': 'task_id'},
        {'$set': {'value': task_id}}
    )


def createTask(form):
    """Form verisinden yeni bir task oluşturur ve veritabanına kaydeder."""
    title = form.title.data
    priority = form.priority.data
    shortdesc = form.shortdesc.data
    task_id = db.settings.find_one()['value']

    task = {
        'id': task_id,
        'title': title,
        'shortdesc': shortdesc,
        'priority': priority
    }

    db.tasks.insert_one(task)
    updateTaskID(1)
    return redirect('/')


def deleteTask(form):
    """Form verisindeki ID veya başlığa göre task siler."""
    key = form.key.data
    title = form.title.data

    if key:
        db.tasks.delete_many({'id': int(key)})
    else:
        db.tasks.delete_many({'title': title})

    return redirect('/')


def updateTask(form):
    """Verilen ID'ye sahip task'ın açıklamasını günceller."""
    key = form.key.data
    shortdesc = form.shortdesc.data

    db.tasks.update_one(
        {"id": int(key)},
        {"$set": {"shortdesc": shortdesc}}
    )

    return redirect('/')


def resetTask(form):
    """Tüm task'ları ve ayarları sıfırlar."""
    db.tasks.drop()
    db.settings.drop()
    db.settings.insert_one({'name': 'task_id', 'value': 0})
    return redirect('/')


# =============================================================================
# FLASK ROUTE'LARI
# =============================================================================

@app.route('/', methods=['GET', 'POST'])
def main():
    """
    Ana sayfa route'u.
    GET: Tüm task'ları listeler
    POST: Form verilerine göre CRUD işlemi yapar
    """
    # Form nesnelerini oluştur
    cform = CreateTask(prefix='cform')
    dform = DeleteTask(prefix='dform')
    uform = UpdateTask(prefix='uform')
    reset = ResetTask(prefix='reset')

    # POST isteklerini işle
    if cform.validate_on_submit() and cform.create.data:
        return createTask(cform)
    if dform.validate_on_submit() and dform.delete.data:
        return deleteTask(dform)
    if uform.validate_on_submit() and uform.update.data:
        return updateTask(uform)
    if reset.validate_on_submit() and reset.reset.data:
        return resetTask(reset)

    # Tüm task'ları oku
    docs = db.tasks.find()
    data = []
    for i in docs:
        data.append(i)

    return render_template(
        'home.html',
        cform=cform,
        dform=dform,
        uform=uform,
        data=data,
        reset=reset
    )


@app.route('/health')
def health():
    """
    Health check endpoint'i.

    NEDEN GEREKLİ?
    ---------------
    Production ortamında load balancer'lar (Nginx, AWS ALB, Kubernetes)
    uygulamanın sağlıklı olup olmadığını kontrol etmek için bu endpoint'i kullanır.
    Eğer uygulama yanıt vermezse, traffic başka instance'lara yönlendirilir.

    Bu endpoint:
    1. Uygulamanın çalıştığını doğrular
    2. MongoDB bağlantısının aktif olduğunu kontrol eder
    """
    try:
        # MongoDB'ye ping atarak bağlantıyı doğrula
        db.client.admin.command('ping')
        return {'status': 'healthy', 'database': 'connected'}, 200
    except Exception as e:
        return {'status': 'unhealthy', 'database': str(e)}, 503


# =============================================================================
# DEVELOPMENT FALLBACK
# =============================================================================
# Bu blok SADECE dosya doğrudan çalıştırıldığında aktif olur.
# Yani: python app.py
#
# Production'da bu blok ÇALIŞMAZ çünkü Gunicorn, app nesnesini
# doğrudan import eder (gunicorn app:app). __name__ == '__main__'
# koşulu sağlanmaz.
#
# Development'ta hızlı test için kullanılabilir:
#   python app.py
#
# Ama production'da HER ZAMAN Gunicorn kullanılmalıdır:
#   gunicorn --bind 0.0.0.0:5000 --workers 4 app:app

if __name__ == '__main__':
    # host='0.0.0.0' — Tüm network interface'lerden gelen bağlantıları kabul et.
    # Docker container içinde '127.0.0.1' kullanırsanız container dışından erişilemez.
    app.run(host='0.0.0.0', port=5000, debug=True)
