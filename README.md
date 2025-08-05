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

### 3. Configuração de Permissões

O script de instalação configura automaticamente as permissões corretas:

- **Grupo proprietário:** `sudo` (permite acesso a todos os usuários com sudo)
- **Permissões:** `775` (leitura, escrita e execução para proprietário e grupo)
- **Herança de grupo:** Ativada (novos arquivos herdam o grupo sudo)
- **Usuário atual:** Adicionado automaticamente aos grupos `sudo` e `www-data`

**Importante:** Após a instalação, faça logout e login novamente para que as mudanças de grupo tenham efeito.

## 📖 Como Usar

### Script Principal (`setup-wordpress-dev.sh`)

Este script configura o ambiente base com um site WordPress padrão.

**Execução:**
```bash
sudo ./scripts/setup-wordpress-dev.sh
```

**Após a execução:**
1. Acesse `http://localhost` no navegador para o dashboard
2. Para sites WordPress individuais, use as URLs específicas
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



### Dashboard Web

Este projeto inclui um dashboard web moderno para gerenciar sites WordPress locais.

**Configuração Automática:**
O dashboard é configurado automaticamente durante a instalação do ambiente WordPress.

**Acesso:**
- **URL:** http://localhost
- **Funcionalidades:**
  - Monitoramento de recursos do sistema
  - Criação e gerenciamento de sites
  - Visualização de logs
  - Interface moderna e responsiva

## 🔧 Configurações Padrão

### Credenciais MySQL Root
- **Usuário:** root
- **Senha:** root123

### Estrutura de Diretórios
- **Web Root (setup-wordpress-dev.sh):** `/var/www/html`
- **Sites (wp-multi.sh):** `/opt/webhost/sites/`
- **Informações dos sites:** `/opt/webhost/site-info/`
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
/opt/webhost/
├── scripts/
│   ├── setup-wordpress-dev.sh    # Script principal de instalação
│   ├── wp-multi.sh              # Script de gerenciamento de múltiplos sites
│   ├── check-status.sh          # Script de verificação de status
│   └── cleanup-wordpress.sh     # Script de limpeza completa
├── dashboard/                    # Dashboard web para gerenciamento
│   ├── index.php                # Interface principal
│   ├── api/                     # APIs do dashboard
│   ├── assets/                  # CSS, JS e recursos
│   └── nginx-config            # Configuração Nginx
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

**2. Problemas de permissão no /opt/webhost:**
```bash
# Verificar permissões atuais
ls -la /opt/webhost

# Corrigir permissões manualmente
sudo chown -R :sudo /opt/webhost
sudo chmod -R 775 /opt/webhost
sudo chmod g+s /opt/webhost

# Adicionar usuário ao grupo sudo
sudo usermod -a -G sudo $USER
sudo usermod -a -G www-data $USER

# Verificar grupos do usuário
groups $USER
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
cat /opt/webhost/site-info/teste-info.txt
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

## 🎛️ Dashboard

O dashboard está disponível em `http://localhost` e oferece uma interface web para gerenciar seus sites WordPress.

### Funcionalidades do Dashboard
- **Criar sites WordPress** com domínio personalizado
- **Deletar sites** com confirmação automática
- **Visualizar informações** dos sites criados
- **Interface intuitiva** para gerenciamento

### Permissões do Dashboard

O usuário `www-data` tem permissões especiais configuradas em `/etc/sudoers.d/www-data`:

```
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/wp-multi.sh
```

Isso permite que o dashboard execute comandos administrativos sem solicitar senha, incluindo a definição da variável de ambiente `AUTO_CONFIRM` para confirmação automática de operações.

## ⚙️ Automação WordPress

### Como Funciona a Automação

O projeto utiliza **automação WordPress nativa** implementada diretamente no script `wp-multi.sh`, **sem dependência do WP-CLI externo**:

#### 🔧 **Processo de Instalação Automática**

