#!/usr/bin/env bash
set -eo pipefail

if [[ "${HOSTNAME}" =~ -([0-9])$ ]]; then
  case "${BASH_REMATCH[1]}" in
    0)
      echo "Initializing Redundancy as Primary"
      cp /config/files/redundancy-primary.xml /data/redundancy.xml
      sed -i "s/ign-backend-0\.ign-backend/$1/g" /data/redundancy.xml
      ;;
    1)
      echo "Initializing Redundancy as Backup"
      cp /config/files/redundancy-backup.xml /data/redundancy.xml
      sed -i "s/ign-backend-0\.ign-backend/$1/g" /data/redundancy.xml
      ;;
    *)
      echo "Unknown Redundancy Hostname Suffix: ${HOSTNAME}"
      ;;
  esac
fi