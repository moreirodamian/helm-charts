{{- define "name" -}}
{{/*{{- $name := "test" | required "A service name is required. (.Values.name)" -}}*/}}
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
{{/*app.kubernetes.io/part-of: project*/}}
{{- end -}}

{{- define "magda.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}


{{- define "cron.image" -}}

{{- $imageRegistry := .Values.cron.image.registry  -}}
{{- $imageName := .Values.cron.image.name | default .Values.name | default "dummy" -}}
{{- $imageTag := .Values.cron.image.tag | toString | default "latest" -}}
{{- $imageTemp := printf "%s/%s:%s" $imageRegistry $imageName $imageTag }}
{{- if hasPrefix "sha:" $imageTag }}
  {{- $imageTemp = printf "%s/%s@%s" $imageRegistry $imageName $imageTag }}
{{- end }}
{{- $image := $imageTemp | replace "registry.hub.docker.com/" "" -}}
{{- printf "%s" $image -}}

{{- end -}}
