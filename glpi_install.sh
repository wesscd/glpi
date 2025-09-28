#!/bin/bash

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

# Função para verificar pré-requisitos
check_prerequisites() {
    log "INFO" "Verificando pré-requisitos..."

    # Verificar espaço em disco (mínimo 1GB livre)
    local free_space=$(df -h / | tail -1 | awk '{print $4}' | grep -oP '\d+')
    if [ -z "$free_space" ] || [ "$free_space" -lt 1000 ]; then
        log "ERROR" "Espaço em disco insuficiente. Necessário pelo menos 1GB livre."
    fi

    # Verificar conectividade com GitHub
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        log "ERROR" "Sem conectividade com a internet. Verifique sua conexão."
    fi

    log "INFO" "Pré-requisitos verificados com sucesso."
}

# Função para exibir mensagens de erro e sair
error_exit() {
    log "ERROR" "$1"
}

# Função para instalar pacotes necessários
install_packages() {
    log "INFO" "Atualizando pacotes e instalando dependências..."
    apt update && apt upgrade -y || error_exit "Falha ao atualizar sistema."
    apt install -y xz-utils bzip2 unzip curl apache2 mariadb-server libapache2-mod-php \
        php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2,redis} \
        unzip wget || error_exit "Falha ao instalar pacotes."
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

# Função para obter a versão mais recente do GLPI via API do GitHub
get_latest_glpi_version() {
    log "INFO" "Obtendo a versão mais recente do GLPI..."
    local latest_tag=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep -oP '"tag_name": "\K[^"]+' || echo "10.0.20")
    if [ -z "$latest_tag" ]; then
        error_exit "Não foi possível obter a versão mais recente do GLPI."
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
    if ! wget -O- "$url" | tar -zxv -C /var/www/html/; then
        error_exit "Erro ao baixar ou extrair o GLPI versão $version."
    fi
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

    # Criar subdiretórios necessários em /var/lib/glpi
    mkdir -p /var/lib/glpi/_cache \
             /var/lib/glpi/_cron \
             /var/lib/glpi/_dumps \
             /var/lib/glpi/_graphs \
             /var/lib/glpi/_lock \
             /var/lib/glpi/_pictures \
             /var/lib/glpi/_plugins \
             /var/lib/glpi/_rss \
             /var/lib/glpi/_sessions \
             /var/lib/glpi/_tmp \
             /var/lib/glpi/_uploads || error_exit "Falha ao criar subdiretórios em /var/lib/glpi."

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
    setup_permissions

    if [ -f /var/www/html/glpi/bin/console ]; then
        php /var/www/html/glpi/bin/console db:update --no-interaction || error_exit "Falha ao executar migrações do banco de dados."
    else
        log "WARN" "Migrações do banco de dados precisam ser executadas manualmente via interface web."
    fi

    log "INFO" "Upgrade concluído. Verifique a instalação e acesse http://$SERVER_NAME$BASE_PATH para finalizar."
}

# Função para configurar permissões
setup_permissions() {
    log "INFO" "Configurando permissões..."
    chown root:root /var/www/html/glpi/ -R || error_exit "Falha ao alterar proprietário do código-fonte."
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
    mysql -u root -p"$root_pass" -e "GRANT SELECT ON \`mysql\`.\`time_zone_name\` TO '$db_user'@'localhost';" || error_exit "Erro ao conceder privilégio de timezone."
    mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;" || error_exit "Erro ao atualizar privilégios."
}

