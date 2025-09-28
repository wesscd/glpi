#!/bin/bash

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para backup rápido antes da remoção
quick_backup() {
    local root_pass=$1
    local db_name=$2
    local backup_dir="/tmp/glpi_uninstall_backup_$(date +%Y%m%d_%H%M%S)"
    local tar_dirs=()

    echo "Realizando backup de segurança em $backup_dir..."
    mkdir -p "$backup_dir" || error_exit "Falha ao criar diretório de backup."

    # Adicionar diretórios apenas se existirem
    [ -d "/var/www/html/glpi" ] && tar_dirs+=("/var/www/html/glpi")
    [ -d "/etc/glpi" ] && tar_dirs+=("/etc/glpi")
    [ -d "/var/lib/glpi" ] && tar_dirs+=("/var/lib/glpi")
    [ -d "/var/log/glpi" ] && tar_dirs+=("/var/log/glpi")

    if [ ${#tar_dirs[@]} -eq 0 ]; then
        echo "Aviso: Nenhum diretório do GLPI encontrado para backup."
    else
        echo "Diretórios incluídos no backup: ${tar_dirs[*]}"
        tar -czf "$backup_dir/glpi_files.tar.gz" "${tar_dirs[@]}" || echo "Aviso: Falha no backup de arquivos."
    fi

    mysqldump -u root -p"$root_pass" --single-transaction --routines --triggers "$db_name" > "$backup_dir/glpi_db.sql" || echo "Aviso: Falha no backup do banco de dados."
    echo "Backup de segurança salvo em $backup_dir. Mantenha este diretório se necessário."
}

# Função para verificar se o GLPI está instalado
check_glpi_installed() {
    if [ ! -d "/var/www/html/glpi" ]; then
        error_exit "GLPI não detectado. Nada a desinstalar."
    fi
}

# Função para remover pacotes
remove_packages() {
    read -p "Deseja remover pacotes instalados (Apache, MariaDB, PHP extensões)? Isso pode afetar outros apps (s/n): " remove_pkgs
    if [[ "$remove_pkgs" =~ ^[sS]$ ]]; then
        echo "Verificando pacotes mantidos (hold)..."
        apt-mark showhold | grep -E 'apache2|mariadb|php' && echo "Aviso: Pacotes mantidos encontrados. Use 'sudo apt-mark unhold <pacote>' para liberar."
        
        echo "Removendo pacotes..."
        apt purge -y apache2 mariadb-server libapache2-mod-php php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2,redis} 2>/dev/null || {
            echo "Aviso: Alguns pacotes não foram removidos devido a dependências ou erros. Verifique com 'apt list --installed | grep php'."
        }
        apt autoremove -y 2>/dev/null || echo "Aviso: Falha ao executar autoremove."
    else
        echo "Manutenção de pacotes cancelada."
    fi
}

# Função para remover banco de dados
remove_database() {
    local root_pass=$1
    local db_name=$2
    local db_user=$3

    echo "Removendo banco de dados $db_name e usuário $db_user..."
    mysql -u root -p"$root_pass" -e "DROP DATABASE IF EXISTS $db_name;" || error_exit "Falha ao remover banco de dados."
    mysql -u root -p"$root_pass" -e "DROP USER IF EXISTS '$db_user'@'localhost';" || error_exit "Falha ao remover usuário do DB."
    mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;" || error_exit "Falha ao atualizar privilégios."
}

# Função para remover arquivos e configs
remove_files() {
    echo "Removendo arquivos e configurações do GLPI..."
    rm -rf /var/www/html/glpi /etc/glpi /var/lib/glpi /var/log/glpi || echo "Aviso: Alguns arquivos não foram removidos (já ausentes?)."
}

# Função para limpar Apache e cron
cleanup_apache_cron() {
    echo "Limpando configurações do Apache e cron..."
    a2dissite glpi.conf 2>/dev/null || true
    rm -f /etc/apache2/sites-available/glpi.conf
    sed -i '/\/var\/www\/html\/glpi\/front\/cron.php/d' /etc/crontab 2>/dev/null || true
    sed -i '/glpi.ini$/d' /etc/php/*/apache2/conf.d/ 2>/dev/null || true
    systemctl reload apache2 2>/dev/null || true
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    error_exit "Este script deve ser executado como root."
fi

check_glpi_installed

# Interações dinâmicas e confirmações
read -sp "Digite a senha para o usuário root do MariaDB: " ROOT_DB_PASS
echo

read -p "Nome do banco de dados do GLPI (padrão: glpi): " DB_NAME
DB_NAME=${DB_NAME:-glpi}

read -p "Usuário do banco de dados (padrão: glpiuser): " DB_USER
DB_USER=${DB_USER:-glpiuser}

read -p "Deseja prosseguir com a desinstalação completa? Isso remove TUDO (DB, arquivos, pacotes). Digite 'SIM' para confirmar: " CONFIRM
if [[ "$CONFIRM" != "SIM" ]]; then
    echo "Desinstalação cancelada."
    exit 0
fi

# Backup rápido obrigatório
quick_backup "$ROOT_DB_PASS" "$DB_NAME"

# Remover em sequência
remove_database "$ROOT_DB_PASS" "$DB_NAME" "$DB_USER"
remove_files
cleanup_apache_cron
remove_packages

echo "Desinstalação completa. O backup está em /tmp/glpi_uninstall_backup_*. Verifique se restou algo."
