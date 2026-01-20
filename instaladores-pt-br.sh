#!/bin/bash
# Criado por Alef Saad

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
Instalador do Snap [Instala o snapd pelo gerenciador de pacotes do sistema, o snapd pelo Snap, a Snap Store e instala o plugin da loja do sistema.] (digite 'snap')
Instalador do add-apt-repository (Repositórios PPA) para sistemas Debian (digite 'ppa')
Instalador do Cryptomator (digite 'cryptomator')
Instalador do Heroic Games Launcher (digite 'heroic')
Instalador do GIMP (digite 'gimp')
Instalador do WhatsApp para Linux [https://github.com/rafatosta/zapzap | https://rtosta.com/zapzap/#home] (digite 'zapzap' ou 'whatsapp')
Instalador do Inkscape (digite 'inkscape')
"
read setup_installer

abrir_instalador() {
    echo "Entrando na pasta dos instaladores..."
    cd "./Instaladores"
    echo "Inicializando instalador selecionado..."
    sudo bash "$(pwd)/$setup_installer.sh"
    exit 0
}

abrir_instalador
