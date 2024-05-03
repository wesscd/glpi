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
echo "Baixando BEHAVIORS"
wget https://github.com/yllen/behaviors/releases/download/v1.4.0/behaviors-1.4.0.tar.gz
echo "Descompactando BEHAVIORS"
tar xvf behaviors-1.4.0.tar.gz &&
rm -Rf behaviors-1.4.0.tar.gz
echo "BEHAVIORS OK"
#
clear
echo "#--------------------------------------------------------#"
echo           "INSTALANDO O PLUGIN COSTS (costs)"
echo "#--------------------------------------------------------#"
echo "Baixando COSTS"
wget https://github.com/ticgal/costs/releases/download/3.0.3/glpi-costs-3.0.3.tar.tgz
echo "Descompactando COSTS"
tar xvf glpi-costs-3.0.3.tar.tgz &&
rm -Rf glpi-costs-3.0.3.tar.tgz 
echo "Costs OK"
#
clear
echo "#--------------------------------------------------------#"
echo     "INSTALANDO O PLUGIN DATA INJECTION (datainjection)"
echo "#--------------------------------------------------------#"
echo "Baixando DATA INJECTION"
wget https://github.com/pluginsGLPI/datainjection/releases/download/2.13.5/glpi-datainjection-2.13.5.tar.bz2
echo "Descompactando DATA INJECTION"
tar xvf glpi-datainjection-2.13.5.tar.bz2 &&
rm -Rf glpi-datainjection-2.13.5.tar.bz2
echo "DATA INJECTION OK"
#
clear
echo "#--------------------------------------------------------#"
echo         "INSTALANDO O PLUGIN ARCHIMAP (Diagrams)"
echo "#--------------------------------------------------------#"
echo "Baixando ARCHIMAP"
wget https://github.com/ericferon/glpi-archimap/releases/download/v3.3.4/archimap-v3.3.4.zip
echo "Descompactando ARCHIMAP"
unzip archimap-v3.3.4.zip &&
rm -Rf archimap-v3.3.4.zip
echo "ARCHIMAP OK"

#
clear
echo "#--------------------------------------------------------#"
echo      "INSTALANDO O PLUGIN FORMCREATOR (For Creator)"
echo "#--------------------------------------------------------#"
echo "Baixando FormCreator"
wget https://github.com/pluginsGLPI/formcreator/releases/download/2.13.9/glpi-formcreator-2.13.9.tar.bz2
echo "Descompactando FormCreator"
tar xvf glpi-formcreator-2.13.9.tar.bz2 &&
rm -Rf glpi-formcreator-2.13.9.tar.bz2
echo "FormCreator OK"
#
clear
echo "#--------------------------------------------------------#"
echo        "INSTALANDO O PLUGIN PDF (Imprimir em PDF)"
echo "#--------------------------------------------------------#"
echo "Baixando PDF Print"
wget https://github.com/yllen/pdf/releases/download/v3.0.0/glpi-pdf-3.0.0.tar.gz
echo "Descompactando PDF Print"
tar xvf glpi-pdf-3.0.0.tar.gz &&
rm -Rf glpi-pdf-3.0.0.tar.gz
echo "PDF Print OK"
#
clear
echo "#--------------------------------------------------------#"
echo     "INSTALANDO O PLUGIN MAIL ANALYZER (Mailanalyzer) "
echo "#--------------------------------------------------------#"
echo "Baixando Mail Analyzer"
wget https://github.com/tomolimo/mailanalyzer/releases/download/3.2.0/mailanalyzer-3.2.0.zip
echo "Descompactando Mail Analyzer"
unzip mailanalyzer-3.2.0.zip &&
rm -Rf mailanalyzer-3.2.0.zip
echo "Mail Analyzer OK"
#
clear
echo "#--------------------------------------------------------#"
echo    "INSTALANDO O PLUGIN SATISFACTION (Mais satisfação)"
echo "#--------------------------------------------------------#"
echo "Baixando SATISFACTION"
wget https://github.com/pluginsGLPI/satisfaction/releases/download/1.6.2/glpi-satisfaction-1.6.2.tar.bz2
echo "Descompactando SATISFACTION"
tar xvf glpi-satisfaction-1.6.2.tar.bz2 &&
rm -Rf glpi-satisfaction-1.6.2.tar.bz2
echo "SATISFACTION OK"
#
clear
echo "#--------------------------------------------------------#"
echo        "INSTALANDO O PLUGIN METABASE (Metabase)"
echo "#--------------------------------------------------------#"
echo "Baixando METABASE"
wget https://github.com/pluginsGLPI/metabase/releases/download/1.3.3/glpi-metabase-1.3.3.tar.bz2
echo "Descompactando METABASE"
tar xvf glpi-metabase-1.3.3.tar.bz2 &&
rm -Rf glpi-metabase-1.3.3.tar.bz2
echo "METABASE OK"

