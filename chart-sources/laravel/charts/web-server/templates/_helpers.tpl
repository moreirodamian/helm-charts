
{{- define "web-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "web-server.fullname" -}}
{{- if .Values.global.name }}
"{{- .Values.global.name | trunc 50 | trimSuffix "-" }}-{{- .Chart.Name | trunc 63 | trimSuffix "-" }}-{{- .Values.global.environment| trunc 63 | trimSuffix "-" }}"
{{- else if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}

{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "web-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "web-server.labels" -}}
helm.sh/chart: {{ include "web-server.chart" . }}
{{ include "web-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ default .Chart.AppVersion .Values.global.appVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "web-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "web-server.name" . }}
app.kubernetes.io/instance: {{ include "web-server.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "web-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "web-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*Set Image*/}}
{{- define "web-server.image" -}}
"{{ .Values.global.image.repository | default .Values.image.repository }}:{{ .Values.global.appVersion | default .Chart.AppVersion }}-{{ .Values.image.component }}"
{{- end -}}