# Função para configurar o Apache
setup_apache() {
    local server_name=$1
    local base_path=$2
    local disable_default=${3:-false}  # Use true para desabilitar o 000-default.conf

    log "INFO" "Configurando Apache..."

    if [ "$base_path" = "/" ]; then
        # GLPI na raiz: criar glpi.conf separado
        cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName $server_name
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/glpi/public

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/glpi/public>
        Require all granted
        AllowOverride All
        RewriteEngine On
        RewriteCond %{HTTP:Authorization} ^(.+)\$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
EOF

        if [ "$disable_default" = true ]; then
            a2dissite 000-default.conf || error_exit "Falha ao desabilitar site default."
        fi

        a2enmod rewrite || error_exit "Falha ao habilitar módulo rewrite."
        a2ensite glpi.conf || error_exit "Falha ao ativar site glpi.conf."

    else if [ "$base_path" = "/glpi" ]; then
        # GLPI em subdiretório: usar apenas 000-default.conf
        # Verifica se existe
        if [ ! -f /etc/apache2/sites-available/000-default.conf ]; then
            error_exit "000-default.conf não encontrado!"
        fi

        # Adiciona configuração do GLPI no 000-default.conf
        if ! grep -q "Directory /var/www/html/glpi/public" /etc/apache2/sites-available/000-default.conf; then
            sed -i "/<\/VirtualHost>/i \
\n    # Configuração GLPI\n    <Directory /var/www/html/glpi/public>\n        Require all granted\n        AllowOverride All\n        RewriteEngine On\n        RewriteCond %{HTTP:Authorization} ^(.+)\$\n        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]\n        RewriteCond %{REQUEST_FILENAME} !-f\n        RewriteRule ^(.*)$ index.php [QSA,L]\n    </Directory>\n" /etc/apache2/sites-available/000-default.conf
        fi

        a2enmod rewrite || error_exit "Falha ao habilitar módulo rewrite."
    fi

    systemctl reload apache2 || error_exit "Erro ao recarregar o Apache."
}


