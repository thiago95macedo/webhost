<?php
/**
 * Script de Deploy Avançado - CasThi SGI
 * Multi-cliente com deploy incremental (FTP/SFTP)
 */

class AdvancedDeployer {
    private $clients;
    private $selectedClient;
    private $deployLog;
    
    public function __construct() {
        $this->loadClients();
        $this->deployLog = [];
    }
    
    /**
     * Carregar configurações dos clientes
     */
    private function loadClients() {
        $configFile = __DIR__ . '/../config/clients.json';
        
        if (!file_exists($configFile)) {
            die("❌ Arquivo clients.json não encontrado em deployment/config/\n");
        }
        
        $config = json_decode(file_get_contents($configFile), true);
        $this->clients = $config['clients'] ?? [];
        
        if (empty($this->clients)) {
            die("❌ Nenhum cliente configurado!\n");
        }
    }
    
    /**
     * Mostrar menu de seleção de cliente
     */
    public function showClientMenu() {
        echo "=== DEPLOY AVANÇADO - CasThi SGI ===\n\n";
        echo "📋 Clientes disponíveis:\n";
        
        $activeClients = [];
        $i = 1;
        
        foreach ($this->clients as $key => $client) {
            $status = $client['status'] === 'active' ? '🟢' : '🔴';
            $protocol = $client['protocol'] ?? 'ftp';
            $protocolIcon = $protocol === 'sftp' ? '🔒' : '📡';
            echo "{$i}. {$status} {$protocolIcon} {$client['name']} ({$client['domain']}) - {$protocol}\n";
            
            if ($client['status'] === 'active') {
                $activeClients[$i] = $key;
            }
            $i++;
        }
        
        echo "\n0. Sair\n";
        echo "\nSelecione o cliente (0-{$i}): ";
        
        $handle = fopen("php://stdin", "r");
        $choice = trim(fgets($handle));
        fclose($handle);
        
        if ($choice === '0') {
            echo "👋 Saindo...\n";
            exit(0);
        }
        
        if (!isset($activeClients[$choice])) {
            echo "❌ Opção inválida!\n";
            exit(1);
        }
        
        $this->selectedClient = $activeClients[$choice];
        $client = $this->clients[$this->selectedClient];
        
        echo "\n✅ Cliente selecionado: {$client['name']} ({$client['domain']})\n";
    }
    
    /**
     * Detectar arquivos alterados desde último deploy
     */
    private function getChangedFiles() {
        $client = $this->clients[$this->selectedClient];
        $lastCommit = $client['last_commit'] ?? null;
        
        if (!$lastCommit) {
            // Primeiro deploy - enviar tudo
            $this->log("🆕 Primeiro deploy - enviando todos os arquivos");
            return $this->getAllFiles();
        }
        
        // Deploy incremental - apenas arquivos alterados
        $this->log("🔄 Deploy incremental - detectando mudanças desde {$lastCommit}");
        
        $command = "git diff --name-only {$lastCommit} HEAD";
        $output = shell_exec($command);
        
        if (empty($output)) {
            $this->log("✅ Nenhuma mudança detectada");
            return [];
        }
        
        $files = array_filter(explode("\n", $output));
        $this->log("📝 Arquivos alterados: " . count($files));
        
        return $files;
    }
    
    /**
     * Obter todos os arquivos do projeto
     */
    private function getAllFiles() {
        $command = "git ls-files";
        $output = shell_exec($command);
        
        if (empty($output)) {
            return [];
        }
        
        $files = array_filter(explode("\n", $output));
        $this->log("📁 Total de arquivos: " . count($files));
        
        return $files;
    }
    
    /**
     * Filtrar arquivos para deploy
     */
    private function filterFiles($files) {
        $excludePatterns = [
            '/^\.git/',
            '/^\.github/',
            '/^deployment/',
            '/^docs/',
            '/^tests/',
            '/^README\.md$/',
            '/^\.gitignore$/',
            '/^\.cursorrules$/',
            '/^deploy.*\.php$/',
            '/^clients\.json$/',
            '/^config\/installed\.lock$/',
            '/^config\/database\.php$/'
        ];
        
        $filteredFiles = [];
        
        foreach ($files as $file) {
            $exclude = false;
            
            foreach ($excludePatterns as $pattern) {
                if (preg_match($pattern, $file)) {
                    $exclude = true;
                    break;
                }
            }
            
            if (!$exclude && file_exists($file)) {
                $filteredFiles[] = $file;
            }
        }
        
        $this->log("✅ Arquivos para deploy: " . count($filteredFiles));
        return $filteredFiles;
    }
    
