#!/usr/bin/env bash
# Criado por Alef Saad

set -euo pipefail

echo "Definindo arquitetura do computador..."

ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64)   ARCH_DL="x86_64" ;;
    aarch64|arm64)  ARCH_DL="aarch64" ;;
    *) echo "Arquitetura não suportada: $ARCH"; exit 1 ;;
esac

echo "Detectando distribuição..."
DISTRO="desconhecida"
VERSION_ID=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi
echo "📦 Distribuição detectada: ${NAME:-indetectável}"

echo "Definindo variáveis..."

API=https://api.github.com/repos/cryptomator/cryptomator/releases/latest

appimage() {
    echo "Baixando o appimage para a sua arquitetura..."
    echo "Estabelecendo variáveis..."
    ASSET=$(curl -s "$API" | grep browser_download_url | grep "$ARCH_DL" | grep '\.AppImage' | cut -d '"' -f 4)
    if [ -z "$ASSET" ]; then
        echo "Erro: não foi encontrado o link para download."
        exit 1
    fi
    echo "Baixando o AppImage do Cryptomator..."
    wget -O cryptomator.AppImage "$ASSET"
    echo "Dando permissões de execução ao AppImage..."
    chmod +x cryptomator.AppImage
    echo "AppImage instalado na pasta $(pwd). Para integrá-lo ao sistema, faça manualmente. Recomendo o uso do app Gear Lever."
    return 0
}

inst_flatpak() {
    echo "O Flatpak deve ser instalado com o repositório Flathub para que o script funcione."
    echo "Instalado o Flatpak do Cryptomator..."
    flatpak install flathub -y org.cryptomator.Cryptomator
    echo "Instalação finalizada!"
    exit 0
}

inst_ppa() {
    echo "Instalando a dependência software-properties-common..."
    sudo apt install software-properties-common -y
    echo "Baixando repostório PPA do Cryptomator..."
    sudo apt-add-repository ppa:sebastian-stenzel/cryptomator
    echo "Atualizando repositórios..."
    sudo apt update
    echo "Instalando o Cryptomator..."
    sudo apt install cryptomator -y
    echo "Instalação finalizada!"
    exit 0
}

inst_aur() {
    echo "Qual pacote você quer utilizar? O baseado em AppImage (cryptomator-bin) (digite 'bin') ou o baseado em código-fonte (cryptomator) (digite 'source')?"
    read inst_def
    if [ "$inst_def" = "bin" ]; then
        echo "Este script suporta os seguintes AUR helpers: Yay, Paru e Pikaur. Se nenhum dos dois estiverem presentes no seu sistema, o pacote AUR será compilado manualmente."
        user=$(logname)
        if command -v yay >/dev/null 2>&1; then
            echo "Instalando o pacote via YAY..."
            sudo -u "$user" yay -S --noconfirm cryptomator-bin
            echo "Instalação finalizada!"
            exit 0
        elif command -v paru >/dev/null 2>&1; then
            echo "Instalando o pacote via Paru..."
            sudo -u "$user" paru -S --noconfirm cryptomator-bin
            echo "Instalação finalizada!"
            exit 0
        elif command -v pikaur >/dev/null 2>&1; then
            echo "Instalando o pacote via Paru..."
            sudo -u "$user" pikaur -S --noconfirm cryptomator-bin
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Aonde você quer clonar o repositório Git do AUR?"
            read folder
            cd $folder
            echo "Clonando repositório Git do AUR..."
            git clone https://aur.archlinux.org/cryptomator-bin.git
            cd "./cryptomator-bin"
            makepkg -si
            echo "Instalação finalizada! Caso queira atualizar, a pasta é $folder/minecraft-launcher."
            return 0
        fi
    elif [ "$inst_def" = "source" ]; then
        echo "Este script suporta os seguintes AUR helpers: Yay, Paru e Pikaur. Se nenhum dos dois estiverem presentes no seu sistema, o pacote AUR será compilado manualmente."
        user=$(logname)
        if command -v yay >/dev/null 2>&1; then
            echo "Instalando o pacote via YAY..."
            sudo -u "$user" yay -S --noconfirm cryptomator
            echo "Instalação finalizada!"
            exit 0
        elif command -v paru >/dev/null 2>&1; then
            echo "Instalando o pacote via Paru..."
            sudo -u "$user" paru -S --noconfirm cryptomator
            echo "Instalação finalizada!"
            exit 0
        elif command -v pikaur >/dev/null 2>&1; then
            echo "Instalando o pacote via Paru..."
            sudo -u "$user" pikaur -S --noconfirm cryptomator
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Aonde você quer clonar o repositório Git do AUR?"
            read folder
            cd $folder
            echo "Clonando repositório Git do AUR..."
            git clone https://aur.archlinux.org/cryptomator.git
            cd "./cryptomator"
            makepkg -si
            echo "Instalação finalizada! Caso queira atualizar, a pasta é $folder/cryptomator."
            return 0
        fi
    else
        echo "Erro: prompt inválido. Digite 'bin' ou 'source'."
    fi
}

inst_nix() {
    if command -v nix >/dev/null 2>&1; then
        echo "Instalando o pacote Nix do Cryptomator..."
        nix profile install nixpkgs#cryptomator
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Erro: o Nix package manager não está disponível."
        return 2
    fi
}

case "$DISTRO" in
    arch|manjaro|endeavouros)
        echo "Você gostaria de instalar pelo AUR (digite 'aur'), pelo Nix (digite 'nix'), pelo AppImage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')?"
        read inst_method
        if [ "$inst_method" = "aur" ]; then
            inst_aur
        elif [ "$inst_method" = "nix" ]; then
            inst_nix
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        elif [ "$inst_method" = "flatpak" ]; then
            inst_flatpak
        else
            echo "Erro: prompt inválido. Digite 'aur', 'nix', 'appimage' ou 'flatpak'."
        fi ;;
    debian|ubuntu|mint|elementary|zorin|pop)
        echo "Você gostaria de instalar pelo PPA (digite 'ppa'), pelo Nix (digite 'nix'), pelo AppImage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')?"
        read inst_method
        if [ "$inst_method" = "ppa" ]; then
            inst_ppa
        elif [ "$inst_method" = "nix" ]; then
            inst_nix
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        elif [ "$inst_method" = "flatpak" ]; then
            inst_flatpak
        else
            echo "Erro: prompt inválido. Digite 'ppa', 'nix', 'appimage' ou 'flatpak'."
        fi ;;
    *)
        echo "Você gostaria de instalar pelo Nix (digite 'nix'), pelo AppImage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')?"
        read inst_method
        if [ "$inst_method" = "nix" ]; then
            inst_nix
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        elif [ "$inst_method" = "flatpak" ]; then
            inst_flatpak
        else
            echo "Erro: prompt inválido. Digite 'nix', 'appimage' ou 'flatpak'."
        fi ;;
esac
