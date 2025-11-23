#!/usr/bin/env bash
# Criado por Alef Saad
# Dependências: flatpak, snapd, wget

set -euo pipefail

# Verificação de arquitetura — Brave é apenas x86_64/amd64
ARCH=$(uname -m)

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
    echo "❌ Esta máquina usa arquitetura '$ARCH'."
    echo "O OnlyOffice só fornece pacotes oficiais para x86_64 (amd64)."
    echo "Instalação abortada."
    exit 1
fi

# Detectar distribuição
DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
    VER=${VERSION_ID%%.*}
fi
echo "📦 Distribuição detectada: ${DISTRO:-indetectável}"

# Ele requer sudo para utilizar gerenciadores de pacotes.
if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

deb() {
    echo "Baixando o pacote .deb do site oficial do OnlyOffice..."
    wget "https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors_amd64.deb"
    echo "Instalando o pacote Debian..."
    sudo dpkg -i onlyoffice-desktopeditors_amd64.deb || sudo apt -f install -y
    echo "Removendo o pacote Debian..."
    rm ./onlyoffice-desktopeditors_amd64.deb
    echo "Instalação finalizada!"
    exit 0
}

rpm() {
    echo "Baixando o pacote .rpm do site oficial do OnlyOffice..."
    wget "https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm"
    echo "Instalando o pacote RPM..."
    sudo dnf install -y ./onlyoffice-desktopeditors.x86_64.rpm
    echo "Removendo o pacote RPM..."
    rm ./onlyoffice-desktopeditors.x86_64.rpm
    echo "Instalação finalizada!"
    exit 0
}

snapd() {
    echo "É necessário ter o snapd para esta instalação."
    echo "Instalando o pacote Snap..."
    sudo snap install onlyoffice-desktopeditors
    echo "Instalação finalizada!"
    exit 0
}

flatpak() {
    echo "É necessário é Flatpak com o repositório Flathub para esta instalação."
    echo "Instalando o pacote Flatpak..."
    flatpak install -y flathub org.onlyoffice.desktopeditors
    echo "Instalação finalizada!"
    exit 0
}

appimage() {
    FOLDER=$(pwd)
    echo "Baixando o AppImage do site oficial do OnlyOffice..."
    wget "https://github.com/ONLYOFFICE/appimage-desktopeditors/releases/latest/download/DesktopEditors-x86_64.AppImage"
    echo "Dando permissões de execução ao AppImage..."
    chmod +x ./DesktopEditors-x86_64.AppImage
    echo "AppImage instalado em $FOLDER. Caso queira integrá-lo ao sistema, considero que faça manualmente com um aplicativo Flatpak chamado Gear Lever."
}

case "$DISTRO" in
    ubuntu|debian|mint|pop|zorin|elementary)
        read -p "Você gostaria de instalar via pacote Debian (digite 'deb'), via Flatpak (digite 'flatpak'), via Snap (digite 'snapd') ou via AppImage (digite 'appimage')? " inst_method
        if [ "$inst_method" = "deb" ]; then
            deb
        elif [ "$inst_method" = "flatpak" ]; then
            flatpak
        elif [ "$inst_method" = "snapd" ]; then
            snapd
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'deb', 'flatpak', 'snapd' ou 'appimage'."
            exit 1
        fi
        ;;
    fedora|rhel|centos|rocky|almalinux)
        read -p "Você gostaria de instalar via pacote RPM (digite 'rpm'), via Flatpak (digite 'flatpak'), via Snap (digite 'snapd') ou via AppImage (digite 'appimage')? " inst_method
        if [ "$inst_method" = "rpm" ]; then
            rpm
        elif [ "$inst_method" = "flatpak" ]; then
            flatpak
        elif [ "$inst_method" = "snapd" ]; then
            snapd
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'rpm', 'flatpak', 'snapd' ou 'appimage'."
            exit 1
        fi
        ;;
    *)
        if [ "$DISTRO" = "manjaro" ]; then
            echo "No Manjaro, o ONLYOFFICE DesktopEditors está disponível no Pamac. É recomendável que você instale por lá."
        fi
        read -p "Você gostaria de instalar via Flatpak (digite 'flatpak'), via Snap (digite 'snapd') ou via AppImage (digite 'appimage')? " inst_method
        if [ "$inst_method" = "flatpak" ]; then
            flatpak
        elif [ "$inst_method" = "snapd" ]; then
            snapd
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'flatpak', 'snapd' ou 'appimage'."
            exit 1
        fi
        ;;
esac
