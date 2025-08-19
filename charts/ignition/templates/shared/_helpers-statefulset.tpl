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
  - https://github.com/thirdgen88/icc2023-ignition-k8s/blob/main/base/frontend-statefulset.yml
  - https://forum.inductiveautomation.com/t/kubernetes-persistentvolume-backup-data/41306/11
  - https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
  - https://github.com/grafana/loki/blob/main/production/helm/loki/templates/backend/statefulset-backend.yaml
  - https://github.com/prometheus-community/helm-charts/blob/main/charts/alertmanager/templates/statefulset.yaml

*/}}

{{- define "ignition.shared.statefulset" }}
{{- if .root.Values.enabled }}

{{ $strippedPSC := $.spec.podSecurityContext }}
{{ $_ := unset $strippedPSC "runAsNonRoot" }}
{{ $_ := unset $strippedPSC "runAsUser" }}
{{ $_ := unset $strippedPSC "runAsGroup" }}

{{- $license_keys:= list }}
{{- $license_tokens:= list }}
{{- range $l := $.context.licenses }}
   {{- $license_keys = append $license_keys $l.key }}
   {{- $license_tokens = append $license_tokens $l.token }}
{{- end }}

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
      {{- with $.spec.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      initContainers:
        - name: preconfigure
          image: "{{ $.spec.image.repository }}:{{ $.spec.image.tag | default $.root.Chart.AppVersion }}"
          command:
            - /config/scripts/invoke-args.sh
          args:
            - /config/scripts/seed-data-volume.sh
            - /config/scripts/seed-redundancy.sh
            - /config/scripts/prepare-gan-certificates.sh
            - cp /config/files/logback.xml /data/logback.xml
          volumeMounts:
          - mountPath: /data
            name: storage
          - mountPath: /config/scripts
            name: ignition-config-scripts
          - mountPath: /config/files
            name: ignition-config-files
          - mountPath: /run/secrets/gan-tls
            name: gan-tls
          - mountPath: /run/secrets/ignition-gan-ca
            name: ignition-gan-ca
            readOnly: true
        {{- with $.spec.initContainers }}
          {{- toYaml . | nindent 8 }}
        {{- end }}
      containers:
        - name: {{ $.root.Chart.Name }}
          image: "{{ $.spec.image.repository }}:{{ $.spec.image.tag | default $.root.Chart.AppVersion }}"
          imagePullPolicy: {{ $.spec.image.pullPolicy }}
          {{- with $.spec.containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP

            {{- /* Accept the EULA or not */}}
            - name: ACCEPT_IGNITION_EULA
              value: {{ $.root.Values.acceptEula | ternary "Y" "N" | quote }}

            {{- /* Disable quick start - default to false */}}
            - name: DISABLE_QUICKSTART
              value: {{ $.root.Values.disableQuickstart | default false | quote }}

            {{- /* Gateway admin user and pass */}}
            - name: GATEWAY_ADMIN_USERNAME
              valueFrom:
                secretKeyRef:
                  name: {{ $.spec.adminSecret }}
                  key: username
            - name: GATEWAY_ADMIN_PASSWORD_FILE
              value: /run/secrets/ignition/gateway-password

            {{- /* Gateway port(s) */}}
            - name: GATEWAY_HTTP_PORT
              value: {{ $.root.Values.service.targetPortHttp | default 8088 | quote }}
            - name: GATEWAY_HTTPS_PORT
              value: {{ $.root.Values.service.targetPortHttps | default 8043 | quote }}
            - name: GATEWAY_GAN_PORT
              value: {{ $.root.Values.service.targetPortGan | default 8060 | quote }}

            {{- /* Gateway Modules Enabled / Disabled */}}
            {{- if or $.context.modules $.spec.modules }}
            - name: GATEWAY_MODULES_ENABLED
              value: {{ $.context.modules | default $.spec.modules | join "," | quote }}
            {{- end }}

            {{- /* Gateway Restore Disabled */}}
            {{- if and $.spec.recovery.enabled $.spec.recovery.restore.enabled }}
            - name: GATEWAY_RESTORE_DISABLED
              value: "false"
            {{- end }}

            {{- /* Edition - defaulting to standard */}}
            - name: IGNITION_EDITION
              value: {{ $.root.Values.edition | default "standard" | quote }}

            {{- /* UID and GID to step down to */}}
            {{- if $.spec.podSecurityContext.runAsNonRoot }}
            - name: IGNITION_GID
              value: {{ $.spec.podSecurityContext.runAsGroup | default 2003 | quote }}
            - name: IGNITION_UID
              value: {{ $.spec.podSecurityContext.runAsUser | default 2003 | quote }}
            {{- end }}

            {{- /* License key(s) and tokens */}}
            {{- with $license_keys }}
            - name: IGNITION_LICENSE_KEY
              value: {{ $license_keys | join "," | quote }}
            {{- end }}
            {{- with $license_tokens }}
            - name: IGNITION_ACTIVATION_TOKEN
              value: {{ $license_tokens | join "," | quote }}
            {{- end }}

            {{- /* Timezone */}}
            - name: TZ
              value: "UTC"

            {{- if $.spec.extraEnv }}
            {{- toYaml $.spec.extraEnv | nindent 12 }}
            {{- end }}
          args:
            - -n{{ camelcase $.context.name }}
            - -m{{ $.spec.memory.max | default 512 }}
            {{- if $.root.Values.debug }}
            - -d
            {{- end }}
            {{- if and $.spec.recovery.enabled $.spec.recovery.restore.enabled }}
            - -r {{ printf "%s/%s" $.spec.recovery.volume.mountPath $.spec.recovery.restore.path }}
            {{- end }}
            - -- 
            - gateway.useProxyForwardedHeader=true
            - wrapper.java.initmemory={{ $.spec.memory.min | default 256 }} 
            {{- if $.spec.unsignedModules }}
            - -Dignition.allowunsignedmodules=false 
            {{- end }}
            {{- with $.spec.extraArgs }}
            {{- toYaml $.spec.extraArgs | nindent 12 }}
            {{- end }}

          ports:
            - name: {{ $.root.Values.service.portNameHttp | default "http" }}
              containerPort: {{ $.root.Values.service.portHttp | default 8088 }}
              protocol: TCP
            - name: {{ $.root.Values.service.portNameHttps | default "https" }}
              containerPort: {{ $.root.Values.service.portHttps | default 8043 }}
              protocol: TCP
            - name: {{ $.root.Values.service.portNameGan | default "gan" }}
              containerPort: {{ $.root.Values.service.portGan | default 8060 }}
              protocol: TCP
            {{- if $.root.Values.debug }}
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
            {{- /* Secretes get mounted RO. Don't use /run/secrets because it will cause other issues
                 https://github.com/kubernetes/kubernetes/issues/65835#issuecomment-577681140 
            */}}
            - name: gateway-password
              mountPath: /run/secrets/ignition/
            {{- if and $.spec.persistence.enabled }}
            - name: storage
              mountPath: /usr/local/bin/ignition/data
            {{- end }}
            {{- if and $.spec.recovery.enabled }}
            - name: {{ $.spec.recovery.volume.name | default "backup" }}
              mountPath: {{ $.spec.recovery.volume.mountPath | default "/backup" }}
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
        - name: ignition-config-scripts
          configMap:
            name: ignition-config-scripts
            defaultMode: 0755
        - name: ignition-config-files
          configMap:
            name: ignition-config-files
            defaultMode: 0644
        - name: ignition-gan-ca
          secret:
            secretName: ignition-gan-ca
        - name: gan-tls
          secret:
            secretName: ignition-gan-tls
        {{- if and $.spec.recovery.enabled (not $.spec.recovery.create) }}
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
  {{- if or $.spec.persistence.enabled (and $.spec.recovery.enabled $.spec.recovery.create) }}
  volumeClaimTemplates:
    {{- if $.spec.persistence.enabled }}
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
    {{- if and $.spec.recovery.enabled $.spec.recovery.create }}
    - metadata:
        name: backup
      spec:
        accessModes:
          {{- toYaml $.spec.recovery.accessModes | nindent 10 }}
        resources:
          requests:
            storage: {{ $.spec.recovery.size }}
      {{- if $.spec.recovery.storageClass }}
      {{- if (eq "-" $.spec.recovery.storageClass) }}
        storageClassName: ""
      {{- else }}
        storageClassName: {{ $.spec.recovery.storageClass }}
      {{- end }}
      {{- end }}
    {{- else }}
        - name: backup
          emptyDir: {}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
