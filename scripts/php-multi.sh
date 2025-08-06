#!/bin/bash

# Script para gerenciar múltiplos sites PHP locais
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
WEB_ROOT="/opt/webhost/sites/php"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
INFO_DIR="/opt/webhost/site-info"

# Função para mostrar ajuda
show_help() {
    echo -e "${BLUE}Script para Gerenciar Múltiplos Sites PHP Locais${NC}"
    echo ""
    echo "Uso: $0 [COMANDO] [OPÇÕES]"
    echo ""
    echo "COMANDOS:"
    echo "  create <nome-do-site> [domínio]  - Criar novo site PHP (porta automática)"
    echo "  delete <nome-do-site>            - Deletar site PHP"
    echo "  list                             - Listar todos os sites"
    echo "  backup <nome-do-site>            - Fazer backup do site"
    echo "  restore <nome-do-site> <arquivo> - Restaurar backup"
    echo "  enable <nome-do-site>            - Habilitar site"
    echo "  disable <nome-do-site>           - Desabilitar site"
    echo "  logs <nome-do-site>              - Ver logs do site"
    echo "  help                             - Mostrar esta ajuda"
    echo ""
    echo "EXEMPLOS:"
    echo "  $0 create meu-projeto"
    echo "  $0 create meu-projeto meusite.local"
    echo "  $0 delete meu-projeto"
    echo "  $0 list"
    echo "  $0 backup meu-projeto"
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

# Função para criar estrutura PHP básica
create_php_structure() {
    local site_name=$1
    local port=$2
    local site_path="$WEB_ROOT/$site_name"

    log "Criando estrutura PHP para: $site_name"

    # Criar index.php principal na raiz
    cat > "$site_path/index.php" << EOF
<?php
/**
 * Site PHP - Página Inicial
 * Gerado automaticamente pelo php-multi.sh
 */

// Configurações básicas
error_reporting(E_ALL);
ini_set('display_errors', 1);
date_default_timezone_set('America/Sao_Paulo');

// Informações do site
\$site_name = '$site_name';
\$site_url = 'http://localhost:$port';
\$created_date = '$(date '+%Y-%m-%d %H:%M:%S')';

?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars(\$site_name); ?> - Site PHP</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #212529;
            background: linear-gradient(135deg, #0056b3 0%, #4d89ca 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .container {
            background: white;
            padding: 3rem;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
            width: 90%;
        }
        
        .logo {
            font-size: 3rem;
            margin-bottom: 1rem;
            color: #0056b3;
        }
        
        h1 {
            color: #212529;
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }
        
        .subtitle {
            color: #6c757d;
            margin-bottom: 2rem;
            font-size: 1.2rem;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin: 2rem 0;
        }
        
        .info-card {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 8px;
            border-left: 4px solid #0056b3;
        }
        
        .info-card h3 {
            color: #0056b3;
            margin-bottom: 0.5rem;
        }
        
        .status {
            background: #d4edda;
            color: #155724;
            padding: 0.75rem;
            border-radius: 5px;
            margin: 1rem 0;
            font-weight: bold;
        }
        
        .tech-stack {
            background: #e9ecef;
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
        }
        
        .tech-stack h3 {
            color: #343a40;
            margin-bottom: 0.5rem;
        }
        
        .tech-list {
            list-style: none;
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            justify-content: center;
        }
        
        .tech-item {
            background: #0056b3;
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 15px;
            font-size: 0.9rem;
        }
        
        .footer {
            margin-top: 2rem;
            padding-top: 1rem;
            border-top: 1px solid #e9ecef;
            color: #6c757d;
            font-size: 0.9rem;
        }
        
        .php-info {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 1rem;
            border-radius: 5px;
            margin: 1rem 0;
        }
        
        .php-info h3 {
            color: #856404;
            margin-bottom: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1><?php echo htmlspecialchars(\$site_name); ?></h1>
        <p class="subtitle">Site PHP funcionando perfeitamente!</p>
        
        <div class="status">
            ✅ Site PHP ativo e operacional
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>URL do Site</h3>
                <p><?php echo htmlspecialchars(\$site_url); ?></p>
            </div>
            <div class="info-card">
                <h3>Data de Criação</h3>
                <p><?php echo htmlspecialchars(\$created_date); ?></p>
            </div>
            <div class="info-card">
                <h3>Versão PHP</h3>
                <p><?php echo PHP_VERSION; ?></p>
            </div>
            <div class="info-card">
                <h3>Servidor Web</h3>
                <p>Nginx + PHP-FPM</p>
            </div>
        </div>
        
        <div class="tech-stack">
            <h3>Stack Tecnológica</h3>
            <ul class="tech-list">
                <li class="tech-item">PHP <?php echo PHP_VERSION; ?></li>
                <li class="tech-item">Nginx</li>
                <li class="tech-item">PHP-FPM</li>
                <li class="tech-item">Ubuntu/Debian</li>
            </ul>
        </div>
        
        <div class="php-info">
            <h3>Informações do PHP</h3>
            <p><strong>Extensões carregadas:</strong> <?php echo count(get_loaded_extensions()); ?></p>
            <p><strong>Memória limite:</strong> <?php echo ini_get('memory_limit'); ?></p>
            <p><strong>Upload máximo:</strong> <?php echo ini_get('upload_max_filesize'); ?></p>
            <p><strong>Timezone:</strong> <?php echo date_default_timezone_get(); ?></p>
        </div>
        
        <div class="footer">
            <p>Site criado automaticamente pelo <strong>php-multi.sh</strong></p>
            <p>Pronto para desenvolvimento! 🎉</p>
        </div>
    </div>
</body>
</html>
EOF

    # Configurar permissões
    chown -R www-data:www-data "$site_path"
    chmod -R 755 "$site_path"

    log "Estrutura PHP criada com sucesso!"
}

# Função para criar novo site
create_site() {
    local site_name=$1
    local domain=${2:-"localhost"}
    
    # Gerar porta automática
    local port=$(find_available_port)
    if [ -z "$port" ]; then
        error "Não foi possível encontrar uma porta disponível entre 8001-9000"
    fi
    
    check_root
    
    log "Criando novo site PHP: $site_name"
    
    # Criar diretório de sites se não existir
    mkdir -p "$WEB_ROOT"
    chown www-data:www-data "$WEB_ROOT"
    chmod 755 "$WEB_ROOT"
    
    # Verificar se o site já existe
    if [ -d "$WEB_ROOT/$site_name" ]; then
        error "Site $site_name já existe!"
    fi
    
    # Criar diretório do site
    log "Criando diretório do site em: $WEB_ROOT/$site_name"
    mkdir -p "$WEB_ROOT/$site_name"
    
    # Configurar permissões
    log "Configurando permissões..."
    chown -R www-data:www-data "$WEB_ROOT/$site_name"
    chmod -R 755 "$WEB_ROOT/$site_name"
    
    # Criar estrutura PHP
    create_php_structure "$site_name" "$port"
    
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

    # Deny access to config files
    location ~ /config/ {
        deny all;
    }

    # Deny access to logs
    location ~ /logs/ {
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
    
    # Criar arquivo de informações
    log "Criando arquivo de informações..."
    cat > "$INFO_DIR/$site_name-info.txt" << EOF
INFORMAÇÕES DO SITE PHP: $site_name
=====================================

DATA DE CRIAÇÃO: $(date '+%Y-%m-%d %H:%M:%S')
TECNOLOGIA: PHP Puro
SERVIDOR: Nginx + PHP-FPM

URL DO SITE:
- Principal: http://localhost:$port

ESTRUTURA DE DIRETÓRIOS:
- Document Root: $WEB_ROOT/$site_name
- Arquivo Principal: $WEB_ROOT/$site_name/index.php

CONFIGURAÇÕES NGINX:
- Arquivo: /etc/nginx/sites-available/$site_name
- Porta: $port
- Status: Ativo

LOGS:
- Nginx Access: /var/log/nginx/$site_name-access.log
- Nginx Error: /var/log/nginx/$site_name-error.log

COMANDOS ÚTEIS:
- Editar index: nano $WEB_ROOT/$site_name/index.php
- Ver status: sudo systemctl status nginx
- Ver logs Nginx: tail -f /var/log/nginx/$site_name-error.log

TECNOLOGIAS UTILIZADAS:
- PHP 8.1
- Nginx
- PHP-FPM
- Ubuntu/Debian

NOTAS:
- Site criado automaticamente pelo php-multi.sh
- Estrutura simplificada com apenas index.php
- Pronto para desenvolvimento PHP puro
- Configurações de segurança aplicadas
EOF
    
    log "Site PHP '$site_name' criado com sucesso!"
    log "URL: http://localhost:$port"
    log "Document root: $WEB_ROOT/$site_name"
    log "Informações salvas em: $INFO_DIR/$site_name-info.txt"
}

# Função para deletar site
delete_site() {
    local site_name=$1
    
    check_root
    
    log "Deletando site PHP: $site_name"
    
    # Confirmar exclusão (pular se AUTO_CONFIRM=1)
    if [ "$AUTO_CONFIRM" != "1" ]; then
        echo -n "Tem certeza que deseja deletar o site '$site_name'? (y/N): "
        read -r confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log "Operação cancelada."
            exit 0
        fi
    else
        log "Confirmação automática ativada"
    fi
    
    # Verificar se o site existe
    if [ ! -d "$WEB_ROOT/$site_name" ]; then
        error "Site '$site_name' não encontrado!"
    fi
    
    # Desabilitar site no Nginx
    log "Desabilitando site no Nginx..."
    rm -f "$NGINX_SITES_ENABLED/$site_name"
    
    # Remover configuração Nginx
    log "Removendo configuração Nginx..."
    rm -f "$NGINX_SITES_AVAILABLE/$site_name"
    
    # Remover diretório do site
    log "Removendo arquivos do site..."
    rm -rf "$WEB_ROOT/$site_name"
    
    # Remover arquivo de informações
    rm -f "$INFO_DIR/$site_name-info.txt"
    
    # Recarregar Nginx
    nginx -t
    systemctl reload nginx
    
    log "Site PHP '$site_name' deletado com sucesso!"
}

# Função para listar sites
list_sites() {
    log "Sites PHP instalados:"
    echo ""
    
    if [ ! -d "$WEB_ROOT" ] || [ -z "$(ls -A $WEB_ROOT 2>/dev/null)" ]; then
        echo "Nenhum site encontrado."
        return
    fi
    
    for site_dir in "$WEB_ROOT"/*; do
        if [ -d "$site_dir" ]; then
            local site_name=$(basename "$site_dir")
            local port=$(grep -h "listen" "$NGINX_SITES_AVAILABLE/$site_name" 2>/dev/null | awk '{print $2}' | sed 's/;$//' || echo "80")
            local status="Desabilitado"
            
            if [ -L "$NGINX_SITES_ENABLED/$site_name" ]; then
                status="Ativo"
            fi
            
            echo -e "  ${BLUE}$site_name${NC} - localhost:$port [$status]"
        fi
    done
}

# Função para habilitar site
enable_site() {
    local site_name=$1
    
    check_root
    
    log "Habilitando site PHP: $site_name"
    
    if [ ! -f "$NGINX_SITES_AVAILABLE/$site_name" ]; then
        error "Configuração do site '$site_name' não encontrada!"
    fi
    
    ln -sf "$NGINX_SITES_AVAILABLE/$site_name" "$NGINX_SITES_ENABLED/"
    nginx -t
    systemctl reload nginx
    
    log "Site PHP '$site_name' habilitado com sucesso!"
}

# Função para desabilitar site
disable_site() {
    local site_name=$1
    
    check_root
    
    log "Desabilitando site PHP: $site_name"
    
    rm -f "$NGINX_SITES_ENABLED/$site_name"
    nginx -t
    systemctl reload nginx
    
    log "Site PHP '$site_name' desabilitado com sucesso!"
}

# Função para ver logs
show_logs() {
    local site_name=$1
    
    if [ -z "$site_name" ]; then
        error "Nome do site é obrigatório"
    fi
    
    log "Logs do site PHP: $site_name"
    echo ""
    
    # Logs do Nginx
    if [ -f "/var/log/nginx/$site_name-error.log" ]; then
        echo -e "${BLUE}=== LOGS DE ERRO DO NGINX ===${NC}"
        tail -20 "/var/log/nginx/$site_name-error.log"
        echo ""
    fi
    
    if [ -f "/var/log/nginx/$site_name-access.log" ]; then
        echo -e "${BLUE}=== LOGS DE ACESSO DO NGINX ===${NC}"
        tail -20 "/var/log/nginx/$site_name-access.log"
        echo ""
    fi
    
    # Logs do PHP
    if [ -f "$WEB_ROOT/$site_name/logs/error.log" ]; then
        echo -e "${BLUE}=== LOGS DE ERRO DO PHP ===${NC}"
        tail -20 "$WEB_ROOT/$site_name/logs/error.log"
        echo ""
    fi
    
    if [ -f "$WEB_ROOT/$site_name/logs/app.log" ]; then
        echo -e "${BLUE}=== LOGS DA APLICAÇÃO ===${NC}"
        tail -20 "$WEB_ROOT/$site_name/logs/app.log"
        echo ""
    fi
}

# Função para fazer backup
backup_site() {
    local site_name=$1
    
    check_root
    
    log "Fazendo backup do site PHP: $site_name"
    
    if [ ! -d "$WEB_ROOT/$site_name" ]; then
        error "Site '$site_name' não encontrado!"
    fi
    
    local backup_dir="/opt/webhost/backups"
    mkdir -p "$backup_dir"
    
    local backup_file="$backup_dir/${site_name}_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    cd "$WEB_ROOT"
    tar -czf "$backup_file" "$site_name"
    
    log "Backup criado: $backup_file"
}

# Função para restaurar backup
restore_site() {
    local site_name=$1
    local backup_file=$2
    
    check_root
    
    if [ -z "$backup_file" ]; then
        error "Arquivo de backup é obrigatório"
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Arquivo de backup não encontrado: $backup_file"
    fi
    
    log "Restaurando site PHP: $site_name"
    
    # Remover site existente se houver
    if [ -d "$WEB_ROOT/$site_name" ]; then
        log "Removendo site existente..."
        rm -rf "$WEB_ROOT/$site_name"
    fi
    
    # Extrair backup
    cd "$WEB_ROOT"
    tar -xzf "$backup_file"
    
    # Reconfigurar Nginx se necessário
    if [ ! -f "$NGINX_SITES_AVAILABLE/$site_name" ]; then
        warn "Configuração Nginx não encontrada. Recrie o site."
    fi
    
    log "Site PHP '$site_name' restaurado com sucesso!"
}

# Função principal
main() {
    # Verificar permissões
    check_permissions
    
    # Verificar argumentos
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    local command=$1
    shift
    
    case $command in
        "create")
            if [ -z "$1" ]; then
                error "Nome do site é obrigatório"
            fi
            create_site "$1" "$2"
            ;;
        "delete")
            if [ -z "$1" ]; then
                error "Nome do site é obrigatório"
            fi
            delete_site "$1"
            ;;
        "list")
            list_sites
            ;;
        "enable")
            if [ -z "$1" ]; then
                error "Nome do site é obrigatório"
            fi
            enable_site "$1"
            ;;
        "disable")
            if [ -z "$1" ]; then
                error "Nome do site é obrigatório"
            fi
            disable_site "$1"
            ;;
        "logs")
            show_logs "$1"
            ;;
        "backup")
            if [ -z "$1" ]; then
                error "Nome do site é obrigatório"
            fi
            backup_site "$1"
            ;;
        "restore")
            if [ -z "$1" ] || [ -z "$2" ]; then
                error "Nome do site e arquivo de backup são obrigatórios"
            fi
            restore_site "$1" "$2"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Comando desconhecido: $command. Use 'help' para ver comandos disponíveis."
            ;;
    esac
}

# Executar função principal
main "$@" 