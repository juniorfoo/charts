{{/* vim: set filetype=mustache: */}}

{{- /*
Template Service for Ignition.

Input: dict with:
- root - root context (i.e., $)
- context - current context (i.e., .Values.spoke[0])

Output: Service Manifest

Note:
- Remember that "." references the incoming dict. Use .root. or .context
*/}}

{{- define "ignition.shared.service" }}
{{- if and .root.Values.enabled .root.Values.service.enabled }}

apiVersion: v1
kind: Service
metadata:
  name: {{ template "ignition.componentfullname" $ }}
  namespace: {{ template "ignition.namespace" $.root }}
  labels:
    app.kubernetes.io/component: {{ template "ignition.componentname" .context.name }}
{{ include "ignition.labels" $.root | indent 4 }}
{{- if $.root.Values.service.labels }}
{{ toYaml $.root.Values.service.labels | indent 4 }}
{{- end }}
{{- if $.root.Values.service.annotations }}
  annotations:
{{ toYaml $.root.Values.service.annotations | indent 4 }}
{{- end }}
spec:
{{- if $.root.Values.service.clusterIP }}
  clusterIP: {{ $.root.Values.service.clusterIP }}
{{- end }}
{{- if $.root.Values.service.externalIPs }}
  externalIPs:
{{ toYaml $.root.Values.service.externalIPs | indent 4 }}
{{- end }}
{{- if $.root.Values.service.loadBalancerIP }}
  loadBalancerIP: {{ $.root.Values.service.loadBalancerIP }}
{{- end }}
{{- if $.root.Values.service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- range $cidr := $.root.Values.service.loadBalancerSourceRanges }}
    - {{ $cidr }}
  {{- end }}
{{- end }}
{{- if ne $.root.Values.service.type "ClusterIP" }}
  externalTrafficPolicy: {{ $.root.Values.service.externalTrafficPolicy }}
{{- end }}
  ports:
  - name: {{ $.root.Values.service.portName }}
  {{- if eq $.root.Values.service.type "NodePort" }}
    nodePort: {{ $.root.Values.service.nodePort }}
  {{- end }}
    port: {{ $.root.Values.service.port }}
    targetPort: {{ $.root.Values.service.targetPort }}
    protocol: TCP
{{- if $.root.Values.service.additionalPorts }}
{{ toYaml $.root.Values.service.additionalPorts | indent 2 }}
{{- end }}
  selector:
    app.kubernetes.io/component: {{ template "ignition.componentname" $.context.name }}
{{ include "ignition.selectorLabels" $.root | indent 4 }}
{{- if $.root.Values.service.sessionAffinity }}
  sessionAffinity: {{ $.root.Values.service.sessionAffinity }}
{{- end }}
  type: "{{ $.root.Values.service.type }}"

{{- end }}
{{- end }}
