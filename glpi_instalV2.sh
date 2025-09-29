#!/bin/bash

# Script de Instalação Automatizada do GLPI para Debian/Ubuntu com Apache
# Versão: 2.0
# Inclui: FHS, logs coloridos, backup com cron, rotação, UFW, Fail2Ban, SSL com Let's Encrypt
# Baseado em: https://github.com/wesscd/GLPIv2 e install_glpi_v1.11_corrigido.sh

set -euo pipefail

# Função para exibir banner inicial
show_banner() {
    echo -e "\033[0;34m=================================================================\033[0m"
    echo -e "\033[0;32m      INSTALAÇÃO AUTOMATIZADA DO GLPI - APACHE SERVER    \033[0m"
    echo -e "\033[0;34m=================================================================\033[0m"
    echo -e "\033[1;33mVersão do Script: 2.0\033[0m"
    echo -e "\033[1;33mEste script irá instalar:\033[0m"
    echo -e "  - Apache, MariaDB, PHP 8.1+ com extensões"
    echo -e "  - GLPI (versão dinâmica, padrão: mais recente)"
    echo -e "  - Backup automatizado com cron e rotação"
    echo -e "  - Firewall UFW, Fail2Ban e SSL com Let's Encrypt (opcionais)"
    echo -e "\033[0;34m=================================================================\033[0m"
    echo -e "\033[0;31mATENÇÃO: Execute em um sistema limpo. Faça backup antes de upgrades.\033[0m"
    read -p "Deseja continuar? (s/n): " confirm
    echo "DEBUG: Valor de confirm: '$confirm'" >&2
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Instalação cancelada."
        exit 0
    fi
    echo "DEBUG: Condição confirm passou, prosseguindo..." >&2
}

# Função para logging com cores e arquivo
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="/var/log/glpi_install.log"

    # Definir cores
    local red='\033[0;31m'
    local green='\033[0;32m'
    local yellow='\033[1;33m'
    local blue='\033[0;34m'
    local nc='\033[0m' # No Color

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

# Função para verificar execução de comandos
check_execution() {
    local status=$?
    local success_msg=$1
    local error_msg=$2
    if [ $status -eq 0 ]; then
        log "INFO" "$success_msg"
    else
        log "ERROR" "$error_msg (Código: $status)"
    fi
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log "INFO" "Verificando pré-requisitos..."
    # Verificar comandos necessários
    local required_cmds=("df" "awk" "grep" "ping")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "Comando $cmd não encontrado. Instale-o com 'apt install coreutils iputils-ping'."
        fi
    done
    # Verificar espaço em disco (mínimo 1GB livre)
    local free_space
    free_space=$(df -k / | tail -1 | awk '{print $4}' 2>/dev/null || echo "0")
    if [ -z "$free_space" ] || [ "$free_space" -eq 0 ]; then
        log "ERROR" "Não foi possível determinar o espaço em disco. Verifique o comando 'df'."
    elif [ "$free_space" -lt 1000000 ]; then  # 1GB em KB
        log "ERROR" "Espaço em disco insuficiente. Necessário pelo menos 1GB livre (encontrado: $((free_space/1024)) MB)."
    else
        log "INFO" "Espaço em disco suficiente: $((free_space/1024)) MB disponível."
    fi
    # Verificar conectividade com GitHub
    if command -v ping >/dev/null 2>&1; then
        if ! ping -c 1 github.com >/dev/null 2>&1; then
            log "WARN" "Sem conectividade com github.com. Isso pode impedir a obtenção da versão mais recente do GLPI."
            read -p "Deseja continuar mesmo assim? (s/n): " continue_no_internet
            if [[ ! "$continue_no_internet" =~ ^[sS]$ ]]; then
                log "INFO" "Instalação cancelada devido à falta de conectividade."
                exit 0
            fi
        else
            log "INFO" "Conectividade com github.com verificada."
        fi
    else
        log "WARN" "Comando 'ping' não encontrado. Pulando verificação de conectividade."
    fi
    log "INFO" "Pré-requisitos verificados com sucesso."
}

