#!/usr/bin/env bash

set -euo pipefail

echo "Este script vai selecionar os instaladores para você."
echo "Qual instalador você quer utilizar?"
echo "
Instalador do Firefox (digite 'instalar-firefox')
Instalador do Brave (digite 'instalar-brave')
Instalador do Lutris (digite 'instalar-lutris')
Instalador do Discord (digite 'instalar-discord')
Instalador do Spotify (digite 'instalar-spotify')
Instalador do Minecraft Launcher (digite 'instalar-mclauncher')
Instalador do qBittorrent (digite 'instalar-qbittorrent')
Instalador do ONLYOFFICE DesktopEditors (digite 'instalar-onlyoffice')
"
read setup_installer

abrir_instalador() {
    echo "Entrando na pasta dos instaladores..."
    cd "./Instaladores"
    echo "Inicializando instalador selecionado..."
    sudo "$(pwd)/$setup_installer.sh"
    echo "Instalador inicializado."
    exit 0
}

abrir_instalador