1. **Download e Configuração**:
   - Baixa WordPress em português brasileiro automaticamente
   - Configura `wp-config.php` com credenciais do banco
   - Define configurações personalizadas (timezone, idioma, etc.)

2. **Instalação via PHP Nativo**:
   ```php
   // Carrega WordPress diretamente
   require_once('wp-load.php');
   require_once('wp-admin/includes/upgrade.php');
   
   // Usa função nativa do WordPress
   $result = wp_install($site_name, $admin_user, $admin_email, ...);
   ```

3. **Personalização Automática**:
   - ✅ Remove posts padrão ("Hello World", "Olá, mundo!")
   - ✅ Remove páginas de exemplo
   - ✅ Oculta painel de boas-vindas
   - ✅ Configura timezone brasileiro (`America/Sao_Paulo`)
   - ✅ Define formato de data brasileiro (`d/m/Y`)
   - ✅ Configura permalinks amigáveis (`/%postname%/`)
   - ✅ Cria página inicial personalizada
   - ✅ Define idioma português (`pt_BR`)

#### 🎯 **Vantagens da Automação Nativa**

- **✅ Sem dependências externas** - Não precisa instalar WP-CLI
- **✅ Mais rápido** - Execução direta via PHP
- **✅ Mais confiável** - Usa funções nativas do WordPress
- **✅ Totalmente personalizada** - Configurações específicas do projeto
- **✅ Controle total** - Pode adicionar qualquer customização

#### 📋 **Diferença do WP-CLI**

| Aspecto | Automação Nativa | WP-CLI |
|---------|------------------|--------|
| **Dependência** | Nenhuma | Requer instalação |
| **Velocidade** | Mais rápido | Mais lento |
| **Personalização** | Total | Limitada |
| **Manutenção** | Menor | Maior |
| **Uso** | Automático | Manual |

**Nota**: O WP-CLI seria útil apenas para gerenciamento manual via linha de comando, mas para automação de criação de sites, a implementação nativa é superior.

## 🔧 Troubleshooting

### Problemas Comuns

#### **Dashboard não carrega em localhost**
```bash
# Verificar se o Nginx está rodando
sudo systemctl status nginx

# Verificar configuração do dashboard
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx
```

#### **Erro ao criar/deletar sites via dashboard**
```bash
# Verificar permissões do sudoers
sudo cat /etc/sudoers.d/www-data

# Verificar se www-data está no grupo correto
groups www-data

# Verificar logs do Nginx
sudo tail -f /var/log/nginx/error.log
```

#### **Sites com portas duplicadas**
```bash
# Verificar portas em uso
ss -tuln | grep :900

# Verificar configurações do Nginx
ls -la /etc/nginx/sites-enabled/
```

#### **Permissões insuficientes**
```bash
# Verificar permissões do diretório
ls -la /opt/webhost/

# Corrigir permissões se necessário
sudo chown -R :sudo /opt/webhost
sudo chmod -R 775 /opt/webhost
sudo chmod g+s /opt/webhost
```

### Logs Importantes

- **Nginx**: `/var/log/nginx/error.log`
- **PHP-FPM**: `/var/log/php8.1-fpm.log`
- **MySQL**: `/var/log/mysql/error.log`
- **Scripts**: Saída colorida no terminal

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs de erro
2. Execute `./scripts/wp-multi.sh help` para ver comandos disponíveis
3. Consulte a seção de troubleshooting acima

## 📝 Changelog

### v1.2.0
- ✅ Dashboard web funcional em http://localhost
- ✅ Correção de permissões para deleção de sites via dashboard
- ✅ Configuração automática de sudoers para www-data
- ✅ Suporte a variáveis de ambiente no sudo (SETENV)
- ✅ Confirmação automática para operações via dashboard
- ✅ Script de instalação atualizado com todas as configurações necessárias
- ✅ Automação WordPress nativa (sem dependência do WP-CLI)
- ✅ Criação automática de diretórios do sistema
- ✅ Cópia automática de scripts necessários

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