#!/bin/bash

# Atualizar repositórios e instalar pacotes necessários
apt update

apt install -y xz-utils bzip2 unzip curl

apt install -y apache2 mariadb-server libapache2-mod-php php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2,intl} unzip wget

# Baixar a última versão do GLPI
wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.15/glpi-10.0.15.tgz | tar -zxv -C /var/www/html/

# Extrair o arquivo baixado
tar -zxvf /tmp/glpi.tar.gz -C /var/www/html/

# CONFIGURANDO PERMISSÕES DO GLPI
chown -R www-data:www-data /var/www/html/glpi

# Configurar permissões
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;

# Criar banco de dados para o GLPI
mysql -e "CREATE DATABASE glpi;"
mysql -e "CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY 'sua_senha';"
mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpiuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Configurar Apache
echo "
<VirtualHost *:80>
    ServerName <IP ou DNS da maquina>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/glpi/public

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/glpi/public>
        AllowOverride All
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
" > /etc/apache2/sites-available/glpi.conf

a2enmod rewrite

a2ensite glpi.conf

systemctl restart apache2

echo -e "* *\t* * *\troot\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab


# Limpar arquivos temporários
rm /tmp/glpi.tar.gz

echo "Instalação concluída. Acesse o GLPI em http://seu_endereco/glpi ou http://seu_endereco e siga as instruções de configuração."