    /**
     * Deploy via FTP ou SFTP
     */
    private function deployFiles($files) {
        $client = $this->clients[$this->selectedClient];
        $protocol = $client['protocol'] ?? 'ftp';
        
        $this->log("🚀 Iniciando deploy via {$protocol}...");
        $this->log("📡 Servidor: {$client['ftp']['server']}");
        $this->log("👤 Usuário: {$client['ftp']['username']}");
        
        if ($protocol === 'sftp') {
            return $this->deployViaSFTP($files);
        } else {
            return $this->deployViaFTP($files);
        }
    }
    
    /**
     * Deploy via SFTP (mais rápido e seguro)
     */
    private function deployViaSFTP($files) {
        $client = $this->clients[$this->selectedClient];
        $ftpConfig = $client['ftp'];
        
        $this->log("🔒 Usando SFTP (criptografado e otimizado)");
        
        // Usar scp/rsync para melhor performance
        $uploadedCount = 0;
        $errorCount = 0;
        
        foreach ($files as $file) {
            $remotePath = $ftpConfig['remote_dir'] . $file;
            $localPath = $file;
            
            // Criar diretório remoto se necessário
            $remoteDir = dirname($remotePath);
            $this->createRemoteDirectorySFTP($remoteDir, $ftpConfig);
            
            // Upload via scp (mais rápido que PHP SFTP)
            $scpCommand = sprintf(
                'scp -o StrictHostKeyChecking=no -o ConnectTimeout=30 "%s" %s@%s:"%s"',
                $localPath,
                $ftpConfig['username'],
                $ftpConfig['server'],
                $remotePath
            );
            
            // Definir senha via SSH_ASKPASS
            putenv("SSH_ASKPASS=/bin/echo");
            putenv("SSHPASS={$ftpConfig['password']}");
            
            $output = shell_exec($scpCommand . " 2>&1");
            
            if (strpos($output, 'Permission denied') !== false || strpos($output, 'Connection refused') !== false) {
                $this->log("❌ Erro no upload: {$file} - {$output}");
                $errorCount++;
            } else {
                $this->log("📤 Upload: {$file}");
                $uploadedCount++;
            }
        }
        
        $this->log("✅ Deploy via SFTP concluído");
        $this->log("📊 Resumo: {$uploadedCount} enviados, {$errorCount} erros");
        
        return $errorCount === 0;
    }
    
    /**
     * Deploy via FTP (fallback)
     */
    private function deployViaFTP($files) {
        $client = $this->clients[$this->selectedClient];
        $ftpConfig = $client['ftp'];
        
        $this->log("📡 Usando FTP (modo compatibilidade)");
        
        // Conectar ao FTP
        $ftp = ftp_connect($ftpConfig['server']);
        if (!$ftp) {
            $this->log("❌ Erro ao conectar ao servidor FTP");
            return false;
        }
        
        // Login
        if (!ftp_login($ftp, $ftpConfig['username'], $ftpConfig['password'])) {
            $this->log("❌ Erro no login FTP");
            ftp_close($ftp);
            return false;
        }
        
        $this->log("✅ Conectado ao FTP com sucesso");
        
        // Ativar modo passivo
        ftp_pasv($ftp, true);
        
        $uploadedCount = 0;
        $errorCount = 0;
        
        foreach ($files as $file) {
            $remotePath = $ftpConfig['remote_dir'] . $file;
            $localPath = $file;
            
            // Criar diretório remoto se necessário
            $remoteDir = dirname($remotePath);
            $this->createRemoteDirectory($ftp, $remoteDir);
            
            // Upload do arquivo
            if (ftp_put($ftp, $remotePath, $localPath, FTP_BINARY)) {
                $this->log("📤 Upload: {$file}");
                $uploadedCount++;
            } else {
                $this->log("❌ Erro no upload: {$file}");
                $errorCount++;
            }
        }
        
        ftp_close($ftp);
        
        $this->log("✅ Deploy via FTP concluído");
        $this->log("📊 Resumo: {$uploadedCount} enviados, {$errorCount} erros");
        
        return $errorCount === 0;
    }
    