# Função para verificar sincronização do relógio
check_system_clock() {
    log "INFO" "Verificando sincronização do relógio..."
    if ! command -v timedatectl >/dev/null 2>&1 || ! timedatectl status | grep -q "System clock synchronized: yes"; then
        log "WARN" "Relógio do sistema não está sincronizado ou timedatectl não está disponível. Isso pode causar falhas no apt."
        echo -e "Recomenda-se corrigir com os seguintes passos:"
        echo -e "  1. sudo timedatectl set-ntp false"
        echo -e "  2. sudo apt install ntpdate -y"
        echo -e "  3. sudo ntpdate pool.ntp.org"
        echo -e "  4. sudo timedatectl set-ntp true"
        read -p "Deseja continuar mesmo assim? (s/n): " continue_clock
        [[ ! "$continue_clock" =~ ^[sS]$ ]] && { log "INFO" "Instalação cancelada para ajuste do relógio."; exit 0; }
    else
        log "INFO" "Relógio do sistema sincronizado."
    fi
}

# Função para exibir mensagens de erro e sair
error_exit() {
    log "ERROR" "$1"
}

# Função para instalar pacotes necessários
install_packages() {
    log "INFO" "Atualizando pacotes e instalando dependências..."
    apt update
    check_execution "Lista de pacotes atualizada." "Falha ao atualizar pacotes. Verifique o relógio do sistema."
    apt upgrade -y
    check_execution "Pacotes atualizados." "Falha ao atualizar pacotes."
    apt install -y xz-utils bzip2 unzip curl apache2 mariadb-server libapache2-mod-php \
        php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2,redis} \
        unzip wget snapd ntpdate dnsutils || error_exit "Falha ao instalar pacotes."
}

# Função para verificar serviços
check_services() {
    log "INFO" "Verificando serviços MariaDB e Apache..."
    systemctl is-active --quiet mariadb || error_exit "MariaDB não está ativo."
    systemctl is-active --quiet apache2 || error_exit "Apache2 não está ativo."
}

# Função para configurar o MariaDB
setup_mariadb() {
    local root_pass=$1
    log "INFO" "Configurando MariaDB..."
    if ! command -v mysql >/dev/null 2>&1; then
        error_exit "MariaDB não está instalado."
    fi
    if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
        log "INFO" "Usuário root do MariaDB já configurado (sem senha ou com senha existente)."
    else
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_pass';" || error_exit "Erro ao definir senha do root."
    fi
    mysql -u root -p"$root_pass" -e "
        DELETE FROM mysql.user WHERE User=''; 
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        FLUSH PRIVILEGES;" || error_exit "Erro ao aplicar configurações de segurança do MariaDB."
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p"$root_pass" mysql || error_exit "Falha ao importar timezones."
}

# Função para otimizar configurações do MariaDB
setup_mysql_optimizations() {
    log "INFO" "Otimizando configurações do MariaDB..."
    cat <<EOF > /etc/mysql/conf.d/glpi_optimizations.cnf
[mysqld]
innodb_buffer_pool_size = 128M
query_cache_type = 1
query_cache_size = 64M
tmp_table_size = 32M
max_connections = 150
EOF
    systemctl restart mariadb
    check_execution "MariaDB otimizado e reiniciado." "Falha ao reiniciar MariaDB após otimizações."
}

# Função para obter a versão mais recente do GLPI
get_latest_glpi_version() {
    log "INFO" "Obtendo a versão mais recente do GLPI..."
    local latest_tag=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep -oP '"tag_name": "\K[^"]+' || true)
    if [ -z "$latest_tag" ]; then
        log "WARN" "Não foi possível obter a versão mais recente do GLPI. Usando fallback: 10.0.20."
        latest_tag="10.0.20"
    fi
    log "INFO" "Versão detectada: $latest_tag"
    echo "$latest_tag"
}

# Função para extrair a versão atual do GLPI instalado
get_current_glpi_version() {
    if [ -f /var/www/html/glpi/inc/define.php ]; then
        grep "define('GLPI_VERSION'" /var/www/html/glpi/inc/define.php | grep -oP "\d+\.\d+\.\d+" || echo ""
    elif [ -f /var/www/html/glpi/VERSION ]; then
        cat /var/www/html/glpi/VERSION | grep -oP "\d+\.\d+\.\d+" || echo ""
    else
        echo ""
    fi
}

# Função para comparar versões
compare_versions() {
    local v1=$1
    local v2=$2
    if [ "$v1" = "$v2" ]; then
        return 1
    fi
    local higher=$(echo -e "$v1\n$v2" | sort -V | tail -n1)
    if [ "$higher" = "$v2" ]; then
        return 0
    else
        return 2
    fi
}

