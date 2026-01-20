#!/bin/bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=$(echo "${NAME:-desconhecido}")
fi
echo "Distribuição detectada: ${DISTRO:-indetectável}"

echo "Infelizmente este instalador não é compatível com a versão em AppImage do Inkscape, pois não tem um repositório centralizado."

inst_ppa() {
    echo "Você quer instalar a versão de desenvolvimento [digite 'trunk'] ou a estável [digite 'stable'] (recomendada) do Inkscape?"
    read version
    if [ "$version" = "stable" ]; then
        echo "Adicionando repositório PPA do Inkscape..."
        sudo add-apt-repository -y ppa:inkscape.dev/$version
        echo "Atualizando repositórios..."
        sudo apt update
        echo "Instalando o Inkscape..."
        sudo apt install inkscape -y
        echo "Instalação finalizada!"
        exit 0
    elif [ "$version" = "trunk" ]; then
        echo "Adicionando repositório PPA do Inkscape..."
        sudo add-apt-repository -y ppa:inkscape.dev/$version
        echo "Atualizando repositórios..."
        sudo apt update
        echo "Instalando o Inkscape..."
        sudo apt install inkscape-trunk -y
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Erro: digite 'stable' ou 'trunk'."
        return 1
    fi
}

inst_flatpak() {
    echo "A versão em Flatpak só tem suporte a versão estável."
    echo "É necessário ter o Flatpak instalado com o repositório Flathub."
    echo "Instalando o Inkscape..."
    flatpak install --user -y flathub org.inkscape.Inkscape
    echo "Instalação finalizada!"
    exit 0
}

inst_snap() {
    echo "É necessário ter o Snap instalado para que o script funcione."
    echo "Você quer instalar a versão de desenvolvimento [digite 'edge'] ou a estável [digite 'stable'] (recomendada) do Inkscape?"
    read version
    if [ "$version" = "stable" ]; then
        echo "Instalando o Inkscape..."
        sudo snap install inkscape
        echo "Instalação finalizada!"
        exit 0
    elif [ "$version" = "edge" ]; then
        echo "Instalando o Inkscape..."
        sudo snap install inkscape --edge
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Erro: digite 'stable' ou 'edge'."
        return 1
    fi
}

case "$DISTRO" in
    ubuntu|zorin|mint|elementary|pop)
        echo "Você quer instalar a versão em Flatpak [digite 'flatpak'], a versão em Snap [digite 'snapd'] ou a versão em PPA [digite 'ppa'] do Inkscape?"
        read inst_version
        if [ "$inst_version" = "flatpak" ]; then
            inst_flatpak
        elif [ "$version" = "snap" ]; then
            inst_snap
        elif [ "$version" = "ppa" ]; then
            inst_ppa
        else
            echo "Erro: digite 'flatpak', 'snap' ou 'ppa'."
            exit 1
        fi ;;
    *)
        echo "Você quer instalar a versão em Flatpak [digite 'flatpak'] ou a versão em Snap [digite 'snapd'] do Inkscape?"
        read inst_version
        if [ "$inst_version" = "flatpak" ]; then
            inst_flatpak
        elif [ "$version" = "snap" ]; then
            inst_snap
        else
            echo "Erro: digite 'flatpak' ou 'snap'."
            exit 1
        fi ;;
esac
