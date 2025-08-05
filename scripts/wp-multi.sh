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
WEB_ROOT="/opt/webhost/sites"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
MYSQL_ROOT_PASSWORD="root123"
INFO_DIR="/opt/webhost/site-info"

# Configurações padrão do WordPress
WP_ADMIN_USER="admin"
WP_ADMIN_PASSWORD="@admin@1q2w3e4r"
WP_ADMIN_EMAIL="thiago95macedo@gmail.com"
WP_LANGUAGE="pt_BR"

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
    # Permitir execução sem root se AUTO_CONFIRM=1 (para uso via dashboard)
    if [[ $EUID -ne 0 ]] && [ "$AUTO_CONFIRM" != "1" ]; then
        error "Este script deve ser executado como root (use sudo)"
    fi
}

# Função para verificar e configurar permissões
check_permissions() {
    log "Verificando permissões do diretório /opt/webhost..."
    
    # Verificar se o diretório existe
    if [ ! -d "/opt/webhost" ]; then
        error "Diretório /opt/webhost não existe. Execute o script setup-wordpress-dev.sh primeiro."
    fi
    
    # Verificar se o grupo proprietário é sudo
    local current_group=$(stat -c '%G' /opt/webhost)
    if [ "$current_group" != "sudo" ]; then
        warn "Grupo proprietário de /opt/webhost não é sudo. Configurando..."
        chown -R :sudo /opt/webhost
        chmod -R 775 /opt/webhost
        chmod g+s /opt/webhost
    fi
    
    # Verificar se o usuário atual está no grupo sudo
    local current_user=${SUDO_USER:-$USER}
    if ! groups $current_user | grep -q sudo; then
        warn "Usuário $current_user não está no grupo sudo. Adicionando..."
        usermod -a -G sudo $current_user
        warn "Usuário $current_user adicionado ao grupo sudo. Faça logout e login novamente."
    fi
    
    log "Permissões verificadas e configuradas."
}

# Função para gerar senha aleatória
generate_password() {
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12 | tr -d "'"
}

# Função para encontrar porta disponível
find_available_port() {
    local port=9001
    while [ $port -le 10000 ]; do
        if ! ss -tuln | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    return 1
}

