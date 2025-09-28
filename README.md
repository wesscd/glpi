# 📦 Scripts Automatizados para Instalação, Backup e Desinstalação do GLPI com Apache

![GLPI](https://img.shields.io/badge/GLPI-10.0.20+-blue)
![Apache](https://img.shields.io/badge/Apache-2.4-green)
![MariaDB](https://img.shields.io/badge/MariaDB-10.5+-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

Este repositório contém scripts Bash modulares e robustos para gerenciar a instalação, upgrade, backup e desinstalação completa do [GLPI](https://glpi-project.org/) (Gestionnaire Libre de Parc Informatique) em servidores Linux baseados em Debian/Ubuntu, utilizando Apache, MariaDB e PHP. Os scripts automatizam todo o processo, incluindo detecção de versões, configuração de cron para backups automáticos, logs coloridos e verificações de pré-requisitos, tornando-os ideais para administradores de TI e implantações em produção.

Diferente de guias manuais (como o [repositório GLPIv2 com Nginx](https://github.com/wesscd/GLPIv2)), nossos scripts oferecem automação completa, suporte ao Filesystem Hierarchy Standard (FHS), e recursos avançados como logs detalhados e integração de backups. Eles foram testados com GLPI 10.0.20+ e são compatíveis com Ubuntu 20.04+ e Debian 11+.

## 📑 Índice

- [📦 Scripts Automatizados para Instalação, Backup e Desinstalação do GLPI com Apache](#-scripts-automatizados-para-instalação-backup-e-desinstalação-do-glpi-com-apache)
  - [📑 Índice](#-índice)
  - [✅ Requisitos](#-requisitos)
  - [🔧 Recursos Principais](#-recursos-principais)
  - [🛠 Scripts Disponíveis](#-scripts-disponíveis)
    - [glpi_install.sh](#glpi_installsh)
    - [glpi_backup.sh](#glpi_backupsh)
    - [glpi_uninstall.sh](#glpi_uninstallsh)
  - [🚀 Uso Rápido](#-uso-rápido)
  - [⏰ Configuração de Cron para Backups](#-configuração-de-cron-para-backups)
  - [🔍 Resolução de Problemas](#-resolução-de-problemas)
  - [🤝 Contribuições](#-contribuições)
  - [📄 Licença](#-licença)

## ✅ Requisitos

- **Sistema Operacional**: Debian 11+ ou Ubuntu 20.04+ (testado em Ubuntu 22.04 LTS).
- **Acesso**: Usuário root ou permissões `sudo`.
- **Hardware**: Mínimo 2GB RAM, 2 vCPUs, 10GB de espaço em disco (verificação automática de 1GB livre).
- **Rede**: Conexão à internet para download de pacotes e GLPI (verificação automática).
- **Dependências**: Instaladas automaticamente pelo script:
  - Apache2, MariaDB, PHP 8.1+ com extensões (`php-soap`, `php-cas`, `php-mysql`, `php-curl`, `php-gd`, `php-imap`, `php-ldap`, `php-xmlrpc`, `php-xml`, `php-mbstring`, `php-bcmath`, `php-intl`, `php-zip`, `php-bz2`, `php-redis`, `php-apcu`).
  - Utilitários: `xz-utils`, `bzip2`, `unzip`, `curl`, `wget`.
- **Versão do GLPI**: Detecta automaticamente a mais recente via API do GitHub; fallback para 10.0.20 se falhar.

**Nota**: Os scripts são projetados para Apache. Para Nginx, consulte [GLPIv2](https://github.com/wesscd/GLPIv2). Sempre faça backup antes de upgrades.

## 🔧 Recursos Principais

- **Instalação Automatizada**: Configura GLPI com Apache, MariaDB e PHP em minutos, com suporte a instalações novas ou upgrades.
- **Estrutura FHS**: Organiza arquivos em `/etc/glpi` (configs), `/var/lib/glpi` (variáveis, ex.: `_cache`, `_uploads`), e `/var/log/glpi` (logs).
- **Logs Coloridos**: Saídas no terminal com cores (verde=INFO, amarelo=WARN, vermelho=ERROR) e logs salvos em `/var/log/glpi_install.log` e `/var/log/glpi_backup.log`.
- **Flexibilidade no Apache**: Suporte a instalação na raiz (`/`) ou subdiretório (`/glpi`); opção para desabilitar o site default do Apache.
- **Segurança**:
  - Configuração equivalente ao `mysql_secure_installation`.
  - Grants para timezones no MariaDB.
  - PHP otimizado com `session.cookie_httponly=On`, `memory_limit=256M`, etc.
  - Permissões granulares (`root:root` para código-fonte, `www-data:www-data` para configs/vars/logs).
- **Backup Integrado**: Script de backup completo (banco + arquivos) com suporte a cron diário (2h) e logs detalhados.
- **Desinstalação Segura**: Remove GLPI, banco de dados, VirtualHost e cron, com backup obrigatório antes da remoção.
- **Pré-requisitos Verificados**: Checa espaço em disco (mínimo 1GB) e conectividade antes de iniciar.
- **Suporte a Idiomas**: Configuração inicial em português (BR) no assistente do GLPI.
- **Upgrade Automático**: Detecta instalações existentes, faz backup e atualiza para a versão solicitada.

## 🛠 Scripts Disponíveis

### glpi_install.sh

**Descrição**: Script principal para instalação ou upgrade do GLPI. Configura dependências, FHS, Apache, MariaDB, PHP, cron e backups automáticos.

**Características**:

- Verifica pré-requisitos (disco, rede).
- Detecta versão mais recente via API do GitHub.
- Suporta instalação na raiz ou subdiretório.
- Configura subdiretórios FHS (`_cache`, `_cron`, `_uploads`, etc.).
- Integra backup com cron opcional.
- Gera logs coloridos e arquivo `/var/log/glpi_install.log`.

**Uso**:

```bash
chmod +x glpi_install.sh
sudo ./glpi_install.sh
```

**Prompts Interativos**:

- Senha root do MariaDB.
- Versão do GLPI (detecção automática ou manual, ex.: `10.0.20`).
- Configurações do banco de dados (nome, usuário, senha).
- ServerName do Apache (ex.: `192.168.1.105`).
- Caminho base (`raiz` ou `sub` para `/glpi`).
- Timezone (ex.: `America/Sao_Paulo`).
- Diretório de backup (ex.: `/backup`).
- Configurar cron de backup diário (s/n).

**Saída Exemplo**:

```
[INFO] 2025-09-27 20:53:12: Bem-vindo ao instalador modular do GLPI!
[INFO] 2025-09-27 20:53:15: Versão detectada: 10.0.20
[INFO] 2025-09-27 20:53:30: Nenhuma instalação existente detectada. Procedendo com instalação nova.
[WARN] 2025-09-27 20:53:35: Diretório _log não encontrado.
[INFO] 2025-09-27 20:53:41: Instalação concluída. Acesse o GLPI em http://192.168.1.105/glpi
```

### glpi_backup.sh

**Descrição**: Script para backup completo do GLPI (banco de dados e arquivos), executável manualmente ou via cron. Integrado ao `glpi_install.sh`.

**Características**:

- Backup do banco com `mysqldump` (transações, triggers, rotinas).
- Backup de arquivos (código, configs, vars, logs) em `.tar.gz`.
- Suporte a FHS dinâmico (detecta diretórios existentes).
- Logs coloridos e salvos em `/var/log/glpi_backup.log`.
- Suporta execução não interativa para cron.

**Uso**:

- **Manual**:
  ```bash
  sudo /usr/local/bin/glpi_backup.sh
  ```
- **Cron (configurado no install)**:
  ```
  0 2 * * * www-data /usr/local/bin/glpi_backup.sh "sua_senha_root" "glpi" "/backup"
  ```

**Saída**:

- Banco: `/backup/glpi_db_backup_YYYYMMDD_HHMMSS.sql`
- Arquivos: `/backup/glpi_files_backup_YYYYMMDD_HHMMSS.tar.gz`

### glpi_uninstall.sh

**Descrição**: Remove completamente o GLPI, incluindo banco de dados, arquivos, VirtualHost e cron, com backup obrigatório antes da desinstalação.

**Características**:

- Backup automático em `/tmp/glpi_uninstall_backup_YYYYMMDD_HHMMSS`.
- Opção para remover pacotes (`apache2`, `mariadb`, `php`).
- Requer confirmação explícita (`SIM`).
- Logs coloridos no terminal.

**Uso**:

```bash
chmod +x glpi_uninstall.sh
sudo ./glpi_uninstall.sh
```

**Prompts Interativos**:

- Senha root do MariaDB.
- Nome/usuário do banco de dados.
- Confirmação de desinstalação.
- Remover pacotes (s/n).

## 🚀 Uso Rápido

1. **Clonar o Repositório**:

   ```bash
   git clone https://github.com/seu-usuario/GLPI-Scripts.git
   cd GLPI-Scripts
   ```

2. **Instalar o GLPI**:

   ```bash
   chmod +x glpi_install.sh
   sudo ./glpi_install.sh
   ```

   - Siga os prompts interativos.
   - Acesse `http://seu-ip/glpi` (ou raiz) e finalize o assistente (use `glpi/glpi` como credenciais iniciais; altere a senha imediatamente).

3. **Executar Backup Manual**:

   ```bash
   sudo /usr/local/bin/glpi_backup.sh
   ```

   - Verifique backups em `/backup`.

4. **Desinstalar (se necessário)**:

   ```bash
   chmod +x glpi_uninstall.sh
   sudo ./glpi_uninstall.sh
   ```

5. **Verificação**:
   - **Setup GLPI**: Acesse `http://seu-ip/glpi` e confirme que a "Etapa 0" não apresenta erros.
   - **Logs**: `tail -f /var/log/glpi_install.log` ou `/var/log/glpi_backup.log`.
   - **Serviços**: `systemctl status apache2 mariadb`.
   - **VirtualHost**: `apache2ctl -S`.
   - **Backups**: `ls -l /backup`.

## ⏰ Configuração de Cron para Backups

O `glpi_install.sh` oferece configuração automática de backups diários às 2h. Para editar manualmente:

```bash
sudo crontab -u www-data -e
```

Adicione:

```
0 2 * * * /usr/local/bin/glpi_backup.sh "sua_senha_root" "glpi" "/backup"
```

**Rotação de Backups (Opcional)**:
Para excluir backups com mais de 7 dias:

```bash
sudo crontab -u root -e
```

Adicione:

```
0 3 * * * find /backup -name "glpi_*" -mtime +7 -delete
```

**Segurança da Senha**:

- Armazenar a senha diretamente no cron não é recomendado. Como alternativa:
  1. Crie `/etc/glpi/backup.conf`:
     ```bash
     echo "ROOT_DB_PASS=sua_senha_root" | sudo tee /etc/glpi/backup.conf
     sudo chmod 600 /etc/glpi/backup.conf
     sudo chown root:root /etc/glpi/backup.conf
     ```
  2. Modifique `glpi_backup.sh` para ler a senha:
     ```bash
     source /etc/glpi/backup.conf
     ```

## 🔍 Resolução de Problemas

| **Problema**                                               | **Causa Possível**                                | **Solução**                                                                                                                            |
| ---------------------------------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Erros no Setup GLPI (ex.: diretórios `_cache`, `_uploads`) | Permissões incorretas ou subdiretórios ausentes.  | Verifique: `ls -ld /var/lib/glpi/_*`; corrija: `sudo chown -R www-data:www-data /var/lib/glpi; sudo chmod -R 755 /var/lib/glpi`.       |
| `session.cookie_httponly` Off                              | PHP.ini não atualizado.                           | Confirme: `grep session.cookie_httponly /etc/php/*/apache2/php.ini`; reexecute `setup_php_ini` ou edite manualmente e reinicie Apache. |
| VirtualHost não funciona                                   | Conflito com site default ou erro no `glpi.conf`. | Escolha subdiretório (`/glpi`); verifique: `apache2ctl -S`; reinicie: `sudo systemctl restart apache2`.                                |
| Backup falha                                               | Senha incorreta ou diretórios ausentes.           | Verifique `/var/log/glpi_backup.log`; teste manualmente: `sudo /usr/local/bin/glpi_backup.sh`.                                         |
| Dependências quebradas                                     | Pacotes em hold ou repositórios instáveis.        | `sudo apt-mark unhold <pacote>`; `sudo apt install -f`.                                                                                |
| Cron não executa                                           | Configuração incorreta ou permissões.             | Teste: `sudo -u www-data /usr/local/bin/glpi_backup.sh "senha" "glpi" "/backup"`; verifique `/etc/crontab`.                            |

**Logs para Depuração**:

- **Instalação**: `/var/log/glpi_install.log`.
- **Backup**: `/var/log/glpi_backup.log`.
- **Apache**: `/var/log/apache2/error.log`.
- **MariaDB**: `/var/log/mysql/error.log`.
- **GLPI**: `/var/log/glpi/`.

Se o problema persistir, abra uma issue com o log relevante.

## 🤝 Contribuições

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do repositório.
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`.
3. Commit suas mudanças: `git commit -m 'Adiciona suporte a X'`.
4. Push para a branch: `git push origin feature/nova-funcionalidade`.
5. Abra um Pull Request.

**Padrões**:

- Teste em Ubuntu 22.04 ou Debian 11.
- Use a função `log` para mensagens consistentes.
- Adicione testes unitários para funções críticas (ex.: `setup_fhs`, `backup_database`).
- Documente mudanças no `README.md`.

Agradecemos sua colaboração! 🌟

## 📄 Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE). Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Mantido por [Seu Nome/Equipe]. Última atualização: 27 de Setembro de 2025.**
