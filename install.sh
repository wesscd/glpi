#!/bin/bash

# -----------------------------------------------------------------------------
# Script de Instalação e Configuração do GLPI
#
# Este script foi projetado para automatizar a instalação do GLPI,
# um software de gerenciamento de ativos de TI e help desk.
#
# Autor: Seu Nome
# Versão: 2.0
# Data: 26/09/2025
#
# Pré-requisitos:
# - Executar como root ou com privilégios de sudo.
# - Sistema operacional baseado em Debian (ex: Ubuntu).
#
# O que o script faz:
# 1.  Define variáveis personalizáveis para a instalação.
# 2.  Atualiza os repositórios e instala as dependências necessárias.
# 3.  Baixa e extrai a versão especificada do GLPI.
# 4.  Configura as permissões de arquivo e diretório para o GLPI.
# 5.  Cria o banco de dados e o usuário para o GLPI no MariaDB.
# 6.  Configura o Apache com um Virtual Host para o GLPI.
# 7.  Adiciona uma tarefa cron para a execução automática de rotinas do GLPI.
# 8.  Fornece feedback sobre a conclusão da instalação.
# -----------------------------------------------------------------------------

# --- Variáveis de Configuração ---
# Modifique estas variáveis de acordo com suas necessidades.

# Versão do GLPI a ser instalada.
# Verifique a versão mais recente em: https://github.com/glpi-project/glpi/releases
GLPI_VERSION="10.0.15"

# Diretório de instalação do GLPI.
GLPI_DIR="/var/www/html"

# Credenciais do banco de dados.
DB_NAME="glpi"
DB_USER="glpiuser"
DB_PASS="sua_senha_segura"  # Recomenda-se usar uma senha forte.

# Configurações do servidor.
SERVER_IP_OR_DNS="seu_servidor.com"  # IP ou DNS do servidor.

# --- Início da Execução ---

# 1. Atualizar repositórios e instalar pacotes essenciais
echo "Atualizando repositórios e instalando pacotes..."
apt-get update -y
apt-get install -y apache2 mariadb-server php-soap php-cas php \
    php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2} \
    unzip wget tar xz-utils bzip2 curl

# 2. Baixar e extrair o GLPI
echo "Baixando e extraindo o GLPI versão ${GLPI_VERSION}..."
GLPI_URL="https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"
wget -O "/tmp/glpi.tgz" "${GLPI_URL}"
tar -zxvf "/tmp/glpi.tgz" -C "${GLPI_DIR}"

# 3. Configurar permissões do GLPI
echo "Configurando permissões para o diretório do GLPI..."
chown -R www-data:www-data "${GLPI_DIR}/glpi"
find "${GLPI_DIR}/glpi" -type d -exec chmod 755 {} \;
find "${GLPI_DIR}/glpi" -type f -exec chmod 644 {} \;

# 4. Criar banco de dados e usuário para o GLPI
echo "Criando banco de dados e usuário no MariaDB..."
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 5. Configurar o Apache para o GLPI
echo "Configurando o Virtual Host do Apache..."
cat <<EOL > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName ${SERVER_IP_OR_DNS}
    DocumentRoot ${GLPI_DIR}/glpi/public

    <Directory ${GLPI_DIR}/glpi/public>
        Require all granted
        AllowOverride All
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ index.php?url=\$1 [QSA,L]
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOL

# 6. Habilitar configurações do Apache
echo "Habilitando o site GLPI e o módulo rewrite..."
a2ensite glpi.conf
a2enmod rewrite
systemctl restart apache2

# 7. Configurar a tarefa cron para o GLPI
echo "Configurando a tarefa cron do GLPI..."
CRON_JOB="* * * * * www-data /usr/bin/php ${GLPI_DIR}/glpi/front/cron.php"
if ! crontab -l -u www-data | grep -q "glpi/front/cron.php"; then
    (crontab -l -u www-data 2>/dev/null; echo "${CRON_JOB}") | crontab -u www-data -
fi

# 8. Limpeza e mensagem final
echo "Limpando arquivos temporários..."
rm -f "/tmp/glpi.tgz"

echo -e "\n\033[1;32mInstalação do GLPI concluída com sucesso!\033[0m"
echo "Acesse o GLPI em: http://${SERVER_IP_OR_DNS}"
echo "Lembre-se de seguir as etapas de configuração final no navegador."
echo "Use as seguintes credenciais para o banco de dados durante a configuração:"
echo " - Servidor SQL: localhost"
echo " - Usuário SQL: ${DB_USER}"
echo " - Senha SQL: ${DB_PASS}"