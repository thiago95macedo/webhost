# 🚀 Deploy - CasThi SGI

## 📋 Estrutura Organizada

```
deployment/
├── deploy                    # Script principal executável
├── config/
│   └── clients.json          # Configurações dos clientes
├── scripts/
│   ├── deploy-advanced.php   # Script principal de deploy
│   └── manage-clients.php    # Gerenciador de clientes
└── logs/
    └── deploy-YYYY-MM-DD.log # Logs de deploy
```

## 🎯 Como Usar

### **Script Principal:**
```bash
./deployment/deploy [comando]
```

### **Comandos Disponíveis:**
- `./deployment/deploy deploy` - Fazer deploy para cliente
- `./deployment/deploy clients` - Gerenciar clientes
- `./deployment/deploy logs` - Ver logs de deploy
- `./deployment/deploy help` - Mostrar ajuda

## 🔒 SFTP vs FTP

### **SFTP (Recomendado):**
- ✅ **Criptografia completa** (SSH)
- ✅ **20-40% mais rápido** em redes instáveis
- ✅ **Compressão automática**
- ✅ **Resume de transferências**
- ✅ **Mais seguro**

### **FTP (Fallback):**
- ❌ Sem criptografia
- ❌ Mais lento
- ❌ Menos seguro

## 📊 Deploy Incremental

### **Como Funciona:**
1. **Primeiro deploy:** Envia todos os arquivos
2. **Deploys seguintes:** Apenas arquivos alterados
3. **Detecção:** Usa `git diff` para identificar mudanças
4. **Histórico:** Mantém commit do último deploy

### **Benefícios:**
- ⚡ **Muito mais rápido** (apenas mudanças)
- 📡 **Menos tráfego** de rede
- 🔄 **Deploy automático** de mudanças
- 📝 **Log detalhado** de cada arquivo

## 👥 Gerenciamento de Clientes

### **Adicionar Cliente:**
```bash
./deployment/deploy clients
# Escolha: 2. Adicionar cliente
```

### **Configuração de Cliente:**
```json
{
  "name": "Nome do Cliente",
  "domain": "cliente.com.br",
  "protocol": "sftp",  // ou "ftp"
  "ftp": {
    "server": "ftp.cliente.com.br",
    "username": "usuario",
    "password": "senha",
    "remote_dir": "/public_html/"
  },
  "status": "active"
}
```

## 🗑️ Arquivos Excluídos

### **Desenvolvimento:**
- `.git/`, `.github/`, `deployment/`
- `docs/`, `tests/`, `README.md`
- `.gitignore`, `.cursorrules`

### **Sensíveis:**
- `config/installed.lock`
- `config/database.php`

## 📊 Logs e Monitoramento

### **Logs Automáticos:**
- 📄 Salvo em `deployment/logs/`
- 📅 Formato: `deploy-YYYY-MM-DD.log`
- 📝 Detalhado: Cada arquivo enviado

### **Ver Logs:**
```bash
./deployment/deploy logs
# ou
tail -f deployment/logs/deploy-2024-01-15.log
```

## ⚡ Performance SFTP

### **Otimizações Implementadas:**
1. **SCP nativo** (mais rápido que PHP SFTP)
2. **Compressão automática**
3. **Timeout otimizado** (30s)
4. **Resume automático**
5. **Criação de diretórios** em lote

### **Ganhos Esperados:**
- 🚀 **20-40% mais rápido** em redes instáveis
- 📦 **Compressão** reduz tamanho
- 🔄 **Resume** em caso de interrupção
- 🔒 **Segurança** end-to-end

## 🔧 Configuração Avançada

### **Para Hosts que Suportam SFTP:**
```json
{
  "protocol": "sftp",
  "ftp": {
    "server": "sftp.cliente.com.br",
    "username": "usuario",
    "password": "senha"
  }
}
```

### **Para Hosts Apenas FTP:**
```json
{
  "protocol": "ftp",
  "ftp": {
    "server": "ftp.cliente.com.br",
    "username": "usuario",
    "password": "senha"
  }
}
```

## 📋 Checklist Pós-Deploy

- [ ] Verificar se o site está acessível
- [ ] Testar funcionalidades principais
- [ ] Verificar logs de erro
- [ ] Validar com usuários
- [ ] Documentar mudanças

## ⚠️ Importante

- **Sempre** faça backup antes de grandes mudanças
- **Teste** em ambiente de desenvolvimento primeiro
- **Monitore** logs após o deploy
- **Valide** funcionamento com usuários
- **Use SFTP** quando possível para melhor performance

## 🆘 Solução de Problemas

### **Erro de conexão SFTP:**
- Verificar se host suporta SFTP
- Verificar credenciais SSH
- Testar conexão manual: `ssh usuario@servidor`

### **Erro de conexão FTP:**
- Verificar credenciais
- Verificar se servidor está acessível
- Verificar firewall

### **Arquivos não enviados:**
- Verificar permissões de arquivo
- Verificar espaço em disco
- Verificar logs de erro

### **Site não funciona:**
- Verificar arquivos críticos
- Verificar configurações
- Verificar logs do servidor
