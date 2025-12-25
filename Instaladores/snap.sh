#!/bin/bash
# Criado por Alef Saad
# Dependências: systemd e um gerenciador de pacotes

set -euo pipefail

DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi
echo "Distribuição detectada: ${NAME:-indetectável}"

if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
else
    PKG_MANAGER="desconhecido"
fi

echo "Gerenciador de pacotes detectado: $PKG_MANAGER"


if [ "$DISTRO" = "rhel" ]; then
    echo "Lendo arquivo /etc/os-release e criando variáveis..."
    RAW=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    echo "Detectando versão do RHEL..."

    # Para RHEL 7, 8 e 9, o VERSION_ID é sempre algo como '7.9', '8.8', '9.3' etc.
    if [[ "$RAW" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        rhel_ver=$(echo "$RAW" | cut -d'.' -f1)
    else
        # Apenas por segurança, embora RHEL sempre tenha VERSION_ID numérico
        rhel_ver=0
    fi

    echo "Sistema RHEL detectado (versão principal: $rhel_ver)."
    echo "Detectado conforme o VERSION_ID do RHEL. Se não for reconhecível, será 0."
    return 0
fi

DE=$XDG_CURRENT_DESKTOP=$(echo "${XDG_CURRENT_DESKTOP:-desconhecido}" | tr '[:upper:]' '[:lower:]')

echo "O snapd tem como dependência o systemd, não podendo funcionar sem ele."

snap_store_install() {
    if [ "$DISTRO" = "ubuntu" ] && [ "$DE" = "gnome" ]; then
        echo "Em sistemas Ubuntu tradicionais, como este, a Snap Store, o snapd e o pacote apt do snap já vem instalados por padrão."
        echo "Gostaria de instalar a GNOME Software com o plugin Snap?"
        read gnome_software_confirm
        gnome_software_confirm=$(echo "${gnome_software_confirm}" | tr '[:upper:]' '[:lower:]')
        if [ "gnome_software_confirm" = "s" ]; then
            echo "Instalando a GNOME Software..."
            sudo apt install gnome-software gnome-software-plugin-snap -y
            exit 0
        elif [ "gnome_software_confirm" = "y" ]; then
            echo "Instalando a GNOME Software..."
            sudo apt install gnome-software gnome-software-plugin-snap -y
            exit 0
        elif [ "gnome_software_confirm" = "n" ]; then
            echo "Instalação recusada."
            exit 0
        else
            echo "Input inválido."
            exit 1
        fi
    elif [ "$DISTRO" = "ubuntu" ] && [ "$DE" = "mate" ]; then
        echo "Em sistemas Ubuntu MATE, o snapd não vem pré-instalado."
        echo "Atualizando os repositórios..."
        sudo apt update
        echo "Instalando o snapd..."
        sudo apt install snapd
        echo "Testando o snapd..."
        sudo snap install hello-world
        command hello-world
        echo "Instalação do snapd finalizada."
    else
        return 0
    fi
    echo "Gostaria de instalar a Snap Store? (s/n)"
    read snap_store_confirm
    snap_store_confirm=$(echo "${snap_store_confirm}" | tr '[:upper:]' '[:lower:]')
    if [ "snap_store_confirm" = "s" ]; then
        echo "Instalando a Snap Store..."
        sudo snap install snap-store
        plugin_store
    elif [ "snap_store_confirm" = "y" ]; then
        echo "Instalando a Snap Store..."
        sudo snap install snap-store
        plugin_store
    elif [ "snap_store_confirm" = "n" ]; then
        plugin_store
    else
        echo "Input inválido."
        return 1
    fi
}

plugin_store() {
    echo "Este script suporta: apt, dnf, zypper, pacman e o yum."
    if [ "$DE" = "gnome" ] || [ "$DE" = "budgie" ] || [ "$DE" = "xfce" ] || [ "$DE" = "mate" ] || [ "$DE" = "unity" ]; then
        if [ "$PKG_MANAGER" = "apt" ] || [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
            echo "Instalando a GNOME Software e o plugin Snap pelo $PKG_MANAGER..."
            sudo $PKG_MANAGER install -y gnome-software gnome-software-plugin-snap
        elif [ "$PKG_MANAGER" = "zypper" ]; then
            echo "Instalando a GNOME Software e o plugin Snap pelo Zypp..."
            sudo zypper install -n gnome-software gnome-software-plugin-snap
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            echo "Instalando a GNOME Software e o plugin Snap pelo Pacman..."
            sudo pacman -S --noconfirm gnome-software gnome-software-plugin-snap
        else
            echo "Gerenciador de pacotes não suportado pelo script."
        fi
    elif [ "$DE" = "kde" ] || [ "$DE" = "lxqt" ] || [ "$DE" = "lxde" ]; then
        if [ "$PKG_MANAGER" = "apt" ] || [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
            echo "Instalando o Plasma Discover e o Snap backend pelo $PKG_MANAGER..."
            sudo $PKG_MANAGER install -y plasma-discover plasma-discover-backend-snap
        elif [ "$PKG_MANAGER" = "zypper" ]; then
            echo "Instalando a GNOME Software e o plugin Snap pelo Zypp..."
            sudo zypper install -n plasma-discover plasma-discover-backend-snap
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            echo "Instalando a GNOME Software e o plugin Snap pelo Pacman..."
            sudo pacman -S --noconfirm plasma-discover plasma-discover-backend-snap
        else
            echo "Gerenciador de pacotes não suportado pelo script."
        fi
    else
        echo "Interface não suportada ou sistema sem interface. Deseja instalar a GNOME Software (sem o GNOME)?"
        echo "Recomendado para contêiner Crostini (Debian) do ChromeOS, mas não recomendado para outros sistemas."
        read gnome_software_confirm
        if [ "gnome_software_confirm" = "s" ]; then
            echo "Instalando a GNOME Software..."
            sudo apt install gnome-software gnome-software-plugin-snap -y
            exit 0
        elif [ "gnome_software_confirm" = "y" ]; then
            echo "Instalando a GNOME Software..."
            sudo apt install gnome-software gnome-software-plugin-snap -y
            exit 0
        elif [ "gnome_software_confirm" = "n" ]; then
            echo "Instalação recusada."
            exit 0
        else
            echo "Input inválido."
            exit 1
        fi
}

alma_rocky_inst_snapd() {
    echo "Instalando o EPEL (Extra Packages for Enterprise Linux)..."
    sudo dnf install -y epel-release
    sudo dnf upgrade -y
    echo "Instalando o snapd..."
    sudo dnf install -y snapd
    echo "Habilitando o serviço do snapd..."
    sudo systemctl enable --now snapd.socket
    echo "Habilitando o suporte aos snaps clássicos..."
    sudo ln -s /var/lib/snapd/snap /snap
    echo "Instalação do snapd finalizada."
    snap_store_install
}

centos_inst_snapd() {
    echo "Instalando o EPEL (Extra Packages for Enterprise Linux)..."
    sudo yum install -y epel-release
    sudo yum upgrade -y
    echo "Instalando o snapd..."
    sudo yum install -y snapd
    echo "Habilitando o serviço do snapd..."
    sudo systemctl enable --now snapd.socket
    echo "Habilitando o suporte aos snaps clássicos..."
    sudo ln -s /var/lib/snapd/snap /snap
    echo "Instalação do snapd finalizada."
    snap_store_install
}

arch_inst_snapd() {
    echo "Este script suporta o yay, o paru e a instalação manual por padrão. Se quiser utilizar outro AUR helper, faça-o manualmente."
    user=$(logname)
    if command -v yay >/dev/null 2>&1; then
        echo "Instalando o snapd pelo yay..."
        sudo -u "$user" yay -S --noconfirm snapd
        echo "Instalação do snapd finalizada."
        snap_store_install
    elif command -v paru >/dev/null 2>&1; then
        echo "Instalando o snapd via paru..."
        sudo -u "$user" paru -S --noconfirm snapd
        echo "Instalação do snapd finalizada."
        snap_store_install
    else
        echo "Em qual diretório você gostaria de instalar o pacote?"
        read dir_inst
        cd $dir_inst
        echo "Clonando o repositório do git em $dir_inst..."
        git clone https://aur.archlinux.org/snapd.git
        cd snapd
        echo "Estamos em $pwd."
        echo "Instalando o pacote do snapd..."
        sudo -u "$user" makepkg -si --noconfirm
        echo "Habilitando o serviço do snapd..."
        sudo systemctl enable --now snapd.socket
        echo "Habilitando o contêiner do AppArmor do snapd..."
        sudo systemctl enable --now snapd.apparmor.service
        echo "Habilitando o suporte aos snaps clássicos..."
        sudo ln -s /var/lib/snapd/snap /snap
        echo "Testando o contêiner do snapd..."
        sudo snap install hello-world
        command hello-world.evil
        echo "Instalação do snapd finalizada."
        snap_store_install
    fi
}

STATE_FILE="/var/tmp/install_snap_state"

# Determine em que etapa estamos:
state="start"
if [ -f "$STATE_FILE" ]; then
  state=$(cat "$STATE_FILE")
fi


debian_inst_snapd() {
    echo "Para instalar o snapd em sistemas baseados em Debian, será necessário reinicializar o computador. Para isso, você terá que rodar o script manualmente algumas vezes."
    echo "Criando o arquivo STATE_FILE para as reinicializações..."
    STATE_FILE="/var/tmp/install_snap_state"
    state="start"
    if [ -f "$STATE_FILE" ]; then
        state=$(cat "$STATE_FILE")
    fi
    case "$state" in
        start)
            echo "Atualizando os repositórios..."
            sudo apt update
            echo "Instalando o snapd..."
            sudo apt install -y snapd
            echo "after_snapd" > "$STATE_FILE"
            echo "Reiniciando para completar instalação do snapd..."
            sudo reboot
            ;;
        after_snapd)
            echo "Instalar o snapd via Snap na versão mais recente..."
            sudo snap install snapd || true
            # (às vezes instalar snapd via snap pode falhar se já estiver instalado — por isso o || true)
            echo "Testando o snapd..."
            sudo snap install hello-world
            hello-world || echo "Aviso: hello-world falhou — talvez PATH ou permissão"
            echo "done" > "$STATE_FILE"
            ;;
        done)
            echo "Trabalhando na resolução de problemas do snapd ao instalar e atualizar o pacote core..."
            sudo snap install core
            sudo snap refresh
            echo "Instalação do snapd finalizada."
            snap_store_install
            ;;
        *)
            echo "Estado desconhecido no arquivo $STATE_FILE: '$state'"
            exit 1
            ;;
    esac
}