    /**
     * Criar diretório remoto via SFTP
     */
    private function createRemoteDirectorySFTP($path, $ftpConfig) {
        $sshCommand = sprintf(
            'ssh -o StrictHostKeyChecking=no %s@%s "mkdir -p %s"',
            $ftpConfig['username'],
            $ftpConfig['server'],
            $path
        );
        
        shell_exec($sshCommand . " 2>/dev/null");
    }
    
    /**
     * Criar diretório remoto via FTP
     */
    private function createRemoteDirectory($ftp, $path) {
        $parts = explode('/', trim($path, '/'));
        $currentPath = '';
        
        foreach ($parts as $part) {
            if (empty($part)) continue;
            
            $currentPath .= '/' . $part;
            
            // Tentar criar diretório
            @ftp_mkdir($ftp, $currentPath);
        }
    }
    
    /**
     * Atualizar informações do cliente
     */
    private function updateClientInfo() {
        $currentCommit = trim(shell_exec('git rev-parse HEAD'));
        $currentDate = date('Y-m-d H:i:s');
        
        $this->clients[$this->selectedClient]['last_deploy'] = $currentDate;
        $this->clients[$this->selectedClient]['last_commit'] = $currentCommit;
        
        // Salvar configurações atualizadas
        $config = ['clients' => $this->clients];
        $configFile = __DIR__ . '/../config/clients.json';
        file_put_contents($configFile, json_encode($config, JSON_PRETTY_PRINT));
        
        $this->log("💾 Informações do cliente atualizadas");
        $this->log("📅 Último deploy: {$currentDate}");
        $this->log("🔗 Commit: {$currentCommit}");
    }
    
    /**
     * Log de mensagens
     */
    private function log($message) {
        $timestamp = date('Y-m-d H:i:s');
        $logMessage = "[{$timestamp}] {$message}";
        echo $logMessage . "\n";
        $this->deployLog[] = $logMessage;
        
        // Salvar log em arquivo
        $logFile = __DIR__ . '/../logs/deploy-' . date('Y-m-d') . '.log';
        file_put_contents($logFile, $logMessage . "\n", FILE_APPEND | LOCK_EX);
    }
    
    /**
     * Executar deploy
     */
    public function execute() {
        $this->showClientMenu();
        
        $client = $this->clients[$this->selectedClient];
        $this->log("🎯 Deploy para: {$client['name']} ({$client['domain']})");
        
        // Detectar arquivos alterados
        $changedFiles = $this->getChangedFiles();
        
        if (empty($changedFiles)) {
            $this->log("✅ Nenhuma mudança para deploy");
            return;
        }
        
        // Filtrar arquivos
        $filesToDeploy = $this->filterFiles($changedFiles);
        
        if (empty($filesToDeploy)) {
            $this->log("✅ Nenhum arquivo válido para deploy");
            return;
        }
        
        // Mostrar arquivos que serão enviados
        $this->log("\n📋 Arquivos para deploy:");
        foreach ($filesToDeploy as $file) {
            $this->log("   • {$file}");
        }
        
        // Confirmação
        echo "\n⚠️  Continuar com o deploy? (s/N): ";
        $handle = fopen("php://stdin", "r");
        $response = trim(fgets($handle));
        fclose($handle);
        
        if (strtolower($response) !== 's' && strtolower($response) !== 'sim' && strtolower($response) !== 'y' && strtolower($response) !== 'yes') {
            $this->log("❌ Deploy cancelado pelo usuário");
            return;
        }
        
        // Executar deploy
        $success = $this->deployFiles($filesToDeploy);
        
        if ($success) {
            $this->log("🎉 DEPLOY CONCLUÍDO COM SUCESSO!");
            $this->updateClientInfo();
            
            $this->log("\n📋 PRÓXIMOS PASSOS:");
            $this->log("1. Verificar funcionamento do sistema");
            $this->log("2. Testar funcionalidades críticas");
            $this->log("3. Validar com usuários");
        } else {
            $this->log("❌ DEPLOY FALHOU!");
            $this->log("Verificar logs e tentar novamente");
        }
    }
}

// Executar deploy
$deployer = new AdvancedDeployer();
$deployer->execute();
