#!/usr/bin/env bash
# Criado por Alef Saad
# Dependências: wget, gnupg, snapd, flatpak, tar

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi
echo "Distribuição detectada: ${DISTRO:-indetectável}"

if [ "$DISTRO" = "debian" ]; then
    echo "Lendo arquivo /etc/debian_version e criando variáveis..."
    RAW=$(cat /etc/debian_version)
    echo "Detectando versão do Debian..."
    if [[ "$RAW" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        DEB_VER=$(echo "$RAW" | cut -d'.' -f1)
    else
        case "$RAW" in
        *stretch*)  DEB_VER=9 ;;
        *buster*)   DEB_VER=10 ;;
        *bullseye*) DEB_VER=11 ;;
        *bookworm*) DEB_VER=12 ;;
        *trixie*)   DEB_VER=13 ;;
        *forkys*)   DEB_VER=14 ;;
        unstable|sid)
            DEB_VER=99 ;;
        *)
            DEB_VER=0 ;;
        esac
    fi
    echo "Sistema baseado em Debian detectado (versão principal: $DEB_VER)."
    echo "É de acordo com a versão do Debian. Se for Sid, será 99 e se não for reconhecível, será 0."
    return 0
fi

# Perguntando a versão do Firefox que você gostaria de instalar.
echo "Qual versão do Firefox você gostaria de instalar? Normal (digite 'firefox'), ESR (digite 'firefox-esr'),"
echo "Beta (digite 'firefox-beta', Dev Edition (digite 'firefox-devedition) ou o Nightly (digite 'firefox-nightly')."
read firefox_version

# Criando variáveis para comandos echo
if [ "$firefox_version" = "firefox" ]; then
    firefox_name="Normal"
elif [ "$firefox_version" = "firefox-esr" ]; then
    firefox_name="ESR"
elif [ "$firefox_version" = "firefox-beta" ]; then
    firefox_name="Beta"
elif [ "$firefox_version" = "firefox-devedition" ]; then
    firefox_name="Dev Edition"
elif [ "$firefox_version" = "firefox-nightly" ]; then
    firefox_name="Nightly"
else
    echo "Versão do Firefox não detectada. Digite 'firefox', 'firefox-esr', 'firefox-beta', 'firefox-devedition' ou 'firefox-nightly'."
    exit 1
fi

firefox_name=${firefox_name:-unknown}

# Criando variáveis para Snap
if [ "$firefox_version" = "firefox" ]; then
    firefox_snap_ver="latest/stable"
elif [ "$firefox_version" = "firefox-esr" ]; then
    firefox_snap_ver="esr/stable"
elif [ "$firefox_version" = "firefox-beta" ]; then
    firefox_snap_ver="latest/beta"
elif [ "$firefox_version" = "firefox-nightly" ]; then
    firefox_snap_ver="latest/edge"
elif [ "$firefox_version" = "firefox-devedition" ]; then
    echo "A versão Dev Edition do Firefox não tem suporte a Snaps."
    firefox_snap_ver="unsupported"
else
    echo "Versão do Firefox não detectada. Digite 'firefox', 'firefox-esr', 'firefox-beta', 'firefox-devedition' ou 'firefox-nightly'."
    exit 1
fi

firefox_snap_ver=${firefox_snap_ver:-unknown}

# Criando variáveis para Tarball
if [ "$firefox_version" = "firefox" ]; then
    firefox_tarball_link="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=pt-BR"
elif [ "$firefox_version" = "firefox-esr" ]; then
    firefox_tarball_link="https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=linux64&lang=pt-BR"
elif [ "$firefox_version" = "firefox-beta" ]; then
    firefox_tarball_link="https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=linux64&lang=pt-BR"
elif [ "$firefox_version" = "firefox-nightly" ]; then
    firefox_tarball_link="https://download.mozilla.org/?product=firefox-nightly-latest-l10n-ssl&os=linux64&lang=pt-BR"
elif [ "$firefox_version" = "firefox-devedition" ]; then
    firefox_tarball_link="https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=pt-BR"
else
    echo "Versão do Firefox não detectada. Digite 'firefox', 'firefox-esr', 'firefox-beta', 'firefox-devedition' ou 'firefox-nightly'."
    exit 1
fi

# Estabelecendo funções

install_debian() {
    echo "Atenção, este script requer as dependências wget e gnupg, que serão instaladas."
    echo "Instalando wget e gnupg..."
    sudo apt install wget gnupg -y
    echo "Criando um diretório para armazenar chaves do repositório APT, se ainda não existir..."
    sudo install -d -m 0755 /etc/apt/keyrings
    echo "Importando a chave de assinatura do repositório APT da Mozilla..."
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    echo "Verificando fingerprint..."
    gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nO fingerprint da chave corresponde ("$0").\n"; else print "\nFalha na verificação: o fingerprint ("$0") não corresponde ao esperado.\n"}'
    echo "Adicionando repositório APT à lista de origens..."
    if [ "$DEB_VER" -le "12" ]; then
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
    else
cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
    fi
    echo "Configurando APT para dar prioridade ao repositório da Mozilla..."
    printf "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" \
    | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
    echo "Atualizando o repositório e instalando a versão $firefox_name do Firefox..."
    sudo apt update && sudo apt install $firefox_version -y
    echo "Instalando o pacote de idioma em português do Firefox..."
    sudo apt install firefox-l10n-pt-br -y
    echo "Instalação finalizada!"
    exit 0
}

