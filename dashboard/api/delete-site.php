<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método não permitido']);
    exit;
}

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['name'])) {
        throw new Exception('Nome do site é obrigatório');
    }
    
    $siteName = trim($input['name']);
    
    // Validate site name
    if (empty($siteName)) {
        throw new Exception('Nome do site não pode estar vazio');
    }
    
    // Check if site exists
    $webRoot = '/home/weth/webhost/sites';
    $siteDir = $webRoot . '/' . $siteName;
    
    if (!is_dir($siteDir)) {
        throw new Exception('Site não encontrado');
    }
    
    // Execute wp-multi.sh script to delete site
    $scriptPath = '/home/weth/webhost/scripts/wp-multi.sh';
    $command = "echo 'y' | sudo $scriptPath delete $siteName 2>&1";
    
    $output = [];
    $returnCode = 0;
    exec($command, $output, $returnCode);
    
    if ($returnCode !== 0) {
        $errorMessage = implode("\n", $output);
        throw new Exception('Erro ao deletar site: ' . $errorMessage);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Site deletado com sucesso',
        'site_name' => $siteName,
        'timestamp' => date('Y-m-d H:i:s')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?> 