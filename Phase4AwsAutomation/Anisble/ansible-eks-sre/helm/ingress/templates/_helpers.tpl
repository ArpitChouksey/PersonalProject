{{- define "ingress.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "ingress.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

