#!/bin/bash

# -----------------------------------------------------------------------------
# Script de Instalação de Plugins para GLPI
#
# Este script automatiza o download e a instalação de plugins para o GLPI.
#
# Autor: Seu Nome
# Versão: 2.0
# Data: 26/09/2025
#
# Pré-requisitos:
# - GLPI já instalado.
# - Permissões de escrita no diretório de plugins.
#
# O que o script faz:
# 1.  Solicita o diretório de plugins do GLPI.
# 2.  Define uma lista de plugins a serem instalados.
# 3.  Itera sobre a lista, baixando e extraindo cada plugin.
# 4.  Registra erros em um arquivo de log (erros.log).
# 5.  Limpa os arquivos de instalação após a conclusão.
# -----------------------------------------------------------------------------

# --- Funções Auxiliares ---

# Função para registrar mensagens de log com data e hora.
log_error() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> erros.log
}

# Função genérica para instalar plugins.
install_plugin() {
    local name="$1"
    local url="$2"
    local type="$3"
    local temp_file="${name}.${type}"

    echo "--------------------------------------------------------"
    echo "Instalando o plugin: ${name}"
    echo "--------------------------------------------------------"

    # Baixar o plugin
    wget --no-verbose "$url" -O "$temp_file" 2>> erros.log
    if [ $? -ne 0 ]; then
        log_error "Falha no download do plugin: ${name}. URL: ${url}"
        return 1
    fi

    # Extrair o plugin
    case "$type" in
        zip)
            unzip -q "$temp_file"
            ;;
        tar.bz2)
            tar -xjf "$temp_file"
            ;;
        tar.gz|tgz)
            tar -xzf "$temp_file"
            ;;
        *)
            log_error "Tipo de arquivo desconhecido para o plugin ${name}: ${type}"
            rm -f "$temp_file"
            return 1
            ;;
    esac

    if [ $? -ne 0 ]; then
        log_error "Falha ao extrair o plugin: ${name}"
        rm -f "$temp_file"
        return 1
    fi

    # Limpar o arquivo baixado
    rm -f "$temp_file"
    echo "Plugin ${name} instalado com sucesso."
    sleep 2 # Pequeno delay para evitar sobrecarga
}

# --- Início da Execução ---

# 1. Obter o diretório de plugins
read -p "Digite o caminho completo para o diretório de plugins do GLPI (ex: /var/www/html/glpi/plugins): " plugins_dir

if [ ! -d "$plugins_dir" ]; then
    echo "Erro: O diretório '$plugins_dir' não existe."
    exit 1
fi

cd "$plugins_dir" || exit 1
touch erros.log # Garante que o arquivo de log exista

# 2. Lista de plugins a serem instalados
# Formato: "nome_plugin|url_plugin|tipo_arquivo"
declare -a plugins=(
    "actualtime|https://github.com/ticgal/actualtime/releases/download/3.2.0/glpi-actualtime-3.2.0.tar.bz2|tar.bz2"
    "fields|https://github.com/pluginsGLPI/fields/releases/download/1.21.13/glpi-fields-1.21.13.tar.bz2|tar.bz2"
    "formcreator|https://github.com/pluginsGLPI/formcreator/releases/download/2.13.10/glpi-formcreator-2.13.10.tar.bz2|tar.bz2"
    "genericobject|https://github.com/pluginsGLPI/genericobject/releases/download/2.14.14/glpi-genericobject-2.14.14.tar.bz2|tar.bz2"
    "trademark|https://github.com/edgardmessias/glpi-trademark/releases/download/v2.0.2/trademark.zip|zip"
    "datainjection|https://github.com/pluginsGLPI/datainjection/releases/download/2.14.1/glpi-datainjection-2.14.1.tar.bz2|tar.bz2"
    "pdf|https://github.com/pluginsGLPI/pdf/releases/download/4.0.1/glpi-pdf-4.0.1.tar.bz2|tar.bz2"
    "moreticket|https://github.com/InfotelGLPI/moreticket/releases/download/1.7.5/glpi-moreticket-1.7.5.tar.bz2|tar.bz2"
    "mailcollector|https://github.com/edgardmessias/glpi-fixmailcollector/releases/download/v1.0.1/fixmailcollector.zip|zip"
    "uninstall|https://github.com/pluginsGLPI/uninstall/releases/download/2.9.4/glpi-uninstall-2.9.4.tar.bz2|tar.bz2"
    "positions|https://github.com/InfotelGLPI/positions/releases/download/6.0.3/glpi-positions-6.0.3.tar.bz2|tar.bz2"
    "glpiinventory|https://github.com/glpi-project/glpi-inventory-plugin/releases/download/1.5.3/glpi-glpiinventory-1.5.3.tar.bz2|tar.bz2"
    "behaviors|https://github.com/yllen/behaviors/releases/download/v1.4.0/behaviors-1.4.0.tar.gz|tar.gz"
    "addressing|https://github.com/pluginsGLPI/addressing/releases/download/3.0.3/glpi-addressing-3.0.3.tar.bz2|tar.bz2"
    "timelineticket|https://github.com/pluginsGLPI/timelineticket/releases/download/10.0%2B1.2/glpi-timelineticket-10.0+1.2.tar.bz2|tar.bz2"
    "archires|https://github.com/InfotelGLPI/archires/releases/download/1.0.2/glpi-archires-1.0.2.tar.bz2|tar.bz2"
    "dashboard|https://github.com/stdonato/glpi-dashboard/archive/refs/tags/1.0.2.tar.gz|tar.gz"
)

# 3. Processar a instalação dos plugins
for plugin_data in "${plugins[@]}"; do
    IFS='|' read -r name url type <<< "$plugin_data"
    install_plugin "$name" "$url" "$type"
done

# 4. Mensagem final
echo -e "\n\033[1;32mInstalação de plugins concluída.\033[0m"
echo "Verifique o arquivo 'erros.log' para detalhes sobre possíveis falhas."