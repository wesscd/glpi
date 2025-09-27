# Scripts de Instalação para GLPI

Este repositório contém scripts para automatizar a instalação do GLPI e seus plugins.

## `install.sh`

Este script realiza a instalação e configuração completa do GLPI em um servidor baseado em Debian (como o Ubuntu).

### Funcionalidades

-   **Instalação Automatizada**: Instala Apache, MariaDB e todas as extensões PHP necessárias.
-   **Configuração Flexível**: Permite personalizar a instalação através de variáveis.
-   **Banco de Dados**: Cria o banco de dados e o usuário para o GLPI.
-   **Configuração do Apache**: Configura um Virtual Host para o GLPI.
-   **Agendamento de Tarefas**: Adiciona uma tarefa cron para as rotinas do GLPI.

### Como Usar

1.  **Abra o script `install.sh`** em um editor de texto.
2.  **Personalize as variáveis** na seção `--- Variáveis de Configuração ---` de acordo com suas necessidades:
    -   `GLPI_VERSION`: A versão do GLPI que você deseja instalar.
    -   `DB_NAME`: O nome do banco de dados do GLPI.
    -   `DB_USER`: O nome de usuário para o banco de dados.
    -   `DB_PASS`: A senha para o usuário do banco de dados.
    -   `SERVER_IP_OR_DNS`: O endereço IP ou DNS do seu servidor.
3.  **Execute o script** com privilégios de superusuário:
    ```bash
    sudo bash install.sh
    ```
4.  **Acesse o GLPI** no seu navegador (`http://<seu_servidor.com>`) e siga as instruções de configuração final, utilizando as credenciais de banco de dados que você definiu.

## `install_plugins.sh`

Este script automatiza o download e a instalação de plugins para o GLPI.

### Como Usar

1.  **Execute o script**:
    ```bash
    bash install_plugins.sh
    ```
2.  **Forneça o caminho** para o diretório de plugins do seu GLPI quando solicitado (ex: `/var/www/html/glpi/plugins`).
3.  O script irá baixar e extrair os plugins listados. Verifique o arquivo `erros.log` para quaisquer problemas que possam ter ocorrido durante a instalação.

## `Crontabs.md`

Este arquivo contém exemplos de como configurar manualmente as tarefas cron para o GLPI em diferentes ambientes. O script `install.sh` já automatiza essa configuração para um ambiente de servidor padrão.