# Função para baixar e extrair o GLPI
download_glpi() {
    local version=$1
    log "INFO" "Baixando e extraindo GLPI versão $version..."
    local url="https://github.com/glpi-project/glpi/releases/download/$version/glpi-$version.tgz"
    wget -O- "$url" | tar -zxv -C /var/www/html/ || error_exit "Erro ao baixar ou extrair o GLPI versão $version."
}

# Função para configurar estrutura FHS
setup_fhs() {
    local glpi_dir="/var/www/html/glpi"
    log "INFO" "Configurando estrutura FHS..."
    cat <<EOF > "$glpi_dir/inc/downstream.php"
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF
    mkdir -p /etc/glpi /var/lib/glpi /var/log/glpi
    [ -d "$glpi_dir/config" ] && mv "$glpi_dir/config" /etc/glpi/ || log "WARN" "Diretório config não encontrado."
    [ -d "$glpi_dir/files" ] && mv "$glpi_dir/files" /var/lib/glpi/ || log "WARN" "Diretório files não encontrado."
    [ -d "/var/lib/glpi/_log" ] && mv /var/lib/glpi/_log /var/log/glpi/ || log "WARN" "Diretório _log não encontrado."
    mkdir -p /var/lib/glpi/{_cache,_cron,_dumps,_graphs,_lock,_pictures,_plugins,_rss,_sessions,_tmp,_uploads} || error_exit "Falha ao criar subdiretórios em /var/lib/glpi."
    cat <<EOF > /etc/glpi/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_DOC_DIR', GLPI_VAR_DIR);
define('GLPI_CACHE_DIR', GLPI_VAR_DIR . '/_cache');
define('GLPI_CRON_DIR', GLPI_VAR_DIR . '/_cron');
define('GLPI_GRAPH_DIR', GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCAL_I18N_DIR', GLPI_VAR_DIR . '/_locales');
define('GLPI_LOCK_DIR', GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR', GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR', GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR', GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR', GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR', GLPI_VAR_DIR . '/_uploads');
define('GLPI_INVENTORY_DIR', GLPI_VAR_DIR . '/_inventories');
define('GLPI_THEMES_DIR', GLPI_VAR_DIR . '/_themes');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF
}

# Função para realizar upgrade do GLPI
upgrade_glpi() {
    local current_version=$1
    local new_version=$2
    local root_pass=$3
    local db_name=$4
    log "INFO" "Realizando upgrade do GLPI de $current_version para $new_version..."
    backup_dir="/var/www/html/glpi_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    [ -d /var/www/html/glpi ] && cp -r /var/www/html/glpi "$backup_dir/glpi" || log "WARN" "Código-fonte não encontrado para backup."
    [ -d /etc/glpi ] && cp -r /etc/glpi "$backup_dir/etc_glpi" || log "WARN" "Configs não encontradas para backup."
    [ -d /var/lib/glpi ] && cp -r /var/lib/glpi "$backup_dir/var_lib_glpi" || log "WARN" "Arquivos variáveis não encontrados para backup."
    [ -d /var/log/glpi ] && cp -r /var/log/glpi "$backup_dir/var_log_glpi" || log "WARN" "Logs não encontrados para backup."
    mysqldump -u root -p"$root_pass" "$db_name" > "$backup_dir/glpi_db_backup.sql" || error_exit "Falha ao fazer backup do banco de dados."
    rm -rf /var/www/html/glpi
    download_glpi "$new_version"
    setup_fhs
    [ -d "$backup_dir/etc_glpi" ] && cp -r "$backup_dir/etc_glpi/"* /etc/glpi/ || log "WARN" "Sem configs para restaurar."
    [ -d "$backup_dir/var_lib_glpi" ] && cp -r "$backup_dir/var_lib_glpi/"* /var/lib/glpi/ || log "WARN" "Sem arquivos variáveis para restaurar."
    [ -d "$backup_dir/var_log_glpi" ] && cp -r "$backup_dir/var_log_glpi/"* /var/log/glpi/ || log "WARN" "Sem logs para restaurar."
    log "INFO" "Upgrade concluído. Backup salvo em $backup_dir."
}

# Função para configurar permissões
setup_permissions() {
    log "INFO" "Configurando permissões..."
    chown www-data:www-data /var/www/html/glpi/ -R || error_exit "Falha ao alterar proprietário do código-fonte."
    chown www-data:www-data /etc/glpi -R || error_exit "Falha ao alterar proprietário de configs."
    chown www-data:www-data /var/lib/glpi -R || error_exit "Falha ao alterar proprietário de vars."
    chown www-data:www-data /var/log/glpi -R || error_exit "Falha ao alterar proprietário de logs."
    chown www-data:www-data /var/www/html/glpi/marketplace -Rf || error_exit "Falha ao alterar proprietário de marketplace."
    find /var/www/html/glpi/ -type f -exec chmod 0644 {} \; || error_exit "Falha ao definir permissões de arquivos no código-fonte."
    find /var/www/html/glpi/ -type d -exec chmod 0755 {} \; || error_exit "Falha ao definir permissões de diretórios no código-fonte."
    find /etc/glpi -type f -exec chmod 0644 {} \; || error_exit "Falha ao definir permissões de arquivos em configs."
    find /etc/glpi -type d -exec chmod 0755 {} \; || error_exit "Falha ao definir permissões de diretórios em configs."
    find /var/lib/glpi -type f -exec chmod 0644 {} \; || error_exit "Falha ao definir permissões de arquivos em vars."
    find /var/lib/glpi -type d -exec chmod 0755 {} \; || error_exit "Falha ao definir permissões de diretórios em vars."
    find /var/log/glpi -type f -exec chmod 0644 {} \; || error_exit "Falha ao definir permissões de arquivos em logs."
    find /var/log/glpi -type d -exec chmod 0755 {} \; || error_exit "Falha ao definir permissões de diretórios em logs."
}

# Função para configurar o banco de dados do GLPI
setup_database() {
    local db_name=$1
    local db_user=$2
    local db_pass=$3
    local root_pass=$4
    log "INFO" "Configurando banco de dados $db_name..."
    mysql -u root -p"$root_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;" || error_exit "Erro ao criar banco de dados $db_name."
    mysql -u root -p"$root_pass" -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';" || error_exit "Erro ao criar usuário $db_user."
    mysql -u root -p"$root_pass" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';" || error_exit "Erro ao conceder privilégios."
    mysql -u root -p"$root_pass" -e "GRANT SELECT ON mysql.time_zone_name TO '$db_user'@'localhost';" || error_exit "Erro ao conceder privilégio de timezone."
    mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;" || error_exit "Erro ao atualizar privilégios."
}

# Função para configurar o Apache
setup_apache() {
    local server_name=$1
    local base_path=$2
    log "INFO" "Configurando Apache..."
    if [ ! -f /etc/apache2/sites-available/glpi.conf ]; then
        if [ "$base_path" = "/" ]; then
            cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName $server_name
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/glpi/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/html/glpi/public>
        Require all granted
        RewriteEngine On
        RewriteCond %{HTTP:Authorization} ^(.+)$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
EOF
        else
            cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName $server_name
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    Alias $base_path /var/www/html/glpi/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/html/glpi/public>
        Require all granted
        RewriteEngine On
        RewriteCond %{HTTP:Authorization} ^(.+)$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
EOF
        fi
        read -p "Deseja desabilitar o site default do Apache (000-default.conf)? (s/n): " disable_default
        if [[ "$disable_default" =~ ^[sS]$ ]]; then
            a2dissite 000-default.conf
            check_execution "Site default desabilitado." "Falha ao desabilitar site default."
        fi
        a2enmod rewrite
        check_execution "Módulo rewrite habilitado." "Falha ao habilitar módulo rewrite."
        a2ensite glpi.conf
        check_execution "Site glpi.conf ativado." "Falha ao ativar site glpi.conf."
        systemctl reload apache2
        check_execution "Apache recarregado." "Erro ao recarregar o Apache."
    fi
}

# Função para configurar headers de segurança no Apache
setup_apache_security() {
    log "INFO" "Configurando headers de segurança no Apache..."
    cat <<EOF > /etc/apache2/conf-available/security-headers.conf
Header set X-Content-Type-Options "nosniff"
Header set X-Frame-Options "DENY"
Header set Referrer-Policy "strict-origin-when-cross-origin"
#Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
EOF
    a2enconf security-headers
    systemctl reload apache2
    check_execution "Headers de segurança configurados." "Falha ao configurar headers de segurança."
}

# Função para configurar SSL com Let's Encrypt
setup_ssl() {
    read -p "Deseja configurar SSL com Let's Encrypt? (s/n): " enable_ssl
    [[ ! "$enable_ssl" =~ ^[sS]$ ]] && { log "INFO" "Configuração de SSL ignorada."; return; }
    read -p "Digite o domínio para o certificado SSL (ex.: glpi.seudominio.com): " ssl_domain
    read -p "Digite o email para Let's Encrypt: " ssl_email
    log "INFO" "Instalando Certbot..."
    apt install snapd -y && snap install core && snap refresh core
    check_execution "Snapd e core instalados." "Falha ao instalar snapd."
    apt-get remove certbot -y 2>/dev/null
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot || error_exit "Falha ao criar link para Certbot."
    log "INFO" "Verificando DNS para $ssl_domain..."
    server_ip=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
    domain_ip=$(dig +short "$ssl_domain" A | tail -n1)
    if [[ -z "$domain_ip" || "$domain_ip" != "$server_ip" ]]; then
        log "WARN" "DNS para $ssl_domain ($domain_ip) não corresponde ao IP do servidor ($server_ip)."
        read -p "Continuar mesmo assim? (s/n): " continue_ssl
        [[ ! "$continue_ssl" =~ ^[sS]$ ]] && { log "INFO" "Configuração SSL cancelada."; return; }
    fi
    log "INFO" "Obtendo certificado SSL..."
    certbot --apache --non-interactive --agree-tos --email "$ssl_email" -d "$ssl_domain" --redirect || {
        log "ERROR" "Falha ao obter certificado. Verifique DNS, portas 80/443 e logs em /var/log/letsencrypt."
        return 1
    }
    echo "0 12 * * * root /usr/bin/certbot renew --quiet && systemctl reload apache2" > /etc/cron.d/certbot-renew
    chmod 644 /etc/cron.d/certbot-renew
    ufw allow 443/tcp comment 'HTTPS SSL access'
    sed -i 's|#Header always set Strict-Transport-Security|Header always set Strict-Transport-Security|' /etc/apache2/conf-available/security-headers.conf
    systemctl reload apache2
    check_execution "SSL e HSTS configurados." "Falha ao configurar SSL."
    log "INFO" "SSL configurado com sucesso. Acesse https://$ssl_domain"
}

# Função para configurar o firewall UFW
setup_firewall() {
    read -p "Deseja configurar o firewall UFW? (s/n): " setup_ufw
    [[ ! "$setup_ufw" =~ ^[sS]$ ]] && { log "INFO" "Configuração de firewall ignorada."; return; }
    log "INFO" "Configurando UFW..."
    apt install ufw -y
    check_execution "UFW instalado." "Falha ao instalar UFW."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp comment 'SSH access'
    ufw allow 80/tcp comment 'HTTP access'
    ufw allow 443/tcp comment 'HTTPS SSL access'
    ufw --force enable
    ufw status verbose
    check_execution "Firewall UFW configurado." "Falha ao configurar UFW."
}

# Função para configurar Fail2Ban
setup_fail2ban() {
    read -p "Deseja configurar o Fail2Ban para proteção contra força bruta? (s/n): " setup_fail2ban
    [[ ! "$setup_fail2ban" =~ ^[sS]$ ]] && { log "INFO" "Configuração de Fail2Ban ignorada."; return; }
    log "INFO" "Instalando e configurando Fail2Ban..."
    apt install fail2ban -y
    check_execution "Fail2Ban instalado." "Falha ao instalar Fail2Ban."
    [ ! -f /etc/fail2ban/jail.local ] && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    if ! grep -q "^\[sshd\]" /etc/fail2ban/jail.local; then
        cat <<EOF >> /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
EOF
    fi
    if ! grep -q "^\[apache-auth\]" /etc/fail2ban/jail.local; then
        cat <<EOF >> /etc/fail2ban/jail.local
[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/error.log
maxretry = 5
bantime = 3600
EOF
    fi
    if ! grep -q "^\[glpi\]" /etc/fail2ban/jail.local; then
        cat <<EOF >> /etc/fail2ban/jail.local
[glpi]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/access.log
maxretry = 10
bantime = 3600
findtime = 600
EOF
    fi
    systemctl restart fail2ban && systemctl enable fail2ban
    check_execution "Fail2Ban configurado." "Falha ao configurar Fail2Ban."
}

# Função para configurar o cron do GLPI
setup_cron() {
    log "INFO" "Configurando cron do GLPI..."
    if ! grep -q "/var/www/html/glpi/front/cron.php" /etc/crontab; then
        echo -e "* *\t* * *\twww-data\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab
        check_execution "Cron do GLPI configurado." "Falha ao configurar cron do GLPI."
    fi
}

# Função para configurar o script de backup e cron
setup_backup() {
    local root_pass=$1
    local db_name=$2
    local backup_dir=$3
    log "INFO" "Configurando script de backup..."
    cat <<EOF > /usr/local/bin/glpi_backup.sh
#!/bin/bash
# Função para logging com cores e arquivo
log() {
    local level=\$1
    local message=\$2
    local timestamp=\$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="/var/log/glpi_backup.log"
    local red='\033[0;31m'
    local green='\033[0;32m'
    local yellow='\033[1;33m'
    local nc='\033[0m'
    case \$level in
        "INFO")
            echo -e "\${green}[INFO] \$timestamp: \$message\${nc}"
            echo "[INFO] \$timestamp: \$message" >> "\$log_file"
            ;;
        "WARN")
            echo -e "\${yellow}[WARN] \$timestamp: \$message\${nc}"
            echo "[WARN] \$timestamp: \$message" >> "\$log_file"
            ;;
        "ERROR")
            echo -e "\${red}[ERROR] \$timestamp: \$message\${nc}"
            echo "[ERROR] \$timestamp: \$message" >> "\$log_file"
            exit 1
            ;;
    esac
}
# Função para exibir mensagens de erro e sair
error_exit() {
    log "ERROR" "\$1"
}
# Função para verificar se o GLPI está instalado
check_glpi_installed() {
    if [ ! -d "/var/www/html/glpi" ]; then
        error_exit "GLPI não detectado em /var/www/html/glpi. Verifique a instalação."
    fi
}
# Função para backup do banco de dados
backup_database() {
    local root_pass="\$1"
    local db_name="\$2"
    local backup_dir="\$3"
    log "INFO" "Fazendo backup do banco de dados \$db_name..."
    mysqldump -u root -p"\$root_pass" --single-transaction --routines --triggers "\$db_name" > "\$backup_dir/glpi_db_backup_\$(date +%Y%m%d_%H%M%S).sql" || error_exit "Falha no backup do banco de dados."
}
# Função para backup de arquivos
backup_files() {
    local backup_dir="\$1"
    local tar_dirs=()
    log "INFO" "Fazendo backup dos arquivos (código-fonte, configs, vars e logs)..."
    [ -d "/var/www/html/glpi" ] && tar_dirs+=("/var/www/html/glpi")
    [ -d "/etc/glpi" ] && tar_dirs+=("/etc/glpi")
    [ -d "/var/lib/glpi" ] && tar_dirs+=("/var/lib/glpi")
    [ -d "/var/log/glpi" ] && tar_dirs+=("/var/log/glpi")
    if [ \${#tar_dirs[@]} -eq 0 ]; then
        error_exit "Nenhum diretório do GLPI encontrado para backup."
    fi
    log "INFO" "Diretórios incluídos no backup: \${tar_dirs[*]}"
    tar -czf "\$backup_dir/glpi_files_backup_\$(date +%Y%m%d_%H%M%S).tar.gz" "\${tar_dirs[@]}" || error_exit "Falha no backup dos arquivos."
}
# Verificar se o script está sendo executado como root
if [ "\$EUID" -ne 0 ]; then
    error_exit "Este script deve ser executado como root."
fi
check_glpi_installed
# Carregar configurações de /etc/glpi/backup.conf
if [ -f /etc/glpi/backup.conf ]; then
    source /etc/glpi/backup.conf
else
    error_exit "Arquivo de configuração /etc/glpi/backup.conf não encontrado."
fi
# Usar variáveis do cron ou entrada interativa
ROOT_DB_PASS="\${ROOT_DB_PASS:-}"
DB_NAME="\${DB_NAME:-$db_name}"
BACKUP_DIR="\${BACKUP_DIR:-$backup_dir}"
if [ -z "\$ROOT_DB_PASS" ]; then
    read -sp "Digite a senha para o usuário root do MariaDB: " ROOT_DB_PASS
    echo
fi
if [ -z "\$DB_NAME" ]; then
    read -p "Nome do banco de dados do GLPI (padrão: glpi): " DB_NAME
    DB_NAME=\${DB_NAME:-glpi}
fi
if [ -z "\$BACKUP_DIR" ]; then
    read -p "Diretório de destino para o backup (padrão: /backup): " BACKUP_DIR
    BACKUP_DIR=\${BACKUP_DIR:-/backup}
fi
mkdir -p "\$BACKUP_DIR" || error_exit "Falha ao criar diretório de backup."
# Executar backups
backup_database "\$ROOT_DB_PASS" "\$DB_NAME" "\$BACKUP_DIR"
backup_files "\$BACKUP_DIR"
log "INFO" "Backup completo realizado em \$BACKUP_DIR. Verifique os arquivos gerados."
EOF
    chmod +x /usr/local/bin/glpi_backup.sh
    chown root:root /usr/local/bin/glpi_backup.sh
    log "INFO" "Script de backup salvo em /usr/local/bin/glpi_backup.sh"
    cat <<EOF > /etc/glpi/backup.conf
ROOT_DB_PASS="$root_pass"
DB_NAME="$db_name"
BACKUP_DIR="$backup_dir"
EOF
    chmod 600 /etc/glpi/backup.conf
    chown root:root /etc/glpi/backup.conf
    log "INFO" "Arquivo de configuração de backup criado em /etc/glpi/backup.conf."
    read -p "Deseja configurar backups automáticos diários às 2h? (s/n): " setup_cron_backup
    if [[ "$setup_cron_backup" =~ ^[sS]$ ]]; then
        log "INFO" "Configurando cron para backup diário às 2h..."
        echo "0 2 * * * root /usr/local/bin/glpi_backup.sh" >> /etc/crontab
        check_execution "Cron de backup configurado." "Falha ao configurar cron de backup."
    fi
    read -p "Deseja configurar rotação automática de backups (excluir >7 dias)? (s/n): " setup_rotation
    if [[ "$setup_rotation" =~ ^[sS]$ ]]; then
        log "INFO" "Configurando cron para rotação de backups às 3h..."
        echo "0 3 * * * root find $backup_dir -name \"glpi_*\" -mtime +7 -delete" >> /etc/crontab
        check_execution "Cron de rotação configurado." "Falha ao configurar cron de rotação."
    fi
}

# Função para configurar php.ini
setup_php_ini() {
    local php_version=$(php -v | grep -oP 'PHP \K\d+\.\d+' | head -1)
    local php_ini="/etc/php/$php_version/apache2/php.ini"
    if [ ! -f "$php_ini" ]; then
        error_exit "Arquivo php.ini não encontrado em $php_ini."
    fi
    log "INFO" "Configurando php.ini..."
    read -p "Informe o timezone (ex: America/Sao_Paulo, padrão: UTC): " TZ
    TZ=${TZ:-UTC}
    if grep -q "^session.cookie_httponly" "$php_ini"; then
        sed -i "s|^session.cookie_httponly.*|session.cookie_httponly = On|" "$php_ini"
    else
        echo "session.cookie_httponly = On" >> "$php_ini"
    fi
    sed -i "s|^upload_max_filesize = .*|upload_max_filesize = 20M|" "$php_ini"
    sed -i "s|^post_max_size = .*|post_max_size = 20M|" "$php_ini"
    sed -i "s|^max_execution_time = .*|max_execution_time = 60|" "$php_ini"
    sed -i "s|^max_input_vars = .*|max_input_vars = 5000|" "$php_ini"
    sed -i "s|^memory_limit = .*|memory_limit = 256M|" "$php_ini"
    if grep -q "^date.timezone" "$php_ini"; then
        sed -i "s|^date.timezone = .*|date.timezone = $TZ|" "$php_ini"
    else
        echo "date.timezone = $TZ" >> "$php_ini"
    fi
    systemctl restart apache2
    check_execution "PHP configurado." "Erro ao reiniciar Apache após ajustes no PHP."
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    error_exit "Este script deve ser executado como root."
fi

# Criar diretório de log
mkdir -p /var/log
touch /var/log/glpi_install.log
chown root:root /var/log/glpi_install.log
chmod 0644 /var/log/glpi_install.log

# Função principal
main() {
    show_banner
    check_prerequisites
    check_system_clock
    read -sp "Digite a senha para o usuário root do MariaDB: " ROOT_DB_PASS
    echo
    read -p "Deseja detectar a versão mais recente do GLPI automaticamente? (s/n): " auto_detect
    if [[ "$auto_detect" =~ ^[sS]$ ]]; then
        GLPI_VERSION=$(get_latest_glpi_version)
    else
        read -p "Informe a versão do GLPI (ex: 10.0.20): " GLPI_VERSION
        GLPI_VERSION=${GLPI_VERSION:-10.0.20}
        log "INFO" "Usando versão: $GLPI_VERSION"
    fi
    read -p "Nome do banco de dados (padrão: glpi): " DB_NAME
    DB_NAME=${DB_NAME:-glpi}
    read -p "Usuário do banco de dados (padrão: glpiuser): " DB_USER
    DB_USER=${DB_USER:-glpiuser}
    read -sp "Senha do banco de dados do GLPI: " DB_PASS
    echo
    SERVER_NAME=$(hostname -I | awk '{print $1}')
    read -p "ServerName para Apache (padrão: $SERVER_NAME): " INPUT_SERVER_NAME
    SERVER_NAME=${INPUT_SERVER_NAME:-$SERVER_NAME}
    read -p "Deseja acessar o GLPI na raiz (/) ou em um subdiretório como /glpi? (raiz/sub): " BASE_PATH
    [[ "$BASE_PATH" =~ ^[sS][uU][bB]$ ]] && BASE_PATH="/glpi" || BASE_PATH="/"
    read -p "Diretório de destino para backups (padrão: /backup): " BACKUP_DIR
    BACKUP_DIR=${BACKUP_DIR:-/backup}
    mkdir -p "$BACKUP_DIR" || error_exit "Falha ao criar diretório de backup."
    CURRENT_VERSION=$(get_current_glpi_version)
    if [ -n "$CURRENT_VERSION" ]; then
        log "INFO" "Instalação existente do GLPI detectada na versão $CURRENT_VERSION."
        compare_versions "$CURRENT_VERSION" "$GLPI_VERSION"
        case $? in
            0)
                read -p "Deseja realizar o upgrade para $GLPI_VERSION? (s/n): " do_upgrade
                if [[ "$do_upgrade" =~ ^[sS]$ ]]; then
                    install_packages
                    check_services
                    setup_mariadb "$ROOT_DB_PASS"
                    upgrade_glpi "$CURRENT_VERSION" "$GLPI_VERSION" "$ROOT_DB_PASS" "$DB_NAME"
                    setup_mysql_optimizations
                    setup_php_ini
                    setup_apache "$SERVER_NAME" "$BASE_PATH"
                    setup_apache_security
                    setup_ssl
                    setup_firewall
                    setup_fail2ban
                    setup_cron
                    setup_backup "$ROOT_DB_PASS" "$DB_NAME" "$BACKUP_DIR"
                    log "INFO" "Instalação concluída. Acesse o GLPI em http${SSL_ENABLED:+s}://$SERVER_NAME$BASE_PATH"
                    exit 0
                else
                    log "INFO" "Upgrade cancelado."
                    exit 0
                fi
                ;;
            1)
                log "INFO" "A versão instalada já é a mais recente ($GLPI_VERSION)."
                exit 0
                ;;
            2)
                log "INFO" "A versão instalada ($CURRENT_VERSION) é mais recente que a solicitada ($GLPI_VERSION)."
                exit 0
                ;;
        esac
    fi
    install_packages
    check_services
    setup_mariadb "$ROOT_DB_PASS"
    setup_mysql_optimizations
    download_glpi "$GLPI_VERSION"
    setup_fhs
    setup_permissions
    setup_database "$DB_NAME" "$DB_USER" "$DB_PASS" "$ROOT_DB_PASS"
    setup_php_ini
    setup_apache "$SERVER_NAME" "$BASE_PATH"
    setup_apache_security
    setup_ssl
    setup_firewall
    setup_fail2ban
    setup_cron
    setup_backup "$ROOT_DB_PASS" "$DB_NAME" "$BACKUP_DIR"
    log "INFO" "Instalação concluída. Acesse o GLPI em http${SSL_ENABLED:+s}://$SERVER_NAME$BASE_PATH"
}

main