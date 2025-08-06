#!/bin/bash

# Script para gerenciar múltiplos sites HTML locais
# Desenvolvido para Ubuntu/Debian

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
WEB_ROOT="/opt/webhost/sites/html"
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"
INFO_DIR="/opt/webhost/site-info"

# Funções de log
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERRO: $1${NC}" >&2
    exit 1
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
Uso: $0 [COMANDO] [OPÇÕES]

COMANDOS:
  create <nome> [domínio]    Criar novo site HTML
  delete <nome>              Deletar site HTML
  list                       Listar sites HTML
  enable <nome>              Habilitar site
  disable <nome>             Desabilitar site
  backup <nome>              Fazer backup do site
  restore <nome> <arquivo>   Restaurar site de backup

EXEMPLOS:
  $0 create meu-site
  $0 create meu-site localhost
  $0 delete meu-site
  $0 list

EOF
}

# Função para verificar se é root
check_root() {
    if [ "$EUID" -ne 0 ] && [ "$AUTO_CONFIRM" != "1" ]; then
        error "Este script deve ser executado como root"
    fi
}

# Função para verificar e configurar permissões
check_permissions() {
    log "Verificando permissões do diretório /opt/webhost..."
    
    # Verificar se o diretório existe
    if [ ! -d "/opt/webhost" ]; then
        error "Diretório /opt/webhost não encontrado. Execute o script setup-ambiente-dev.sh primeiro."
    fi
    
    # Verificar se o usuário atual está no grupo sudo
    if ! groups | grep -q sudo; then
        warn "Usuário atual não está no grupo sudo. Adicionando..."
        usermod -a -G sudo "$(whoami)"
    fi
    
    log "Permissões verificadas e configuradas."
}

# Função para encontrar porta disponível
find_available_port() {
    local port=9001
    while [ $port -le 10000 ]; do
        # Verificar se a porta não está em uso E não está configurada no Apache
        if ! ss -tuln | grep -q ":$port " && ! grep -q "Listen $port" /etc/apache2/ports.conf; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    return 1
}

