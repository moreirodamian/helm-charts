{{- define "name" -}}
{{- $name := .Values.name | required "A service name is required. (.Values.name)" -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "instance" -}}
{{- $env := .Values.deployEnv | required "A deployEnv is required. (.Values.deployEnv)" -}}
{{- $region := .Values.region | required "A region is required. (.Values.region)" -}}
{{- printf "%s-%s" $env $region | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common-labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "name" . }}
app.kubernetes.io/instance: {{ include "instance" . }}
{{- end -}}

{{- define "selector-labels" -}}
app.kubernetes.io/name: {{ include "name" . }}
app.kubernetes.io/instance: {{ include "instance" . }}
{{- end -}}

{{- define "migrations-labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "name" . }}
app.kubernetes.io/instance: {{ include "instance" . }}
{{- end -}}

{{- define "app.image" -}}
{{- $imageRegistry := .Values.app.image.registry | required "Image registry is required. (.Values.app.image.registry)" -}}
{{- $imageName := .Values.app.image.name | default .Values.name | default "dummy" -}}
{{- $imageTag := .Values.app.image.tag | toString | default "latest" -}}
{{- $imageTemp := printf "%s/%s:%s" $imageRegistry $imageName $imageTag -}}
{{- if hasPrefix "sha:" $imageTag }}
  {{- $imageTemp = printf "%s/%s@%s" $imageRegistry $imageName $imageTag -}}
{{- end }}
{{- $image := $imageTemp | replace "registry.hub.docker.com/" "" -}}
{{- printf "%s" $image -}}
{{- end -}}

{{- define "cron.image" -}}
{{- if and .Values.cron.image .Values.cron.image.registry .Values.cron.image.name }}
  {{- $imageRegistry := .Values.cron.image.registry -}}
  {{- $imageName := .Values.cron.image.name -}}
  {{- $imageTag := .Values.cron.image.tag | toString | default "latest" -}}
  {{- $imageTemp := printf "%s/%s:%s" $imageRegistry $imageName $imageTag -}}
  {{- if hasPrefix "sha:" $imageTag }}
    {{- $imageTemp = printf "%s/%s@%s" $imageRegistry $imageName $imageTag -}}
  {{- end }}
  {{- $image := $imageTemp | replace "registry.hub.docker.com/" "" -}}
  {{- printf "%s" $image -}}
{{- else }}
  {{- include "app.image" . -}}
{{- end }}
{{- end -}}

{{- define "migrations.image" -}}
{{- if and .Values.migrations.image .Values.migrations.image.registry .Values.migrations.image.name }}
  {{- $imageRegistry := .Values.migrations.image.registry -}}
  {{- $imageName := .Values.migrations.image.name -}}
  {{- $imageTag := .Values.migrations.image.tag | toString | default "latest" -}}
  {{- $imageTemp := printf "%s/%s:%s" $imageRegistry $imageName $imageTag -}}
  {{- if hasPrefix "sha:" $imageTag }}
    {{- $imageTemp = printf "%s/%s@%s" $imageRegistry $imageName $imageTag -}}
  {{- end }}
  {{- $image := $imageTemp | replace "registry.hub.docker.com/" "" -}}
  {{- printf "%s" $image -}}
{{- else }}
  {{- include "app.image" . -}}
{{- end }}
{{- end -}}
