#!/bin/bash

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para instalar pacotes necessários
install_packages() {
    apt update && apt upgrade -y || error_exit "Falha ao atualizar sistema."
    apt install -y xz-utils bzip2 unzip curl apache2 mariadb-server libapache2-mod-php \
        php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2,redis} \
        unzip wget || error_exit "Falha ao instalar pacotes."
}

# Função para verificar serviços
check_services() {
    systemctl is-active --quiet mariadb || error_exit "MariaDB não está ativo."
    systemctl is-active --quiet apache2 || error_exit "Apache2 não está ativo."
}

# Função para configurar o MariaDB (equivalente ao mysql_secure_installation)
setup_mariadb() {
    local root_pass=$1

    # Verificar se o MariaDB está instalado
    if ! command -v mysql >/dev/null 2>&1; then
        error_exit "MariaDB não está instalado."
    fi

    # Verificar se o usuário root já tem uma senha definida
    if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
        echo "Usuário root do MariaDB já configurado (sem senha ou com senha existente)."
    else
        # Definir senha para o usuário root
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_pass';" || error_exit "Erro ao definir senha do root."
    fi

    # Executar configurações de segurança (equivalente ao mysql_secure_installation)
    mysql -u root -p"$root_pass" -e "
        DELETE FROM mysql.user WHERE User='';  -- Remover usuários anônimos
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');  -- Remover root remoto
        DROP DATABASE IF EXISTS test;  -- Remover banco de teste
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';  -- Remover privilégios do banco de teste
        FLUSH PRIVILEGES;" || error_exit "Erro ao aplicar configurações de segurança do MariaDB."

    # Importar timezones
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p"$root_pass" mysql || error_exit "Falha ao importar timezones para MariaDB."
}

# Função para obter a versão mais recente do GLPI
get_latest_glpi_version() {
    local latest_tag=$(curl -sL https://github.com/glpi-project/glpi/releases/latest | grep -oP 'releases/tag/\K[^"]+' | head -1)
    if [ -z "$latest_tag" ]; then
        error_exit "Não foi possível obter a versão mais recente do GLPI."
    fi
    echo "$latest_tag"
}

# Função para extrair a versão atual do GLPI instalado
get_current_glpi_version() {
    if [ -f /var/www/html/glpi/inc/define.php ]; then
        grep "define('GLPI_VERSION'" /var/www/html/glpi/inc/define.php | grep -oP "\d+\.\d+\.\d+" || echo ""
    else
        echo ""
    fi
}

# Função para comparar versões (retorna 0 se v1 < v2, 1 se v1 == v2, 2 se v1 > v2)
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
    local url="https://github.com/glpi-project/glpi/releases/download/$version/glpi-$version.tgz"
    if ! wget -O- "$url" | tar -zxv -C /var/www/html/; then
        error_exit "Erro ao baixar ou extrair o GLPI versão $version."
    fi
}

# Função para configurar estrutura FHS
setup_fhs() {
    local glpi_dir="/var/www/html/glpi"

    # Criar downstream.php
    cat <<EOF > "$glpi_dir/inc/downstream.php"
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

    # Mover diretórios
    mkdir -p /etc/glpi /var/lib/glpi /var/log/glpi
    mv "$glpi_dir/config" /etc/glpi/ || true
    mv "$glpi_dir/files" /var/lib/glpi/ || true
    mv /var/lib/glpi/_log /var/log/glpi/ || true

    # Criar local_define.php
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

    echo "Realizando upgrade do GLPI de $current_version para $new_version..."

    # Backup do diretório atual (incluindo FHS)
    backup_dir="/var/www/html/glpi_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r /var/www/html/glpi "$backup_dir/glpi" || error_exit "Falha ao fazer backup do código-fonte."
    cp -r /etc/glpi "$backup_dir/etc_glpi" || error_exit "Falha ao fazer backup de configs."
    cp -r /var/lib/glpi "$backup_dir/var_lib_glpi" || error_exit "Falha ao fazer backup de vars."
    cp -r /var/log/glpi "$backup_dir/var_log_glpi" || error_exit "Falha ao fazer backup de logs."

    # Backup do banco de dados
    mysqldump -u root -p"$root_pass" "$db_name" > "$backup_dir/glpi_db_backup.sql" || error_exit "Falha ao fazer backup do banco de dados."

    # Remover diretório antigo e baixar nova versão
    rm -rf /var/www/html/glpi
    download_glpi "$new_version"

    # Aplicar FHS na nova versão
    setup_fhs

    # Copiar arquivos de configuração da versão anterior (compatível com FHS)
    cp -r "$backup_dir/etc_glpi/"* /etc/glpi/ || error_exit "Falha ao copiar configurações."
    cp -r "$backup_dir/var_lib_glpi/"* /var/lib/glpi/ || error_exit "Falha ao copiar arquivos variáveis."

    # Configurar permissões na nova instalação
    setup_permissions

    # Executar migrações do banco de dados via CLI (se disponível)
    if [ -f /var/www/html/glpi/bin/console ]; then
        php /var/www/html/glpi/bin/console db:update --no-interaction || error_exit "Falha ao executar migrações do banco de dados."
    else
        echo "Aviso: Migrações do banco de dados precisam ser executadas manualmente via interface web."
    fi

    echo "Upgrade concluído. Verifique a instalação e acesse http://$SERVER_NAME/glpi para finalizar."
}

