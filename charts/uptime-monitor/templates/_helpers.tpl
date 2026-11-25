{{- define "uptime.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "uptime.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/part-of: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* selector labels: call with (dict "ctx" $ "component" "api") */}}
{{- define "uptime.selectorLabels" -}}
app.kubernetes.io/name: {{ .ctx.Chart.Name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "uptime.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{- define "uptime.dbHost" -}}
{{ include "uptime.fullname" . }}-db
{{- end -}}

{{- define "uptime.secretName" -}}
{{- if .Values.externalDatabase.existingSecret -}}
{{ .Values.externalDatabase.existingSecret }}
{{- else -}}
{{ include "uptime.fullname" . }}-secrets
{{- end -}}
{{- end -}}

{{- define "uptime.databaseUrl" -}}
{{- if .Values.postgresql.enabled -}}
{{- with .Values.postgresql -}}
postgresql+psycopg://{{ .username }}:{{ .password | urlquery }}@{{ include "uptime.dbHost" $ }}:5432/{{ .database }}
{{- end -}}
{{- else -}}
{{- required "externalDatabase.url is required when postgresql.enabled=false" .Values.externalDatabase.url -}}
{{- end -}}
{{- end -}}

{{/* env shared by api, worker and migrate */}}
{{- define "uptime.env" -}}
- name: UPTIME_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "uptime.secretName" . }}
      key: UPTIME_DATABASE_URL
- name: UPTIME_CHECK_INTERVAL_SECONDS
  value: {{ .Values.config.checkIntervalSeconds | quote }}
- name: UPTIME_CHECK_TIMEOUT_SECONDS
  value: {{ .Values.config.checkTimeoutSeconds | quote }}
{{- if .Values.adminToken }}
- name: UPTIME_ADMIN_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "uptime.fullname" . }}-secrets
      key: UPTIME_ADMIN_TOKEN
{{- end }}
{{- end -}}
