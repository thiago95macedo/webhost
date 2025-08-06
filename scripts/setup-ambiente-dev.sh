#!/bin/bash

# =============================================================================
# Script de Instalação do Ambiente de Desenvolvimento Web Multi-Tecnologia
# Versão: 1.4.0 - Migração para Apache
# Descrição: Instala e configura um ambiente completo de desenvolvimento web
#            com suporte a WordPress, PHP puro e HTML estático usando Apache
#            Ambiente limpo sem instalação automática de sites
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

# Verificar se tem permissões sudo
if ! sudo -n true 2>/dev/null; then
   error "Este script precisa de permissões sudo. Execute com: sudo ./scripts/setup-ambiente-dev.sh"
fi

# Obter usuário atual
CURRENT_USER=$(whoami)
log "Usuário atual: $CURRENT_USER"

# Diretório base
BASE_DIR="/opt/webhost"
SITES_DIR="$BASE_DIR/sites"
SCRIPTS_DIR="$BASE_DIR/scripts"
DASHBOARD_DIR="$BASE_DIR/dashboard"
INFO_DIR="$BASE_DIR/site-info"

# Criar estrutura de diretórios
log "Criando estrutura de diretórios..."
sudo mkdir -p "$SITES_DIR"/{wordpress,php,html}
sudo mkdir -p "$SCRIPTS_DIR"
sudo mkdir -p "$DASHBOARD_DIR"
sudo mkdir -p "$INFO_DIR"

# Configurar permissões
log "Configurando permissões..."
sudo chown -R :sudo "$BASE_DIR"
sudo chmod -R 775 "$BASE_DIR"
sudo chmod g+s "$BASE_DIR"

# Adicionar usuário aos grupos necessários
log "Adicionando usuário aos grupos..."
sudo usermod -a -G sudo "$CURRENT_USER"
sudo usermod -a -G www-data "$CURRENT_USER"

# Atualizar lista de pacotes
log "Atualizando lista de pacotes..."
sudo apt update

# Instalar dependências
log "Instalando dependências..."
sudo apt install -y apache2 mysql-server php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-bcmath php8.1-intl php8.1-soap php8.1-opcache php8.1-readline unzip curl wget git

# Configurar Apache
log "Configurando Apache..."
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod expires
sudo a2enmod deflate
sudo a2enmod ssl
sudo a2enmod php8.1

# Configurar MySQL
log "Configurando MySQL..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Configurar MySQL root sem senha (apenas para desenvolvimento)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Configurar dashboard
log "Configurando dashboard..."
if [[ -f "$DASHBOARD_DIR/apache-config" ]]; then
    sudo cp "$DASHBOARD_DIR/apache-config" /etc/apache2/sites-available/dashboard.conf
    sudo a2ensite dashboard
    sudo a2dissite 000-default
fi

# Testar configuração Apache
log "Testando configuração Apache..."
sudo apache2ctl configtest

# Reiniciar Apache
log "Reiniciando Apache..."
sudo systemctl restart apache2

# Configurar sudoers para www-data
log "Configurando sudoers..."
sudo tee /etc/sudoers.d/www-data > /dev/null <<EOF
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/wp-multi.sh
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/php-multi.sh
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/html-multi.sh
www-data ALL=(ALL) NOPASSWD: apache2ctl
www-data ALL=(ALL) NOPASSWD: systemctl reload apache2
www-data ALL=(ALL) NOPASSWD: systemctl restart apache2
EOF

# Testar configuração final
sudo apache2ctl configtest
sudo systemctl reload apache2

log "Instalação concluída com sucesso!"
log ""
log "=== INFORMAÇÕES DO AMBIENTE ==="
log "Dashboard: http://localhost"
log ""
log "Para criar novos sites:"
log "  sudo ./scripts/wp-multi.sh create nome-do-site"
log "  sudo ./scripts/php-multi.sh create nome-do-site"
log "  sudo ./scripts/html-multi.sh create nome-do-site"
log ""
log "Para verificar status:"
log "  sudo ./scripts/check-status.sh" cleanup-ambiente-devcleanup-ambiente-devcleanup-ambiente-devcleanup-ambiente-dev