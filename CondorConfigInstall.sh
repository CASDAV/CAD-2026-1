#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa sudo."
  exit 1
fi

dnf config-manager --set-enabled crb
dnf -y install epel-release wget

#Instalacion de condor e inicializacion del servicio
dnf install -y https://research.cs.wisc.edu/htcondor/repo/24.x/htcondor-release-current.el9.noarch.rpm
dnf install -y condor
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

# Hacer backup antes de modificar
cp "$SECURITY_FILE" "${SECURITY_FILE}.bak"

echo "Backup creado en ${SECURITY_FILE}.bak"

# Procesar archivo
while IFS= read -r linea; do
    # Quitar espacios iniciales para comparar
    linea_trim=$(echo "$linea" | sed 's/^[[:space:]]*//')
    if [[ "$linea_trim" == "use security:host_based" ]] || \
       [[ "$linea_trim" == "#use security:host_based" ]]; then
        echo "use security:host_based"
    else
        if [[ -z "$linea_trim" ]]; then
            echo ""
        else
            if [[ "$linea_trim" == \#* ]]; then
                echo "$linea"
            else
                echo "#$linea"
            fi
        fi
    fi
    
done < "$SECURITY_FILE" > "${SECURITY_FILE}.tmp"

# Reemplazar archivo original
mv "${SECURITY_FILE}.tmp" "$SECURITY_FILE"

echo "Configuración actualizada correctamente."

condor_store_cred query -f /var/lib/condor/condor_credential

echo "Reiniciando el servicio condor"

systemctl restart condor

echo "el servicio condor se ha reiniciado, espere a que se valide el status"
sleep 5

systemctl status condor --no-pager