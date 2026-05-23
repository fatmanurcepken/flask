"""
WTForms Sınıfları
=================
Flask-WTF kütüphanesi ile oluşturulmuş form sınıfları.
Bu sınıflar HTML formlarının Python tarafındaki karşılığıdır.
CSRF koruması Flask-WTF tarafından otomatik olarak sağlanır.
"""

from flask_wtf import FlaskForm
from wtforms import StringField, IntegerField, SubmitField


class CreateTask(FlaskForm):
    """Yeni task oluşturma formu."""
    title = StringField('Task Title')
    shortdesc = StringField('Short Description')
    priority = IntegerField('Priority')
    create = SubmitField('Create')


class DeleteTask(FlaskForm):
    """Task silme formu. ID veya başlık ile silinebilir."""
    key = StringField('Task ID')
    title = StringField('Task Title')
    delete = SubmitField('Delete')


class UpdateTask(FlaskForm):
    """Task açıklamasını güncelleme formu."""
    key = StringField('Task Key')
    shortdesc = StringField('Short Description')
    update = SubmitField('Update')


class ResetTask(FlaskForm):
    """Tüm verileri sıfırlama formu."""
    reset = SubmitField('Reset')
