{{- define "flask-mongodb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "flask-mongodb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "flask-mongodb.namespace" -}}
{{- .Values.namespace.name | default "flask-mongodb" }}
{{- end }}

{{- define "flask-mongodb.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "flask-mongodb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: flask-mongodb
{{- end }}

{{- define "flask-mongodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-mongodb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "flask-mongodb.flask.selectorLabels" -}}
app: flask-app
app.kubernetes.io/name: flask-app
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "flask-mongodb.mongodb.selectorLabels" -}}
app: mongodb
app.kubernetes.io/name: mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "flask-mongodb.mongodb.serviceName" -}}
{{- printf "%s-mongodb-service" .Release.Name }}
{{- end }}

{{- define "flask-mongodb.secretName" -}}
{{- printf "%s-secret" .Release.Name }}
{{- end }}

{{- define "flask-mongodb.configmapName" -}}
{{- printf "%s-config" .Release.Name }}
{{- end }}