# Função para criar estrutura HTML básica
create_html_structure() {
    local site_name=$1
    local port=$2
    local site_path="$WEB_ROOT/$site_name"

    log "Criando estrutura HTML para: $site_name"

    # Criar index.html principal na raiz
    cat > "$site_path/index.html" << EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$site_name - Site HTML</title>
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
        
        .html-info {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 1rem;
            border-radius: 5px;
            margin: 1rem 0;
        }
        
        .html-info h3 {
            color: #856404;
            margin-bottom: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1>$site_name</h1>
        <p class="subtitle">Site HTML funcionando perfeitamente!</p>
        
        <div class="status">
            ✅ Site HTML ativo e operacional
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>URL do Site</h3>
                <p>http://localhost:$port</p>
            </div>
            <div class="info-card">
                <h3>Data de Criação</h3>
                <p>$(date '+%Y-%m-%d %H:%M:%S')</p>
            </div>
            <div class="info-card">
                <h3>Tecnologia</h3>
                <p>HTML5 + CSS3</p>
            </div>
            <div class="info-card">
                <h3>Servidor Web</h3>
                <p>Apache</p>
            </div>
        </div>
        
        <div class="tech-stack">
            <h3>Stack Tecnológica</h3>
            <ul class="tech-list">
                <li class="tech-item">HTML5</li>
                <li class="tech-item">CSS3</li>
                <li class="tech-item">Apache</li>
                <li class="tech-item">Ubuntu/Debian</li>
            </ul>
        </div>
        
        <div class="html-info">
            <h3>Informações do Site</h3>
            <p><strong>Tipo:</strong> Site HTML Estático</p>
            <p><strong>Processamento:</strong> Client-side</p>
            <p><strong>Performance:</strong> Alta velocidade</p>
            <p><strong>SEO:</strong> Otimizado</p>
        </div>
        
        <div class="footer">
            <p>Site criado automaticamente pelo <strong>html-multi.sh</strong></p>
            <p>Pronto para desenvolvimento! 🎉</p>
        </div>
    </div>
</body>
</html>
EOF

    # Configurar permissões
    chown -R www-data:sudo "$site_path"
    chmod -R 775 "$site_path"

    log "Estrutura HTML criada com sucesso!"
}

# Função para criar site
create_site() {
    local site_name=$1
    local domain=${2:-"localhost"}
    
    check_root
    check_permissions
    
    log "Criando novo site HTML: $site_name"
    
    # Validar nome do site
    if [[ ! $site_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Nome do site deve conter apenas letras, números, hífens e underscores"
    fi
    
    # Verificar se o site já existe
    if [ -d "$WEB_ROOT/$site_name" ]; then
        error "Site '$site_name' já existe"
    fi
    
    # Encontrar porta disponível
    local port=$(find_available_port)
    if [ -z "$port" ]; then
        error "Nenhuma porta disponível encontrada"
    fi
    
    log "Criando diretório do site em: $WEB_ROOT/$site_name"
    mkdir -p "$WEB_ROOT/$site_name"
    
    log "Configurando permissões..."
    chown -R :sudo "$WEB_ROOT/$site_name"
    chmod -R 775 "$WEB_ROOT/$site_name"
    
    # Criar estrutura HTML
    create_html_structure "$site_name" "$port"
    
    # Configurar Apache
    log "Configurando Apache..."
    cat > "$APACHE_SITES_AVAILABLE/$site_name.conf" << EOF
<VirtualHost *:$port>
    ServerName localhost
    ServerAdmin webmaster@localhost
    
    DocumentRoot $WEB_ROOT/$site_name
    DirectoryIndex index.html index.htm
    
    # Logs
    ErrorLog \${APACHE_LOG_DIR}/$site_name-error.log
    CustomLog \${APACHE_LOG_DIR}/$site_name-access.log combined
    
    # Diretório raiz do site
    <Directory $WEB_ROOT/$site_name>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Headers de segurança
        <IfModule mod_headers.c>
            Header always set X-Frame-Options "SAMEORIGIN"
            Header always set X-XSS-Protection "1; mode=block"
            Header always set X-Content-Type-Options "nosniff"
            Header always set Referrer-Policy "no-referrer-when-downgrade"
            Header always set Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'"
        </IfModule>
    </Directory>
    
    # Configurações de segurança
    <Files .htaccess>
        Require all denied
    </Files>
    
    <DirectoryMatch "^/.*/\.git/">
        Require all denied
    </DirectoryMatch>
    
    # Compressão
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/plain
        AddOutputFilterByType DEFLATE text/html
        AddOutputFilterByType DEFLATE text/xml
        AddOutputFilterByType DEFLATE text/css
        AddOutputFilterByType DEFLATE application/xml
        AddOutputFilterByType DEFLATE application/xhtml+xml
        AddOutputFilterByType DEFLATE application/rss+xml
        AddOutputFilterByType DEFLATE application/javascript
        AddOutputFilterByType DEFLATE application/x-javascript
        AddOutputFilterByType DEFLATE application/json
        AddOutputFilterByType DEFLATE application/atom+xml
        AddOutputFilterByType DEFLATE image/svg+xml
    </IfModule>
    
    # Cache para arquivos estáticos
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType text/css "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
        ExpiresByType application/x-javascript "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/ico "access plus 1 year"
        ExpiresByType image/icon "access plus 1 year"
        ExpiresByType text/plain "access plus 1 month"
        ExpiresByType application/pdf "access plus 1 month"
        ExpiresByType application/x-shockwave-flash "access plus 1 month"
        ExpiresByType image/x-icon "access plus 1 year"
        ExpiresDefault "access plus 2 days"
    </IfModule>
    
    # Configuração principal
    <Location />
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ /index.html [QSA,L]
    </Location>
</VirtualHost>
EOF

    # Configurar porta no Apache se não existir
    if ! grep -q "Listen $port" /etc/apache2/ports.conf; then
        log "Adicionando porta $port ao Apache..."
        echo "Listen $port" >> /etc/apache2/ports.conf
    fi
    
    # Habilitar site
    a2ensite "$site_name"
    
    # Testar e recarregar Apache
    apache2ctl configtest
    systemctl reload apache2
    
    # Criar arquivo de informações
    log "Criando arquivo de informações..."
    cat > "$INFO_DIR/$site_name-info.txt" << EOF
INFORMAÇÕES DO SITE HTML: $site_name
=====================================

DATA DE CRIAÇÃO: $(date '+%Y-%m-%d %H:%M:%S')
TECNOLOGIA: HTML Puro
SERVIDOR: Apache

URL DO SITE:
- Principal: http://localhost:$port

ESTRUTURA DE DIRETÓRIOS:
- Document Root: $WEB_ROOT/$site_name
- Arquivo Principal: $WEB_ROOT/$site_name/index.html

CONFIGURAÇÕES APACHE:
- Arquivo: /etc/apache2/sites-available/$site_name.conf
- Porta: $port
- Status: Ativo

LOGS:
- Apache Access: /var/log/apache2/$site_name-access.log
- Apache Error: /var/log/apache2/$site_name-error.log

COMANDOS ÚTEIS:
- Editar index: nano $WEB_ROOT/$site_name/index.html
- Ver status: sudo systemctl status apache2
- Ver logs Apache: tail -f /var/log/apache2/$site_name-error.log

TECNOLOGIAS UTILIZADAS:
- HTML5
- CSS3
- Apache
- Ubuntu/Debian

NOTAS:
- Site criado automaticamente pelo html-multi.sh
- Estrutura simplificada com apenas index.html
- Pronto para desenvolvimento HTML puro
- Configurações de segurança aplicadas
EOF

    log "Site HTML '$site_name' criado com sucesso!"
    log "URL: http://localhost:$port"
    log "Document root: $WEB_ROOT/$site_name"
    log "Informações salvas em: $INFO_DIR/$site_name-info.txt"
}

# Função para deletar site
delete_site() {
    local site_name=$1
    
    check_root
    
    log "Deletando site HTML: $site_name"
    
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
    
    # Obter a porta do site ANTES de remover a configuração
    local port=$(grep -h "VirtualHost \*:" "$APACHE_SITES_AVAILABLE/$site_name.conf" 2>/dev/null | awk '{print $2}' | sed 's/[:>*]//g' || echo "")
    
    # Desabilitar site no Apache
    log "Desabilitando site no Apache..."
    a2dissite "$site_name" 2>/dev/null || true
    
    # Remover configuração Apache
    log "Removendo configuração Apache..."
    rm -f "$APACHE_SITES_AVAILABLE/$site_name.conf"
    
    # Remover diretório do site
    log "Removendo arquivos do site..."
    rm -rf "$WEB_ROOT/$site_name"
    
    # Remover arquivo de informações
    rm -f "$INFO_DIR/$site_name-info.txt"
    
    # Remover a porta do ports.conf se existir e não for 80 ou 443
    if [ -n "$port" ] && [ "$port" != "80" ] && [ "$port" != "443" ]; then
        log "Removendo porta $port do ports.conf..."
        sed -i "/^Listen $port$/d" /etc/apache2/ports.conf
    fi
    
    # Recarregar Apache
    apache2ctl configtest
    systemctl reload apache2
    
    log "Site HTML '$site_name' deletado com sucesso!"
}

# Função para listar sites
list_sites() {
    log "Sites HTML instalados:"
    echo ""
    
    if [ ! -d "$WEB_ROOT" ] || [ -z "$(ls -A $WEB_ROOT 2>/dev/null)" ]; then
        echo "Nenhum site encontrado."
        return
    fi
    
    for site_dir in "$WEB_ROOT"/*; do
        if [ -d "$site_dir" ]; then
            local site_name=$(basename "$site_dir")
            local port=$(grep -h "VirtualHost \*:" "$APACHE_SITES_AVAILABLE/$site_name.conf" 2>/dev/null | awk '{print $2}' | sed 's/:$//' || echo "80")
            local status="Desabilitado"
            
            if [ -f "$APACHE_SITES_ENABLED/$site_name.conf" ]; then
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
    
    log "Habilitando site HTML: $site_name"
    
    if [ ! -f "$APACHE_SITES_AVAILABLE/$site_name.conf" ]; then
        error "Configuração do site '$site_name' não encontrada!"
    fi
    
    a2ensite "$site_name"
    apache2ctl configtest
    systemctl reload apache2
    
    log "Site HTML '$site_name' habilitado com sucesso!"
}

# Função para desabilitar site
disable_site() {
    local site_name=$1
    
    check_root
    
    log "Desabilitando site HTML: $site_name"
    
    a2dissite "$site_name"
    apache2ctl configtest
    systemctl reload apache2
    
    log "Site HTML '$site_name' desabilitado com sucesso!"
}

# Função principal
main() {
    case "${1:-}" in
        create)
            if [ -z "${2:-}" ]; then
                error "Nome do site é obrigatório"
            fi
            create_site "$2" "${3:-}"
            ;;
        delete)
            if [ -z "${2:-}" ]; then
                error "Nome do site é obrigatório"
            fi
            delete_site "$2"
            ;;
        list)
            list_sites
            ;;
        enable)
            if [ -z "${2:-}" ]; then
                error "Nome do site é obrigatório"
            fi
            enable_site "$2"
            ;;
        disable)
            if [ -z "${2:-}" ]; then
                error "Nome do site é obrigatório"
            fi
            disable_site "$2"
            ;;
        backup)
            if [ -z "${2:-}" ]; then
                error "Nome do site é obrigatório"
            fi
            warn "Funcionalidade de backup ainda não implementada"
            ;;
        restore)
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                error "Nome do site e arquivo de backup são obrigatórios"
            fi
            warn "Funcionalidade de restore ainda não implementada"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@" 