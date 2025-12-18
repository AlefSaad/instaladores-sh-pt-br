#!/usr/bin/env bash
# Criado por Alef Saad
# Dependências: wget tar
# Dependências do Arch Linux manual: base-devel git

set -euo pipefail

# Ele requer sudo para utilizar gerenciadores de pacotes.
if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

# Detectar distribuição
DISTRO="desconhecida"
VERSION_ID=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi
echo "📦 Distribuição detectada: ${NAME:-indetectável}"

# observações

case "$DISTRO" in
    arch|manjaro|endeavouros)
        echo "Dependências gerais do script: wget e tar."
        echo "Para a instalação manual no Arch, será necessária a instalação das seguintes dependências: base-devel e git."
        ;;
    *)
        echo "Dependências do script: wget e tar."
esac

echo "Este instalador não instala o Prism Launcher (mais adequado para mods), não instala o Minecraft e nem crackeia o Minecraft."
echo "Ele só automatiza o processo oficial de instalação do Minecraft Launcher do próprio site."
echo "Não funciona para a versão em Snap, pois esta não é oficial."
echo "Não instala a versão Bedrock não oficialmente, também não instala a Server Edition."

# funções

install_debian() {
    echo "Baixando pacote .deb do site do Minecraft Launcher"
    wget https://launcher.mojang.com/download/Minecraft.deb
    echo "Instalando o pacote..."
    sudo dpkg -i Minecraft.deb
    echo "Resolvendo dependências caso necessário..."
    sudo apt-get install -f
    echo "Removendo o pacote para economizar espaço..."
    rm Minecraft.deb
    echo "O Minecraft Launcher está instalado."
    exit 0
}

install_targz() {
    FOLDER=$(pwd)
    echo "Baixando o pacote tar.gz do site oficial do Minecraft..."
    wget https://launcher.mojang.com/download/Minecraft.tar.gz
    echo "Em qual pasta você gostaria de extrair o arquivo tar.gz?"
    read folder_extract
    echo "Extraindo o pacote dentro da pasta escolhida..."
    tar -xvzf Minecraft.tar.gz -C "$folder_extract"
    cd "$folder_extract/minecraft-launcher"
    echo "Dando permissões de execução ao binário do Minecraft..."
    chmod +x minecraft-launcher
    echo "Removendo o tar.gz para economizar espaço..."
    rm "$FOLDER/Minecraft.tar.gz"
    echo "Minecraft Launcher instalado em $folder_extract/minecraft-launcher. Caso deseje inicializá-lo, abra o binário 'minecraft-launcher' dentro da determinada pasta."
    echo "Você terá que integrá-lo ao sistema manualmente."
    return 0
}

install_aur() {
    echo "Este comando só tem suporte ao YAY e ao Paru. Se nenhum dos dois estiverem presentes no seu sistema, o pacote AUR deverá ser compilado manualmente."
    user=$(logname)
    if command -v yay >/dev/null 2>&1; then
        echo "Instalando o pacote via YAY..."
        sudo -u "$user" yay -S --noconfirm minecraft-launcher
        echo "Instalação finalizada!"
        exit 0
    elif command -v paru >/dev/null 2>&1; then
        echo "Instalando o pacote via Paru..."
        sudo -u "$user" paru -S --noconfirm minecraft-launcher
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Erro: nenhum AUR helper detectado. Você deverá compilar manualmente."
        return 2
    fi
}

case "$DISTRO" in
    arch|manjaro|endeavouros)
        echo "Gostaria de instalar via pacote AUR (digite 'aur') ou via tar.gz (digite 'tar')? "
        read inst_method_arch
        if [ "$inst_method_arch" = "aur" ]; then
            install_aur
        elif [ "$inst_method_arch" = "tar" ]; then
            install_targz
        else
            echo "Erro: digite 'aur' ou 'tar'."
        fi
        ;;
    debian|ubuntu|zorin|mint|elementary|pop)
        echo "Gostaria de instalar via pacote .deb (digite 'deb') ou via tar.gz (digite 'tar')? "
        read inst_method_debian
        if [ "$inst_method_debian" = "deb" ]; then
            install_debian
        elif [ "$inst_method_debian" = "tar" ]; then
            install_targz
        else
            echo "Erro: digite 'deb' ou 'tar'."
        fi
        ;;
    *)
        install_targz
        ;;
esac
