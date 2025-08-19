#!/usr/bin/bash

kubectl create configmap ignition-config-scripts \
  --from-file=charts/ignition/files/scripts/seed-data-volume.sh \
  --from-file=charts/ignition/files/scripts/seed-redundancy.sh \
  --from-file=charts/ignition/files/scripts/prepare-gan-certificates.sh \
  --from-file=charts/ignition/files/scripts/prepare-tls-certificates.sh \
  --from-file=charts/ignition/files/scripts/invoke-args.sh \
  --from-file=charts/ignition/files/scripts/redundant-health-check.sh \
  --dry-run=client -o yaml > charts/ignition/templates/ignition-config-scripts.yaml

kubectl create configmap ignition-config-files \
  --from-file=charts/ignition/files/config/redundancy-primary.xml \
  --from-file=charts/ignition/files/config/redundancy-backup.xml \
  --from-file=charts/ignition/files/config/logback.xml \
  --dry-run=client -o yaml > charts/ignition/templates/ignition-config-files.yaml

  kubectl create configmap gateway-base-config \
  --from-file=charts/ignition/files/config/gateway-base-config.env \
  --dry-run=client -o yaml > charts/ignition/templates/gateway-base-config.yaml
  