# Função para instalar WordPress automaticamente
install_wordpress() {
    local site_name=$1
    local port=$2
    local site_path="$WEB_ROOT/$site_name"

    # Aguardar um pouco para o Nginx carregar
    sleep 2

    log "Iniciando instalação automática do WordPress..."

    # Baixar WordPress em português brasileiro
    log "Baixando WordPress em português brasileiro..."
    cd /tmp
    rm -rf wordpress-pt_BR 2>/dev/null || true
    rm -f latest-pt_BR.zip 2>/dev/null || true
    
    if ! wget --timeout=60 --tries=3 --progress=bar:force https://br.wordpress.org/latest-pt_BR.zip; then
        error "Falha ao baixar WordPress em português. Verifique sua conexão com a internet."
    fi
    
    # Verificar se o arquivo foi baixado corretamente
    if [ ! -f "latest-pt_BR.zip" ] || [ ! -s "latest-pt_BR.zip" ]; then
        error "Arquivo WordPress em português não foi baixado corretamente."
    fi
    
    # Extrair WordPress em português
    log "Extraindo WordPress..."
    if ! unzip -q -o latest-pt_BR.zip; then
        error "Falha ao extrair WordPress em português. Arquivo pode estar corrompido."
    fi
    
    rm latest-pt_BR.zip
    
    # Copiar arquivos do WordPress em português para o diretório do site
    log "Instalando WordPress..."
    cp -rf wordpress/* "$site_path/"
    rm -rf wordpress

    # Configurar wp-config.php
    local db_name="${site_name//-/_}_db"
    local db_user="${site_name//-/_}_user"
    local db_password=$(grep "Senha:" "$INFO_DIR/$site_name-info.txt" | head -1 | awk '{print $3}')

    # Garantir que wp-config.php existe e está correto
    if [ ! -f "$site_path/wp-config.php" ]; then
        cp "$site_path/wp-config-sample.php" "$site_path/wp-config.php"

        # Configurar banco de dados
        sed -i "s/database_name_here/$db_name/g" "$site_path/wp-config.php"
        sed -i "s/username_here/$db_user/g" "$site_path/wp-config.php" 
        sed -i "s/password_here/$db_password/g" "$site_path/wp-config.php"

        # Adicionar configurações personalizadas ao wp-config.php
        cat >> "$site_path/wp-config.php" << 'CONFIG_EOF'

// Configurações personalizadas
define( 'WP_DEBUG', false );
define( 'WPLANG', 'pt_BR' );
define( 'WP_AUTO_UPDATE_CORE', true );

CONFIG_EOF
    fi

    # Criar arquivo de personalização da instalação
    cat > "$site_path/wp-content/install.php" << 'INSTALL_EOF'
<?php
/**
 * Personalização automática da instalação WordPress
 * Remove tela de boas-vindas e configura site automaticamente
 */

// Substituir função padrão para remover conteúdo desnecessário
function wp_install_defaults( $user_id ) {
    global $wpdb, $wp_rewrite;

    // Categoria padrão
    $cat_name = 'Geral';
    $cat_slug = 'geral';
    $cat_id = 1;

    $wpdb->insert( $wpdb->terms, array('term_id' => $cat_id, 'name' => $cat_name, 'slug' => $cat_slug, 'term_group' => 0) );
    $wpdb->insert( $wpdb->term_taxonomy, array('term_id' => $cat_id, 'taxonomy' => 'category', 'description' => '', 'parent' => 0, 'count' => 0));

    // IMPORTANTE: Ocultar painel de boas-vindas
    update_user_meta( $user_id, 'show_welcome_panel', 0 );

    // Configurações básicas do WordPress
    update_option( 'timezone_string', 'America/Sao_Paulo' );
    update_option( 'date_format', 'd/m/Y' );
    update_option( 'time_format', 'H:i' );
    update_option( 'start_of_week', 0 );
    update_option( 'use_smilies', 0 );
    update_option( 'WPLANG', 'pt_BR' );

    // Configurar permalinks
    update_option( 'permalink_structure', '/%postname%/' );
    if ( $wp_rewrite ) {
        $wp_rewrite->init();
        $wp_rewrite->flush_rules();
    }

    // NÃO criar posts/páginas padrão
    // (não executamos wp_insert_post aqui)
}

// Hook para executar após instalação
add_action( 'wp_install', 'remove_default_content' );

function remove_default_content( $user_id ) {
    // Aguardar um pouco para garantir que tudo foi criado
    sleep(1);

    // Remover post "Hello World" se existir
    $hello_post = get_posts(array(
        'title' => 'Hello world!',
        'post_type' => 'post',
        'numberposts' => 1
    ));

    if ( !empty($hello_post) ) {
        wp_delete_post( $hello_post[0]->ID, true );
    }

    // Remover post "Olá, mundo!" se existir  
    $ola_post = get_posts(array(
        'title' => 'Olá, mundo!',
        'post_type' => 'post', 
        'numberposts' => 1
    ));

    if ( !empty($ola_post) ) {
        wp_delete_post( $ola_post[0]->ID, true );
    }

    // Remover página de exemplo
    $sample_page = get_page_by_title( 'Sample Page' );
    if ( $sample_page ) {
        wp_delete_post( $sample_page->ID, true );
    }

    $exemplo_page = get_page_by_title( 'Página de exemplo' );
    if ( $exemplo_page ) {
        wp_delete_post( $exemplo_page->ID, true );
    }

    // Garantir que painel de boas-vindas permanece oculto
    update_user_meta( $user_id, 'show_welcome_panel', 0 );

    // Criar página inicial personalizada
    $home_page = array(
        'post_title' => 'Página Inicial',
        'post_content' => '<h1>Bem-vindo ao ' . get_bloginfo('name') . '!</h1><p>Seu site WordPress foi configurado automaticamente e está pronto para uso.</p>',
        'post_status' => 'publish',
        'post_type' => 'page',
        'post_name' => 'inicio'
    );

    $home_id = wp_insert_post( $home_page );

    if ( $home_id && !is_wp_error($home_id) ) {
        update_option( 'show_on_front', 'page' );
        update_option( 'page_on_front', $home_id );
    }
}
?>
INSTALL_EOF

    # Executar instalação do WordPress
    log "Executando instalação automática..."

    cd "$site_path"

    # Criar script de instalação mais simples e confiável
    cat > /tmp/install-wp.php << EOF
<?php
// Definir constante de instalação
define('WP_INSTALLING', true);

// Carregar WordPress
require_once('$site_path/wp-load.php');
require_once('$site_path/wp-admin/includes/upgrade.php');

// Verificar se já instalado
if ( is_blog_installed() ) {
    echo "WordPress já instalado!";
    exit(0);
}

// Executar instalação
\$result = wp_install(
    '$site_name',
    '$WP_ADMIN_USER', 
    '$WP_ADMIN_EMAIL',
    true,
    '',
    '$WP_ADMIN_PASSWORD',
    'pt_BR'
);

if ( is_wp_error(\$result) ) {
    echo "Erro: " . \$result->get_error_message();
    exit(1);
}

// Configurações pós-instalação
update_option('home', 'http://localhost:$port');
update_option('siteurl', 'http://localhost:$port');
update_option('blogdescription', 'Site WordPress automatizado');

// Garantir que painel de boas-vindas está oculto
\$user = get_user_by('login', '$WP_ADMIN_USER');
if ( \$user ) {
    update_user_meta( \$user->ID, 'show_welcome_panel', 0 );
}

echo "WordPress instalado com sucesso!";
?>
EOF

    # Executar instalação com timeout
    if timeout 60 php /tmp/install-wp.php > /tmp/wp-install.log 2>&1; then
        log "WordPress instalado e configurado com sucesso!"

        # Mostrar resultado
        if [ -f /tmp/wp-install.log ]; then
            cat /tmp/wp-install.log
        fi

        # Limpar arquivos temporários
        rm -f /tmp/install-wp.php /tmp/wp-install.log

        # Remover arquivo de personalização por segurança
        rm -f "$site_path/wp-content/install.php"

        return 0
    else
        error "Falha na instalação automática do WordPress"
        if [ -f /tmp/wp-install.log ]; then
            cat /tmp/wp-install.log
        fi
        return 1
    fi
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
    
    # Gerar credenciais únicas (substituir hífens por underscores)
    local db_name="${site_name//-/_}_db"
    local db_user="${site_name//-/_}_user"
    local db_password=$(generate_password)
    
    # Criar banco de dados
    log "Criando banco de dados..."
    if [[ $EUID -eq 0 ]]; then
        mysql -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';"
        mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"
    else
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        sudo mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';"
        sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
        sudo mysql -e "FLUSH PRIVILEGES;"
    fi
    
    # Criar diretório do site
    log "Criando diretório do site em: $WEB_ROOT/$site_name"
    mkdir -p "$WEB_ROOT/$site_name"
    
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
    
    # Configurar WordPress (será feito na função install_wordpress)
    log "Configurando WordPress..."
    
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
    chown :sudo "$INFO_DIR"
    chmod 775 "$INFO_DIR"
    
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

CREDENCIAIS DO ADMINISTRADOR:
- Usuário: $WP_ADMIN_USER
- Senha: $WP_ADMIN_PASSWORD
- Email: $WP_ADMIN_EMAIL

PRÓXIMOS PASSOS:
1. Acesse http://localhost:$port no seu navegador
2. O WordPress já está instalado e configurado
3. Faça login em http://localhost:$port/wp-admin

===========================================
EOF
    
    # Instalar WordPress automaticamente
    log "Instalando WordPress automaticamente..."
    install_wordpress "$site_name" "$port"
    
    log "Site $site_name criado com sucesso!"
    log "URL: http://localhost:$port"
    log "Admin: http://localhost:$port/wp-admin"
    log "Usuário: $WP_ADMIN_USER"
    log "Senha: $WP_ADMIN_PASSWORD"
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
    
    # Confirmar exclusão (pular se AUTO_CONFIRM=1)
    if [ "$AUTO_CONFIRM" != "1" ]; then
        read -p "Tem certeza que deseja deletar o site $site_name? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Operação cancelada"
            exit 0
        fi
    else
        log "Confirmação automática ativada"
    fi
    
    # Deletar banco de dados (substituir hífens por underscores)
    local db_name="${site_name//-/_}_db"
    local db_user="${site_name//-/_}_user"
    
    log "Deletando banco de dados..."
    if [[ $EUID -eq 0 ]]; then
        mysql -e "DROP DATABASE IF EXISTS $db_name;"
        mysql -e "DROP USER IF EXISTS '$db_user'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"
    else
        sudo mysql -e "DROP DATABASE IF EXISTS $db_name;"
        sudo mysql -e "DROP USER IF EXISTS '$db_user'@'localhost';"
        sudo mysql -e "FLUSH PRIVILEGES;"
    fi
    
    # Deletar arquivos
    log "Deletando arquivos..."
    rm -rf "$WEB_ROOT/$site_name"
    # Remover também do diretório antigo (compatibilidade)
    rm -rf "/opt/webhost/sites/$site_name"
    
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
    local backup_dir="/opt/webhost/backups"
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
    
    # Fazer backup do banco de dados (substituir hífens por underscores)
    local db_name="${site_name//-/_}_db"
    local db_backup_file="$backup_dir/${site_name}_db_${timestamp}.sql"
    
    log "Backup do banco de dados..."
    if [[ $EUID -eq 0 ]]; then
        mysqldump "$db_name" > "$db_backup_file"
    else
        sudo mysqldump "$db_name" > "$db_backup_file"
    fi
    
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

# Verificar permissões antes de executar qualquer comando
check_permissions

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