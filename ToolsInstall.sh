#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa sudo."
  exit 1
fi

dnf groupinstall -y "Development Tools"
dnf -y install gfortran g++ zlib zlib-devel gsl gsl-devel blas boost git dnf-utils ntfs-3g hfsplus-tools squashfs-tools hfsplus-tools readline-devel libX11-devel libXt-devel bzip2 bzip2-devel xz-devel pcre2-devel libcurl-devel openssl-devel

