#!/bin/bash
# Criado por Alef Saad

set -euo pipefail

# Detectar distribuição
DISTRO="desconhecida"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${ID:-desconhecido}" | tr '[:upper:]' '[:lower:]')
    NAME=${NAME:-desconhecido}
fi

# Ele requer sudo para escrever arquivos em /usr/bin.
if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Atenção: este script pode exigir privilégios de administrador. Execute com sudo se necessário."
fi

if [ "$DISTRO" = debian ]; then
    dir=$(pwd)
    echo "Escrevendo add-apt-repository.sh"
    touch $dir/add-apt-repository.sh
    cat <<'EOF' > "add-apt-repository.sh"
#!/bin/bash
# Fonte do script: https://diolinux.com.br/sistemas-operacionais/tem-como-instalar-ppa-no-debian.html
# Traduzido por Alef Saad
# add-apt-repository.sh

if [ $# -eq 1 ]

NM=`uname -a && date

NAME=`echo $NM | md5sum | cut -f1 -d" "`

then

ppa_name=`echo "$1" | cut -d":" -f2 -s`

if [ -z "$ppa_name" ]

then

echo "Nome do PPA não encontrado."

echo "Utilitário para adicionar repositórios PPA no seu Debian."

echo "$0 ppa:user/ppa-name"

else

echo "$ppa_name"

echo "deb http://ppa.launchpad.net/$ppa_name/ubuntu lucid main" >> /etc/apt/sources.list

apt-get update >> /dev/null 2> /tmp/${NAME}_apt_add_key.txt

key=`cat /tmp/${NAME}_apt_add_key.txt | cut -d":" -f6 | cut -d" " -f3`

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key

rm -rf /tmp/${NAME}_apt_add_key.txt

fi

else

echo "Utilitáio para adicionar repositórios PPA no seu Debian."

echo "$0 ppa:user/ppa-name"

fi
EOF
    echo "Dando as permissões de execução..."
    chmod +x $dir/add-apt-repository.sh
    echo "Movendo para a pasta /usr/bin..."
    sudo mv $dir/add-apt-repository.sh /usr/bin
    echo "Criando links simbólicos..."
    sudo ln -s /usr/bin/add-apt-repository.sh /usr/bin/apt-add-repository.sh
    sudo ln -s /usr/bin/add-apt-repository.sh /usr/sbin/add-apt-repository.sh
    sudo ln -s /usr/bin/add-apt-repository.sh /usr/sbin/apt-add-repository.sh
    echo "Agora você pode dar o comando add-apt-repository ou apt-add-repository no seu terminal e adicionar repositórios PPA no seu sistema Debian."
    exit 0
else
    echo "Seu sistema precisa ser Debian para o script funcionar, caso contrário ele não terá necessidade."
    exit 1
fi





