<?php
/**
 * Gerenciador de Clientes - CasThi SGI
 * Adicionar, editar e remover clientes
 */

class ClientManager {
    private $clients;
    private $configFile = __DIR__ . '/../config/clients.json';
    
    public function __construct() {
        $this->loadClients();
    }
    
    /**
     * Carregar clientes
     */
    private function loadClients() {
        if (file_exists($this->configFile)) {
            $config = json_decode(file_get_contents($this->configFile), true);
            $this->clients = $config['clients'] ?? [];
        } else {
            $this->clients = [];
        }
    }
    
    /**
     * Salvar clientes
     */
    private function saveClients() {
        $config = ['clients' => $this->clients];
        file_put_contents($this->configFile, json_encode($config, JSON_PRETTY_PRINT));
    }
    
    /**
     * Mostrar menu principal
     */
    public function showMenu() {
        while (true) {
            echo "\n=== GERENCIADOR DE CLIENTES ===\n";
            echo "1. 📋 Listar clientes\n";
            echo "2. ➕ Adicionar cliente\n";
            echo "3. ✏️  Editar cliente\n";
            echo "4. 🗑️  Remover cliente\n";
            echo "5. 🔄 Ativar/Desativar cliente\n";
            echo "0. 👋 Sair\n";
            echo "\nEscolha uma opção: ";
            
            $handle = fopen("php://stdin", "r");
            $choice = trim(fgets($handle));
            fclose($handle);
            
            switch ($choice) {
                case '1':
                    $this->listClients();
                    break;
                case '2':
                    $this->addClient();
                    break;
                case '3':
                    $this->editClient();
                    break;
                case '4':
                    $this->removeClient();
                    break;
                case '5':
                    $this->toggleClient();
                    break;
                case '0':
                    echo "👋 Saindo...\n";
                    exit(0);
                default:
                    echo "❌ Opção inválida!\n";
            }
        }
    }
    
    /**
     * Listar clientes
     */
    private function listClients() {
        echo "\n📋 CLIENTES CONFIGURADOS:\n";
        
        if (empty($this->clients)) {
            echo "❌ Nenhum cliente configurado\n";
            return;
        }
        
        foreach ($this->clients as $key => $client) {
            $status = $client['status'] === 'active' ? '🟢' : '🔴';
            echo "\n{$status} {$client['name']} ({$key})\n";
            echo "   Domínio: {$client['domain']}\n";
            echo "   FTP: {$client['ftp']['server']}\n";
            echo "   Status: {$client['status']}\n";
            
            if ($client['last_deploy']) {
                echo "   Último deploy: {$client['last_deploy']}\n";
            }
        }
    }
    
    /**
     * Adicionar cliente
     */
    private function addClient() {
        echo "\n➕ ADICIONAR NOVO CLIENTE:\n";
        
        $key = $this->getInput("Chave do cliente (ex: sintrenorte): ");
        
        if (isset($this->clients[$key])) {
            echo "❌ Cliente já existe!\n";
            return;
        }
        
        $client = [
            'name' => $this->getInput("Nome do cliente: "),
            'domain' => $this->getInput("Domínio: "),
            'ftp' => [
                'server' => $this->getInput("Servidor FTP: "),
                'username' => $this->getInput("Usuário FTP: "),
                'password' => $this->getInput("Senha FTP: "),
                'remote_dir' => $this->getInput("Diretório remoto (ex: /public_html/): ", "/public_html/")
            ],
            'database' => [
                'host' => $this->getInput("Host do banco: ", "localhost"),
                'name' => $this->getInput("Nome do banco: "),
                'username' => $this->getInput("Usuário do banco: ")
            ],
            'status' => 'active',
            'last_deploy' => null,
            'last_commit' => null
        ];
        
        $this->clients[$key] = $client;
        $this->saveClients();
        
        echo "✅ Cliente adicionado com sucesso!\n";
    }
    
    /**
     * Editar cliente
     */
    private function editClient() {
        $key = $this->selectClient("Selecione o cliente para editar");
        if (!$key) return;
        
        $client = $this->clients[$key];
        
        echo "\n✏️  EDITAR CLIENTE: {$client['name']}\n";
        
        $client['name'] = $this->getInput("Nome do cliente: ", $client['name']);
        $client['domain'] = $this->getInput("Domínio: ", $client['domain']);
        $client['ftp']['server'] = $this->getInput("Servidor FTP: ", $client['ftp']['server']);
        $client['ftp']['username'] = $this->getInput("Usuário FTP: ", $client['ftp']['username']);
        $client['ftp']['password'] = $this->getInput("Senha FTP: ", $client['ftp']['password']);
        $client['ftp']['remote_dir'] = $this->getInput("Diretório remoto: ", $client['ftp']['remote_dir']);
        
        $this->clients[$key] = $client;
        $this->saveClients();
        
        echo "✅ Cliente atualizado com sucesso!\n";
    }
    
    /**
     * Remover cliente
     */
    private function removeClient() {
        $key = $this->selectClient("Selecione o cliente para remover");
        if (!$key) return;
        
        $client = $this->clients[$key];
        
        echo "\n🗑️  REMOVER CLIENTE:\n";
        echo "Nome: {$client['name']}\n";
        echo "Domínio: {$client['domain']}\n";
        
        $confirm = $this->getInput("Tem certeza? (s/N): ");
        
        if (strtolower($confirm) === 's' || strtolower($confirm) === 'sim' || strtolower($confirm) === 'y' || strtolower($confirm) === 'yes') {
            unset($this->clients[$key]);
            $this->saveClients();
            echo "✅ Cliente removido com sucesso!\n";
        } else {
            echo "❌ Operação cancelada\n";
        }
    }
    
    /**
     * Ativar/Desativar cliente
     */
    private function toggleClient() {
        $key = $this->selectClient("Selecione o cliente para ativar/desativar");
        if (!$key) return;
        
        $client = $this->clients[$key];
        $newStatus = $client['status'] === 'active' ? 'inactive' : 'active';
        
        $this->clients[$key]['status'] = $newStatus;
        $this->saveClients();
        
        echo "✅ Cliente {$client['name']} {$newStatus}!\n";
    }
    
    /**
     * Selecionar cliente
     */
    private function selectClient($message) {
        if (empty($this->clients)) {
            echo "❌ Nenhum cliente configurado\n";
            return null;
        }
        
        echo "\n{$message}:\n";
        
        $activeClients = [];
        $i = 1;
        
        foreach ($this->clients as $key => $client) {
            $status = $client['status'] === 'active' ? '🟢' : '🔴';
            echo "{$i}. {$status} {$client['name']} ({$key})\n";
            $activeClients[$i] = $key;
            $i++;
        }
        
        echo "\nEscolha (0 para cancelar): ";
        
        $handle = fopen("php://stdin", "r");
        $choice = trim(fgets($handle));
        fclose($handle);
        
        if ($choice === '0') {
            return null;
        }
        
        if (!isset($activeClients[$choice])) {
            echo "❌ Opção inválida!\n";
            return null;
        }
        
        return $activeClients[$choice];
    }
    
    /**
     * Obter input do usuário
     */
    private function getInput($message, $default = '') {
        echo $message;
        if ($default) {
            echo " [{$default}]";
        }
        echo ": ";
        
        $handle = fopen("php://stdin", "r");
        $input = trim(fgets($handle));
        fclose($handle);
        
        return $input ?: $default;
    }
}

// Executar gerenciador
$manager = new ClientManager();
$manager->showMenu();
