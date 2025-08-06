#!/bin/bash

# Script para limpeza completa do ambiente de desenvolvimento web
# Versão: 1.4.0 - Migração para Apache
# Desenvolvido para Ubuntu/Debian

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   error "Este script deve ser executado como root (use sudo)"
fi

log "Iniciando limpeza completa do ambiente de desenvolvimento web..."

# Parar serviços
log "Parando serviços..."
systemctl stop apache2 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true

# Desabilitar serviços
log "Desabilitando serviços..."
systemctl disable apache2 2>/dev/null || true
systemctl disable mysql 2>/dev/null || true

# Remover pacotes
log "Removendo pacotes..."
apt remove --purge -y apache2 apache2-bin apache2-data apache2-utils 2>/dev/null || true
apt remove --purge -y mysql-server mysql-client mysql-common 2>/dev/null || true
apt remove --purge -y php8.1 php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-xmlrpc php8.1-soap php8.1-intl php8.1-bcmath 2>/dev/null || true

# Remover dependências não utilizadas
log "Removendo dependências não utilizadas..."
apt autoremove -y
apt autoclean

# Remover diretórios e arquivos
log "Removendo diretórios e arquivos..."

# Remover sites
rm -rf /var/www/html/* 2>/dev/null || true
rm -rf /var/www/html/.* 2>/dev/null || true
rm -rf /opt/webhost/sites/wordpress/* 2>/dev/null || true
rm -rf /opt/webhost/sites/php/* 2>/dev/null || true
rm -rf /opt/webhost/sites/html/* 2>/dev/null || true

# Remover configurações Apache
rm -rf /etc/apache2/sites-available/* 2>/dev/null || true
rm -rf /etc/apache2/sites-enabled/* 2>/dev/null || true
rm -f /etc/apache2/sites-enabled/000-default.conf 2>/dev/null || true

# Remover logs
rm -rf /var/log/apache2/* 2>/dev/null || true
rm -rf /var/log/mysql/* 2>/dev/null || true

# Remover dados MySQL
rm -rf /var/lib/mysql/* 2>/dev/null || true

# Remover configurações PHP
rm -rf /etc/php/8.1/cli/conf.d/* 2>/dev/null || true

# Remover repositórios PHP
log "Removendo repositórios PHP..."
add-apt-repository --remove ppa:ondrej/php -y 2>/dev/null || true

# Limpar cache do apt
log "Limpando cache do apt..."
apt clean
apt autoclean

# Remover usuários e grupos criados (não remover www-data pois é necessário para Nginx)
log "Removendo usuários e grupos..."
# userdel -r www-data 2>/dev/null || true  # Não remover www-data - necessário para Nginx
# groupdel www-data 2>/dev/null || true    # Não remover www-data - necessário para Nginx

# Remover diretórios temporários
log "Limpando diretórios temporários..."
rm -rf /tmp/wordpress* 2>/dev/null || true
rm -rf /tmp/latest.zip 2>/dev/null || true

# Remover backups
log "Removendo backups..."
rm -rf /root/backups/* 2>/dev/null || true

# Limpar histórico do bash
log "Limpando histórico..."
history -c

# Verificar se ainda existem arquivos
log "Verificando arquivos remanescentes..."
if [ -d "/var/www/html" ] && [ "$(ls -A /var/www/html 2>/dev/null)" ]; then
    warn "Ainda existem arquivos em /var/www/html:"
    ls -la /var/www/html
fi

if [ -d "/etc/nginx/sites-available" ] && [ "$(ls -A /etc/nginx/sites-available 2>/dev/null)" ]; then
    warn "Ainda existem configurações Nginx:"
    ls -la /etc/nginx/sites-available
fi

if [ -d "/var/lib/mysql" ] && [ "$(ls -A /var/lib/mysql 2>/dev/null)" ]; then
    warn "Ainda existem dados MySQL:"
    ls -la /var/lib/mysql
fi

# Verificar processos
log "Verificando processos..."
if pgrep -x "nginx" > /dev/null; then
    warn "Processo Nginx ainda está rodando"
fi

if pgrep -x "mysqld" > /dev/null; then
    warn "Processo MySQL ainda está rodando"
fi

if pgrep -x "php-fpm" > /dev/null; then
    warn "Processo PHP-FPM ainda está rodando"
fi

log "Limpeza concluída!"
log "O sistema foi limpo completamente."
log "Agora você pode executar uma nova instalação limpa." 