# Ambiente WordPress Local - Scripts de Automação

Este projeto contém scripts para automatizar a criação e gerenciamento de ambientes WordPress locais com Nginx e MySQL.

## 📋 Pré-requisitos

- Sistema operacional Ubuntu/Debian
- Acesso root (sudo)
- Conexão com internet
- Mínimo 2GB RAM livre
- 5GB espaço em disco livre

## 🚀 Instalação Inicial

### 1. Configuração do Ambiente Base

Execute o script principal para configurar o ambiente WordPress:

```bash
# Dar permissão de execução
chmod +x scripts/setup-wordpress-dev.sh

# Executar como root
sudo ./scripts/setup-wordpress-dev.sh
```

Este script irá:
- ✅ Instalar e configurar Nginx
- ✅ Instalar e configurar MySQL
- ✅ Instalar PHP 8.1 e extensões necessárias
- ✅ Baixar e configurar WordPress
- ✅ Configurar virtual hosts
- ✅ Criar banco de dados
- ✅ Configurar permissões
- ✅ Configurar firewall
- ✅ Gerar arquivo de informações

### 2. Configuração dos Scripts

```bash
# Dar permissão de execução a todos os scripts
chmod +x scripts/*.sh

# Mover para um local no PATH (opcional)
sudo mv scripts/wp-multi.sh /usr/local/bin/wp-multi
sudo mv scripts/check-status.sh /usr/local/bin/wp-status
```

## 📖 Como Usar

### Script Principal (`setup-wordpress-dev.sh`)

Este script configura o ambiente base com um site WordPress padrão.

**Execução:**
```bash
sudo ./scripts/setup-wordpress-dev.sh
```

**Após a execução:**
1. Acesse `http://localhost` no navegador
2. Complete a instalação do WordPress
3. Configure o título do site e credenciais de administrador

**Nota:** Sites criados com `wp-multi.sh` usam URLs como `http://localhost:9001`, `http://localhost:9002`, etc.

### Script de Múltiplos Sites (`wp-multi.sh`)

Este script permite gerenciar múltiplos sites WordPress locais usando localhost com portas automáticas.

#### Comandos Disponíveis:

**Criar novo site:**
```bash
sudo ./scripts/wp-multi.sh create nome-do-site
```

**Listar sites:**
```bash
sudo ./scripts/wp-multi.sh list
```

**Fazer backup:**
```bash
sudo ./scripts/wp-multi.sh backup nome-do-site
```

**Deletar site:**
```bash
sudo ./scripts/wp-multi.sh delete nome-do-site
```

**Habilitar/Desabilitar site:**
```bash
sudo ./scripts/wp-multi.sh enable nome-do-site
sudo ./scripts/wp-multi.sh disable nome-do-site
```

**Ver logs:**
```bash
sudo ./scripts/wp-multi.sh logs nome-do-site
```

**Ajuda:**
```bash
./scripts/wp-multi.sh help
```

### Script de Verificação de Status (`check-status.sh`)

Este script verifica o status completo do ambiente WordPress local.

**Execução:**
```bash
./scripts/check-status.sh
```

**O que verifica:**
- ✅ Status dos serviços (Nginx, MySQL, PHP-FPM)
- ✅ Portas abertas (80, 3306)
- ✅ Versões dos softwares instalados
- ✅ Sites WordPress ativos
- ✅ Recursos do sistema (CPU, RAM, Disco)
- ✅ Conectividade com internet
- ✅ Logs recentes de erros

## 🔧 Configurações Padrão

### Credenciais MySQL Root
- **Usuário:** root
- **Senha:** root123

### Estrutura de Diretórios
- **Web Root (setup-wordpress-dev.sh):** `/var/www/html`
- **Sites (wp-multi.sh):** `/home/weth/wordpress/sites/`
- **Informações dos sites:** `/home/weth/wordpress/site-info/`
- **Logs Nginx:** `/var/log/nginx/`
- **Backups:** `/root/backups/`

