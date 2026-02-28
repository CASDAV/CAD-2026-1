#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa sudo."
  exit 1
fi

activar_nfs=false

while getopts "n:f" opt; do
    case $opt in
        n) nombre="$OPTARG";;
        f) activar_nfs=true;;
        *) echo "Argumento no soportado"
           exit 1;;
    esac
done

# Validar que se haya pasado el nombre
if [ -z "$nombre" ]; then
    echo "Debes especificar el nombre del host con -n"
    exit 1
fi

# Cambio de nombre del host
hostnamectl set-hostname "$nombre"

# Actualización de paquetes
dnf -y update --refresh
dnf -y install chrony nfs-utils nano vim

# Verificar si firewalld está activo
if [ "$(systemctl is-active firewalld)" = "active" ]; then
  echo "Firewalld está activo ➜ deshabilitando ahora..."
  systemctl disable firewalld --now
  echo "Firewalld deshabilitado."
else
  echo "Firewalld no está activo."
fi

CONFIG_FILE="/etc/selinux/config"

# Hacer una copia de seguridad
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Cambiar a disabled
sed -i 's/^SELINUX=.*/SELINUX=disabled/' "$CONFIG_FILE"

echo "Configuración actualizada en $CONFIG_FILE"
echo "Necesitas reiniciar para aplicar la desactivación permanente."

systemctl enable --now chronyd
chronyc sources
chronyc tracking

# Activar NFS solo si se pasó la flag
if [ "$activar_nfs" = true ]; then
    echo "Activando servicio NFS..."
    systemctl enable --now nfs-server
    echo "NFS activado."
else
    echo "Flag -f no especificada ➜ NFS no será activado."
fi

echo "El sistema se reiniciará en 10 segundos..."
sleep 10
reboot