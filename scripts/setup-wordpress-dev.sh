#!/bin/bash

# Script para criação de ambiente WordPress local com Nginx e MySQL
# Desenvolvido para Ubuntu/Debian

set -e  # Para o script se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configurações
DOMAIN="localhost"
SITE_NAME="wordpress-dev"
MYSQL_ROOT_PASSWORD="root123"
MYSQL_DB_NAME="wordpress_db"
MYSQL_USER="wordpress_user"
MYSQL_PASSWORD="wordpress123"
WEB_ROOT="/var/www/html"
SITE_PATH="$WEB_ROOT/$SITE_NAME"
NGINX_SITE_CONFIG="/etc/nginx/sites-available/$SITE_NAME"

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   error "Este script deve ser executado como root (use sudo)"
fi

log "Iniciando configuração do ambiente WordPress local..."

# Atualizar sistema
log "Atualizando sistema..."
apt update && apt upgrade -y

# Instalar dependências
log "Instalando dependências..."
apt install -y curl wget unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Adicionar repositório PHP
log "Adicionando repositório PHP..."
add-apt-repository ppa:ondrej/php -y
apt update

# Criar usuário www-data (necessário para Nginx)
log "Criando usuário www-data..."
useradd -r -s /bin/false -d /var/www -c "Web Server" www-data 2>/dev/null || true
groupadd www-data 2>/dev/null || true
usermod -a -G www-data www-data 2>/dev/null || true

# Criar diretório /var/www se não existir
mkdir -p /var/www
chown www-data:www-data /var/www

# Instalar Nginx
log "Instalando Nginx..."
apt install -y nginx

# Instalar MySQL
log "Instalando MySQL..."
apt install -y mysql-server

# Instalar PHP e extensões
log "Instalando PHP 8.1 e extensões..."
apt install -y php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-xmlrpc php8.1-soap php8.1-intl php8.1-bcmath

# Configurar MySQL
log "Configurando MySQL..."

# Aguardar MySQL inicializar
sleep 5

# Verificar se o MySQL está rodando
if ! systemctl is-active --quiet mysql; then
    error "MySQL não está rodando. Verifique o status com: systemctl status mysql"
fi

# Configurar MySQL para usar autenticação por socket (mais seguro)
log "Configurando MySQL para autenticação por socket..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;" 2>/dev/null || {
    warn "Usuário root já configurado com auth_socket"
}

# Criar banco de dados e usuário WordPress
log "Criando banco de dados WordPress..."
mysql -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON $MYSQL_DB_NAME.* TO '$MYSQL_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Baixar WordPress
log "Baixando WordPress..."
cd /tmp
wget https://wordpress.org/latest.zip
unzip latest.zip
rm latest.zip

