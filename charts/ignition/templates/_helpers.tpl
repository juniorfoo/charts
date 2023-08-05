{{/* vim: set filetype=mustache: */}}

{{/* Expand the name of the chart.
*/}}
{{- define "ignition.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
    If release name contains chart name it will be used as a full name.
*/}}
{{- define "ignition.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
     Component name
*/}}
{{- define "ignition.componentname" -}}
  {{- if . -}}
     {{ printf "%s-%s" "ignition" (kebabcase .) }}
  {{- else -}}
    {{- "ignition" -}}
  {{- end -}}
{{- end }}

{{/*
     Component full name
*/}}
{{- define "ignition.componentfullname" -}}
{{ printf "%s-%s" (include "ignition.fullname" .root) (kebabcase .context.name) }}
{{- end }}

{{/* 
    Create chart name and version as used by the chart label. 
*/}}
{{- define "ignition.chartref" -}}
{{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end }}

{{/* 
    Generate basic labels 
     - https://v2.helm.sh/docs/chart_best_practices/#labels-and-annotations
    app.kubernetes.io/part-of: {{ template "ignition.name" . }}
*/}}
{{- define "ignition.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: ignition
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ .Chart.Version | default .Chart.AppVersion | replace "+" "_" }}"
helm.sh/chart: {{ template "ignition.chartref" . }}
helm.sh/release: {{ $.Release.Name | quote }}
helm.sh/heritage: {{ $.Release.Service | quote }}
{{- if .Values.commonLabels}}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/* 
    Selector labels 
    app.kubernetes.io/part-of: {{ template "ignition.name" . }}
*/}}
{{- define "ignition.selectorLabels" -}}
app.kubernetes.io/name: ignition
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
    Allow the release namespace to be overridden for multi-namespace deployments in combined charts 
*/}}
{{- define "ignition.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}


{{/*
    If create is true, returns a built out name. Else, returns the value given for the name.
    If create is false and a value is given for name, it must exist ahead of time.

    Input: root context
    Output: ServiceAccount name
*/}}
{{- define "ignition.serviceAccountName" }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "ignition.name" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