mint_inst_snapd() {
    echo "Para instalar o snapd em sistemas Linux Mint, será necessário reinicializar o computador. Para isso, você terá que rodar o script manualmente algumas vezes."
    echo "Criando o arquivo STATE_FILE para as reinicializações..."
    STATE_FILE="/var/tmp/install_snap_state"
    state="start"
    if [ -f "$STATE_FILE" ]; then
        state=$(cat "$STATE_FILE")
    fi
    case "$state" in
        start)
            echo "Seu sistema é o $NAME."
            folder_preferences=/etc/apt/preferences.d
            echo "Movendo o $folder_preferences/nosnap.pref para $folder_preferences/nosnap.backup..."
            sudo mv $folder_preferences/nosnap.pref $folder_preferences/nosnap.backup
            echo "Atualizando repositórios..."
            sudo apt update
            echo "Instalando o snapd..."
            sudo apt install snapd -y
            echo "Reinicializando o computador..."
            sudo reboot
            ;;
        after_snapd)
            echo "Testando o snapd..."
            sudo snap install hello-world
            hello-world || echo "Aviso: hello-world falhou — talvez PATH ou permissão"
            echo "done" > "$STATE_FILE"
            ;;
        done)
            echo "Instalação do snapd finalizada."
            snap_store_install
            ;;
        *)
            echo "Estado desconhecido no arquivo $STATE_FILE: '$state'"
            return 1
            ;;
    esac
}

