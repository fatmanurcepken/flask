{{/*
=============================================================================
_helpers.tpl — Helm Template Yardımcı Fonksiyonları
=============================================================================

Bu dosya, diğer template dosyalarında tekrar eden mantığı tanımlar.
Go template'inin "define" bloğu ile named template oluşturulur.
"include" ile başka template dosyalarından çağrılır.

Örnekler:
  {{ include "flask-mongodb.fullname" . }}      → flask-mongodb-release
  {{ include "flask-mongodb.labels" . | indent 4 }} → label bloğu

Neden _helpers.tpl?
-------------------
1. DRY (Don't Repeat Yourself): Aynı mantığı tek yerde yaz
2. Alt çizgi (_) ile başlayan dosyalar Kubernetes'e gönderiLMEZ
   sadece yardımcı template olarak kullanılır
=============================================================================
*/}}

{{/*
Chart'ın tam adını üretir.
nameOverride veya fullnameOverride values.yaml'da belirtilmişse onu kullanır.
Aksi halde: release-adı + chart-adı
*/}}
{{- define "flask-mongodb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Chart adını döndürür (nameOverride yoksa Chart.yaml'daki name)
*/}}
{{- define "flask-mongodb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Namespace adını döndürür
*/}}
{{- define "flask-mongodb.namespace" -}}
{{- .Values.namespace.name | default "flask-mongodb" }}
{{- end }}

{{/*
Ortak Kubernetes labels — Helm best practice olarak her kaynağa eklenir.
Bu etiketler ile kaynakları filtreleyebilirsiniz:
  kubectl get all -l helm.sh/chart=flask-mongodb-0.1.0
*/}}
{{- define "flask-mongodb.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "flask-mongodb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: flask-mongodb
{{- end }}

{{/*
Selector labels — Service ve Deployment'ın Pod'ları seçmek için kullandığı etiketler
Bu etiketler deployment süresince DEĞIŞMEMELI (immutable)
*/}}
{{- define "flask-mongodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-mongodb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Flask app için selector labels
*/}}
{{- define "flask-mongodb.flask.selectorLabels" -}}
app: flask-app
app.kubernetes.io/name: flask-app
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MongoDB için selector labels
*/}}
{{- define "flask-mongodb.mongodb.selectorLabels" -}}
app: mongodb
app.kubernetes.io/name: mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MongoDB Service adını döndürür (ConfigMap'te MONGO_HOST olarak kullanılır)
*/}}
{{- define "flask-mongodb.mongodb.serviceName" -}}
{{- printf "%s-mongodb-service" .Release.Name }}
{{- end }}

{{/*
Secret adını döndürür
*/}}
{{- define "flask-mongodb.secretName" -}}
{{- printf "%s-secret" .Release.Name }}
{{- end }}

{{/*
ConfigMap adını döndürür
*/}}
{{- define "flask-mongodb.configmapName" -}}
{{- printf "%s-config" .Release.Name }}
{{- end }}
