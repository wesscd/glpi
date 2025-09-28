#!/bin/bash

# Função para logging com cores e arquivo
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="/var/log/glpi_backup.log"

    local red='\033[0;31m'
    local green='\033[0;32m'
    local yellow='\033[1;33m'
    local nc='\033[0m'

    case $level in
        "INFO")
            echo -e "${green}[INFO] $timestamp: $message${nc}"
            echo "[INFO] $timestamp: $message" >> "$log_file"
            ;;
        "WARN")
            echo -e "${yellow}[WARN] $timestamp: $message${nc}"
            echo "[WARN] $timestamp: $message" >> "$log_file"
            ;;
        "ERROR")
            echo -e "${red}[ERROR] $timestamp: $message${nc}"
            echo "[ERROR] $timestamp: $message" >> "$log_file"
            exit 1
            ;;
    esac
}

# Função para exibir mensagens de erro e sair
error_exit() {
    log "ERROR" "$1"
}

# Função para verificar se o GLPI está instalado
check_glpi_installed() {
    if [ ! -d "/var/www/html/glpi" ]; then
        error_exit "GLPI não detectado em /var/www/html/glpi. Verifique a instalação."
    fi
}

# Função para backup do banco de dados
backup_database() {
    local root_pass="$1"
    local db_name="$2"
    local backup_dir="$3"

    log "INFO" "Fazendo backup do banco de dados $db_name..."
    mysqldump -u root -p"$root_pass" --single-transaction --routines --triggers "$db_name" > "$backup_dir/glpi_db_backup_$(date +%Y%m%d_%H%M%S).sql" || error_exit "Falha no backup do banco de dados."
}

# Função para backup de arquivos
backup_files() {
    local backup_dir="$1"
    local tar_dirs=()

    log "INFO" "Fazendo backup dos arquivos (código-fonte, configs, vars e logs)..."
    [ -d "/var/www/html/glpi" ] && tar_dirs+=("/var/www/html/glpi")
    [ -d "/etc/glpi" ] && tar_dirs+=("/etc/glpi")
    [ -d "/var/lib/glpi" ] && tar_dirs+=("/var/lib/glpi")
    [ -d "/var/log/glpi" ] && tar_dirs+=("/var/log/glpi")

    if [ ${#tar_dirs[@]} -eq 0 ]; then
        error_exit "Nenhum diretório do GLPI encontrado para backup."
    fi

    log "INFO" "Diretórios incluídos no backup: ${tar_dirs[*]}"
    tar -czf "$backup_dir/glpi_files_backup_$(date +%Y%m%d_%H%M%S).tar.gz" "${tar_dirs[@]}" || error_exit "Falha no backup dos arquivos."
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    error_exit "Este script deve ser executado como root."
fi

# Criar diretório de log se não existir
mkdir -p /var/log
touch /var/log/glpi_backup.log
chown root:root /var/log/glpi_backup.log
chmod 0644 /var/log/glpi_backup.log

check_glpi_installed

# Usar variáveis do cron ou entrada interativa
ROOT_DB_PASS="$1"
DB_NAME="$2"
BACKUP_DIR="$3"

if [ -z "$ROOT_DB_PASS" ]; then
    read -sp "Digite a senha para o usuário root do MariaDB: " ROOT_DB_PASS
    echo
fi

if [ -z "$DB_NAME" ]; then
    read -p "Nome do banco de dados do GLPI (padrão: glpi): " DB_NAME
    DB_NAME=${DB_NAME:-glpi}
fi

if [ -z "$BACKUP_DIR" ]; then
    read -p "Diretório de destino para o backup (padrão: /backup): " BACKUP_DIR
    BACKUP_DIR=${BACKUP_DIR:-/backup}
fi

mkdir -p "$BACKUP_DIR" || error_exit "Falha ao criar diretório de backup."

# Executar backups
backup_database "$ROOT_DB_PASS" "$DB_NAME" "$BACKUP_DIR"
backup_files "$BACKUP_DIR"

log "INFO" "Backup completo realizado em $BACKUP_DIR. Verifique os arquivos gerados."
