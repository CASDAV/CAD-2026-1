#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa sudo."
  exit 1
fi

dnf config-manager --set-enabled crb
dnf -y install epel-release wget

#Instalacion de condor e inicializacion del servicio
sudo dnf install -y https://research.cs.wisc.edu/htcondor/repo/24.x/htcondor-release-current.el9.noarch.rpm
sudo -y dnf install condor
systemctl enable condor
systemctl start condor
systemctl status condor


CONFIG_FILE="/etc/condor/condor_config"
NEW_VALUE="/nfs/condor/condor_config.cluster"


# Verificar que el archivo exista
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE no existe."
    exit 1
fi

# Hacer backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Reemplazar la línea (aunque esté comentada)
sed -i "s|^#\?LOCAL_CONFIG_FILE.*|LOCAL_CONFIG_FILE = $NEW_VALUE|" "$CONFIG_FILE"

echo "Configuración actualizada en $CONFIG_FILE"

SECURITY_FILE="/etc/condor/config.d/00-security"

# Verificar que el archivo exista
if [ ! -f "$SECURITY_FILE" ]; then
    echo "Error: $SECURITY_FILE no existe."
    exit 1
fi

# Backup del archivo de seguridad
cp "$SECURITY_FILE" "${SECURITY_FILE}.bak"

# Descomentar la línea use security:host_based
sed -i 's|^#\s*\(use security:host_based\)|\1|' "$SECURITY_FILE"

echo "Línea 'use security:host_based' descomentada en $SECURITY_FILE"

condor_store_cred query -f /var/lib/condor/condor_credential