# Criar diretório do site
log "Criando diretório do site..."
mkdir -p $SITE_PATH
cp -r wordpress/* $SITE_PATH/

# Configurar permissões
log "Configurando permissões..."
chown -R www-data:www-data $SITE_PATH
chmod -R 755 $SITE_PATH

# Configurar permissões para diretórios específicos (se existirem)
[ -d "$SITE_PATH/wp-content/uploads" ] && chmod -R 775 $SITE_PATH/wp-content/uploads
[ -d "$SITE_PATH/wp-content/cache" ] && chmod -R 775 $SITE_PATH/wp-content/cache
[ -d "$SITE_PATH/wp-content/backup-db" ] && chmod -R 775 $SITE_PATH/wp-content/backup-db
[ -d "$SITE_PATH/wp-content/backups" ] && chmod -R 775 $SITE_PATH/wp-content/backups
[ -d "$SITE_PATH/wp-content/blogs.dir" ] && chmod -R 775 $SITE_PATH/wp-content/blogs.dir
[ -d "$SITE_PATH/wp-content/upgrade" ] && chmod -R 775 $SITE_PATH/wp-content/upgrade
[ -f "$SITE_PATH/wp-content/wp-cache-config.php" ] && chmod 775 $SITE_PATH/wp-content/wp-cache-config.php
[ -d "$SITE_PATH/wp-content/plugins" ] && chmod -R 775 $SITE_PATH/wp-content/plugins
[ -d "$SITE_PATH/wp-content/themes" ] && chmod -R 775 $SITE_PATH/wp-content/themes

# Criar arquivo wp-config.php
log "Criando arquivo wp-config.php..."
cp $SITE_PATH/wp-config-sample.php $SITE_PATH/wp-config.php

# Configurar wp-config.php
sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$MYSQL_DB_NAME' );/" $SITE_PATH/wp-config.php
sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$MYSQL_USER' );/" $SITE_PATH/wp-config.php
sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$MYSQL_PASSWORD' );/" $SITE_PATH/wp-config.php
sed -i "s/define( 'DB_HOST', 'localhost' );/define( 'DB_HOST', 'localhost' );/" $SITE_PATH/wp-config.php

# Gerar chaves de segurança
log "Gerando chaves de segurança..."
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
sed -i "/#@-/,/#@+/c\\$SALT" $SITE_PATH/wp-config.php

# Configurar Nginx
log "Configurando Nginx..."
cat > $NGINX_SITE_CONFIG << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $SITE_PATH;
    index index.php index.html index.htm;

    # Logs
    access_log /var/log/nginx/$SITE_NAME-access.log;
    error_log /var/log/nginx/$SITE_NAME-error.log;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;

    # WordPress rewrite rules
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP-FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Deny access to wp-config.php
    location = /wp-config.php {
        deny all;
    }

    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# Habilitar site
ln -sf $NGINX_SITE_CONFIG /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração Nginx
log "Testando configuração Nginx..."
nginx -t

# Reiniciar serviços
log "Reiniciando serviços..."
systemctl restart nginx
systemctl restart mysql
systemctl restart php8.1-fpm

# Habilitar serviços para iniciar com o sistema
systemctl enable nginx
systemctl enable mysql
systemctl enable php8.1-fpm

# Configurar firewall (opcional)
log "Configurando firewall..."
ufw allow 'Nginx Full'
ufw allow ssh
ufw --force enable

# Configurar permissões sudo para www-data (para o dashboard)
log "Configurando permissões sudo para www-data..."
echo "www-data ALL=(ALL) NOPASSWD: /home/weth/webhost/scripts/wp-multi.sh" > /etc/sudoers.d/www-data
chmod 440 /etc/sudoers.d/www-data

# Configurar dashboard (se existir)
if [ -d "/home/weth/webhost/dashboard" ]; then
    log "Configurando dashboard..."
    
    # Configurar permissões do diretório pai (necessário para Nginx acessar)
    chmod 755 /home/weth/
    
    # Configurar permissões do dashboard
    chmod -R 755 /home/weth/webhost/dashboard/
    
    # Configurar Nginx para o dashboard no localhost
    if [ -f "/home/weth/webhost/dashboard/nginx-config" ]; then
        cp /home/weth/webhost/dashboard/nginx-config /etc/nginx/sites-available/dashboard
        ln -sf /etc/nginx/sites-available/dashboard /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        log "Dashboard configurado em http://localhost"
    else
        warn "Arquivo nginx-config não encontrado no dashboard"
    fi
else
    warn "Dashboard não encontrado em /home/weth/webhost/dashboard"
fi

# Criar arquivo de informações
log "Criando arquivo de informações..."
cat > /root/wordpress-info.txt << EOF
===========================================
AMBIENTE WORDPRESS LOCAL CONFIGURADO
===========================================

Data de instalação: $(date)
Domínio: http://$DOMAIN
Diretório do site: $SITE_PATH

CREDENCIAIS DO BANCO DE DADOS:
- Database: $MYSQL_DB_NAME
- Usuário: $MYSQL_USER
- Senha: $MYSQL_PASSWORD
- Host: localhost

CREDENCIAIS MYSQL ROOT:
- Usuário: root
- Senha: $MYSQL_ROOT_PASSWORD

PRÓXIMOS PASSOS:
1. Acesse http://localhost no seu navegador para o dashboard
2. Use o dashboard para gerenciar sites WordPress
3. Configure o título do site e credenciais de administrador

ARQUIVOS IMPORTANTES:
- Configuração Nginx: $NGINX_SITE_CONFIG
- Logs Nginx: /var/log/nginx/$SITE_NAME-*.log
- Logs PHP: /var/log/php8.1-fpm.log

COMANDOS ÚTEIS:
- Reiniciar Nginx: systemctl restart nginx
- Reiniciar MySQL: systemctl restart mysql
- Reiniciar PHP-FPM: systemctl restart php8.1-fpm
- Verificar status: systemctl status nginx mysql php8.1-fpm

===========================================
EOF

log "Configuração concluída com sucesso!"

# Informações sobre o dashboard
if [ -d "/home/weth/webhost/dashboard" ]; then
    log "🎛️  Dashboard disponível em http://localhost"
    log "📊 Use o dashboard para gerenciar sites WordPress locais"
else
    log "Acesse http://$DOMAIN para completar a instalação do WordPress"
fi

log "Informações detalhadas salvas em /root/wordpress-info.txt"

# Mostrar informações finais
echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}AMBIENTE WORDPRESS LOCAL CONFIGURADO${NC}"
echo -e "${BLUE}===========================================${NC}"

# Informações sobre o dashboard
if [ -d "/home/weth/webhost/dashboard" ]; then
    echo -e "${GREEN}🎛️  Dashboard: http://localhost${NC}"
    echo -e "${YELLOW}📊 Use o dashboard para gerenciar sites WordPress${NC}"
else
    echo -e "${GREEN}URL: http://$DOMAIN${NC}"
fi

echo -e "${GREEN}Diretório: $SITE_PATH${NC}"
echo -e "${GREEN}Banco de dados: $MYSQL_DB_NAME${NC}"
echo -e "${BLUE}===========================================${NC}"
echo "" 