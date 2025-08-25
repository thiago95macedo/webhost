#!/bin/bash

# Script para configurar projeto automaticamente
# Uso: ./configure-project.sh <project_name> <project_type> <port>

PROJECT_NAME="$1"
PROJECT_TYPE="$2"
PORT="$3"

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_TYPE" ] || [ -z "$PORT" ]; then
    echo "Erro: Parâmetros insuficientes"
    echo "Uso: $0 <project_name> <project_type> <port>"
    exit 1
fi

# Definir diretórios base
case $PROJECT_TYPE in
    "php")
        PROJECT_DIR="/opt/webhost/sites/php/$PROJECT_NAME"
        ;;
    "html")
        PROJECT_DIR="/opt/webhost/sites/html/$PROJECT_NAME"
        ;;
    "wordpress")
        PROJECT_DIR="/opt/webhost/sites/wordpress/$PROJECT_NAME"
        ;;
    *)
        echo "Erro: Tipo de projeto inválido: $PROJECT_TYPE"
        exit 1
        ;;
esac

# Verificar se o diretório existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Erro: Diretório do projeto não encontrado: $PROJECT_DIR"
    exit 1
fi

# Criar configuração Apache
CONFIG_FILE="/etc/apache2/sites-available/$PROJECT_NAME.conf"

# Template base
cat > "$CONFIG_FILE" << EOF
<VirtualHost *:$PORT>
    ServerName localhost
    ServerAdmin webmaster@localhost
    
    DocumentRoot $PROJECT_DIR
    DirectoryIndex index.php index.html
    
    # Logs
    ErrorLog \${APACHE_LOG_DIR}/$PROJECT_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$PROJECT_NAME-access.log combined
    
    # Diretório raiz do site
    <Directory $PROJECT_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Headers de segurança
        <IfModule mod_headers.c>
            Header always set X-Frame-Options "SAMEORIGIN"
            Header always set X-XSS-Protection "1; mode=block"
            Header always set X-Content-Type-Options "nosniff"
            Header always set Referrer-Policy "no-referrer-when-downgrade"
        </IfModule>
    </Directory>
    
    # Configurações de segurança
    <Files .htaccess>
        Require all denied
    </Files>
    
    <DirectoryMatch "^/.*/\.git/">
        Require all denied
    </DirectoryMatch>
    
    <DirectoryMatch "^/.*/config/">
        Require all denied
    </DirectoryMatch>
    
    <DirectoryMatch "^/.*/logs/">
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
EOF

# Adicionar configuração específica por tipo
if [ "$PROJECT_TYPE" = "php" ]; then
    cat >> "$CONFIG_FILE" << EOF
    
    # Configuração PHP
    <Location />
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ /index.php [QSA,L]
    </Location>
EOF
elif [ "$PROJECT_TYPE" = "wordpress" ]; then
    cat >> "$CONFIG_FILE" << EOF
    
    # Configuração WordPress
    <Location />
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.php [L]
    </Location>
EOF
fi

# Fechar o VirtualHost
echo "</VirtualHost>" >> "$CONFIG_FILE"

# Verificar se a porta já está configurada no ports.conf
if ! grep -q "Listen $PORT" /etc/apache2/ports.conf; then
    echo "Listen $PORT" >> /etc/apache2/ports.conf
    echo "Porta $PORT adicionada ao ports.conf"
fi

# Habilitar o site
a2ensite "$PROJECT_NAME.conf"

# Recarregar Apache
systemctl reload apache2

echo "Projeto $PROJECT_NAME configurado com sucesso na porta $PORT"
echo "URL: http://localhost:$PORT"
