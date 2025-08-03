#!/bin/bash

# Script para gerenciar múltiplos sites WordPress locais
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

# Configurações padrão
WEB_ROOT="/home/weth/wordpress/sites"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
MYSQL_ROOT_PASSWORD="root123"
INFO_DIR="/home/weth/wordpress/site-info"

# Função para mostrar ajuda
show_help() {
    echo -e "${BLUE}Script para Gerenciar Múltiplos Sites WordPress Locais${NC}"
    echo ""
    echo "Uso: $0 [COMANDO] [OPÇÕES]"
    echo ""
    echo "COMANDOS:"
echo "  create <nome-do-site> [domínio]  - Criar novo site WordPress (porta automática)"
    echo "  delete <nome-do-site>            - Deletar site WordPress"
    echo "  list                             - Listar todos os sites"
    echo "  backup <nome-do-site>            - Fazer backup do site"
    echo "  restore <nome-do-site> <arquivo> - Restaurar backup"
    echo "  enable <nome-do-site>            - Habilitar site"
    echo "  disable <nome-do-site>           - Desabilitar site"
    echo "  logs <nome-do-site>              - Ver logs do site"
    echo "  help                             - Mostrar esta ajuda"
    echo ""
    echo "EXEMPLOS:"
echo "  $0 create meu-site"
echo "  $0 create meu-site meusite.local"
    echo "  $0 delete meu-site"
    echo "  $0 list"
    echo "  $0 backup meu-site"
    echo ""
}

# Função para verificar se está rodando como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script deve ser executado como root (use sudo)"
    fi
}

# Função para gerar senha aleatória
generate_password() {
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12 | tr -d "'"
}

# Função para encontrar porta disponível
find_available_port() {
    local port=9001
    while [ $port -le 10000 ]; do
        if ! netstat -tuln | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    return 1
}

