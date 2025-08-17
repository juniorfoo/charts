{{/* vim: set filetype=mustache: */}}

{{- /*
Template Ingress for Ignition.

Input: dict with:
- root - root context (i.e., $)
- ingress - ingress context (i.e., .Values.ingress)
- context - current context (i.e., .Values.spoke[0] or,  .Values.hub)

Output: Ingress Manifest

Note:
- Remember that "." references the incoming dict. Use .root... or .ingress
*/}}

{{- define "ignition.shared.ingress" }}

{{- if and .root.Values.enabled .context.ingress.enabled }}

{{- $appName := printf "%s-%s" (include "ignition.name" .root)  (kebabcase .context.name) | camelcase }}
{{- $serviceName := printf "%s-%s" (include "ignition.fullname" .root)  (kebabcase .context.name) }}
{{- $backendServiceName := .context.serviceName | default $serviceName }}
{{- $servicePort := .context.servicePort | default .root.Values.service.port -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $serviceName }}
  namespace: {{ template "ignition.namespace" .root }}
  annotations:
    hajimari.io/appName: {{ $appName }}
{{- if .ingress.annotations }}
{{ toYaml .ingress.annotations | indent 4 }}
{{- end }}
  labels:
    app.kubernetes.io/component: {{ $serviceName }}
{{- if .ingress.labels }}
{{ toYaml .ingress.labels | indent 4 }}
{{- end }}
{{ include "ignition.labels" .root| indent 4 }}
spec:
  {{- if .ingress.ingressClassName }}
  ingressClassName: {{ .ingress.ingressClassName }}
  {{- end }}
  tls:
    {{- if .context.ingress.hosts }}
    - hosts:
      {{- range $host := .context.ingress.hosts }}
      - {{ kebabcase $host }}
      {{- end }}
      secretName: {{ $serviceName }}-tls-certificate
    {{- end }}
  rules:
  {{- if .context.ingress.hosts }}
    {{- range $host := .context.ingress.hosts }}
    - host: {{ kebabcase $host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ $backendServiceName }}
                port:
                  number: {{ $servicePort }}
    {{- end -}}
  {{- end -}}

{{- end }}

{{- end }}
