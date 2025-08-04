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
    $domain = isset($input['domain']) ? trim($input['domain']) : 'localhost';
    
    // Validate site name
    if (empty($siteName)) {
        throw new Exception('Nome do site não pode estar vazio');
    }
    
    if (!preg_match('/^[a-zA-Z0-9_-]+$/', $siteName)) {
        throw new Exception('Nome do site deve conter apenas letras, números, hífens e underscores');
    }
    
    // Check if site already exists
    $webRoot = '/home/weth/webhost/sites';
    $siteDir = $webRoot . '/' . $siteName;
    
    if (is_dir($siteDir)) {
        throw new Exception('Site com este nome já existe');
    }
    
    // Execute wp-multi.sh script with sudo privileges
    $scriptPath = '/home/weth/webhost/scripts/wp-multi.sh';
    $command = "sudo -n $scriptPath create $siteName $domain 2>&1";
    
    $output = [];
    $returnCode = 0;
    exec($command, $output, $returnCode);
    
    if ($returnCode !== 0) {
        $errorMessage = implode("\n", $output);
        throw new Exception('Erro ao criar site: ' . $errorMessage);
    }
    
    // Get site info after creation
    $siteInfo = getSiteInfo($siteName);
    
    echo json_encode([
        'success' => true,
        'message' => 'Site criado com sucesso',
        'site' => $siteInfo,
        'timestamp' => date('Y-m-d H:i:s')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

function getSiteInfo($siteName) {
    $webRoot = '/home/weth/webhost/sites';
    $infoDir = '/home/weth/webhost/site-info';
    $nginxSitesEnabled = '/etc/nginx/sites-enabled';
    
    $siteDir = $webRoot . '/' . $siteName;
    $infoFile = $infoDir . '/' . $siteName . '-info.txt';
    
    $siteInfo = [
        'name' => $siteName,
        'url' => '',
        'port' => '',
        'admin_user' => '',
        'admin_password' => '',
        'directory' => $siteDir,
        'active' => false
    ];
    
    // Check if site is active
    $nginxConfig = $nginxSitesEnabled . '/' . $siteName;
    $siteInfo['active'] = is_link($nginxConfig);
    
    // Get port from nginx config
    $siteInfo['port'] = getPortFromNginxConfig($siteName);
    
    // Build URL
    $siteInfo['url'] = 'http://localhost:' . $siteInfo['port'];
    
    // Get admin info from info file
    if (file_exists($infoFile)) {
        $content = file_get_contents($infoFile);
        
        // Extract admin password from CREDENCIAIS DO ADMINISTRADOR section
        if (preg_match('/CREDENCIAIS DO ADMINISTRADOR:.*?- Senha:\s+(\S+)/s', $content, $matches)) {
            $siteInfo['admin_password'] = trim($matches[1]);
        }
        
        // Extract admin user from CREDENCIAIS DO ADMINISTRADOR section
        if (preg_match('/CREDENCIAIS DO ADMINISTRADOR:.*?- Usuário:\s+(\S+)/s', $content, $matches)) {
            $siteInfo['admin_user'] = trim($matches[1]);
        }
    }
    
    return $siteInfo;
}

function getPortFromNginxConfig($siteName) {
    $nginxSitesAvailable = '/etc/nginx/sites-available';
    $configFile = $nginxSitesAvailable . '/' . $siteName;
    
    if (!file_exists($configFile)) {
        return '80';
    }
    
    $configContent = file_get_contents($configFile);
    if (preg_match('/listen\s+(\d+);/', $configContent, $matches)) {
        return $matches[1];
    }
    
    return '80';
}
?> 