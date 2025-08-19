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
{{- if $.root.Values.service.externalIps }}
  externalIPs:
{{ toYaml $.root.Values.service.externalIps | indent 4 }}
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
  - name: {{ $.root.Values.service.portNameHttp }}
  {{- if eq $.root.Values.service.type "NodePort" }}
    nodePort: {{ $.root.Values.service.nodePortHttp }}
  {{- end }}
    port: {{ $.root.Values.service.portHttp }}
    targetPort: {{ $.root.Values.service.portNameHttp }}
    protocol: TCP
  - name: {{ $.root.Values.service.portNameHttps }}
  {{- if eq $.root.Values.service.type "NodePort" }}
    nodePort: {{ $.root.Values.service.nodePortHttps }}
  {{- end }}
    port: {{ $.root.Values.service.portHttps }}
    targetPort: {{ $.root.Values.service.portNameHttps }}
    protocol: TCP
  - name: {{ $.root.Values.service.portNameGan }}
  {{- if eq $.root.Values.service.type "NodePort" }}
    nodePort: {{ $.root.Values.service.nodePortGan }}
  {{- end }}
    port: {{ $.root.Values.service.portGan }}
    targetPort: {{ $.root.Values.service.portNameGan }}
    protocol: TCP
  selector:
    app.kubernetes.io/component: {{ template "ignition.componentname" $.context.name }}
{{ include "ignition.selectorLabels" $.root | indent 4 }}
{{- if $.root.Values.service.sessionAffinity }}
  sessionAffinity: {{ $.root.Values.service.sessionAffinity }}
{{- end }}
  type: "{{ $.root.Values.service.type }}"

{{- end }}
{{- end }}
