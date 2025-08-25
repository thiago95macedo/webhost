<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Listar projetos não configurados
        $projects = detectUnconfiguredProjects();
        
        echo json_encode([
            'success' => true,
            'projects' => $projects,
            'count' => count($projects),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Configurar projeto específico
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['project_name']) || !isset($input['project_type'])) {
            throw new Exception('Nome do projeto e tipo são obrigatórios');
        }
        
        $result = configureProject($input['project_name'], $input['project_type'], $input['port'] ?? null);
        
        echo json_encode([
            'success' => true,
            'message' => 'Projeto configurado com sucesso',
            'result' => $result
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro: ' . $e->getMessage()
    ]);
}

function detectUnconfiguredProjects() {
    $projects = [];
    $webRoots = [
        'php' => '/opt/webhost/sites/php',
        'html' => '/opt/webhost/sites/html',
        'wordpress' => '/opt/webhost/sites/wordpress'
    ];
    
    $apacheSitesEnabled = '/etc/apache2/sites-enabled';
    
    foreach ($webRoots as $type => $webRoot) {
        if (!is_dir($webRoot)) {
            continue;
        }
        
        $siteDirs = glob($webRoot . '/*', GLOB_ONLYDIR);
        
        foreach ($siteDirs as $siteDir) {
            $siteName = basename($siteDir);
            
            // Verificar se já existe configuração Apache
            $apacheConfig = $apacheSitesEnabled . '/' . $siteName . '.conf';
            if (is_link($apacheConfig)) {
                continue; // Já está configurado
            }
            
            $project = [
                'name' => $siteName,
                'type' => $type,
                'directory' => $siteDir,
                'detected_at' => date('Y-m-d H:i:s'),
                'has_index' => false,
                'suggested_port' => getNextAvailablePort($type)
            ];
            
            // Verificar se tem arquivo index
            $indexFiles = ['index.php', 'index.html', 'index.htm'];
            foreach ($indexFiles as $indexFile) {
                if (file_exists($siteDir . '/' . $indexFile)) {
                    $project['has_index'] = true;
                    break;
                }
            }
            
            // Para WordPress, verificar se tem wp-config.php
            if ($type === 'wordpress' && file_exists($siteDir . '/wp-config.php')) {
                $project['is_wordpress'] = true;
            }
            
            $projects[] = $project;
        }
    }
    
    return $projects;
}

function configureProject($projectName, $projectType, $port = null) {
    $webRoots = [
        'php' => '/opt/webhost/sites/php',
        'html' => '/opt/webhost/sites/html',
        'wordpress' => '/opt/webhost/sites/wordpress'
    ];
    
    if (!isset($webRoots[$projectType])) {
        throw new Exception('Tipo de projeto inválido');
    }
    
    $projectDir = $webRoots[$projectType] . '/' . $projectName;
    
    if (!is_dir($projectDir)) {
        throw new Exception('Diretório do projeto não encontrado');
    }
    
    // Definir porta se não fornecida
    if (!$port) {
        $port = getNextAvailablePort($projectType);
    }
    
    // Usar script auxiliar para configurar o projeto
    $scriptPath = '/opt/webhost/scripts/configure-project.sh';
    $result = shell_exec("sudo {$scriptPath} {$projectName} {$projectType} {$port} 2>&1");
    
    return [
        'project_name' => $projectName,
        'project_type' => $projectType,
        'port' => $port,
        'url' => "http://localhost:{$port}",
        'script_result' => $result
    ];
}



function getNextAvailablePort($projectType) {
    $basePorts = [
        'php' => 9000,
        'html' => 9100,
        'wordpress' => 9200
    ];
    
    $basePort = $basePorts[$projectType] ?? 9000;
    
    // Verificar portas em uso
    $usedPorts = [];
    $apacheSitesAvailable = '/etc/apache2/sites-available';
    
    if (is_dir($apacheSitesAvailable)) {
        $configFiles = glob($apacheSitesAvailable . '/*.conf');
        
        foreach ($configFiles as $configFile) {
            $content = file_get_contents($configFile);
            if (preg_match('/<VirtualHost\s+\*:(\d+)>/', $content, $matches)) {
                $usedPorts[] = (int)$matches[1];
            }
        }
    }
    
    // Encontrar próxima porta disponível
    $port = $basePort;
    while (in_array($port, $usedPorts)) {
        $port++;
    }
    
    return $port;
}
?>