opensuse_inst_snapd() {
    case "$DISTRO" in
        opensuse-leap)
            echo "Adicionando o repositório do $PRETTY_NAME..."
            sudo zypper addrepo --refresh \
            https://download.opensuse.org/repositories/system:/snappy/openSUSE_Leap_$VERSION_ID \
            snappy
             ;;
        opensuse-tumbleweed)
            echo "Adicionando o repositório do $PRETTY_NAME..."
            sudo zypper addrepo --refresh \
            https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed \
            snappy ;;
        *)
            echo "Este sistema não é openSUSE."
            return 2
    esac
    echo "Importando a chave GPG do repositório snappy..."
    sudo zypper --gpg-auto-import-keys refresh
    echo "Atualizando o cache de pacotes para incluir o repositório snappy..."
    sudo zypper dup --from snappy
    echo "Instalando o snapd..."
    sudo zypper install -n snapd
    echo "Habilitando o serviço do snapd..."
    sudo systemctl enable --now snapd
    echo "Habilitando o serviço AppArmor do snapd..."
    sudo systemctl enable --now snapd.apparmor
    echo "Instalação do snapd finalizada."
    snap_store_install
}

rhel_inst_snapd() {
    echo "Instalando o EPEL (Extra Packages for Enterprise Linux) para o $NAME $rhel_ver..."
    if [ "$rhel_ver" = "7" ]; then
        sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    elif [ "$rhel_ver" = "8" ]; then
        sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        echo "Atualizando pacotes e repositórios..."
        sudo dnf upgrade -y
    elif [ "$rhel_ver" = "9" ]; then
        sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
        echo "Atualizando pacotes e repositórios..."
        sudo dnf upgrade -y
    else
        echo "A versão do RHEL não pode ser detectada ou é incompatível com o snapd."
        echo "A versão deve ser: RHEL 7, RHEL 8 ou RHEL 9."
        return 2
    fi
    echo "Adicionando repositórios opcionais e extras..."
    sudo subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"
    echo "Atualizando repositórios..."
    sudo yum update -y
    echo "Instalando o snapd..."
    sudo yum install snapd
    echo "Habilitando a unidade do systemd do socket de comunicação principal do snapd..."
    sudo systemctl enable --now snapd.socket
    echo "Habilitando suporte aos snaps clássicos..."
    sudo ln -s /var/lib/snapd/snap /snap
    echo "Instalação do snapd finalizada."
    snap_store_install
}