install_snap() {
    echo "Certifique-se de ter o snapd instalado."
    if [ "$firefox_snap_ver" = "unsupported" ]; then
        echo "A versão Dev Edition não possui suporte a Snaps, busque outra."
        exit 2
    elif [ "$firefox_snap_ver" = "unknown" ]; then
        echo "Versão desconhecida. Escolha 'firefox', 'firefox-esr', 'firefox-beta' ou 'firefox-nightly' se quiser instalar via Snaps."
        exit 1
    else
        return 0
    fi
    echo "Instalando a versão $firefox_name do Firefox pelo channel $firefox_snap_ver do Firefox..."
    sudo snap install firefox --channel=$firefox_snap_ver
}

install_flatpak() {
    echo "Certifique-se de ter o Flatpak com o repositório Flathub. As versões ESR, Dev Edition e Nightly não estão disponíveis em Flatpak."
    if [ "$firefox_version" = "firefox" ]; then
        echo "Instalando a versão $firefox_name do Firefox em Flatpak..."
        flatpak install -y flathub org.mozilla.firefox
        echo "Instalação finalizada!"
        exit 0
    elif [ "$firefox_version" = "firefox-beta" ]; then
        echo "Instalando a versão $firefox_name do Firefox em Flatpak..."
        flatpak install -y flathub org.mozilla.firefox.Beta
        echo "Instalação finalizada!"
        exit 0
    else
        echo "Versão $firefox_name do Firefox não suportada pelo Flatpak ou versão desconhecida do Firefox."
        return 1
        return 2
    fi
}

install_tarball() {
    folder_tarball=$(pwd)
    echo "Baixaremos o tarball do Firefox para sistemas de 64-bits. Se a sua arquitetura for outra, faça manualmente."
    echo "Certifique-se de ter as dependências wget e tar."
    echo "Baixando o tarball do Firefox do site oficial..."
    wget -O $firefox_version-latest.tar.xz "$firefox_tarball_link"
    read -p "Aonde você gostaria de extrair o tarball?" folder_extract
    echo "Extraindo o tarball do Firefox..."
    tar xJf $firefox_version-latest.tar.xz -C $folder_extract
    echo "Criando link simbólico para o executável do Firefox..."
    ln -s $folder_tarball/firefox/firefox /usr/local/bin/firefox
    echo "Baixando uma cópia do arquivo da área de trabalho..."
    wget https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop -P /usr/local/share/applications
    echo "Removendo o arquivo tar.xz do Firefox..."
    rm "$folder_tarball/$firefox_version-latest.tar.xz"
    echo "Firefox instalado em $folder_extract. O executável do Firefox está em $folder_extract/firefox/firefox."
    return 0
}

install_firefox_native() {
    echo "O método do gerenciador nativo funciona nos seguintes gerenciadores de pacotes: dnf, zypp, pacman, xbps, apk e portage."
    echo "Instalando o Firefox via gerenciador nativo..."
    case "$DISTRO" in
        fedora|rhel|centos|rocky|almalinux) sudo dnf install -y $firefox_version ;;
        opensuse*|suse) sudo zypper install -y $firefox_version ;;
        arch|manjaro|endeavouros) sudo pacman -Syu --noconfirm $firefox_version ;;
        void) sudo xbps-install -Sy $firefox_version ;;
        alpine) sudo apk add --yes $firefox_version ;;
        gentoo) sudo emerge --ask=n www-client/$firefox_version ;;
        *)
            echo "Gerenciador nativo não reconhecido."
            return 1
            ;;
    esac
    echo "Firefox instalado via gerenciador nativo."
    exit 0
}

# Fluxo principal
case "$DISTRO" in
    debian|ubuntu|mint|pop|elementary|zorin)
        read -p "Você gostaria de instalar o tarball (digite 'tar'), o Flatpak (digite 'flatpak'), o Snap (digite 'snap') ou o repositório APT oficial da Mozilla (digite 'apt')? " inst_method_debian
        if [ "$inst_method_debian" = "tar" ]; then
            install_tarball
        elif [ "$inst_method_debian" = "flatpak" ]; then
            install_flatpak
        elif [ "$inst_method_debian" = "snap" ]; then
            install_snap
        elif [ "$inst_method_debian" = "apt" ]; then
            install_debian
        else
            echo "Erro: digite 'tar', 'flatpak', 'snap' ou 'apt'."
            return 1
        fi
        ;;
    *)
        echo "Se você quiser instalar via repositórios do sistema, faça isso manualmente."
        read -p "Você gostaria de instalar o tarball (digite 'tar'), o Flatpak (digite 'flatpak'), o Snap (digite 'snap')? ou pelo gerenciador de pacotes do sistema (digite 'native')? " inst_method_generic
        if [ "$inst_method_generic" = "tar" ]; then
            install_tarball
        elif [ "$inst_method_generic" = "flatpak" ]; then
            install_flatpak
        elif [ "$inst_method_generic" = "snap" ]; then
            install_snap
        elif [ "$inst_method_generic" = "native" ]; then
            install_firefox_native
        else
            echo "Erro: digite 'tar', 'flatpak' ou 'snap'."
            return 1
        fi
        ;;
esac
