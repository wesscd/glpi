#!/bin/bash

clear
echo "#--------------------------------------------------------#"
echo  "INFORME O CAMINHO COMPLETO DO SEU DIRETORIO "glpi/plugins" "
echo "#--------------------------------------------------------#"
read -p "EXEMPLO: /var/www/html/glpi/plugins " diretorio &&
#
clear
echo "#--------------------------------------------------------#"
echo           "ENTRANDO NO DIRETORIO "glpi/plugins" "
echo "#--------------------------------------------------------#"
cd  $diretorio &&
#
clear
echo "#--------------------------------------------------------#"
echo  "INSTALANDO O PLUGIN TradeMark	(trademark)"
echo "#--------------------------------------------------------#"
echo "Baixando TradeMark"
wget https://github.com/LibreCodeCoop/trademark/archive/refs/heads/main.zip
echo "Descompactando TradeMark"
unzip main.zip &&
rm -Rf main.zip
echo "Modificando a pasta"
mv trademark-main trademark
echo "Trademark OK"
#

clear
echo "#--------------------------------------------------------#"
echo       "INSTALANDO O PLUGIN MORETICKET (Mais Chamados)"
echo "#--------------------------------------------------------#"
echo "Baixando Moreticket"
wget https://github.com/InfotelGLPI/moreticket/releases/download/1.7.4/glpi-moreticket-1.7.4.tar.bz2
echo "Descompactando Moreticket"
tar xvf glpi-moreticket-1.7.4.tar.bz2 &&
rm -Rf glpi-moreticket-1.7.4.tar.bz2 
echo "Moreticket OK"
#

clear
echo "#--------------------------------------------------------#"
echo       "INSTALANDO O PLUGIN ACTUALTIME (actualtime)"
echo "#--------------------------------------------------------#"
echo "Baixando ActualTime"
wget https://github.com/ticgal/actualtime/releases/download/3.0.1/glpi-actualtime-3.0.1.tar.tgz
echo "Descompactando ActualTime"
tar xvf glpi-actualtime-3.0.1.tar.tgz &&
rm -Rf glpi-actualtime-3.0.1.tar.tgz
echo "ActualTime OK"
#
clear
echo "#--------------------------------------------------------#"
echo       "INSTALANDO O PLUGIN FIELDS (Campos adicionais)"
echo "#--------------------------------------------------------#"
echo "Baixando FIELDS"
wget https://github.com/pluginsGLPI/fields/releases/download/1.21.8/glpi-fields-1.21.8.tar.bz2
echo "Descompactando FIELDS"
tar xvf glpi-fields-1.21.8.tar.bz2 &&
rm -Rf glpi-fields-1.21.8.tar.bz2
echo "FIELDS OK"
# 
clear
echo "#--------------------------------------------------------#"
echo      "INSTALANDO O PLUGIN BEHAVIORS (Comportamentos)"
echo "#--------------------------------------------------------#"
wget https://github.com/yllen/behaviors/releases/download/v1.4.0/behaviors-1.4.0.tar.gz
tar xvf behaviors-1.4.0.tar.gz &&
rm -Rf behaviors-1.4.0.tar.gz 
#
clear
echo "#--------------------------------------------------------#"
echo           "INSTALANDO O PLUGIN COSTS (costs)"
echo "#--------------------------------------------------------#"
wget https://github.com/ticgal/costs/releases/download/3.0.1/glpi-costs-3.0.1.tar.tgz
tar xvf glpi-costs-3.0.1.tar.tgz &&
rm -Rf glpi-costs-3.0.1.tar.tgz 
#
clear
echo "#--------------------------------------------------------#"
echo     "INSTALANDO O PLUGIN DATA INJECTION (datainjection)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/datainjection/releases/download/2.13.0/glpi-datainjection-2.13.0.tar.bz2
tar xvf glpi-datainjection-2.13.0.tar.bz2 &&
rm -Rf glpi-datainjection-2.13.0.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo         "INSTALANDO O PLUGIN ARCHIMAP (Diagrams)"
echo "#--------------------------------------------------------#"
wget https://github.com/ericferon/glpi-archimap/releases/download/v3.2.19/archimap-v3.2.19.tar.gz
tar xvf archimap-v3.2.19.tar.gz &&
rm -Rf archimap-v3.2.19.tar.gz 
#
clear
echo "#--------------------------------------------------------#"
echo       "INSTALANDO O PLUGIN ESCALADE (Escalonamento)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/escalade/releases/download/2.8.2/glpi-escalade-2.8.2.tar.bz2
tar xvf glpi-escalade-2.8.2.tar.bz2 &&
rm -Rf glpi-escalade-2.8.2.tar.bz2 
#
clear
echo "#--------------------------------------------------------#"
echo      "INSTALANDO O PLUGIN FORMCREATOR (For Creator)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/formcreator/releases/download/2.13.4/glpi-formcreator-2.13.4.tar.bz2
tar xvf glpi-formcreator-2.13.4.tar.bz2 &&
rm -Rf glpi-formcreator-2.13.4.tar.bz2 