# Função para criar novo site
create_site() {
    local site_name=$1
    local domain=${2:-"localhost"}
    
    # Gerar porta automática
    local port=$(find_available_port)
    if [ -z "$port" ]; then
        error "Não foi possível encontrar uma porta disponível entre 9001-10000"
    fi
    
    check_root
    
    log "Criando novo site WordPress: $site_name"
    
    # Criar diretório de sites se não existir
    mkdir -p "$WEB_ROOT"
    chown www-data:www-data "$WEB_ROOT"
    chmod 755 "$WEB_ROOT"
    
    # Verificar se o site já existe
    if [ -d "$WEB_ROOT/$site_name" ]; then
        error "Site $site_name já existe!"
    fi
    
    # Gerar credenciais únicas
    local db_name="${site_name}_db"
    local db_user="${site_name}_user"
    local db_password=$(generate_password)
    
    # Criar banco de dados
    log "Criando banco de dados..."
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
    
    # Baixar WordPress
    log "Baixando WordPress..."
    cd /tmp
    rm -rf wordpress 2>/dev/null || true
    rm -f latest.zip 2>/dev/null || true
    
    # Tentar baixar WordPress com timeout adequado
    log "Baixando WordPress (pode demorar alguns minutos)..."
    if ! wget --timeout=60 --tries=3 --progress=bar:force https://wordpress.org/latest.zip; then
        error "Falha ao baixar WordPress. Verifique sua conexão com a internet."
    fi
    
    # Verificar se o arquivo foi baixado corretamente
    if [ ! -f "latest.zip" ] || [ ! -s "latest.zip" ]; then
        error "Arquivo WordPress não foi baixado corretamente."
    fi
    
    # Extrair WordPress
    if ! unzip -q latest.zip; then
        error "Falha ao extrair WordPress. Arquivo pode estar corrompido."
    fi
    
    rm latest.zip
    
    # Criar diretório do site
    log "Criando diretório do site em: $WEB_ROOT/$site_name"
    mkdir -p "$WEB_ROOT/$site_name"
    cp -rf wordpress/* "$WEB_ROOT/$site_name/"
    
    # Configurar permissões
    log "Configurando permissões..."
    chown -R www-data:www-data "$WEB_ROOT/$site_name"
    chmod -R 755 "$WEB_ROOT/$site_name"
    
    # Garantir que o diretório pai tenha permissões corretas para o Nginx
    local parent_dir=$(dirname "$WEB_ROOT")
    if [ -d "$parent_dir" ]; then
        chmod 755 "$parent_dir"
        log "Permissões do diretório pai configuradas"
    fi
    
    # Configurar permissões para diretórios específicos (se existirem)
    [ -d "$WEB_ROOT/$site_name/wp-content/uploads" ] && chmod -R 775 "$WEB_ROOT/$site_name/wp-content/uploads"
    [ -d "$WEB_ROOT/$site_name/wp-content/cache" ] && chmod -R 775 "$WEB_ROOT/$site_name/wp-content/cache"
    [ -d "$WEB_ROOT/$site_name/wp-content/plugins" ] && chmod -R 775 "$WEB_ROOT/$site_name/wp-content/plugins"
    [ -d "$WEB_ROOT/$site_name/wp-content/themes" ] && chmod -R 775 "$WEB_ROOT/$site_name/wp-content/themes"
    
    # Configurar wp-config.php
    log "Configurando WordPress..."
    cp "$WEB_ROOT/$site_name/wp-config-sample.php" "$WEB_ROOT/$site_name/wp-config.php"
    
    # Usar perl para substituições mais seguras
    perl -pi -e "s/database_name_here/$db_name/g" "$WEB_ROOT/$site_name/wp-config.php"
    perl -pi -e "s/username_here/$db_user/g" "$WEB_ROOT/$site_name/wp-config.php"
    perl -pi -e "s/password_here/$db_password/g" "$WEB_ROOT/$site_name/wp-config.php"
    
    # Gerar chaves de segurança
    log "Gerando chaves de segurança..."
    SALT=$(curl -s -L -m 60 https://api.wordpress.org/secret-key/1.1/salt/ 2>/dev/null || echo "ERROR")
    
    if [ "$SALT" != "ERROR" ]; then
        # Salvar chaves em arquivo temporário
        echo "$SALT" > /tmp/wp-keys.txt
        # Substituir seção de chaves usando uma abordagem mais simples
        # Primeiro, encontrar as linhas de início e fim
        START_LINE=$(grep -n "#@+" "$WEB_ROOT/$site_name/wp-config.php" | cut -d: -f1)
        END_LINE=$(grep -n "#@-" "$WEB_ROOT/$site_name/wp-config.php" | cut -d: -f1)
        
        if [ -n "$START_LINE" ] && [ -n "$END_LINE" ]; then
            # Criar arquivo temporário com o conteúdo antes das chaves
            head -n $((START_LINE - 1)) "$WEB_ROOT/$site_name/wp-config.php" > /tmp/wp-config-temp.txt
            # Adicionar as chaves
            cat /tmp/wp-keys.txt >> /tmp/wp-config-temp.txt
            # Adicionar o resto do arquivo
            tail -n +$((END_LINE + 1)) "$WEB_ROOT/$site_name/wp-config.php" >> /tmp/wp-config-temp.txt
            # Substituir o arquivo original
            mv /tmp/wp-config-temp.txt "$WEB_ROOT/$site_name/wp-config.php"
            log "Chaves de segurança geradas com sucesso"
        else
            warn "Não foi possível localizar as seções de chaves no wp-config.php"
        fi
        rm -f /tmp/wp-keys.txt
    else
        warn "Erro ao gerar chaves de segurança, mantendo chaves padrão"
        log "Chaves padrão mantidas (funcionais mas menos seguras)"
    fi
    
    # Configurar Nginx
    log "Configurando Nginx..."
    cat > "$NGINX_SITES_AVAILABLE/$site_name" << EOF
server {
    listen $port;
    server_name localhost 127.0.0.1;
    root $WEB_ROOT/$site_name;
    index index.php index.html index.htm;

    # Logs
    access_log /var/log/nginx/$site_name-access.log;
    error_log /var/log/nginx/$site_name-error.log;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
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
    ln -sf "$NGINX_SITES_AVAILABLE/$site_name" "$NGINX_SITES_ENABLED/"
    
    # Testar e reiniciar Nginx
    nginx -t
    systemctl reload nginx
    
    # Não precisamos adicionar entradas no /etc/hosts para localhost
    
    # Criar diretório de informações se não existir
    mkdir -p "$INFO_DIR"
    chown weth:weth "$INFO_DIR"
    
    # Salvar informações do site
    cat > "$INFO_DIR/$site_name-info.txt" << EOF
===========================================
SITE WORDPRESS: $site_name
===========================================

Data de criação: $(date)
URL: http://localhost:$port
Diretório: $WEB_ROOT/$site_name

CREDENCIAIS DO BANCO DE DADOS:
- Database: $db_name
- Usuário: $db_user
- Senha: $db_password
- Host: localhost

PRÓXIMOS PASSOS:
1. Acesse http://localhost:$port no seu navegador
2. Complete a instalação do WordPress
3. Configure o título do site e credenciais de administrador

===========================================
EOF
    
    log "Site $site_name criado com sucesso!"
    log "URL: http://localhost:$port"
    log "Informações salvas em $INFO_DIR/$site_name-info.txt"
}

# Função para deletar site
delete_site() {
    local site_name=$1
    
    check_root
    
    log "Deletando site: $site_name"
    
    # Verificar se o site existe
    if [ ! -d "$WEB_ROOT/$site_name" ]; then
        error "Site $site_name não existe!"
    fi
    
    # Confirmar exclusão
    read -p "Tem certeza que deseja deletar o site $site_name? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Operação cancelada"
        exit 0
    fi
    
    # Deletar banco de dados
    local db_name="${site_name}_db"
    local db_user="${site_name}_user"
    
    log "Deletando banco de dados..."
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DROP DATABASE IF EXISTS $db_name;"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DROP USER IF EXISTS '$db_user'@'localhost';"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
    
    # Deletar arquivos
    log "Deletando arquivos..."
    rm -rf "$WEB_ROOT/$site_name"
    # Remover também do diretório antigo (compatibilidade)
    rm -rf "/home/weth/wordpress/sites/$site_name"
    
    # Deletar configuração Nginx
    log "Removendo configuração Nginx..."
    rm -f "$NGINX_SITES_AVAILABLE/$site_name"
    rm -f "$NGINX_SITES_ENABLED/$site_name"
    
    # Deletar logs
    rm -f "/var/log/nginx/$site_name-access.log"
    rm -f "/var/log/nginx/$site_name-error.log"
    
    # Deletar arquivo de informações
    rm -f "$INFO_DIR/$site_name-info.txt"
    
    # Testar e reiniciar Nginx
    nginx -t
    systemctl reload nginx
    
    # Verificar se a porta foi liberada
    local port=$(grep -h "listen" "$NGINX_SITES_AVAILABLE/$site_name" 2>/dev/null | awk '{print $2}' | sed 's/;$//' || echo "")
    if [ -n "$port" ]; then
        log "Porta $port liberada e disponível para novos sites"
    fi
    
    log "Site $site_name deletado com sucesso!"
}

# Função para listar sites
list_sites() {
    log "Sites WordPress instalados:"
    echo ""
    
    if [ ! "$(ls -A $WEB_ROOT)" ]; then
        echo "Nenhum site encontrado."
        return
    fi
    
    for site_dir in "$WEB_ROOT"/*; do
        if [ -d "$site_dir" ] && [ -f "$site_dir/wp-config.php" ]; then
            site_name=$(basename "$site_dir")
            port=$(grep -h "listen" "$NGINX_SITES_AVAILABLE/$site_name" 2>/dev/null | awk '{print $2}' | sed 's/;$//' || echo "80")
            status=""
            
            if [ -L "$NGINX_SITES_ENABLED/$site_name" ]; then
                status="${GREEN}Ativo${NC}"
            else
                status="${RED}Inativo${NC}"
            fi
            
            echo -e "  ${BLUE}$site_name${NC} - localhost:$port [$status]"
        fi
    done
    echo ""
}

# Função para fazer backup
backup_site() {
    local site_name=$1
    local backup_dir="/root/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${site_name}_${timestamp}.tar.gz"
    
    check_root
    
    log "Fazendo backup do site: $site_name"
    
    # Verificar se o site existe
    if [ ! -d "$WEB_ROOT/$site_name" ]; then
        error "Site $site_name não existe!"
    fi
    
    # Criar diretório de backup
    mkdir -p "$backup_dir"
    
    # Fazer backup dos arquivos
    log "Backup dos arquivos..."
    tar -czf "$backup_file" -C "$WEB_ROOT" "$site_name"
    
    # Fazer backup do banco de dados
    local db_name="${site_name}_db"
    local db_backup_file="$backup_dir/${site_name}_db_${timestamp}.sql"
    
    log "Backup do banco de dados..."
    mysqldump -u root -p$MYSQL_ROOT_PASSWORD "$db_name" > "$db_backup_file"
    
    log "Backup concluído!"
    log "Arquivos: $backup_file"
    log "Banco de dados: $db_backup_file"
}

# Função para restaurar backup
restore_site() {
    local site_name=$1
    local backup_file=$2
    
    check_root
    
    log "Restaurando backup do site: $site_name"
    
    if [ ! -f "$backup_file" ]; then
        error "Arquivo de backup não encontrado: $backup_file"
    fi
    
    # TODO: Implementar restauração
    warn "Função de restauração ainda não implementada"
}

# Função para habilitar site
enable_site() {
    local site_name=$1
    
    check_root
    
    log "Habilitando site: $site_name"
    
    if [ ! -f "$NGINX_SITES_AVAILABLE/$site_name" ]; then
        error "Configuração do site $site_name não encontrada!"
    fi
    
    ln -sf "$NGINX_SITES_AVAILABLE/$site_name" "$NGINX_SITES_ENABLED/"
    nginx -t
    systemctl reload nginx
    
    log "Site $site_name habilitado!"
}

# Função para desabilitar site
disable_site() {
    local site_name=$1
    
    check_root
    
    log "Desabilitando site: $site_name"
    
    rm -f "$NGINX_SITES_ENABLED/$site_name"
    nginx -t
    systemctl reload nginx
    
    log "Site $site_name desabilitado!"
}

# Função para ver logs
show_logs() {
    local site_name=$1
    
    log "Logs do site: $site_name"
    echo ""
    
    if [ -f "/var/log/nginx/$site_name-access.log" ]; then
        echo -e "${BLUE}Access Log:${NC}"
        tail -20 "/var/log/nginx/$site_name-access.log"
        echo ""
    fi
    
    if [ -f "/var/log/nginx/$site_name-error.log" ]; then
        echo -e "${BLUE}Error Log:${NC}"
        tail -20 "/var/log/nginx/$site_name-error.log"
        echo ""
    fi
}

# Main script
case "$1" in
    create)
        if [ -z "$2" ]; then
            error "Nome do site é obrigatório. Use: $0 create <nome-do-site> [domínio]"
        fi
        create_site "$2" "$3"
        ;;
    delete)
        if [ -z "$2" ]; then
            error "Nome do site é obrigatório. Use: $0 delete <nome-do-site>"
        fi
        delete_site "$2"
        ;;
    list)
        list_sites
        ;;
    backup)
        if [ -z "$2" ]; then
            error "Nome do site é obrigatório. Use: $0 backup <nome-do-site>"
        fi
        backup_site "$2"
        ;;
    restore)
        if [ -z "$2" ] || [ -z "$3" ]; then
            error "Nome do site e arquivo de backup são obrigatórios. Use: $0 restore <nome-do-site> <arquivo>"
        fi
        restore_site "$2" "$3"
        ;;
    enable)
        if [ -z "$2" ]; then
            error "Nome do site é obrigatório. Use: $0 enable <nome-do-site>"
        fi
        enable_site "$2"
        ;;
    disable)
        if [ -z "$2" ]; then
            error "Nome do site é obrigatório. Use: $0 disable <nome-do-site>"
        fi
        disable_site "$2"
        ;;
    logs)
        if [ -z "$2" ]; then
            error "Nome do site é obrigatório. Use: $0 logs <nome-do-site>"
        fi
        show_logs "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac 