#!/bin/bash

# Script para verificar status do ambiente WordPress local

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
}

# Função para verificar status do serviço
check_service() {
    local service=$1
    local name=$2
    
    if systemctl is-active --quiet $service; then
        echo -e "  ${GREEN}✓${NC} $name: ${GREEN}Ativo${NC}"
    else
        echo -e "  ${RED}✗${NC} $name: ${RED}Inativo${NC}"
    fi
}

# Função para verificar porta
check_port() {
    local port=$1
    local service=$2
    
    if netstat -tuln | grep -q ":$port "; then
        echo -e "  ${GREEN}✓${NC} Porta $port ($service): ${GREEN}Aberta${NC}"
    else
        echo -e "  ${RED}✗${NC} Porta $port ($service): ${RED}Fechada${NC}"
    fi
}

# Função para verificar versão
get_version() {
    local command=$1
    local version=$(eval $command 2>/dev/null | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "Não instalado"
    fi
}

# Função para verificar sites WordPress
check_wordpress_sites() {
    local web_root="/var/www/html"
    local multi_sites_root="/opt/webhost/sites"
    
    echo -e "\n${BLUE}=== SITES WORDPRESS ===${NC}"
    
    # Verificar sites do diretório padrão
    if [ -d "$web_root" ] && [ "$(ls -A $web_root 2>/dev/null)" ]; then
        for site_dir in "$web_root"/*; do
            if [ -d "$site_dir" ] && [ -f "$site_dir/wp-config.php" ]; then
                local site_name=$(basename "$site_dir")
                local port=$(grep -h "listen" "/etc/nginx/sites-available/$site_name" 2>/dev/null | awk '{print $2}' | sed 's/;$//' || echo "80")
                local status=""
                
                if [ -L "/etc/nginx/sites-enabled/$site_name" ]; then
                    status="${GREEN}Ativo${NC}"
                else
                    status="${RED}Inativo${NC}"
                fi
                
                echo -e "  ${BLUE}$site_name${NC} - localhost:$port [$status]"
            fi
        done
    fi
    
    # Verificar sites do wp-multi.sh
    if [ -d "$multi_sites_root" ] && [ "$(ls -A $multi_sites_root 2>/dev/null)" ]; then
        for site_dir in "$multi_sites_root"/*; do
            if [ -d "$site_dir" ] && [ -f "$site_dir/wp-config.php" ]; then
                local site_name=$(basename "$site_dir")
                local port=$(grep -h "listen" "/etc/nginx/sites-available/$site_name" 2>/dev/null | awk '{print $2}' | sed 's/;$//' || echo "80")
                local status=""
                
                if [ -L "/etc/nginx/sites-enabled/$site_name" ]; then
                    status="${GREEN}Ativo${NC}"
                else
                    status="${RED}Inativo${NC}"
                fi
                
                echo -e "  ${BLUE}$site_name${NC} - localhost:$port [$status]"
            fi
        done
    fi
    
    # Se nenhum site foi encontrado
    if [ ! -d "$web_root" ] || [ -z "$(ls -A $web_root 2>/dev/null)" ] && [ ! -d "$multi_sites_root" ] || [ -z "$(ls -A $multi_sites_root 2>/dev/null)" ]; then
        echo "  Nenhum site WordPress encontrado"
    fi
}

# Função para verificar recursos do sistema
check_system_resources() {
    echo -e "\n${BLUE}=== RECURSOS DO SISTEMA ===${NC}"
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "  CPU: ${YELLOW}${cpu_usage}%${NC} em uso"
    
    # Memória
    local mem_total=$(free -m | awk 'NR==2{printf "%.1f", $2/1024}')
    local mem_used=$(free -m | awk 'NR==2{printf "%.1f", $3/1024}')
    local mem_percent=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    echo -e "  RAM: ${YELLOW}${mem_used}GB${NC} / ${BLUE}${mem_total}GB${NC} (${YELLOW}${mem_percent}%${NC})"
    
    # Disco
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    local disk_available=$(df -h / | awk 'NR==2{print $4}')
    echo -e "  Disco: ${YELLOW}${disk_usage}%${NC} usado (${BLUE}${disk_available}${NC} livre)"
}

# Função para verificar conectividade
check_connectivity() {
    echo -e "\n${BLUE}=== CONECTIVIDADE ===${NC}"
    
    # Internet
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Internet: ${GREEN}Conectado${NC}"
    else
        echo -e "  ${RED}✗${NC} Internet: ${RED}Desconectado${NC}"
    fi
    
    # WordPress.org
    if curl -s --head https://wordpress.org | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
        echo -e "  ${GREEN}✓${NC} WordPress.org: ${GREEN}Acessível${NC}"
    else
        echo -e "  ${RED}✗${NC} WordPress.org: ${RED}Inacessível${NC}"
    fi
}

# Função para verificar logs recentes
check_recent_logs() {
    echo -e "\n${BLUE}=== LOGS RECENTES ===${NC}"
    
    # Nginx error logs
    if [ -f "/var/log/nginx/error.log" ]; then
        local nginx_errors=$(tail -5 /var/log/nginx/error.log | grep -v "favicon.ico" | wc -l)
        if [ $nginx_errors -gt 0 ]; then
            echo -e "  ${YELLOW}⚠${NC} Nginx: ${YELLOW}$nginx_errors${NC} erros recentes"
        else
            echo -e "  ${GREEN}✓${NC} Nginx: ${GREEN}Sem erros recentes${NC}"
        fi
    fi
    
    # MySQL error logs
    if [ -f "/var/log/mysql/error.log" ]; then
        local mysql_errors=$(tail -5 /var/log/mysql/error.log | grep -i error | wc -l)
        if [ $mysql_errors -gt 0 ]; then
            echo -e "  ${YELLOW}⚠${NC} MySQL: ${YELLOW}$mysql_errors${NC} erros recentes"
        else
            echo -e "  ${GREEN}✓${NC} MySQL: ${GREEN}Sem erros recentes${NC}"
        fi
    fi
}

# Função principal
main() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  VERIFICAÇÃO DO AMBIENTE WORDPRESS${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "Data: $(date)"
    echo -e "Sistema: $(uname -a | cut -d' ' -f1-3)"
    
    # Verificar serviços
    echo -e "\n${BLUE}=== SERVIÇOS ===${NC}"
    check_service "nginx" "Nginx"
    check_service "mysql" "MySQL"
    check_service "php8.1-fpm" "PHP-FPM"
    
    # Verificar portas
    echo -e "\n${BLUE}=== PORTAS ===${NC}"
    check_port "80" "HTTP"
    check_port "3306" "MySQL"
    
    # Verificar versões
    echo -e "\n${BLUE}=== VERSÕES ===${NC}"
    echo -e "  Nginx: $(get_version 'nginx -v 2>&1')"
    echo -e "  MySQL: $(get_version 'mysql --version')"
    echo -e "  PHP: $(get_version 'php -v')"
    
    # Verificar sites WordPress
    check_wordpress_sites
    
    # Verificar recursos do sistema
    check_system_resources
    
    # Verificar conectividade
    check_connectivity
    
    # Verificar logs recentes
    check_recent_logs
    
    echo -e "\n${BLUE}===========================================${NC}"
    echo -e "${BLUE}  VERIFICAÇÃO CONCLUÍDA${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

# Executar função principal
main 