clear
echo "#--------------------------------------------------------#"
echo        "INSTALANDO O PLUGIN PDF (Imprimir em PDF)"
echo "#--------------------------------------------------------#"
wget https://github.com/yllen/pdf/releases/download/v3.0.0/glpi-pdf-3.0.0.tar.gz
tar xvf glpi-pdf-3.0.0.tar.gz &&
rm -Rf glpi-pdf-3.0.0.tar.gz
#
clear
echo "#--------------------------------------------------------#"
echo     "INSTALANDO O PLUGIN MAIL ANALYZER (Mailanalyzer) "
echo "#--------------------------------------------------------#"
wget https://github.com/tomolimo/mailanalyzer/releases/download/3.2.0/mailanalyzer-3.2.0.zip
unzip mailanalyzer-3.2.0.zip &&
rm -Rf mailanalyzer-3.2.0.zip
#
clear
echo "#--------------------------------------------------------#"
echo    "INSTALANDO O PLUGIN SATISFACTION (Mais satisfação)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/satisfaction/releases/download/1.6.1/glpi-satisfaction-1.6.1.tar.bz2
tar xvf glpi-satisfaction-1.6.1.tar.bz2 &&
rm -Rf glpi-satisfaction-1.6.1.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo        "INSTALANDO O PLUGIN METABASE (Metabase)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/metabase/releases/download/1.3.2/glpi-metabase-1.3.2.tar.bz2
tar xvf glpi-metabase-1.3.2.tar.bz2 &&
rm -Rf glpi-metabase-1.3.2.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo       "INSTALANDO O PLUGIN Oauth IMAP (oauthimap)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/oauthimap/releases/download/1.4.1/glpi-oauthimap-1.4.1.tar.bz2
tar xvf glpi-oauthimap-1.4.1.tar.bz2 &&
rm -Rf glpi-oauthimap-1.4.1.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo        "INSTALANDO O PLUGIN TASK LIST (tasklists)"
echo "#--------------------------------------------------------#"
wget https://github.com/InfotelGLPI/tasklists/releases/download/2.0.3/glpi-tasklists-2.0.3.tar.bz2
tar xvf glpi-tasklists-2.0.3.tar.bz2 &&
rm -Rf glpi-tasklists-2.0.3.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo          "INSTALANDO O PLUGIN NEWS (alertas)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/news/releases/download/1.10.5/glpi-news-1.10.5.tar.bz2
tar xvf glpi-news-1.10.5.tar.bz2 &&
rm -Rf glpi-news-1.10.5.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo "INSTALANDO O PLUGIN GENERICOBJECT (Gerenciamento de objetos)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/genericobject/releases/download/2.14.1/glpi-genericobject-2.14.1.tar.bz2
tar xvf glpi-genericobject-2.14.1.tar.bz2 &&
rm -Rf glpi-genericobject-2.14.1.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo "INSTALANDO O PLUGIN TIMELINETICKET (Linha do tempo dos chamados)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/timelineticket/releases/download/10.0%2B1.1/glpi-timelineticket-10.0+1.1.tar.bz2
tar xvf glpi-timelineticket-10.0+1.1.tar.bz2 &&
rm -Rf glpi-timelineticket-10.0+1.1.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo    "INSTALANDO O PLUGIN TAG (Gerenciamento de Etiquetas)"
echo "#--------------------------------------------------------#"
wget https://github.com/pluginsGLPI/tag/releases/download/2.11.0/glpi-tag-2.11.0.tar.bz2
tar xvf glpi-tag-2.11.0.tar.bz2 &&
rm -Rf glpi-tag-2.11.0.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo         "INSTALANDO O PLUGIN CONTAS (accounts)"
echo "#--------------------------------------------------------#"
wget https://github.com/InfotelGLPI/accounts/releases/download/3.0.2/glpi-accounts-3.0.2.tar.bz2
tar xvf glpi-accounts-3.0.2.tar.bz2 &&
rm -Rf glpi-accounts-3.0.2.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo         "INSTALANDO O PLUGIN CRACHÁS (badges)"
echo "#--------------------------------------------------------#"
wget https://github.com/InfotelGLPI/badges/releases/download/3.0.0/glpi-badges-3.0.0.tar.bz2
tar xvf glpi-badges-3.0.0.tar.bz2 &&
rm -Rf glpi-badges-3.0.0.tar.bz2
#
clear
echo "#--------------------------------------------------------#"
echo                          "FIM"
echo "#--------------------------------------------------------#"
