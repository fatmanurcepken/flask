import os
import time
from flask import Flask, render_template, redirect
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
from classes import *

app = Flask(__name__)
app.config.update(dict(
    SECRET_KEY=os.environ.get('FLASK_SECRET_KEY', 'fallback-dev-secret-key')
))

MONGO_HOST = os.environ.get('MONGO_HOST', 'mongodb')
MONGO_PORT = os.environ.get('MONGO_PORT', '27017')
MONGO_USER = os.environ.get('MONGO_INITDB_ROOT_USERNAME', 'admin')
MONGO_PASS = os.environ.get('MONGO_INITDB_ROOT_PASSWORD', 'securepassword123')
MONGO_DB = os.environ.get('MONGO_DB_NAME', 'TaskManager')

MONGO_URI = (
    f"mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:{MONGO_PORT}"
    f"/{MONGO_DB}?authSource=admin"
)


def connect_to_mongo(max_retries=5, retry_delay=3):
    for attempt in range(1, max_retries + 1):
        try:
            client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
            client.admin.command('ping')
            print(f"[INFO] MongoDB bağlantısı başarılı! (Deneme {attempt}/{max_retries})")
            return client[MONGO_DB]
        except ConnectionFailure as e:
            print(f"[WARN] MongoDB bağlantısı başarısız (Deneme {attempt}/{max_retries}): {e}")
            if attempt < max_retries:
                print(f"[INFO] {retry_delay} saniye sonra tekrar denenecek...")
                time.sleep(retry_delay)
            else:
                print("[ERROR] MongoDB'ye bağlanılamadı! Maksimum deneme sayısına ulaşıldı.")
                raise


db = connect_to_mongo()

if db.settings.count_documents({'name': 'task_id'}) <= 0:
    print("[INFO] task_id sayacı bulunamadı, oluşturuluyor...")
    db.settings.insert_one({'name': 'task_id', 'value': 0})


def updateTaskID(value):
    task_id = db.settings.find_one()['value']
    task_id += value
    db.settings.update_one(
        {'name': 'task_id'},
        {'$set': {'value': task_id}}
    )


def createTask(form):
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
    key = form.key.data
    title = form.title.data

    if key:
        db.tasks.delete_many({'id': int(key)})
    else:
        db.tasks.delete_many({'title': title})

    return redirect('/')


def updateTask(form):
    key = form.key.data
    shortdesc = form.shortdesc.data

    db.tasks.update_one(
        {"id": int(key)},
        {"$set": {"shortdesc": shortdesc}}
    )

    return redirect('/')


def resetTask(form):
    db.tasks.drop()
    db.settings.drop()
    db.settings.insert_one({'name': 'task_id', 'value': 0})
    return redirect('/')


@app.route('/', methods=['GET', 'POST'])
def main():
    cform = CreateTask(prefix='cform')
    dform = DeleteTask(prefix='dform')
    uform = UpdateTask(prefix='uform')
    reset = ResetTask(prefix='reset')

    if cform.validate_on_submit() and cform.create.data:
        return createTask(cform)
    if dform.validate_on_submit() and dform.delete.data:
        return deleteTask(dform)
    if uform.validate_on_submit() and uform.update.data:
        return updateTask(uform)
    if reset.validate_on_submit() and reset.reset.data:
        return resetTask(reset)

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
    try:
        db.client.admin.command('ping')
        return {'status': 'healthy', 'database': 'connected'}, 200
    except Exception as e:
        return {'status': 'unhealthy', 'database': str(e)}, 503


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
