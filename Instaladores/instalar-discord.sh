#!/usr/bin/env bash
# Criado por Alef Saad
# Dependências: wget e tar

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

targz() {
    echo "É necessário ter o wget e o tar instalados para que o script funcione."
    echo "Baixando o arquivo tar.gz do Discord..."
    wget -O discord.tar.gz "https://discord.com/api/download?platform=linux&format=tar.gz"
    echo "Extraindo o arquivo tar.gz do Discord..."
    tar -xvzf discord.tar.gz
    echo "Movendo a pasta do Discord para a sua /home..."
    sudo mv Discord $HOME/discord
    echo "Criando link simbólico para o Discord..."
    sudo ln -s /opt/discord/Discord /usr/bin/discord
    echo "Criando um atalho do desktop para o Discord..."
    sudo tee /usr/share/applications/discord.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Discord
Comment=Discord Chat
Exec=/usr/bin/discord
Icon=$HOME/discord/discord.png
Terminal=false
Type=Application
Categories=Network;Chat;
EOF
    echo "Limpando arquivos temporários..."
    rm -f /tmp/discord.tar.gz
    rm discord.tar.gz
    echo "Instalação finalizada!"
    exit 0
}

deb() {
    echo "Wget é uma dependência do script. Instalando-a..."
    sudo apt install wget -y
    echo "Baixando o arquivo .deb do Discord..."
    wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
    echo "Instalando o pacote .deb do Discord..."
    sudo dpkg -i lutris-latest.deb || sudo apt -f install -y
    echo "Instalação finalizada!"
    exit 0
}

case "$DISTRO" in(
    ubuntu|debian|elementary|mint|zorin|pop)
        read -p "Você quer instalar via .deb (digite 'deb') ou via .tar.gz (digite 'tar')?" inst_method
        if [ "$inst_method" = "deb" ]; then
            deb
        elif [ "$inst_method" = "tar" ]; then
            targz
        else
            echo "Erro: digite 'deb' ou 'tar'."
            exit 1
        ;;
    *)
        targz ;;
esac
