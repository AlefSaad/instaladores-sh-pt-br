#!/usr/bin/env bash
# Por Alef Saad
# Dependências: wget, tar e flatpak

set -euo pipefail

# Estabelecendo as funções

software_properties_common() {
    echo "Vamos instalar software-properties-common (se já não estiver instalado) para que o PPA funcione corretamente."
    sudo apt install software-properties-common -y
    return 0
}

appimage_install() {
    echo "Baixando o qBittorrent do sourceforge..."
    wget -O qbittorrent.AppImage https://sourceforge.net/projects/qbittorrent/files/latest/download || { echo "Erro: falha no download do AppImage"; return 1; }
    echo "Dando as permissões necessárias..."
    chmod +x qbittorrent.AppImage
    echo "Appimage baixado em $(pwd). Para integrá-lo ao sistema, recomendo o uso do Gear Lever, que está disponível em Flatpak."
    return 0
}

qbittorrent_ubuntu_stable() {
    software_properties_common
    echo "Vamos instalar a versão estável do qBittorrent para sistemas baseados em Ubuntu."
    echo "Adicionando o repositório PPA ao APT..."
    sudo apt-add-repository -y ppa:qbittorrent-team/qbittorrent-stable
    echo "Atualizando repositórios e baixando o qBittorrent..."
    sudo apt update && sudo apt install qbittorrent -y
    echo "Instalação finalizada!"
    exit 0
}

qbittorrent_ubuntu_unstable() {
    software_properties_common
    echo "Vamos instalar a versão instável do qBittorrent para sistemas baseados em Ubuntu."
    echo "Adicionando o repositório PPA ao APT..."
    sudo apt-add-repository -y ppa:qbittorrent-team/qbittorrent-unstable
    echo "Atualizando repositórios e baixando o qBittorrent..."
    sudo apt update && sudo apt install qbittorrent -y
    echo "Instalação finalizada!"
    exit 0
}

slackbuild_install() {
    echo "Baixando o SlackBuild do site oficial..."
    wget https://slackbuilds.org/slackbuilds/15.0/network/qbittorrent.tar.gz || { echo "Erro: falha no download do SlackBuild"; return 1; }
    echo "Extraindo o arquivo tar.gz..."
    tar xvf qbittorrent.tar.gz
    cd qbittorrent/
    echo "Baixando arquivo de código fonte disponível no site oficial do SlackBuild..."
    wget https://sourceforge.net/projects/qbittorrent/files/qbittorrent/qbittorrent-4.6.7/qbittorrent-4.6.7.tar.xz
    echo "Executando o SlackBuild..."
    chmod +x qbittorrent.SlackBuild
    sudo ./qbittorrent.SlackBuild
    echo "Instalando o pacote gerado..."
    TXZ=$(ls /tmp/qbittorrent-*.txz 2>/dev/null | head -n1)
    if [ -f "$TXZ" ]; then
        sudo installpkg "$TXZ"
    else
        echo "Erro: nenhum pacote gerado pelo SlackBuild encontrado."
        exit 1
    fi
    echo "Instalação finalizada!"
    exit 0
}

pardus_install() {
    echo "Verificando a presença do repositório 'contrib' no sistema..."
    sudo pisi ar contrib http://packages.pardus.org.tr/contrib-2009/pisi-index.xml.bz2
    echo "Habilitando o repositório 'contrib' caso esteja desabilitado..."
    sudo pisi er contrib
    echo "Instalando o qBittorrent..."
    sudo pisi it --yes qbittorrent
    echo "Instalação finalizada!"
    exit 0
}

opensuse_install() {
    echo "qBittorrent está no repositório oficial do Zypp. Instalando-o..."
    sudo zypper -n install qbittorrent
    echo "Instalação finalizada!"
    exit 0
}

mageia_install() {
    echo "qBittorrent está no repositório oficial do Mageia. Instalando-o..."
    sudo urpmi --auto qbittorrent
    echo "Instalação finalizada!"
    exit 0
}

gentoo_install() {
    echo "Estabelecendo variáveis..."
    PKG="net-p2p/qbittorrent"
    FLAGS="gui webui qt5 dbus"
    USEFILE="/etc/portage/package.use/qbittorrent"
    echo "Criando /etc/portage/package.use se inexistente..."
    sudo mkdir -p /etc/portage/package.use
    echo "${PKG} ${FLAGS}" | sudo tee "${USEFILE}" >/dev/null
    echo "Atualizando repositórios e instalando o pacote ${PKG}"
    sudo emerge --sync
    sudo emerge -av --ask=n ${PKG}
    echo "Instalação finalizada!"
    exit 0
}

flatpak_install() {
    echo "Instalando o Flatpak..."
    echo "Talvez o comando exija interação do usuário."
    echo "Instalando o qBittorrent via Flatpak..."
    flatpak install -y flathub org.qbittorrent.qBittorrent
    echo "Instalação finalizada!"
    exit 0
}

fedora_install() {
    echo "qBittorrent está no repositório oficial do Fedora. Instalando-o..."
    sudo dnf install -y qbittorrent
    echo "Instalação finalizada!"
    exit 0
}

debian_install() {
    echo "qBittorrent está no repositório oficial do Debian. Instalando-o..."
    sudo apt install qbittorrent libtorrent-rasterbar9 -y || sudo apt install qbittorrent -y || sudo apt install qbittorrent libtorrent-rasterbar2.0
    echo "Instalação finalizada!"
    exit 0
}

