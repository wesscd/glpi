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
    echo "Tentando baixar $url" >> erros.log
    wget --debug "$url" -O "$arquivo" 2>> erros.log
    if [ $? -ne 0 ]; then
        echo "Erro ao baixar $nome"
        echo "$nome - Falha no download: veja erros.log para detalhes" >> erros.log
        return 1
    fi
    sleep 5  # Adiciona delay de 5 segundos para evitar rate-limiting

    case "$tipo_arquivo" in
        zip)
            unzip -q "$arquivo" || echo "$nome - Erro ao extrair zip" >> erros.log;;
        tar.bz2)
            tar -xjf "$arquivo" || echo "$nome - Erro ao extrair tar.bz2" >> erros.log;;
        tar.gz | tgz | tar.tgz)
            tar -xzf "$arquivo" || echo "$nome - Erro ao extrair tar.gz" >> erros.log;;
        *)
            echo "Tipo de arquivo desconhecido: $tipo_arquivo"
            echo "$nome - Tipo de arquivo desconhecido: $tipo_arquivo" >> erros.log
            return 1;;
    esac

    rm -f "$arquivo"

    if [ -n "$pasta_destino" ]; then
        mv */ "$pasta_destino" 2>> erros.log || echo "$nome - Erro ao mover arquivos para $pasta_destino" >> erros.log
    fi

    echo "Plugin $nome instalado com sucesso."
}

# Plugins com versão e URL atualizada
instalar_plugin "actualtime" \
    "https://github.com/ticgal/actualtime/releases/download/3.2.0/glpi-actualtime-3.2.0.tar.bz2" \
    "tar.bz2"

instalar_plugin "fields" \
    "https://github.com/pluginsGLPI/fields/releases/download/1.21.13/glpi-fields-1.21.13.tar.bz2" \
    "tar.bz2"

instalar_plugin "formcreator" \
    "https://github.com/pluginsGLPI/formcreator/releases/download/2.13.10/glpi-formcreator-2.13.10.tar.bz2" \
    "tar.bz2"

instalar_plugin "genericobject" \
    "https://github.com/pluginsGLPI/genericobject/releases/download/2.14.14/glpi-genericobject-2.14.14.tar.bz2" \
    "tar.bz2"

instalar_plugin "trademark" \
    "https://github.com/edgardmessias/glpi-trademark/releases/download/v2.0.2/trademark.zip" \
    "zip"

instalar_plugin "datainjection" \
    "https://github.com/pluginsGLPI/datainjection/releases/download/2.14.1/glpi-datainjection-2.14.1.tar.bz2" \
    "tar.bz2"

instalar_plugin "pdf" \
    "https://github.com/pluginsGLPI/pdf/releases/download/4.0.1/glpi-pdf-4.0.1.tar.bz2" \
    "tar.bz2"

instalar_plugin "moreticket" \
    "https://github.com/InfotelGLPI/moreticket/releases/download/1.7.5/glpi-moreticket-1.7.5.tar.bz2" \
    "tar.bz2"

instalar_plugin "mailcollector" \
    "https://github.com/edgardmessias/glpi-fixmailcollector/releases/download/v1.0.1/fixmailcollector.zip" \
    "zip"

instalar_plugin "uninstall" \
    "https://github.com/pluginsGLPI/uninstall/releases/download/2.9.4/glpi-uninstall-2.9.4.tar.bz2" \
    "tar.bz2"

instalar_plugin "positions" \
    "https://github.com/InfotelGLPI/positions/releases/download/6.0.3/glpi-positions-6.0.3.tar.bz2" \
    "tar.bz2"

instalar_plugin "glpiinventory" \
    "https://github.com/glpi-project/glpi-inventory-plugin/releases/download/1.5.3/glpi-glpiinventory-1.5.3.tar.bz2" \
    "tar.bz2"

instalar_plugin "behaviors" \
    "https://github.com/yllen/behaviors/releases/download/v1.4.0/behaviors-1.4.0.tar.gz" \
    "tar.gz"

instalar_plugin "addressing" \
    "https://github.com/pluginsGLPI/addressing/releases/download/3.0.3/glpi-addressing-3.0.3.tar.bz2" \
    "tar.bz2"

instalar_plugin "timelineticket" \
    "https://github.com/pluginsGLPI/timelineticket/releases/download/10.0%2B1.2/glpi-timelineticket-10.0+1.2.tar.bz2" \
    "tar.bz2"

instalar_plugin "archires" \
    "https://github.com/InfotelGLPI/archires/releases/download/1.0.2/glpi-archires-1.0.2.tar.bz2" \
    "tar.bz2"

instalar_plugin "dashboard" \
    "https://github.com/stdonato/glpi-dashboard/archive/refs/tags/1.0.2.tar.gz" \
    "tar.gz"

echo "\n$(tput setaf 2)Instalação concluída. Verifique erros.log para eventuais falhas.$(tput sgr0)"
