#!/usr/bin/env bash
# Criado por Alef Saad

set -euo pipefail

echo "Definindo arquitetura do computador..."

ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64)   ARCH_DL="x86_64" ;;
    aarch64|arm64)  ARCH_DL="arm64" ;;
    *) echo "Arquitetura não suportada: $ARCH"; exit 1 ;;
esac

echo "Estabelecendo variáveis..."

API=https://api.github.com/repos/dail8859/Deezer-Desktop/releases/latest

if [ "$ARCH_DL" = "x86_64" ]; then
    arch_dl_rpm="x86_64"
elif [ "$ARCH_DL" = "arm64" ]; then
    arch_dl_rpm="aarch64"
fi

if [ "$ARCH_DL" = "x86_64" ]; then
    arch_dl_deb="amd64"
elif [ "$ARCH_DL" = "arm64" ]; then
    arch_dl_deb="arm64"
fi

if [ "$ARCH_DL" = "x86_64" ]; then
    arch_dl_tar="x64"
elif [ "$ARCH_DL" = "arm64" ]; then
    arch_dl_tar="arm64"
fi


if [ "$ARCH_DL" = "x86_64" ]; then
    arch_dl_ai="x86_64"
elif [ "$ARCH_DL" = "arm64" ]; then
    arch_dl_ai="arm64"
fi

if [ "$ARCH_DL" = "x86_64" ]; then
    arch_dl_snap="amd64"
elif [ "$ARCH_DL" = "arm64" ]; then
    arch_dl_snap="arm64"
fi

tarxz() {
    echo "Estabelecendo variáveis..."
    ASSET=$(curl -s "$API" | grep browser_download_url | grep "$arch_dl_tar" | grep '\.tar\.xz$' | cut -d '"' -f 4)
    echo "Baixando o tar.xz do GitHub..."
    wget -O deezer-linux.tar.xz "$ASSET"
    DIR=$(tar -tf deezer-linux.tar.xz | head -1 | cut -d '/' -f 1)
    read -p "Em qual pasta você gostaria de extrair o arquivo tar.xz?" folder
    echo "Extraindo o arquivo..."
    tar -xvzf deezer-linux.tar.xz -C "$folder"
    echo "Removendo o tarball remanescente..."
    rm ./deezer-linux.tar.xz
    echo "Dando permissões necessárias..."
    chmod +x "$folder/$DIR/deezer-desktop"
    echo "O Deezer para Linux está extraído em $folder/$DIR. Para executá-lo, entre nessa pasta e execute o arquivo deezer-desktop."
    echo "Integre o Deezer ao sistema manualmente."
    return 0
}

deb() {
    echo "Estabelecendo variáveis..."
    ASSET=$(curl -s "$API" | grep browser_download_url | grep "$arch_dl_deb" | grep '\.deb$' | cut -d '"' -f 4)
    echo "Baixando o pacote Debian do GitHub..."
    wget -O deezer-linux.deb "$ASSET"
    echo "Instalando o pacote Debian..."
    sudo dpkg -i deezer-linux.deb || sudo apt -f install -y
    echo "Removendo o pacote remanescente..."
    rm ./deezer-linux.deb
    echo "Instalação finalizada!"
    exit 0
}

rpm_opensuse() {
    echo "Estabelecendo variáveis..."
    ASSET=$(curl -s "$API" | grep browser_download_url | grep "$arch_dl_rpm" | grep '\.rpm$' | cut -d '"' -f 4)
    echo "Baixando o pacote RPM do GitHub..."
    wget -O deezer-linux.rpm "$ASSET"
    echo "Instalando o pacote RPM..."
    sudo zypper -n install deezer-linux.rpm
    echo "Removendo o pacote remanescente..."
    rm ./deezer-linux.rpm
    echo "Instalação finalizada!"
    exit 0
}

rpm_fedora() {
    echo "Estabelecendo variáveis..."
    ASSET=$(curl -s "$API" | grep browser_download_url | grep "$arch_dl_rpm" | grep '\.rpm$' | cut -d '"' -f 4)
    echo "Baixando o pacote RPM do GitHub..."
    wget -O deezer-linux.rpm "$ASSET"
    echo "Instalando o pacote RPM..."
    sudo dnf install deezer-linux.rpm -y
    echo "Removendo o pacote remanescente..."
    rm ./deezer-linux.rpm
    echo "Instalação finalizada!"
    exit 0
}