arch_install() {
    echo "Instalando o qBittorrent pelo repositório oficial do Arch Linux..."
    sudo pacman -S --noconfirm qbittorrent
    echo "Instalação finalizada!"
    exit 0
}

alt_linux_install() {
    echo "Instalando qBittorrent para Alt Linux..."
    sudo apt update && sudo apt install qbittorrent -y
    echo "Instalação finalizada!"
    exit 0
}

# Iniciando o script

echo "Aqui neste script, instalaremos o QBitTorrent com interface gráfica."

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

echo "Dependências do script: wget e tar. Caso não estejam instalados, o script pode falhar."
echo "A instalação via Flatpak depende da instalação do flatpak para funcionar. No Ubuntu, a instalação via APT depende do pacote software-properties-common."

# Fluxo principal

case "$DISTRO" in
    ubuntu|pop|zorin|mint|elementary)
        echo "Distro baseada em Ubuntu detectada."
        echo "Você quer instalar pelo repositório oficial estável (digite 'apt-stable'),"
        echo "pelo repositório oficial instável (digite 'apt-unstable'),"
        echo "por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')?"
        read install_method_ubuntu
        if [ "$install_method_ubuntu" = "apt-stable" ]; then
            qbittorrent_ubuntu_stable
        elif [ "$install_method_ubuntu" = "apt-unstable" ]; then
            qbittorrent_ubuntu_unstable
        elif [ "$install_method_ubuntu" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_ubuntu" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'apt-stable', 'apt-unstable', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    altlinux)
        echo "Alt Linux detectado."
        echo "Você quer instalar pelo repositório do Alt Linux (digite 'alt'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_alt
        if [ "$install_method_alt" = "alt" ]; then
            alt_linux_install
        elif [ "$install_method_alt" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_alt" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'alt', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    slackware)
        echo "Slackware detectado."
        echo "Você quer instalar pelo SlackBuild (digite 'slackbuild'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_slackware
        if [ "$install_method_slackware" = "slackbuild" ]; then
            slackbuild_install
        elif [ "$install_method_slackware" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_slackware" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'slackbuild', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    pardus)
        echo "Pardus detectado."
        echo "Você quer instalar pelo repositório contrib do pisi (digite 'pisi'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_pardus
        if [ "$install_method_pardus" = "pisi" ]; then
            pardus_install
        elif [ "$install_method_pardus" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_pardus" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'pisi', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    opensuse*|suse)
        echo "Distribuição openSUSE ou SUSE detectada."
        echo "Você quer instalar pelo repositório oficial do Zypp (digite 'zypp'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_opensuse
        if [ "$install_method_opensuse" = "zypp" ]; then
            opensuse_install
        elif [ "$install_method_opensuse" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_opensuse" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'zypp', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    mageia)
        echo "Distribuição Mageia detectada."
        echo "Você quer instalar pelo repositório oficial do Mageia (digite 'urpmi'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_mageia
        if [ "$install_method_mageia" = "urpmi" ]; then
            mageia_install
        elif [ "$install_method_mageia" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_mageia" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'urpmi', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    gentoo)
        echo "Distribuição Gentoo detectada."
        echo "Você quer instalar pelo repositório oficial do Gentoo (digite 'portage'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_gentoo
        if [ "$install_method_gentoo" = "portage" ]; then
            gentoo_install
        elif [ "$install_method_gentoo" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_gentoo" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'portage', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    fedora|rhel|centos|rocky|almalinux)
        echo "Distribuição baseada em Fedora ou RHEL detectada."
        echo "Você quer instalar pelo repositório oficial do $NAME (digite 'dnf'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_fedora
        if [ "$install_method_fedora" = "dnf" ]; then
            fedora_install
        elif [ "$install_method_fedora" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_fedora" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'dnf', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    debian)
        echo "Distribuição Debian detectada."
        echo "Você quer instalar pelo repositório oficial do Debian (digite 'apt'), por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')? "
        read install_method_debian
        if [ "$install_method_debian" = "apt" ]; then
            debian_install
        elif [ "$install_method_debian" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_debian" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'apt', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    arch|manjaro|endeavouros)
        echo "Distribuição baseada em Arch Linux detectada."
        echo "Você quer instalar pelo repositório oficial do $NAME (digite 'pacman'),"
        echo "por Appimage (digite 'appimage') ou pelo Flatpak (digite 'flatpak')?"
        read install_method_arch
        if [ "$install_method_arch" = "pacman" ]; then
            arch_install
        elif [ "$install_method_arch" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_arch" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'pacman', 'appimage' ou 'flatpak'."
            return 2
        fi
        ;;
    *)
        echo "Distribuição $NAME não suportada pelo script de instalação."
        echo "Você terá que compilar da fonte manualmente, instalar do repositório do seu sistema manualmente"
        echo "(não suportado pelos desenvolvedores do Qbittorrent), instalar por Appimage (digite 'appimage')"
        echo "ou por Flatpak (digite 'flatpak')."
        read install_method_unknown
        if [ "$install_method_unknown" = "appimage" ]; then
            appimage_install
        elif [ "$install_method_unknown" = "flatpak" ]; then
            flatpak_install
        else
            echo "Erro: digite 'appimage', 'flatpak', compile da fonte manualmente ou instale não oficialmente pela sua distribuição."
            return 2
        fi
        ;;
esac






