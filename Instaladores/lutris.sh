#!/usr/bin/env bash
# Criado por Alef Saad
# Dependências: wget, flatpak, curl, tar e git

set -euo pipefail

echo "Esse script precisa do curl, instale ele primeiro antes de continuar."

# Descobre a última versão pelo redirecionamento
VERSION_RAW=$(curl -Ls -o /dev/null -w '%{url_effective}' \
    https://github.com/lutris/lutris/releases/latest \
    | grep -oP 'tag/\K[^/]+')

VERSION="${VERSION_RAW#v}"

# URLs corretos
DEB_URL="https://github.com/lutris/lutris/releases/download/v${VERSION}/lutris_${VERSION}_all.deb"
TARBALL_URL="https://lutris.net/releases/lutris_${VERSION}.tar.xz"

echo "$VERSION $DEB_URL $TARBALL_URL"

popos() {
    echo "O Lutris está disponível na Pop!_Shop. Abrindo-a..."
    xdg-open appstream://net.lutris.Lutris
    exit 0
}

flatpak_inst() {
    read -p "Você gostaria de instalar o Lutris Beta (é necessário o repositório Flathub Beta) (digite '-beta') ou o normal (é necessário o repositório Flathub) (deixe em branco)? " inst_flatpak
    flatpak install flathub$inst_flatpak --user -y net.lutris.Lutris
    echo "Instalação finalizada!"
    exit 0
}

ubuntu() {
    echo "Baixando a dependência wget..."
    sudo apt install wget -y
    echo "Baixando o pacote .deb do Lutris..."
    echo "Versão: $VERSION Link: $DEB_URL"
    wget -O lutris-latest.deb $DEB_URL
    echo "Instalando o pacote .deb do Lutris..."
    sudo dpkg -i lutris-latest.deb || sudo apt -f install -y
    echo "Removendo o instalar .deb do Lutris..."
    rm lutris-latest.deb
    echo "Instalação finalizada!"
    exit 0
}

debian() {
    echo "Baixando e adicionando o repositório do Lutris ao Debian..."
    echo -e "Types: deb\nURIs: https://download.opensuse.org/repositories/home:/strycore/Debian_12/\nSuites: ./\nComponents: \nSigned-By: /etc/apt/keyrings/lutris.gpg" | sudo tee /etc/apt/sources.list.d/lutris.sources > /dev/null
    wget -q -O- https://download.opensuse.org/repositories/home:/strycore/Debian_12/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/lutris.gpg
    echo "Atualizando os repositórios do APT..."
    sudo apt update
    echo "Instalando o Lutris..."
    sudo apt install lutris -y
    echo "Instalação finalizada!"
    exit 0
}

slackbuild() {
    FOLDER=$(pwd)
    echo "Baixando o SlackBuild..."
    wget https://slackbuilds.org/slackbuilds/15.0/games/lutris.tar.gz
    echo "Extraindo o arquivo tar..."
    tar xf lutris.tar.gz
    cd lutris/
    echo "Executando o SlackBuild..."
    sudo sh lutris.SlackBuild
    echo "Instalando o pacote..."
    ls /tmp/lutris-*.txz
    sudo installpkg /tmp/lutris-*
    echo "Removendo o SlackBuild..."
    rm $FOLDER/lutris.tar.gz
    echo "Pacote SlackBuild instalado."
    exit 0
}

git_source() {
    echo "Este método é mais recomendado para desenvolvedores!"
    echo "Entrando na sua /home..."
    cd $HOME
    echo "É necessário ter o git instalado, senão o comando vai falhar."
    echo "Clonando repositório do git..."
    git clone https://github.com/lutris/lutris.git
    echo "Executando o Lutris..."
    cd ./lutris
    ./bin/lutris -d
    echo "Lutris executado."
    return 0
}

tarball() {
    echo "Entrando na sua /home..."
    cd $HOME
    echo "Baixando a versão tar.xz estável mais recente..."
    echo "Versão: ${VERSION} Link: ${TARBALL_URL}"
    wget -O lutris-latest.tar.xz $TARBALL_URL
    echo "Extraindo o arquivo tar.xz do Lutris..."
    tar xf lutris-latest.tar.xz
    echo "Executando o Lutris..."
    cd ./lutris
    ./bin/lutris -d
    echo "Removendo o tar.xz do Lutris..."
    rm $HOME/lutris-latest.tar.xz
    echo "Lutris executado."
    return 0
}

epel() {
    EPEL_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-$VER.noarch.rpm"
    echo "Instalando EPEL..."
    sudo dnf install -y "$EPEL_URL"
    echo "Atualizando cache de pacotes..."
    sudo dnf makecache
    echo "Instalando o Lutris pelo EPEL..."
    sudo dnf install -y lutris
    echo "Instalação finalizada!"
    exit 0
}

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

