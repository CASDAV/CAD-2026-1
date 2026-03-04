#!/bin/bash

asignar_password=false

while getopts "f:p" opt; do
    case $opt in
        f) archivo="$OPTARG";;
        p) asignar_password=true;;
        *) echo "Uso: $0 -f archivo [-p]"
           exit 1;;
    esac
done

# Validaciones iniciales
if [ -z "$archivo" ]; then
    echo "Debes indicar el archivo con -f"
    exit 1
fi

if [ ! -f "$archivo" ]; then
    echo "El archivo no existe"
    exit 1
fi

# Leer archivo
while IFS=: read -r usuario uid; do

    # Saltar líneas vacías
    [ -z "$usuario" ] && continue

    # Validar que venga UID
    if [ -z "$uid" ]; then
        echo "Formato inválido en línea: $usuario"
        continue
    fi

    # Validar si usuario ya existe
    if id "$usuario" &>/dev/null; then
        echo "Usuario $usuario ya existe, se omite"
        continue
    fi

    # Validar si UID ya existe
    if getent passwd "$uid" &>/dev/null; then
        echo "UID $uid ya está en uso, se omite $usuario"
        continue
    fi

    # Crear usuario con UID específico
    useradd -u "$uid" -m "$usuario"
    echo "Usuario $usuario creado con UID $uid"

    # Asignar contraseña si se pasa -p
    if $asignar_password; then
        echo "Asignando contraseña para $usuario"
        passwd "$usuario" < /dev/tty
    fi

done < "$archivo"