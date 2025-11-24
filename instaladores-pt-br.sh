#!/usr/bin/env bash

set -euo pipefail

echo "Este script vai selecionar os instaladores para você."
echo "Qual instalador você quer utilizar?"
echo "
Instalador do Firefox (digite 'firefox')
Instalador do Brave (digite 'brave')
Instalador do Lutris (digite 'lutris')
Instalador do Discord (digite 'discord')
Instalador do Spotify (digite 'spotify')
Instalador do Minecraft Launcher (digite 'mclauncher')
Instalador do qBittorrent (digite 'qbittorrent')
Instalador do ONLYOFFICE DesktopEditors (digite 'onlyoffice')
Instalador do pacote comunitário [https://github.com/aunetx/deezer-linux para mais detalhes] do Deezer para Linux (digite 'deezer')
"
read setup_installer

abrir_instalador() {
    echo "Entrando na pasta dos instaladores..."
    cd "./Instaladores"
    echo "Inicializando instalador selecionado..."
    sudo bash "$(pwd)/$setup_installer.sh"
    echo "Instalador inicializado."
    exit 0
}

abrir_instalador
