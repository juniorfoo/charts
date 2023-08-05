{{/* vim: set filetype=mustache: */}}

{{- /*
Template StatefulSet for Ignition.

Input: dict with:
- root - root context (i.e., $)
- context - current context (i.e., .Values.hub or .Values.spoke[0])
- spec - current spec (i.e., .Values.hubSpec or Values.spokeSpec)

Output: StatefulSet Manifest

Note:
- Remember that "." references the incoming dict. Use .root. or .context


  podManagementPolicy: {{ .Values.backend.podManagementPolicy }}
  updateStrategy:
    rollingUpdate:
      partition: 0  
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain
    whenScaled: Retain

- Build with design hints from:
  - https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
  - https://github.com/grafana/loki/blob/main/production/helm/loki/templates/backend/statefulset-backend.yaml
  - https://github.com/prometheus-community/helm-charts/blob/main/charts/alertmanager/templates/statefulset.yaml

*/}}

{{- define "ignition.shared.statefulset" }}
{{- if .root.Values.enabled }}

apiVersion: apps/v1
kind: StatefulSet
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
  replicas: {{ .spec.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/component: {{ template "ignition.componentname" .context.name }}
      {{- include "ignition.selectorLabels" $.root | nindent 6 }}
  serviceName: {{ template "ignition.componentfullname" $ }}
  template:
    metadata:
      labels:
        app.kubernetes.io/component: {{ template "ignition.componentname" $.context.name }}
        {{- include "ignition.selectorLabels" $.root | nindent 8 }}
        {{- with .spec.labels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      annotations:
        {{- with .spec.annotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      automountServiceAccountToken: {{ $.root.Values.serviceAccount.automountServiceAccountToken }}
      {{- with $.root.Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "ignition.serviceAccountName" $.root }}
      {{- with $.root.Values.dnsConfig }}
      dnsConfig:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $.root.Values.hostAliases }}
      hostAliases:
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $.spec.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if or $.spec.podAntiAffinity $.spec.affinity $.spec.nodeArchitecture }}
      affinity:
      {{- end }}
        {{- with $.spec.affinity }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $.spec.nodeArchitecture }}
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: "kubernetes.io/arch"
                    operator: In
                    values:
                    {{- toYaml . | nindent 20 }}
        {{- end }}
        {{- if eq $.spec.podAntiAffinity "hard" }}
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - topologyKey: {{ $.spec.podAntiAffinityTopologyKey }}
              labelSelector:
                {{- /* expressions are ANDed */}}
                matchExpressions:
                  - key: app.kubernetes.io/name
                    operator: In
                    values:
                      - {{ include "ignition.name" $.root }}
        {{- else if eq $.spec.podAntiAffinity "soft" }}
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                topologyKey: {{ $.spec.podAntiAffinityTopologyKey }}
                labelSelector:
                matchExpressions:
                  - key: app.kubernetes.io/name, 
                    operator: In, 
                    values:
                    {{- include "ignition.selectorLabels" $.root | nindent 22 }}
        {{- end }}
      {{- with $.spec.priorityClassName }}
      priorityClassName: {{ . }}
      {{- end }}
      {{- with $.root.Values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $.spec.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        {{- toYaml $.spec.podSecurityContext | nindent 8 }}
      {{- with $.spec.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ $.root.Chart.Name }}
          {{- with $.spec.containerSecurityContext }}
          securityContext:
            {{- toYaml $.spec.containerSecurityContext | nindent 12 }}
          {{- end }}
          image: "{{ $.spec.image.repository }}:{{ $.spec.image.tag | default $.root.Chart.AppVersion }}"
          imagePullPolicy: {{ $.spec.image.pullPolicy }}
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
            - name: ACCEPT_IGNITION_EULA
              value: {{ ternary "Y" "N" $.spec.acceptEula | quote }}
            - name: GATEWAY_ADMIN_USERNAME
              valueFrom:
                secretKeyRef:
                  name: {{ $.spec.adminSecret }}
                  key: username
            - name: GATEWAY_ADMIN_PASSWORD_FILE
              value: /run/secrets/gateway-password
            - name: IGNITION_EDITION
              value: {{ $.spec.edition | default "standard" }}
            - name: TZ
              value: UTC
            {{- if and $.spec.recovery.enabled $.spec.recovery.restore.enabled }}
            - name: GATEWAY_RESTORE_DISABLED
              value: false
            {{- end }}
            {{- if $.spec.extraEnv }}
            {{- toYaml $.spec.extraEnv | nindent 12 }}
            {{- end }}
          args:
            - -n {{ camelcase $.context.name }}
            - -m {{ $.spec.memory.max | default 512 }}
            {{- if $.spec.debug }}
            - -d
            {{- end }}
            {{- if and $.spec.recovery.enabled $.spec.recovery.restore.enabled }}
            - -r {{ printf "%s/%s" $.spec.recovery.volume.mountPath $.spec.recovery.restore.path }}
            {{- end }}
            - -- 
            - wrapper.java.initmemory={{ $.spec.memory.min | default 256 }} 
            {{- if $.spec.unsignedModules }}
            - -Dignition.allowunsignedmodules=false 
            {{- end }}
            {{- with $.spec.extraArgs }}
            {{- toYaml $.spec.extraArgs | nindent 12 }}
            {{- end }}
          ports:
            - name: {{ $.root.Values.service.portName | default "http-web" }}
              containerPort: {{ $.root.Values.service.targetPort | default 8088 }}
              protocol: TCP
            {{- if $.spec.debug }}
            - name: debug
              containerPort: 8000
              protocol: TCP
            {{- end }}
          livenessProbe:
            {{- toYaml $.spec.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml $.spec.readinessProbe | nindent 12 }}
          {{- with $.spec.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: gateway-password
              mountPath: /run/secrets/
            {{- if and $.spec.recovery.enabled }}
            - name: {{ $.spec.recovery.volume.name }}
              mountPath: {{ $.spec.recovery.volume.mountPath }}
            {{- end }}
            {{- range $.spec.extraSecretMounts }}
            - name: {{ .name }}
              mountPath: {{ .mountPath }}
              subPath: {{ .subPath }}
              readOnly: {{ .readOnly }}
            {{- end }}
            {{- range $.spec.extraVolumeMounts }}
            - name: {{ .name }}
              mountPath: {{ .mountPath }}
              subPath: {{ .subPath }}
              readOnly: {{ .readOnly }}
            {{- end }}
      volumes:
        - name: gateway-password
          secret:
            secretName: {{ $.spec.adminSecret }}
            items:
              - key: password
                path: gateway-password
        {{- if and $.spec.recovery.enabled }}
        - name: {{ $.spec.recovery.volume.name }}
          persistentVolumeClaim:
            claimName: {{ $.spec.recovery.volume.name }}
        {{- end }}
        {{- range $.spec.extraSecretMounts }}
        - name: {{ .name }}
          secret:
            secretName: {{ .secretName }}
            {{- with .optional }}
            optional: {{ . }}
            {{- end }}
        {{- end }}
        {{- range $.spec.extraVolumeMounts }}
        - name: {{ .name }}
          persistentVolumeClaim:
            claimName: {{ .claimName }}
        {{- end }}
  {{- if $.spec.persistence.enabled }}
  volumeClaimTemplates:
    - metadata:
        name: storage
      spec:
        accessModes:
          {{- toYaml $.spec.persistence.accessModes | nindent 10 }}
        resources:
          requests:
            storage: {{ $.spec.persistence.size }}
      {{- if $.spec.persistence.storageClass }}
      {{- if (eq "-" $.spec.persistence.storageClass) }}
        storageClassName: ""
      {{- else }}
        storageClassName: {{ $.spec.persistence.storageClass }}
      {{- end }}
      {{- end }}
  {{- else }}
        - name: storage
          emptyDir: {}
  {{- end }}
{{- end }}
{{- end }}
