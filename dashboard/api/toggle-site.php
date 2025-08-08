<?php
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// Verificar se o método é POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método não permitido']);
    exit;
}

// Ler dados JSON
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['site_name']) || !isset($input['action'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Nome do site e ação são obrigatórios']);
    exit;
}

$siteName = $input['site_name'];
$action = $input['action']; // 'enable' ou 'disable'

// Validar ação
if (!in_array($action, ['enable', 'disable'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Ação inválida. Use enable ou disable']);
    exit;
}

// Definir caminhos
$apacheSitesAvailable = '/etc/apache2/sites-available';
$apacheSitesEnabled = '/etc/apache2/sites-enabled';

// Verificar se o site existe
$configFile = "$apacheSitesAvailable/$siteName.conf";
if (!file_exists($configFile)) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Site não encontrado']);
    exit;
}

try {
    $enabledFile = "$apacheSitesEnabled/$siteName.conf";
    
    if ($action === 'enable') {
        // Ativar site
        if (file_exists($enabledFile)) {
            echo json_encode(['success' => false, 'message' => 'Site já está ativo']);
            exit;
        }
        
        $cmd = "sudo a2ensite $siteName 2>&1";
        exec($cmd, $output, $returnVar);
        
        if ($returnVar !== 0) {
            throw new Exception('Erro ao ativar site: ' . implode("\n", $output));
        }
        
        // Recarregar Apache
        exec('sudo systemctl reload apache2 2>&1', $reloadOutput, $reloadReturn);
        if ($reloadReturn !== 0) {
            throw new Exception('Erro ao recarregar Apache: ' . implode("\n", $reloadOutput));
        }
        
        echo json_encode([
            'success' => true, 
            'message' => 'Site ativado com sucesso',
            'status' => 'active'
        ]);
        
    } else {
        // Desativar site
        if (!file_exists($enabledFile)) {
            echo json_encode(['success' => false, 'message' => 'Site já está inativo']);
            exit;
        }
        
        $cmd = "sudo a2dissite $siteName 2>&1";
        exec($cmd, $output, $returnVar);
        
        if ($returnVar !== 0) {
            throw new Exception('Erro ao desativar site: ' . implode("\n", $output));
        }
        
        // Recarregar Apache
        exec('sudo systemctl reload apache2 2>&1', $reloadOutput, $reloadReturn);
        if ($reloadReturn !== 0) {
            throw new Exception('Erro ao recarregar Apache: ' . implode("\n", $reloadOutput));
        }
        
        echo json_encode([
            'success' => true, 
            'message' => 'Site desativado com sucesso',
            'status' => 'inactive'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