#
clear
echo "#--------------------------------------------------------#"
echo       "INSTALANDO O PLUGIN Oauth IMAP (oauthimap)"
echo "#--------------------------------------------------------#"
echo "Baixando Oauth IMAP"
wget https://github.com/pluginsGLPI/oauthimap/releases/download/1.4.3/glpi-oauthimap-1.4.3.tar.bz2
echo "Descompactando Oauth IMAP"
tar xvf glpi-oauthimap-1.4.3.tar.bz2 &&
rm -Rf glpi-oauthimap-1.4.3.tar.bz2
echo "Oauth IMAP OK"
#
clear
echo "#--------------------------------------------------------#"
echo        "INSTALANDO O PLUGIN TASK LIST (tasklists)"
echo "#--------------------------------------------------------#"
echo "Baixando TASK LIST"
wget https://github.com/InfotelGLPI/tasklists/releases/download/2.0.3/glpi-tasklists-2.0.3.tar.bz2
echo "Descompactando TASK LIST"
tar xvf glpi-tasklists-2.0.3.tar.bz2 &&
rm -Rf glpi-tasklists-2.0.3.tar.bz2
echo "TASK LIST OK"
#
clear
echo "#--------------------------------------------------------#"
echo          "INSTALANDO O PLUGIN NEWS (alertas)"
echo "#--------------------------------------------------------#"
echo "Baixando NEWS"
wget https://github.com/pluginsGLPI/news/releases/download/1.12.2/glpi-news-1.12.2.tar.bz2
echo "Descompactando NEWS"
tar xvf glpi-news-1.12.2.tar.bz2 &&
rm -Rf glpi-news-1.12.2.tar.bz2
echo "NEWS OK"
#
clear
echo "#--------------------------------------------------------#"
echo "INSTALANDO O PLUGIN GENERICOBJECT (Gerenciamento de objetos)"
echo "#--------------------------------------------------------#"
echo "Baixando GENERICOBJECT"
wget https://github.com/pluginsGLPI/genericobject/releases/download/2.14.9/glpi-genericobject-2.14.9.tar.bz2
echo "Descompactando GENERICOBJECT"
tar xvf glpi-genericobject-2.14.9.tar.bz2 &&
rm -Rf glpi-genericobject-2.14.9.tar.bz2
echo "GENERICOBJECT OK"
#
clear
echo "#--------------------------------------------------------#"
echo "INSTALANDO O PLUGIN TIMELINETICKET (Linha do tempo dos chamados)"
echo "#--------------------------------------------------------#"
echo "Baixando Time Line Ticket"
wget https://github.com/pluginsGLPI/timelineticket/releases/download/10.0%2B1.2/glpi-timelineticket-10.0+1.2.tar.bz2
echo "Descompactando Time Line Ticket"
tar xvf glpi-timelineticket-10.0+1.2.tar.bz2 &&
rm -Rf glpi-timelineticket-10.0+1.2.tar.bz2
echo "Time Line Ticket OK"
#
clear
echo "#--------------------------------------------------------#"
echo    "INSTALANDO O PLUGIN TAG (Gerenciamento de Etiquetas)"
echo "#--------------------------------------------------------#"
echo "Baixando TAG"
wget https://github.com/pluginsGLPI/tag/releases/download/2.11.7/glpi-tag-2.11.7.tar.bz2
echo "Descompactando TAG"
tar xvf glpi-tag-2.11.7.tar.bz2 &&
rm -Rf glpi-tag-2.11.7.tar.bz2
echo "TAG OK"
#
clear
echo "#--------------------------------------------------------#"
echo         "INSTALANDO O PLUGIN CONTAS (accounts)"
echo "#--------------------------------------------------------#"
echo "Baixando Accounts"
wget https://github.com/InfotelGLPI/accounts/releases/download/3.0.4/glpi-accounts-3.0.4.tar.bz2
echo "Descompactando Accounts"
tar xvf glpi-accounts-3.0.4.tar.bz2 &&
rm -Rf glpi-accounts-3.0.4.tar.bz2
echo "Accounts OK"
#
clear
echo "#--------------------------------------------------------#"
echo         "INSTALANDO O PLUGIN CRACHÁS (badges)"
echo "#--------------------------------------------------------#"
echo "Baixando Badges"
wget https://github.com/InfotelGLPI/badges/releases/download/3.0.0/glpi-badges-3.0.0.tar.bz2
echo "Descompactando Badges"
tar xvf glpi-badges-3.0.0.tar.bz2 &&
rm -Rf glpi-badges-3.0.0.tar.bz2
echo "Badges OK"
#
clear
echo "#--------------------------------------------------------#"
echo                          "FIM"
echo "#--------------------------------------------------------#"