### Configurações Nginx
- **Porta:** 80
- **PHP-FPM:** Unix socket
- **Gzip:** Habilitado
- **Cache:** Configurado para arquivos estáticos
- **Segurança:** Headers de segurança configurados

## 📁 Estrutura de Arquivos

```
/home/weth/wordpress/
├── scripts/
│   ├── setup-wordpress-dev.sh    # Script principal de instalação
│   ├── wp-multi.sh              # Script de gerenciamento de múltiplos sites
│   ├── check-status.sh          # Script de verificação de status
│   └── cleanup-wordpress.sh     # Script de limpeza completa
├── sites/                       # Sites criados pelo wp-multi.sh
├── site-info/                   # Informações dos sites
└── README.md                    # Este arquivo
```

## 🔍 Troubleshooting

### Problemas Comuns

**1. Erro de permissão:**
```bash
sudo chown -R www-data:www-data /var/www/html/nome-do-site
sudo chmod -R 755 /var/www/html/nome-do-site
```

**2. Nginx não inicia:**
```bash
sudo nginx -t
sudo systemctl status nginx
```

**3. MySQL não conecta:**
```bash
sudo systemctl status mysql
sudo mysql -u root -p
```

**4. PHP-FPM não funciona:**
```bash
sudo systemctl status php8.1-fpm
sudo nginx -t
```

### Logs Importantes

- **Nginx Access:** `/var/log/nginx/nome-do-site-access.log`
- **Nginx Error:** `/var/log/nginx/nome-do-site-error.log`
- **PHP-FPM:** `/var/log/php8.1-fpm.log`
- **MySQL:** `/var/log/mysql/error.log`

## 🛠️ Comandos Úteis

### Gerenciamento de Serviços
```bash
# Reiniciar serviços
sudo systemctl restart nginx
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm

# Verificar status
sudo systemctl status nginx mysql php8.1-fpm

# Habilitar no boot
sudo systemctl enable nginx mysql php8.1-fpm
```

### Gerenciamento de Sites
```bash
# Listar todos os sites
sudo ./scripts/wp-multi.sh list

# Criar site de teste
sudo ./scripts/wp-multi.sh create teste

# Fazer backup
sudo ./scripts/wp-multi.sh backup teste

# Ver logs
sudo ./scripts/wp-multi.sh logs teste

# Verificar status do ambiente
./scripts/check-status.sh

# Ver informações do site
cat /home/weth/wordpress/site-info/teste-info.txt
```

### Banco de Dados
```bash
# Acessar MySQL
sudo mysql -u root -p

# Listar bancos
SHOW DATABASES;

# Acessar banco específico
USE nome-do-site_db;
SHOW TABLES;
```

## 🔒 Segurança

### Recomendações
1. **Alterar senhas padrão** após a instalação
2. **Configurar firewall** adequadamente
3. **Manter sistema atualizado**
4. **Fazer backups regulares**
5. **Usar HTTPS** em produção

### Configurações de Segurança Incluídas
- Headers de segurança no Nginx
- Acesso negado a arquivos ocultos
- Proteção do wp-config.php
- Configuração de permissões adequadas
- Chaves de segurança únicas geradas automaticamente
- URLs locais sem necessidade de configuração de DNS

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs de erro
2. Execute `./scripts/wp-multi.sh help` para ver comandos disponíveis
3. Consulte a seção de troubleshooting

## 📝 Changelog

### v1.1.0
- ✅ URLs simplificadas usando localhost com portas automáticas
- ✅ Chaves de segurança únicas geradas automaticamente
- ✅ Arquivos de informações organizados em diretório específico
- ✅ Correção automática de permissões de diretórios
- ✅ Melhor tratamento de erros e logs

### v1.0.0
- ✅ Instalação automatizada do ambiente WordPress
- ✅ Gerenciamento de múltiplos sites
- ✅ Sistema de backup
- ✅ Configurações de segurança
- ✅ Logs coloridos e informativos

## 📄 Licença

Este projeto é de uso livre para fins educacionais e de desenvolvimento.

---

**Desenvolvido para facilitar o desenvolvimento local com WordPress, Nginx e MySQL.** 