# Função para configurar permissões
setup_permissions() {
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

    mysql -u root -p"$root_pass" -e "CREATE DATABASE IF NOT EXISTS $db_name;" || error_exit "Erro ao criar banco de dados $db_name."
    mysql -u root -p"$root_pass" -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';" || error_exit "Erro ao criar usuário $db_user."
    mysql -u root -p"$root_pass" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';" || error_exit "Erro ao conceder privilégios."
    mysql -u root -p"$root_pass" -e "GRANT SELECT ON \`mysql\`.\`time_zone_name\` TO '$db_user'@'localhost';" || error_exit "Erro ao conceder privilégio de timezone."
    mysql -u root -p"$root_pass" -e "FLUSH PRIVILEGES;" || error_exit "Erro ao atualizar privilégios."
}

# Função para configurar o Apache
setup_apache() {
    local server_name=$1

    if [ ! -f /etc/apache2/sites-available/glpi.conf ]; then
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

        read -p "Deseja desabilitar o site default do Apache (000-default.conf)? (s/n): " disable_default
        if [[ "$disable_default" =~ ^[sS]$ ]]; then
            a2dissite 000-default.conf || error_exit "Falha ao desabilitar site default."
        fi

        a2enmod rewrite || error_exit "Falha ao habilitar módulo rewrite."
        a2ensite glpi.conf || error_exit "Falha ao ativar site glpi.conf."
    fi
    systemctl restart apache2 || error_exit "Erro ao reiniciar o Apache."
}

# Função para configurar o cron
setup_cron() {
    if ! grep -q "/var/www/html/glpi/front/cron.php" /etc/crontab; then
        echo -e "* *\t* * *\twww-data\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab || error_exit "Falha ao configurar cron."
    fi
}

# Função para configurar php.ini
setup_php_ini() {
    local php_version=$(php -v | grep -oP 'PHP \K\d+\.\d+' | head -1)
    local php_ini="/etc/php/$php_version/apache2/php.ini"
    if [ ! -f "$php_ini" ]; then
        error_exit "Arquivo php.ini não encontrado em $php_ini."
    fi

    read -p "Informe o timezone (ex: America/Sao_Paulo): " TZ
    TZ=${TZ:-UTC}

    sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 20M/" "$php_ini"
    sed -i "s/^post_max_size = .*/post_max_size = 20M/" "$php_ini"
    sed -i "s/^max_execution_time = .*/max_execution_time = 60/" "$php_ini"
    sed -i "s/^max_input_vars = .*/max_input_vars = 5000/" "$php_ini"
    sed -i "s/^memory_limit = .*/memory_limit = 256M/" "$php_ini"
    sed -i "s/^session.cookie_httponly = .*/session.cookie_httponly = On/" "$php_ini"
    sed -i "s/^date.timezone = .*/date.timezone = $TZ/" "$php_ini"

    systemctl restart apache2 || error_exit "Erro ao reiniciar Apache após ajustes no PHP."
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    error_exit "Este script deve ser executado como root."
fi

# Interações dinâmicas com o usuário
echo "Bem-vindo ao instalador modular do GLPI!"

# Configuração inicial do MariaDB
read -sp "Digite a senha para o usuário root do MariaDB: " ROOT_DB_PASS
echo

# Perguntar se deseja detectar a versão mais recente ou informar manualmente
read -p "Deseja detectar a versão mais recente do GLPI automaticamente? (s/n): " auto_detect
if [[ "$auto_detect" =~ ^[sS]$ ]]; then
    GLPI_VERSION=$(get_latest_glpi_version)
    echo "Versão detectada: $GLPI_VERSION"
else
    read -p "Informe a versão do GLPI (ex: 10.0.20): " GLPI_VERSION
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

# Verificar instalação existente
CURRENT_VERSION=$(get_current_glpi_version)
if [ -n "$CURRENT_VERSION" ]; then
    echo "Instalação existente do GLPI detectada na versão $CURRENT_VERSION."
    compare_versions "$CURRENT_VERSION" "$GLPI_VERSION"
    case $? in
        0)
            read -p "Deseja realizar o upgrade para $GLPI_VERSION? (s/n): " do_upgrade
            if [[ "$do_upgrade" =~ ^[sS]$ ]]; then
                install_packages  # Atualizar pacotes se necessário
                check_services
                setup_mariadb "$ROOT_DB_PASS"
                upgrade_glpi "$CURRENT_VERSION" "$GLPI_VERSION" "$ROOT_DB_PASS" "$DB_NAME"
                setup_php_ini
                setup_apache "$SERVER_NAME"
                setup_cron
                exit 0
            else
                echo "Upgrade cancelado."
                exit 0
            fi
            ;;
        1)
            echo "A versão instalada já é a mais recente ($GLPI_VERSION). Nenhuma ação necessária."
            exit 0
            ;;
        2)
            echo "A versão instalada ($CURRENT_VERSION) é mais recente que a solicitada ($GLPI_VERSION). Nenhuma ação necessária."
            exit 0
            ;;
    esac
else
    echo "Nenhuma instalação existente detectada. Procedendo com instalação nova."
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
setup_apache "$SERVER_NAME"
setup_cron

echo "Instalação concluída. Acesse o GLPI em http://$SERVER_NAME/glpi e siga as instruções de configuração."