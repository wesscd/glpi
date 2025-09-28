#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

# Atualizar repositórios e instalar pacotes necessários
apt update || { echo "Erro ao atualizar repositórios."; exit 1; }
apt install -y xz-utils bzip2 unzip curl apache2 mariadb-server libapache2-mod-php \
    php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2} \
    unzip wget || { echo "Erro ao instalar pacotes."; exit 1; }

# Verificar se o MariaDB e Apache estão ativos
systemctl is-active --quiet mariadb || { echo "MariaDB não está ativo."; exit 1; }
systemctl is-active --quiet apache2 || { echo "Apache2 não está ativo."; exit 1; }

# Baixar e extrair a última versão do GLPI
if ! wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.20/glpi-10.0.20.tgz | tar -zxv -C /var/www/html/; then
    echo "Erro ao baixar ou extrair o GLPI."
    exit 1
fi

# Configurar permissões do GLPI
chown -R www-data:www-data /var/www/html/glpi
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;

# Criar banco de dados para o GLPI
read -sp "Digite a senha para o usuário do banco de dados GLPI: " GLPI_DB_PASSWORD
echo
mysql -e "CREATE DATABASE glpi;" || { echo "Erro ao criar banco de dados."; exit 1; }
mysql -e "CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY '$GLPI_DB_PASSWORD';" || { echo "Erro ao criar usuário."; exit 1; }
mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpiuser'@'localhost';" || { echo "Erro ao conceder privilégios."; exit 1; }
mysql -e "FLUSH PRIVILEGES;"

# Configurar Apache
SERVER_NAME=$(hostname -I | awk '{print $1}')
cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName $SERVER_NAME
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/glpi/public

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/glpi/public>
        AllowOverride All
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite glpi.conf
systemctl restart apache2 || { echo "Erro ao reiniciar o Apache."; exit 1; }

# Configurar cron
echo -e "* *\t* * *\twww-data\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab

echo "Instalação concluída. Acesse o GLPI em http://$SERVER_NAME/glpi e siga as instruções de configuração."