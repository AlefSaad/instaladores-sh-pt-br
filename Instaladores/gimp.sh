#!/usr/bin/env bash
# Criado por Alef Saad

set -euo pipefail

echo "Estabelecendo variáveis..."

BASE_URL="https://download.gimp.org/gimp"

LATEST_SERIES=$(curl -fs "$BASE_URL/" \
  | grep -o 'v[0-9]\+\.[0-9]\+/' \
  | tr -d '/' \
  | sort -V \
  | tail -1)

ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH_MATCH="x86_64" ;;
  aarch64|arm64) ARCH_MATCH="aarch64" ;;
  *)
    echo "Arquitetura não suportada: $ARCH"
    exit 1
    ;;
esac

LINUX_DIR="$BASE_URL/$LATEST_SERIES/linux"

APPIMAGE=$(curl -fs "$LINUX_DIR/" \
  | grep -o "GIMP-[0-9.]*-$ARCH_MATCH.AppImage" \
  | sort -V \
  | tail -1)

if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

appimage() {
    echo "Em qual pasta você quer colocar o seu AppImage?"
    read folder
    echo "Baixando AppImage..."
    wget -O gimp.AppImage "$APPIMAGE" -C "$folder"
    echo "Dando permissões necessário ao AppImage..."
    chmod +x "$folder/gimp.AppImage"
    echo "AppImage instalado em $folder/gimp.AppImage. Integre-o ao sistema manualmente, o Gear Lever é ótimo para isso."
    return 0
}

inst_flatpak() {
    echo "Instalando o Flatpak do GIMP..."
    flatpak install flathub -y org.gimp.GIMP
    photogimp_inst() {
        read -p "Você gostaria de instalar o PhotoGIMP? (s/n)" photogimp_boolean
        photogimp_boolean=$(echo "${photogimp_boolean}" | tr ':upper:' ':lower:' )
        if [ "$photogimp_boolean" = "s" ] || [ -z "$photogimp_boolean" ]; then
            echo "Baixando os arquivos do PhotoGIMP..."
            wget https://github.com/Diolinux/PhotoGIMP/releases/download/latest/PhotoGIMP-linux.zip
            echo "Desempacotando o arquivo .zip do PhotoGIMP..."
            unzip PhotoGIMP-linux.zip
            echo "Enviando os arquivos para os lugares certos..."
            mv -f ./PhotoGIMP-linux/.config $HOME
            mv -f ./PhotoGIMP-linux/.local $HOME
        elif [ "$photogimp_boolean" = "n" ]; then
            return 0
        else
            photogimp_inst
        fi
    }
    photogimp_inst
    echo "Instalação finalizada!"
    exit 0
}

inst_snap() {
    echo "Instalando o GIMP pelo Snap..."
    snap install gimp
    echo "Instalação finalizada!"
    exit 0
}

echo "Você gostaria de instalar o GIMP pelo Flatpak (digite 'flatpak') [A instalação pelo Flatpak também pode instalar o PhotoGIMP], pelo Snap (digite 'snapd') ou pelo AppImage (digite 'appimage')?"
read inst_method
if [ "$inst_method" = "flatpak" ]; then
    inst_flatpak
elif [ "$inst_method" = "snapd" ]; then
    inst_snap
elif [ "$inst_method" = "appimage" ]; then
    appimage
else
    echo "Erro: digite 'flatpak', 'snap' ou 'appimage'."
    exit 1
fi