case "$DISTRO" in
    ubuntu)
        echo "Seu sistema é o $NAME."
        snap_store_install
        exit 0 ;;
    manjaro|neon|solus|zorin)
        echo "Seu sistema é o $NAME."
        echo "Ele vem com o snap e o snapd instalado por padrão."
        snap_store_install ;;
    almalinux|rocky)
        echo "Seu sistema é o $NAME."
        alma_rocky_inst_snapd ;;
    arch|endeavouros)
        echo "Seu sistema é o $NAME."
        arch_inst_snapd ;;
    debian|raspbian)
        echo "Seu sistema é o $NAME."
        debian_inst_snapd ;;
    elementary|pop)
        echo "Seu sistema é o $NAME."
        echo "Atualizando repositórios..."
        sudo apt update
        echo "Instalando o snapd..."
        sudo apt install snapd -y
        echo "Testando o snapd..."
        sudo snap install hello-world
        command hello-world
        echo "Instalação do snapd finalizada."
        snap_store_install ;;
    fedora)
        echo "Seu sistema é o $NAME."
        echo "Instalando o snapd..."
        sudo dnf install -y snapd
        echo "Habilitando suporte aos snaps clássicos..."
        sudo ln -s /var/lib/snapd/snap /snap
        echo "Testando o snapd..."
        sudo snap install hello-world
        command hello-world
        echo "Instalação do snapd finalizada."
        snap_store_install ;;
    mint)
        echo "Seu sistema é o $NAME."
        mint_inst_snapd ;;
    opensuse*)
        echo "Seu sistema é o $NAME."
        opensuse_inst_snapd ;;
    centos)
        echo "Seu sistema é o $NAME."
        centos_inst_snapd ;;
    rhel)
        echo "Seu sistema é o $NAME $rhel_ver."
        rhel_inst_snapd ;;
esac