case "$DISTRO" in
    pop)
        echo "Você gostaria de instalar via Pop!_Shop (digite 'pop'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_pop
        if [ "$inst_method_pop" = "pop" ]; then
            popos
        elif [ "$inst_method_pop" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_pop" = "tar" ]; then
            tarball
        elif [ "$inst_method_pop" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'pop', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    ubuntu|elementary|mint|zorin)
        echo "Você gostaria de instalar via pacote .deb (digite 'deb'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_ubuntu
        if [ "$inst_method_ubuntu" = "deb" ]; then
            ubuntu
        elif [ "$inst_method_ubuntu" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_ubuntu" = "tar" ]; then
            tarball
        elif [ "$inst_method_ubuntu" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'deb', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    debian)
        echo "Você gostaria de instalar via repositório APT (digite 'apt'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_debian
        if [ "$inst_method_debian" = "apt" ]; then
            debian
        elif [ "$inst_method_debian" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_debian" = "tar" ]; then
            tarball
        elif [ "$inst_method_debian" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'apt', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    slackware)
        echo "Você gostaria de instalar via SlackBuild (digite 'slackbuild'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_slackware
        if [ "$inst_method_slackware" = "slackbuild" ]; then
            slackbuild
        elif [ "$inst_method_slackware" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_slackware" = "tar" ]; then
            tarball
        elif [ "$inst_method_slackware" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'slackbuild', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    fedora)
        echo "Você gostaria de instalar via DNF (digite 'dnf'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_fedora
        if [ "$inst_method_fedora" = "dnf" ]; then
            sudo dnf install lutris -y
        elif [ "$inst_method_fedora" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_fedora" = "tar" ]; then
            tarball
        elif [ "$inst_method_fedora" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'dnf', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    opensuse*|suse)
        echo "Você gostaria de instalar via Zypp (digite 'zypp'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_suse
        if [ "$inst_method_suse" = "zypp" ]; then
            sudo zypper --non-interactive install lutris
        elif [ "$inst_method_suse" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_suse" = "tar" ]; then
            tarball
        elif [ "$inst_method_suse" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'zypp', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    arch|manjaro|endeavouros)
        echo "Você gostaria de instalar via Arch Extra Repository (digite 'extra'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_arch
        if [ "$inst_method_arch" = "extra" ]; then
            sudo pacman -S --noconfirm lutris
        elif [ "$inst_method_arch" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_arch" = "tar" ]; then
            tarball
        elif [ "$inst_method_arch" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'extra', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    solus)
        echo "Você gostaria de instalar via EOPKG (digite 'eopkg'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_solus
        if [ "$inst_method_solus" = "eopkg" ]; then
            sudo eopkg install -y lutris
        elif [ "$inst_method_solus" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_solus" = "tar" ]; then
            tarball
        elif [ "$inst_method_solus" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'eopkg', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    clear-linux-os)
        echo "Você gostaria de instalar via Bundle (digite 'swupd'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_clear
        if [ "$inst_method_clear" = "swupd" ]; then
            sudo swupd bundle-add lutris
        elif [ "$inst_method_clear" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_clear" = "tar" ]; then
            tarball
        elif [ "$inst_method_clear" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'swupd', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    mageia)
        echo "Você gostaria de instalar via urpmi (digite 'urpmi'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_mageia
        if [ "$inst_method_mageia" = "urpmi" ]; then
            sudo urpmi --auto lutris
        elif [ "$inst_method_mageia" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_mageia" = "tar" ]; then
            tarball
        elif [ "$inst_method_mageia" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'urpmi', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    gentoo)
        echo "Você gostaria de instalar via Portage (digite 'portage'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_gentoo
        if [ "$inst_method_gentoo" = "portage" ]; then
            sudo emerge --quiet --verbose --oneshot games-util/lutris
        elif [ "$inst_method_gentoo" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_gentoo" = "tar" ]; then
            tarball
        elif [ "$inst_method_gentoo" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'portage', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    centos|almalinux|rocky|rhel)
        echo "Você gostaria de instalar via EPEL (digite 'epel'), via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_enterprise
        if [ "$inst_method_enterprise" = "epel" ]; then
            epel
        elif [ "$inst_method_gentoo" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_gentoo" = "tar" ]; then
            tarball
        elif [ "$inst_method_gentoo" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'epel', 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
    *)
        echo "Distro desconhecida."
        echo "Você gostaria de instalar via Flatpak (digite 'flatpak'), via tarball (digite 'tar') ou via código-fonte (para desenvolvedores, digite 'git')? "
        read inst_method_unknown
        if [ "$inst_method_unknown" = "flatpak" ]; then
            flatpak_inst
        elif [ "$inst_method_unknown" = "tar" ]; then
            tarball
        elif [ "$inst_method_unknown" = "git" ]; then
            git_source
        else
            echo "Erro: digite 'flatpak', 'tar' ou 'git'."
            exit 1
        fi
        ;;
esac