# Função para configurar o cron do GLPI
setup_cron() {
    log "INFO" "Configurando cron do GLPI..."
    if ! grep -q "/var/www/html/glpi/front/cron.php" /etc/crontab; then
        echo -e "* *\t* * *\twww-data\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab || error_exit "Falha ao configurar cron do GLPI."
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

# Carregar senha de /etc/glpi/backup.conf
if [ -f /etc/glpi/backup.conf ]; then
    source /etc/glpi/backup.conf
else
    error_exit "Arquivo de configuração /etc/glpi/backup.conf não encontrado."
fi

# Usar variáveis do cron ou entrada interativa
ROOT_DB_PASS="\${ROOT_DB_PASS}"
DB_NAME="${db_name}"
BACKUP_DIR="${backup_dir}"

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

    # Criar arquivo de configuração seguro para senha do MariaDB
    echo "ROOT_DB_PASS=$root_pass" > /etc/glpi/backup.conf
    chmod 600 /etc/glpi/backup.conf
    chown root:root /etc/glpi/backup.conf
    log "INFO" "Arquivo de configuração de backup criado em /etc/glpi/backup.conf com permissões restritas."

    # Configurar cron para backup
    read -p "Deseja configurar backups automáticos diários às 2h? (s/n): " setup_cron_backup
    if [[ "$setup_cron_backup" =~ ^[sS]$ ]]; then
        log "INFO" "Configurando cron para backup diário às 2h..."
        echo "0 2 * * * www-data /usr/local/bin/glpi_backup.sh \"\$db_name\" \"\$backup_dir\"" >> /etc/crontab || error_exit "Falha ao configurar cron de backup."
        log "INFO" "Cron de backup configurado com sucesso."
    else
        log "INFO" "Configuração de cron de backup ignorada."
    fi

    # Configurar cron para rotação de backups (excluir backups mais antigos que 7 dias)
    read -p "Deseja configurar rotação automática de backups (excluir >7 dias)? (s/n): " setup_rotation
    if [[ "$setup_rotation" =~ ^[sS]$ ]]; then
        log "INFO" "Configurando cron para rotação de backups às 3h..."
        echo "0 3 * * * root find $backup_dir -name \"glpi_*\" -mtime +7 -delete" >> /etc/crontab || error_exit "Falha ao configurar cron de rotação."
        log "INFO" "Cron de rotação de backups configurado com sucesso."
    else
        log "INFO" "Configuração de rotação de backups ignorada."
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
        sed -i "s/^session.cookie_httponly.*/session.cookie_httponly = On/" "$php_ini"
    else
        echo "session.cookie_httponly = On" >> "$php_ini"
    fi

    sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 20M/" "$php_ini"
    sed -i "s/^post_max_size = .*/post_max_size = 20M/" "$php_ini"
    sed -i "s/^max_execution_time = .*/max_execution_time = 60/" "$php_ini"
    sed -i "s/^max_input_vars = .*/max_input_vars = 5000/" "$php_ini"
    sed -i "s/^memory_limit = .*/memory_limit = 256M/" "$php_ini"
    sed -i "s/^date.timezone = .*/date.timezone = $TZ/" "$php_ini"

    systemctl restart apache2 || error_exit "Erro ao reiniciar Apache após ajustes no PHP."
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    error_exit "Este script deve ser executado como root."
fi

# Criar diretório de log se não existir
mkdir -p /var/log
touch /var/log/glpi_install.log
chown root:root /var/log/glpi_install.log
chmod 0644 /var/log/glpi_install.log

# Interações dinâmicas com o usuário
log "INFO" "Bem-vindo ao instalador modular do GLPI!"

# Verificar pré-requisitos
check_prerequisites

# Configuração inicial do MariaDB
read -sp "Digite a senha para o usuário root do MariaDB: " ROOT_DB_PASS
echo

# Perguntar se deseja detectar a versão mais recente ou informar manualmente
read -p "Deseja detectar a versão mais recente do GLPI automaticamente? (s/n): " auto_detect
if [[ "$auto_detect" =~ ^[sS]$ ]]; then
    GLPI_VERSION=$(get_latest_glpi_version)
else
    read -p "Informe a versão do GLPI (ex: 10.0.20): " GLPI_VERSION
    if [ -z "$GLPI_VERSION" ] || [[ "$GLPI_VERSION" =~ ^[[:space:]]*$ ]]; then
        GLPI_VERSION="10.0.20"
        log "INFO" "Nenhuma versão informada. Usando versão padrão: $GLPI_VERSION"
    fi
fi

# Perguntar configurações do banco de dados do GLPI
read -p "Nome do banco de dados (padrão: glpi): " DB_NAME
DB_NAME=${DB_NAME:-glpi}

read -p "Usuário do banco de dados (padrão: glpiuser): " DB_USER
DB_USER=${DB_USER:-glpiuser}

read -sp "Senha do banco de dados do GLPI: " DB_PASS
echo

# Obter ServerName automaticamente ou manual
SERVER_NAME=$(hostname -I | awk '{print $1}')
read -p "ServerName para Apache (padrão: $SERVER_NAME): " INPUT_SERVER_NAME
SERVER_NAME=${INPUT_SERVER_NAME:-$SERVER_NAME}

# Perguntar se o GLPI deve ser servido na raiz ou em um subdiretório
read -p "Deseja acessar o GLPI na raiz (/) ou em um subdiretório como /glpi? (raiz/sub): " BASE_PATH
if [[ "$BASE_PATH" =~ ^[sS][uU][bB]$ ]]; then
    BASE_PATH="/glpi"
else
    BASE_PATH="/"
fi

# Perguntar configurações de backup
read -p "Diretório de destino para backups (padrão: /backup): " BACKUP_DIR
BACKUP_DIR=${BACKUP_DIR:-/backup}
mkdir -p "$BACKUP_DIR" || error_exit "Falha ao criar diretório de backup."

# Verificar instalação existente
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
                setup_php_ini
                setup_apache "$SERVER_NAME" "$BASE_PATH"
                setup_cron
                setup_backup "$ROOT_DB_PASS" "$DB_NAME" "$BACKUP_DIR"
                log "INFO" "Instalação concluída. Acesse o GLPI em http://$SERVER_NAME$BASE_PATH e siga as instruções de configuração."
                exit 0
            else
                log "INFO" "Upgrade cancelado."
                exit 0
            fi
            ;;
        1)
            log "INFO" "A versão instalada já é a mais recente ($GLPI_VERSION). Nenhuma ação necessária."
            exit 0
            ;;
        2)
            log "INFO" "A versão instalada ($CURRENT_VERSION) é mais recente que a solicitada ($GLPI_VERSION). Nenhuma ação necessária."
            exit 0
            ;;
    esac
else
    log "INFO" "Nenhuma instalação existente detectada. Procedendo com instalação nova."
fi

# Executar as funções em sequência para instalação nova
install_packages
check_services
setup_mariadb "$ROOT_DB_PASS"
download_glpi "$GLPI_VERSION"
setup_fhs
setup_permissions
setup_database "$DB_NAME" "$DB_USER" "$DB_PASS" "$ROOT_DB_PASS"
setup_php_ini
setup_apache "$SERVER_NAME" "$BASE_PATH"
setup_cron
setup_backup "$ROOT_DB_PASS" "$DB_NAME" "$BACKUP_DIR"

log "INFO" "Instalação concluída. Acesse o GLPI em http://$SERVER_NAME$BASE_PATH e siga as instruções de configuração."
