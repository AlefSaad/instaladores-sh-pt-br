#!/usr/bin/env bash
# Criado por Alef Saad
# Dependências gerais: curl
# Dependências Fedora: dnf-plugins-core
# Dependências Arch: yay e/ou paru

set -euo pipefail

# Verificação de arquitetura — Brave é apenas x86_64/amd64
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    echo "Esta máquina usa arquitetura $ARCH. Prosseguindo..."
else
    echo "Esta máquina usa arquitetura $ARCH."
    echo "O Brave só fornece pacotes oficiais para x86_64 (amd64)."
    echo "Instalação abortada."
    exit 1
fi


if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    VERSION_ID="${VERSION_ID:-0}"
fi
echo "Distribuição detectada: ${DISTRO:-indetectável}"

if [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rocky" ]  || [ "$DISTRO" = "almalinux" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "centos" ]; then
    fedora_version=unknown
    if [ -f /run/ostree-booted ]; then
        echo "Distribuição Fedora Atomic Desktop detectada."
        fedora_version=atomic
    else
        if [ "${VERSION_ID%%.*}" -lt 41 ] || [ "$DISTRO" = "rocky" ] || [ "$DISTRO" = "almalinux" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "centos" ]; then
            echo "Distribuição Fedora enterprise ou <41 detectada."
            fedora_version=enterprise
        else
            echo "Distribuição Fedora 41+ detectada."
            fedora_version=dnf5
        fi
    fi
fi

echo "Qual versão do Brave você gostaria de instalar? Release (digite 'release'), Beta (digite 'beta') ou Nightly (digite 'nightly')"
read -r brave_version
brave_version=$(echo "$brave_version" | tr '[:upper:]' '[:lower:]')

install_sh() {
    if [ "$brave_version" = "release" ]; then
        echo "Baixando e rodando script de instalação..."
        curl -fsS https://dl.brave.com/install.sh | sh
        echo "Brave instalado."
        exit 0
    elif [ "$brave_version" = "beta" ]; then
        echo "Baixando e rodando script de instalação..."
        curl -fsS https://dl.brave.com/install.sh | CHANNEL=beta sh
        echo "Brave instalado."
        exit 0
    elif [ "$brave_version" = "nightly" ]; then
        echo "Baixando e rodando script de instalação..."
        curl -fsS https://dl.brave.com/install.sh | CHANNEL=nightly sh
        echo "Brave instalado."
        exit 0
    else
        echo "Erro: digite 'release', 'beta' ou 'nightly'."
        return 1
    fi
}

install_debian() {
    if [ "$brave_version" = "release" ]; then
        echo "Esse script requer a instalação do curl. Instalando-o..."
        sudo apt install curl -y
        echo "Baixando os repositórios e suas chaves de assinatura..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
        echo "Atualizando os repositórios..."
        sudo apt update
        echo "Instalando o Brave..."
        sudo apt install brave-browser -y
        echo "Brave instalado."
        exit 0
    elif [ "$brave_version" = "beta" ]; then
        echo "Esse script requer a instalação do curl. Instalando-o..."
        sudo apt install curl -y
        echo "Baixando os repositórios e suas chaves de assinatura..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg
        sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-beta.sources https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta.sources
        echo "Atualizando os repositórios..."
        sudo apt update
        echo "Instalando o Brave..."
        sudo apt install brave-browser-beta -y
        echo "Brave instalado."
        exit 0
    elif [ "$brave_version" = "nightly" ]; then
        echo "Esse script requer a instalação do curl. Instalando-o..."
        sudo apt install curl -y
        echo "Baixando os repositórios e suas chaves de assinatura..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg
        sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly.sources
        echo "Atualizando os repositórios..."
        sudo apt update
        echo "Instalando o Brave..."
        sudo apt install brave-browser-nightly -y
        echo "Brave instalado."
        exit 0
    else
        echo "Erro: digite 'release', 'beta' ou 'nightly'."
        return 1
    fi
}

install_fedora() {
    if [ "$brave_version" = "release" ]; then
        if [ "$fedora_version" = "atomic" ]; then
            if command -v run0 >/dev/null 2>&1; then
                cmd_run="run0"
            else
                cmd_run="sudo" # ou use "sudo" ou falhe com mensagem clara
            fi
            echo "Uma das dependências da instalação é o curl. Ele será instalado pelo rpm-ostree. Instalando-o..."
            $cmd_run rpm-ostree install curl
            echo "Baixando o repositório do Brave..."
            $cmd_run curl -fsSLo /etc/yum.repos.d/brave-browser.repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            echo "Instalando o Brave..."
            $cmd_run rpm-ostree install brave-browser
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Uma das dependências do script é dnf-plugins-core. Instalando-a..."
            sudo dnf install -y dnf-plugins-core
            if [ "$fedora_version" = "enterprise" ]; then
                echo "Adicionando repositório do Brave ao DNF..."
                sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            else
                echo "Adicionando repositório do Brave ao DNF..."
                sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            fi
            echo "Instalando o Brave..."
            sudo dnf install -y brave-browser
            echo "Instalação finalizada!"
            exit 0
        fi
    elif [ "$brave_version" = "beta" ]; then
        if [ "$fedora_version" = "atomic" ]; then
            echo "Uma das dependências da instalação é o curl. Ele será instalado pelo rpm-ostree. Instalando-o..."
            $cmd_run rpm-ostree install curl
            echo "Baixando o repositório do Brave..."
            $cmd_run curl -fsSLo /etc/yum.repos.d/brave-browser-beta.repo https://brave-browser-rpm-beta.s3.brave.com/brave-browser-beta.repo
            echo "Instalando o Brave..."
            $cmd_run rpm-ostree install brave-browser-beta
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Uma das dependências do script é dnf-plugins-core. Instalando-a..."
            sudo dnf install -y dnf-plugins-core
            if [ "$fedora_version" = "enterprise" ]; then
                echo "Adicionando repositório do Brave ao DNF..."
                sudo dnf config-manager --add-repo https://brave-browser-rpm-beta.s3.brave.com/brave-browser-beta.repo
            else
                echo "Adicionando repositório do Brave ao DNF..."
                sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-beta.s3.brave.com/brave-browser-beta.repo
            fi
            echo "Instalando o Brave..."
            sudo dnf install -y brave-browser-beta
            echo "Instalação finalizada!"
            exit 0
        fi
    elif [ "$brave_version" = "nightly" ]; then
        if [ "$fedora_version" = "atomic" ]; then
            echo "Uma das dependências da instalação é o curl. Ele será instalado pelo rpm-ostree. Instalando-o..."
            $cmd_run rpm-ostree install curl
            echo "Baixando o repositório do Brave..."
            $cmd_run curl -fsSLo /etc/yum.repos.d/brave-browser-nightly.repo https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
            echo "Instalando o Brave..."
            $cmd_run rpm-ostree install brave-browser-nightly
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Uma das dependências do script é dnf-plugins-core. Instalando-a..."
            sudo dnf install -y dnf-plugins-core
            if [ "$fedora_version" = "enterprise" ]; then
                echo "Adicionando repositório do Brave ao DNF..."
                sudo dnf config-manager --add-repo https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
            else
                echo "Adicionando repositório do Brave ao DNF..."
                sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
            fi
            echo "Instalando o Brave..."
            sudo dnf install -y brave-browser-nightly
            echo "Instalação finalizada!"
            exit 0
        fi
    else
        echo "Erro: digite 'release', 'beta' ou 'nightly'."
        return 1
    fi
}

install_opensuse() {
    if [ "$brave_version" = "release" ]; then
        echo "Adicionando o repositório do Brave..."
        sudo zypper addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
        echo "Instalando o Brave..."
        sudo zypper -n install brave-browser
        echo "Instalação finalizada!"
        exit 0
    elif [ "$brave_version" = "beta" ]; then
        echo "Adicionando o repositório do Brave..."
        sudo zypper addrepo https://brave-browser-rpm-beta.s3.brave.com/brave-browser-beta.repo
        echo "Instalando o Brave..."
        sudo zypper -n install brave-browser-beta
        echo "Instalação finalizada!"
        exit 0
    elif [ "$brave_version" = "nightly" ]; then
        echo "Adicionando o repositório do Brave..."
        sudo zypper addrepo https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
        echo "Instalando o Brave..."
        sudo zypper -n install brave-browser-nightly
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Erro: digite 'release', 'beta' ou 'nightly'."
        return 1
    fi
}

install_aur() {
    echo "Para essa instalação o site do Brave diz que você precisa de um AUR helper. Caso não tenha um, instale um."
    echo "Esse script funciona para o yay e o paru. Se tiver os dois, o yay será escolhido."
    user=$(logname)
    if command -v yay >/dev/null 2>&1; then
        if [ "$brave_version" = "release" ]; then
            echo "Instalando o Brave pelo yay..."
            sudo -u "$user" yay -Sy --noconfirm brave-bin
            echo "Instalação finalizada!"
            exit 0
        elif [ "$brave_version" = "beta" ]; then
            echo "Instalando o Brave pelo yay..."
            sudo -u "$user" yay -Sy --noconfirm brave-beta-bin
            echo "Instalação finalizada!"
            exit 0
        elif [ "$brave_version" = "nightly" ]; then
            echo "Instalando o Brave pelo yay..."
            sudo -u "$user" yay -Sy --noconfirm brave-nightly-bin
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Erro: digite 'release', 'beta' ou 'nightly'."
            return 1
        fi
    elif command -v paru >/dev/null 2>&1; then
        if [ "$brave_version" = "release" ]; then
            echo "Instalando o Brave pelo paru..."
            sudo -u "$user" paru -Sy --noconfirm brave-bin
            echo "Instalação finalizada!"
            exit 0
        elif [ "$brave_version" = "beta" ]; then
            echo "Instalando o Brave pelo paru..."
            sudo -u "$user" paru -Sy --noconfirm brave-beta-bin
            echo "Instalação finalizada!"
            exit 0
        elif [ "$brave_version" = "nightly" ]; then
            echo "Instalando o Brave pelo paru..."
            sudo -u "$user" paru -Sy --noconfirm brave-nightly-bin
            echo "Instalação finalizada!"
            exit 0
        else
            echo "Erro: digite 'release', 'beta' ou 'nightly'."
            return 1
        fi
    else
        echo "Você não possui um AUR helper ou o seu AUR helper não é compatível com o script. Instale um ou instale o Brave manualmente."
        return 2
    fi
}

manjaro_install() {
    if [ "$brave_version" = "release" ]; then
        echo "Atenção, este pacote é comunitário!"
        echo "Instalando o Brave..."
        sudo pacman -Sy --noconfirm brave-browser
        echo "Instalação finalizada!"
        exit 0
    elif [ "$brave_version" = "beta" ]; then
        echo "Atenção, este pacote é comunitário!"
        echo "Instalando o Brave..."
        sudo pacman -Sy --noconfirm brave-browser-beta
        echo "Instalação finalizada!"
        exit 0
    elif [ "$brave_version" = "nightly" ]; then
        echo "A versão Nightly não pode ser instalada pelo pacote comunitário do Manjaro."
        return 3
    else
        echo "Erro: digite 'release', 'beta' ou 'nightly'."
        return 1
    fi
}

solus_install() {
    if [ "$brave_version" = "release" ]; then
        echo "Atenção, este pacote é comunitário!"
        echo "Atualizando repositórios..."
        sudo eopkg update-repo
        echo "Instalando o Brave..."
        sudo eopkg install brave
        echo "Instalação finalizada!"
        exit 0
    else
        echo "A instalação pelo pacote comunitário do Solus só é compatível com a versão Release do Brave."
        return 3
    fi
}

case "$DISTRO" in
    debian|ubuntu|zorin|mint|elementary|pop)
        echo "Gostaria de instalar pelo repositório APT (digite 'apt') ou pelo script de instalação (digite 'sh')? "
        read inst_method_debian
        if [ "$inst_method_debian" = "apt" ]; then
            install_debian
        elif [ "$inst_method_debian" = "sh" ]; then
            install_sh
        else
            echo "Erro: digite 'apt' ou 'sh'."
            exit 1
        fi
        ;;
    fedora|rhel|centos|rocky|almalinux)
        echo "Gostaria de instalar pelo repositório do Fedora (digite 'fedora') ou pelo script de instalação (digite 'sh')? "
        read inst_method_fedora
        if [ "$inst_method_fedora" = "fedora" ]; then
            install_fedora
        elif [ "$inst_method_fedora" = "sh" ]; then
            install_sh
        else
            echo "Erro: digite 'fedora' ou 'sh'."
            exit 1
        fi
        ;;
    opensuse*|suse)
        echo "Gostaria de instalar pelo repositório do Zypp (digite 'zypp') ou pelo script de instalação (digite 'sh')? "
        read inst_method_suse
        if [ "$inst_method_suse" = "zypp" ]; then
            install_opensuse
        elif [ "$inst_method_suse" = "sh" ]; then
            install_sh
        else
            echo "Erro: digite 'zypp' ou 'sh'."
            exit 1
        fi
        ;;
    arch|endeavouros)
        echo "Gostaria de instalar pelo repositório do AUR (digite 'aur') ou pelo script de instalação (digite 'sh')? "
        read inst_method_arch
        if [ "$inst_method_arch" = "aur" ]; then
            install_aur
        elif [ "$inst_method_arch" = "sh" ]; then
            install_sh
        else
            echo "Erro: digite 'aur' ou 'sh'."
            exit 1
        fi
        ;;
    manjaro)
        echo "Gostaria de instalar pelo repositório do AUR (digite 'aur'), pelo repositório comunitário do Manjaro (digite 'manjaro') ou pelo script de instalação (digite 'sh')? "
        read inst_method_manjaro
        if [ "$inst_method_manjaro" = "aur" ]; then
            install_aur
        elif [ "$inst_method_manjaro" = "manjaro" ]; then
            manjaro_install
        elif [ "$inst_method_manjaro" = "sh" ]; then
            install_sh
        else
            echo "Erro: digite 'aur', 'manjaro' ou 'sh'."
            exit 1
        fi
        ;;
    solus)
        echo "Gostaria de instalar pelo repositório comunitário do Solus (digite 'solus') ou pelo script de instalação (digite 'sh')? "
        read inst_method_solus
        if [ "$inst_method_solus" = "solus" ]; then
            solus_install
        elif [ "$inst_method_solus" = "sh" ]; then
            install_sh
        else
            echo "Erro: digite 'solus' ou 'sh'."
            exit 1
        fi
        ;;
    *)
        echo "Sua distribuição não foi detectada. O Brave será instalado pelo script de instalação."
        install_sh
        ;;
esac
