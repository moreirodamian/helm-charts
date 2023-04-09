{{/*
Expand the name of the chart.
*/}}
{{- define "fpm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fpm.fullname" -}}
{{- if .Values.global.name }}
{{- .Values.global.name | trunc 50 | trimSuffix "-" }}-{{- .Chart.Name | trunc 63 | trimSuffix "-" }}-{{- .Values.global.environment| trunc 63 | trimSuffix "-" }}
{{- else if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fpm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fpm.labels" -}}
helm.sh/chart: {{ include "fpm.chart" . }}
{{ include "fpm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ default .Chart.AppVersion .Values.global.appVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fpm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fpm.name" . }}
app.kubernetes.io/instance: {{ include "fpm.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fpm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fpm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*Set Image*/}}
{{- define "fpm.image" -}}
"{{ .Values.global.image.repository | default .Values.image.repository }}:{{ .Values.global.appVersion | default .Chart.AppVersion }}-{{ .Values.image.component }}"
{{- end -}}

