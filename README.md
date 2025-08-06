# 🚀 Ambiente de Desenvolvimento Web Multi-Tecnologia

Um ambiente completo de desenvolvimento web que suporta **WordPress**, **PHP** e **HTML** com dashboard visual integrado.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Instalação](#instalação)
- [Estrutura de Diretórios](#estrutura-de-diretórios)
- [Dashboard](#dashboard)
- [Tipos de Sites](#tipos-de-sites)
- [Automação WordPress](#automação-wordpress)
- [Configuração de Permissões](#configuração-de-permissões)
- [Troubleshooting](#troubleshooting)
- [Changelog](#changelog)

## 🎯 Visão Geral

Este projeto oferece um ambiente de desenvolvimento web completo com:

- **Dashboard visual** para gerenciar todos os sites
- **Suporte multi-tecnologia**: WordPress, PHP e HTML
- **Configuração automática** de Apache e MySQL
- **Sistema de permissões** otimizado
- **Automação nativa** sem dependências externas

## ✨ Funcionalidades

### 🎛️ Dashboard Integrado
- Interface web moderna e responsiva
- Gerenciamento visual de todos os sites
- Criação e exclusão de sites com um clique
- Monitoramento de status em tempo real
- Informações detalhadas de cada site

### 🌐 Suporte Multi-Tecnologia
- **WordPress**: Sites completos com CMS
- **PHP**: Sites com processamento server-side
- **HTML**: Sites estáticos de alta performance

### 🔧 Automação Completa
- Instalação automática do WordPress
- Configuração de banco de dados
- Configuração de Apache
- Atribuição automática de portas
- Gerenciamento de permissões

## 🛠️ Instalação

### Pré-requisitos
- Ubuntu/Debian (ou similar)
- Acesso root/sudo
- Conexão com internet

### Instalação Automática
```bash
# Clone o repositório
git clone <repository-url>
cd webhost

# Execute o script de instalação
sudo bash scripts/setup-ambiente-dev.sh
```

O script irá:
- Instalar todas as dependências
- Configurar Apache, MySQL e PHP
- Criar estrutura de diretórios
- Configurar permissões
- Instalar o dashboard
- Configurar sudoers para automação

## 📁 Estrutura de Diretórios

```
/opt/webhost/
├── dashboard/                 # Interface web do dashboard
│   ├── api/                  # APIs para gerenciamento
│   ├── assets/               # CSS, JS e imagens
│   └── index.php             # Página principal
├── sites/
│   ├── wordpress/            # Sites WordPress
│   ├── php/                  # Sites PHP
│   └── html/                 # Sites HTML
├── site-info/                # Informações dos sites
├── scripts/                  # Scripts de gerenciamento
│   ├── setup-ambiente-dev.sh # Instalação do ambiente
│   ├── cleanup-ambiente-dev.sh # Limpeza do ambiente
│   ├── wp-multi.sh          # Gerenciamento WordPress
│   ├── php-multi.sh         # Gerenciamento PHP
│   ├── html-multi.sh        # Gerenciamento HTML
│   └── check-status.sh      # Verificação de status
└── logs/                     # Logs do sistema
```

## 🎛️ Dashboard

### Acesso
- **URL**: `http://localhost`
- **Porta padrão**: 80

### Funcionalidades
- **Visão geral do sistema**: Status, recursos, logs
- **Gerenciamento de sites**: Criar, deletar, visualizar
- **Monitoramento**: Status em tempo real
- **Logs**: Visualização de logs do sistema
- **Backup**: Backup automático de sites

### Permissões
O dashboard executa com permissões `www-data` e tem acesso sudo para:
- Executar scripts de criação/deleção
- Gerenciar arquivos dos sites
- Configurar Apache
- Operações de banco de dados

## 🌐 Tipos de Sites

### 1. Sites WordPress
- **Tecnologia**: WordPress completo
- **Cor**: Verde (`btn-success`)
- **Portas**: 9001-10000
- **Estrutura**: WordPress completo com banco de dados
- **Admin**: `/wp-admin` com credenciais automáticas

**Criação via Dashboard:**
- Nome do site
- Domínio (opcional, padrão: localhost)
- Instalação automática do WordPress
- Criação de banco de dados
- Configuração de admin

### 2. Sites PHP
- **Tecnologia**: PHP puro
- **Cor**: Azul (`btn-primary`)
- **Portas**: 9001-10000
- **Estrutura**: Apenas `index.php` na raiz
- **Performance**: Alta velocidade

**Criação via Dashboard:**
- Nome do site
- Domínio (opcional, padrão: localhost)
- Template PHP básico
- Configuração Apache otimizada

### 3. Sites HTML
- **Tecnologia**: HTML5 estático
- **Cor**: Laranja (`btn-warning`)
- **Portas**: 9001-10000
- **Estrutura**: Apenas `index.html` na raiz
- **Performance**: Máxima velocidade

**Criação via Dashboard:**
- Nome do site
- Domínio (opcional, padrão: localhost)
- Template HTML5 básico
- Configuração Apache para arquivos estáticos

## ⚙️ Automação WordPress

### Abordagem Nativa
O sistema usa **automação nativa PHP** em vez de WP-CLI:

**Vantagens:**
- ✅ Sem dependências externas
- ✅ Instalação mais rápida
- ✅ Menos pontos de falha
- ✅ Controle total do processo

**Como funciona:**
1. Criação de banco de dados MySQL
2. Download do WordPress
3. Configuração via funções PHP nativas
4. Instalação automática
5. Configuração de admin

### Comparação com WP-CLI

| Aspecto | Automação Nativa | WP-CLI |
|---------|------------------|--------|
| Dependências | Nenhuma | WP-CLI instalado |
| Velocidade | Mais rápida | Mais lenta |
| Confiabilidade | Alta | Média |
| Controle | Total | Limitado |

## 🔐 Configuração de Permissões

### Estrutura de Permissões
```bash
# Diretório principal
chown -R :sudo /opt/webhost
chmod -R 775 /opt/webhost
chmod g+s /opt/webhost

# Usuário do sistema
usermod -a -G sudo,www-data $CURRENT_USER
```

### Sudoers Configuration
```bash
# /etc/sudoers.d/www-data
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/wp-multi.sh
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/php-multi.sh
www-data ALL=(ALL) NOPASSWD: SETENV: /opt/webhost/scripts/html-multi.sh
www-data ALL=(ALL) NOPASSWD: mysql, mysqldump, apache2ctl, systemctl reload apache2, systemctl restart apache2
```

### Benefícios
- ✅ Acesso compartilhado entre usuários
- ✅ Herança automática de grupo
- ✅ Execução segura via dashboard
- ✅ Sem prompts de senha

## 🔧 Troubleshooting

### Problemas Comuns

#### Dashboard não carrega
```bash
# Verificar Apache
sudo systemctl status apache2
sudo apache2ctl configtest

# Verificar permissões
ls -la /opt/webhost/dashboard/
```

#### Erro ao criar/deletar sites
```bash
# Verificar sudoers
sudo cat /etc/sudoers.d/www-data

# Verificar permissões
ls -la /opt/webhost/scripts/
```

#### Portas duplicadas
```bash
# Verificar portas em uso
ss -tuln | grep :900

# Verificar configurações Apache
ls -la /etc/apache2/sites-enabled/
```

#### Problemas de permissão
```bash
# Recriar permissões
sudo chown -R :sudo /opt/webhost
sudo chmod -R 775 /opt/webhost
sudo chmod g+s /opt/webhost
```

### Logs Importantes
```bash
# Apache
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log

# Sistema
sudo journalctl -u apache2 -f
sudo journalctl -u mysql -f
```

### Comandos Úteis
```bash
# Verificar status do ambiente
sudo ./scripts/check-status.sh

# Limpar ambiente completamente
sudo ./scripts/cleanup-ambiente-dev.sh

# Reinstalar ambiente
sudo ./scripts/setup-ambiente-dev.sh
```

## 🚀 Vantagens da Migração para Apache

### 🔧 Flexibilidade para Desenvolvedores
- **Arquivos .htaccess**: Cada site pode ter suas próprias configurações
- **Controle granular**: Configurações específicas por diretório
- **Facilidade de configuração**: Sintaxe mais intuitiva para desenvolvedores
- **Compatibilidade**: Maior compatibilidade com frameworks e CMS

### 🛡️ Segurança e Performance
- **Headers de segurança**: Configuração automática via mod_headers
- **Compressão**: Otimização automática via mod_deflate
- **Cache**: Configuração inteligente de cache via mod_expires
- **Controle de acesso**: Configurações granulares de permissões

### 🔄 Gerenciamento Simplificado
- **Comandos padrão**: a2ensite, a2dissite, apache2ctl
- **Logs centralizados**: Todos os logs em /var/log/apache2/
- **Configurações modulares**: Módulos habilitados automaticamente
- **Teste de configuração**: Validação automática antes de aplicar mudanças

## 📝 Changelog

### v1.4.0 - Migração para Apache
- 🔄 Migração completa de Nginx para Apache
- ✨ Suporte a arquivos .htaccess para cada site
- 🔧 Configurações VirtualHost otimizadas
- 🛡️ Headers de segurança via mod_headers
- 📦 Compressão via mod_deflate
- ⚡ Cache de arquivos estáticos via mod_expires
- 🔄 Scripts atualizados para Apache (a2ensite, a2dissite)
- 📊 Logs centralizados em /var/log/apache2/
- 🎯 Maior flexibilidade para desenvolvedores

### v1.3.0 - Sistema Multi-Tecnologia
- ✨ Adicionado suporte a sites PHP
- ✨ Adicionado suporte a sites HTML
- 🎨 Dashboard redesenhado com seções separadas
- 🎨 Cores padronizadas por tecnologia
- 🔧 APIs específicas para cada tipo de site
- 📱 Interface responsiva melhorada

### v1.2.0 - Dashboard e Permissões
- ✨ Dashboard web completo
- 🔐 Sistema de permissões otimizado
- ⚙️ Configuração sudoers automática
- 🎛️ Gerenciamento visual de sites
- 🔧 APIs REST para automação
- 📊 Monitoramento em tempo real

### v1.1.0 - Refatoração e Melhorias
- 🔄 Refatoração para `/opt/webhost`
- 🔧 Correção de permissões
- ⚡ Otimização de performance
- 🐛 Correção de bugs diversos
- 📚 Documentação atualizada

### v1.0.0 - Versão Inicial
- ✨ Instalação automática do WordPress
- 🌐 Configuração Apache automática
- 🗄️ Configuração MySQL automática
- 🔧 Scripts de gerenciamento
- 📁 Estrutura de diretórios organizada

## 🤝 Contribuição

Para contribuir com o projeto:

1. Fork o repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Autor

**Thiago Macêdo**
- Desenvolvedor Full Stack
- Especialista em WordPress e PHP
- Criador do ambiente de desenvolvimento

---

**⭐ Se este projeto te ajudou, considere dar uma estrela!** 