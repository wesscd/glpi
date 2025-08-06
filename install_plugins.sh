#!/bin/bash

# Diretório de destino para os plugins
read -p "Digite o caminho completo do diretório de plugins do GLPI: " diretorio

if [ ! -d "$diretorio" ]; then
    echo "Diretório inválido: $diretorio"
    exit 1
fi

cd "$diretorio" || exit 1

# Função genérica para instalar plugins
instalar_plugin() {
    local nome="$1"
    local url="$2"
    local tipo_arquivo="$3"
    local pasta_destino="$4"

    echo "\n$(tput setaf 6)#--------------------------------------------------------#"
    echo "INSTALANDO O PLUGIN: $(tput bold)$nome$(tput sgr0)"
    echo "$(tput setaf 6)#--------------------------------------------------------#$(tput sgr0)"

    local arquivo="${nome}.${tipo_arquivo}"
    wget -q --show-progress "$url" -O "$arquivo"
    if [ $? -ne 0 ]; then
        echo "Erro ao baixar $nome"
        echo "$nome - Falha no download" >> erros.log
        return 1
    fi

    case "$tipo_arquivo" in
        zip)
            unzip -q "$arquivo";;
        tar.bz2)
            tar -xjf "$arquivo";;
        tar.gz | tgz | tar.tgz)
            tar -xzf "$arquivo";;
        *)
            echo "Tipo de arquivo desconhecido: $tipo_arquivo"
            echo "$nome - Tipo de arquivo desconhecido: $tipo_arquivo" >> erros.log
            return 1;;
    esac

    rm -f "$arquivo"

    if [ -n "$pasta_destino" ]; then
        mv */ "$pasta_destino" 2>/dev/null
    fi

    echo "Plugin $nome instalado com sucesso."
}

# Plugins com versão e URL atualizada
instalar_plugin "actualtime" \
    "https://github.com/pluginsGLPI/actualtime/releases/download/3.2.0/actualtime-3.2.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "fields" \
    "https://github.com/pluginsGLPI/fields/releases/download/1.21.13/fields-1.21.13.tar.bz2" \
    "tar.bz2"

instalar_plugin "formcreator" \
    "https://github.com/pluginsGLPI/formcreator/releases/download/2.13.10/formcreator-2.13.10.tar.bz2" \
    "tar.bz2"

instalar_plugin "genericobject" \
    "https://github.com/pluginsGLPI/genericobject/releases/download/2.14.14/genericobject-2.14.14.tar.bz2" \
    "tar.bz2"

instalar_plugin "trademark" \
    "https://github.com/pluginsGLPI/trademark/releases/download/1.4.1/trademark-1.4.1.tar.bz2" \
    "tar.bz2"

instalar_plugin "datainjection" \
    "https://github.com/pluginsGLPI/datainjection/releases/download/2.13.4/datainjection-2.13.4.tar.bz2" \
    "tar.bz2"

instalar_plugin "pdf" \
    "https://github.com/pluginsGLPI/pdf/releases/download/1.6.1/pdf-1.6.1.tar.bz2" \
    "tar.bz2"

instalar_plugin "moreticket" \
    "https://github.com/pluginsGLPI/moreticket/releases/download/1.4.1/moreticket-1.4.1.tar.bz2" \
    "tar.bz2"

instalar_plugin "mailcollector" \
    "https://github.com/pluginsGLPI/mailcollector/releases/download/1.0.2/mailcollector-1.0.2.tar.bz2" \
    "tar.bz2"

instalar_plugin "uninstall" \
    "https://github.com/pluginsGLPI/uninstall/releases/download/1.4.0/uninstall-1.4.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "positions" \
    "https://github.com/pluginsGLPI/positions/releases/download/2.13.2/positions-2.13.2.tar.bz2" \
    "tar.bz2"

instalar_plugin "customfields" \
    "https://github.com/pluginsGLPI/customfields/releases/download/1.12.0/customfields-1.12.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "glpiinventory" \
    "https://github.com/glpi-project/glpi-inventory-plugin/releases/download/1.7.3/glpi-glpiinventory-1.7.3.tar.bz2" \
    "tar.bz2"

instalar_plugin "behaviors" \
    "https://github.com/pluginsGLPI/behaviors/releases/download/2.13.1/behaviors-2.13.1.tar.bz2" \
    "tar.bz2"

instalar_plugin "addressing" \
    "https://github.com/pluginsGLPI/addressing/releases/download/2.13.0/addressing-2.13.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "timelineticket" \
    "https://github.com/pluginsGLPI/timelineticket/releases/download/1.4.0/timelineticket-1.4.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "archires" \
    "https://github.com/pluginsGLPI/archires/releases/download/2.13.0/archires-2.13.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "dashboard" \
    "https://github.com/pluginsGLPI/dashboard/releases/download/1.5.1/dashboard-1.5.1.tar.bz2" \
    "tar.bz2"

echo "\n$(tput setaf 2)Instalação concluída. Verifique erros.log para eventuais falhas.$(tput sgr0)"