snap_install() {
    if [ "$arch_dl_snap" = "amd64" ]; then
        echo "Estabelecendo variáveis..."
        ASSET=$(curl -s "$API" | grep browser_download_url | grep "amd64" | grep '\.snap$' | cut -d '"' -f 4)
        echo "Baixando o pacote Snap do GitHub..."
        wget -O deezer-linux.snap "$ASSET"
        echo "Instalando o pacote Snap..."
        sudo snap install --dangerous "./deezer-linux.snap"
        echo "Removendo o pacote remanescente..."
        rm ./deezer-linux.snap
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Arquitetura do processador não suportada pela instalação em Snap. Tente de outra forma."
        return 2
    fi
}

appimage() {
    echo "Estabelecendo variáveis..."
    ASSET=$(curl -s "$API" | grep browser_download_url | grep "$arch_dl_ai" | grep '\.AppImage$' | cut -d '"' -f 4)
    folder=$(pwd)
    echo "Baixando o AppImage do GitHub..."
    wget -O deezer-linux.AppImage "$ASSET"
    echo "Dando permissões ao AppImage..."
    chmod +x deezer-linux.AppImage
    echo "AppImage instalado em $folder. Integre ele ao sistema, de preferência com o Gear Lever."
    return 0
}

flatpak_inst() {
    echo "Instalando Deezer para Linux pelo Flatpak..."
    flatpak install -y flathub dev.aunetx.deezer
    echo "Instalação finalizada!"
    exit 0
}

# Detectar distribuição
DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi
echo "📦 Distribuição detectada: ${NAME:-indetectável}"

# Ele requer sudo para utilizar gerenciadores de pacotes.
if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

echo "Dependências do script: wget, tar e curl. Caso não estejam instalados, o script pode falhar."
echo "A instalação via Flatpak depende da instalação do flatpak para funcionar. A instalação via Snap depende da instalação do snapd para funcionar."

case "$DISTRO" in
    debian|ubuntu|pop|zorin|mint|elementary)
        echo "Você gostaria de instalar pelo .deb (digite 'deb'), pelo .tar.xz (digite 'tar'), pelo pacote Snap (digite 'snap') ou pelo Flatpak (digite 'flatpak')? "
        read inst_method
        if [ "$inst_method" = "deb" ]; then
            deb
        elif [ "$inst_method" = "tar" ]; then
            tarxz
        elif [ "$inst_method" = "snap" ]; then
            snap
        elif [ "$inst_method" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'deb', 'tar', 'snap', 'flatpak', ou 'appimage'."
        fi ;;
    opensuse*|suse)
        echo "Você gostaria de instalar pelo .rpm (digite 'rpm'), pelo .tar.xz (digite 'tar'), pelo pacote Snap (digite 'snap') ou pelo Flatpak (digite 'flatpak')? "
        read inst_method
        if [ "$inst_method" = "rpm" ]; then
            rpm_opensuse
        elif [ "$inst_method" = "tar" ]; then
            tarxz
        elif [ "$inst_method" = "snap" ]; then
            snap
        elif [ "$inst_method" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'rpm', 'tar', 'snap', 'flatpak', ou 'appimage'."
        fi ;;
    fedora|rhel|centos|rocky|almalinux)
        echo "Você gostaria de instalar pelo .rpm (digite 'rpm'), pelo .tar.xz (digite 'tar'), pelo pacote Snap (digite 'snap'), pelo Flatpak (digite 'flatpak') ou pelo AppImage (digite 'appimage')? "
        read inst_method
        if [ "$inst_method" = "rpm" ]; then
            rpm_fedora
        elif [ "$inst_method" = "tar" ]; then
            tarxz
        elif [ "$inst_method" = "snap" ]; then
            snap
        elif [ "$inst_method" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'rpm', 'tar', 'snap', 'flatpak', ou 'appimage'."
        fi ;;
    *)
        echo "Você gostaria de instalar pelo .tar.xz (digite 'tar'), pelo pacote Snap (digite 'snap'), pelo Flatpak (digite 'flatpak') ou pelo AppImage (digite 'appimage')? "
        read inst_method
        if [ "$inst_method" = "tar" ]; then
            tarxz
        elif [ "$inst_method" = "snap" ]; then
            snap
        elif [ "$inst_method" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        else
            echo "Erro: digite 'tar', 'snap', 'flatpak', ou 'appimage'."
        fi ;;
esac

