#!/usr/bin/env bash
# Criado por Alef Saad

set -euo pipefail

echo "Para a instalação do PPA, será instalada a dependência curl."

# Detectar distribuição
DISTRO="desconhecida"
VERSION_ID=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi
echo "📦 Distribuição detectada: ${NAME:-indetectável}"

# Estabelecendo funções

ppa() {
    echo "Instalando dependências..."
    sudo apt install curl -y
    echo "Baixando o repositório PPA do Spotify..."
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    echo "Baixando e instalando o Spotify..."
    sudo apt-get update && sudo apt-get install spotify-client -y
    echo "Instalação finalizada!"
    exit 0
}

flatpak() {
    echo "Certifique-se de ter o Flatpak instalado no seu computador."
    echo "Instalando o Spotify (não oficial) em Flatpak..."
    flatpak install  -y flathub com.spotify.Client
    echo "Instalação finalizada!"
    exit 0
}

snap() {
    echo "Certifique-se de ter o snapd instalado no seu computador."
    echo "Instalando o Spotify em Snap..."
    sudo snap install spotify
    echo "Instalação finalizada!"
    exit 0
}

# Fluxo principal

case "$DISTRO" in
    ubuntu|pop|zorin|mint|debian|elementary)
        echo "Quer instalar via PPA (digite 'ppa'), Flatpak (não é suportado oficialmente pelo Spotify) (digite 'flatpak') ou Snap (digite 'snap')? "
        read inst_method_debian
        if [ "$inst_method_debian" = "ppa" ]; then
            ppa
        elif [ "$inst_method_debian" = "flatpak" ]; then
            flatpak
        elif [ "$inst_method_debian" = "snap" ]; then
            snap
        else
            echo "Erro: digite 'ppa', 'flatpak' ou 'snap'."
            return 1
        fi
        ;;
    *)
        echo "Quer instalar via Flatpak (não é suportado oficialmente pelo Spotify) (digite 'flatpak') ou Snap (digite 'snap')? "
        read inst_method
        if [ "$inst_method" = "flatpak" ]; then
            flatpak
        elif [ "$inst_method" = "snap" ]; then
            snap
        else
            echo "Erro: digite 'flatpak' ou 'snap'."
            return 1
        fi
        ;;
esac

