#!/bin/bash

while getopts "f:" opt; do
    case $opt in
        f) archivo="$OPTARG";;
        *) echo "Uso: $0 -f archivo"
           exit 1;;
    esac
done

if [ -z "$archivo" ]; then
    echo "Debes indicar el archivo con -f"
    exit 1
fi

if [ ! -f "$archivo" ]; then
    echo "El archivo no existe"
    exit 1
fi

BASE_DIR="/nfs/condor"

# Verificar que la ruta base exista
if [ ! -d "$BASE_DIR" ]; then
    echo "El directorio $BASE_DIR no existe"
    exit 1
fi

while IFS=: read -r usuario uid; do

    [ -z "$usuario" ] && continue

    if ! id "$usuario" &>/dev/null; then
        echo "El usuario $usuario no existe en el sistema, se omite"
        continue
    fi

    USER_DIR="$BASE_DIR/$usuario"

    if [ -d "$USER_DIR" ]; then
        echo "El directorio $USER_DIR ya existe"
    else
        mkdir "$USER_DIR"
        echo "Directorio creado: $USER_DIR"
    fi

    # Asignar owner y grupo
    chown "$usuario:$usuario" "$USER_DIR"

    # Permisos: solo el usuario puede acceder
    chmod 700 "$USER_DIR"

    echo "Permisos asignados correctamente a $usuario"

done < "$archivo"