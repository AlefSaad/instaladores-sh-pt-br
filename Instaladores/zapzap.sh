#!/bin/bash
# Criado por Alef Saad

set -euo pipefail

DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID=-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME=-desconhecido}
fi
echo "Distribuição detectada: ${NAME=-indetectável}"

if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

fedora_copr() {
    echo "Habilitando repositório Copr do ZapZap..."
    sudo dnf copr enable rafatosta/zapzap
    echo "Instalando ZapZap..."
    sudo dnf install -y zapzap
    echo "Instalação finalizada!"
    exit 0
}

install_aur() {
    echo "Este comando só tem suporte ao YAY, ao Paru e ao Pikaur. Se nenhum dos dois estiverem presentes no seu sistema, o pacote AUR será compilado manualmente."
    user=$(logname)
    if command -v yay >/dev/null 2>&1; then
        echo "Instalando o pacote via YAY..."
        sudo -u "$user" yay -S --noconfirm zapzap
        echo "Instalação finalizada!"
        exit 0
    elif command -v paru >/dev/null 2>&1; then
        echo "Instalando o pacote via Paru..."
        sudo -u "$user" paru -S --noconfirm zapzap
        echo "Instalação finalizada!"
        exit 0
    elif command -v pikaur >/dev/null 2>&1; then
        echo "Instalando o pacote via Paru..."
        sudo -u "$user" pikaur -S --noconfirm zapzap
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Aonde você quer clonar o repositório Git do AUR?"
        read folder
        cd $folder
        echo "Clonando repositório Git do AUR..."
        git clone https://aur.archlinux.org/zapzap.git
        cd "./zapzap"
        makepkg -si
        echo "Instalação finalizada! Caso queira atualizar, a pasta é $folder/zapzap."
        return 0
    fi
}

appimage() {
    echo "Em qual pasta você quer baixar o AppImage?"
    read folder
    echo "Baixando AppImage do ZapZap em $folder..."
    wget https://github.com/rafatosta/zapzap/releases/latest/download/ZapZap-x86_64.AppImage -C $folder
    echo "Dando permissões de execução ao AppImage..."
    chmod +x $folder/ZapZap-x86_64.AppImage
    echo "O AppImage acaba de ser baixado em $folder. Caso queira executá-lo, abra $folder/ZapZap-x86_64.AppImage."
    echo "Você deverá integrá-lo ao sistema manualmente, o Gear Lever é ótimo para isso."
    return 0
}

inst_flatpak() {
    echo "Instalando o Flatpak do ZapZap..."
    flatpak install flathub -y com.rtosta.zapzap
    echo "Instalação finalizada!"
    exit 0
}

case "$DISTRO" in
    fedora)
        echo "Gostaria de instalar via Fedora Copr (digite 'copr'), via AppImage (digite 'appimage') ou via Flatpak [recomendado] (digite 'flatpak')?"
        read inst_method
        if [ "$inst_method" = "copr" ]; then
            fedora_copr
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        elif [ "$inst_method" = "flatpak" ]; then
            inst_flatpak
        else
            echo "Erro: digite 'copr', 'appimage' ou 'flatpak'."
        fi
        ;;
    arch|manjaro|endeavouros)
        echo "Gostaria de instalar via pacote AUR (digite 'aur'), via AppImage (digite 'appimage') ou via Flatpak [recomendado] (digite 'flatpak')?"
        read inst_method
        if [ "$inst_method" = "aur" ]; then
            install_aur
        elif [ "$inst_method" = "appimage" ]; then
            appimage
        elif [ "$inst_method" = "flatpak" ]; then
            inst_flatpak
        else
            echo "Erro: digite 'aur', 'appimage' ou 'flatpak'."
        fi
        ;;
    *)
        echo "Gostaria de instalar via AppImage (digite 'appimage') ou via Flatpak [recomendado] (digite 'flatpak')?"
        read inst_method
        if [ "$inst_method" = "appimage" ]; then
            appimage
        elif [ "$inst_method" = "flatpak" ]; then
            inst_flatpak
        else
            echo "Erro: digite 'appimage' ou 'flatpak'."
        fi
        ;;
esac
