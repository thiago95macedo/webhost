<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    $webRoot = '/opt/webhost/sites/html';
    $infoDir = '/opt/webhost/site-info';
    $nginxSitesEnabled = '/etc/nginx/sites-enabled';
    $sites = [];
    
    if (is_dir($webRoot)) {
        $siteDirs = glob($webRoot . '/*', GLOB_ONLYDIR);
        
        foreach ($siteDirs as $siteDir) {
            $siteName = basename($siteDir);
            $infoFile = $infoDir . '/' . $siteName . '-info.txt';
            
            $siteInfo = [
                'name' => $siteName,
                'url' => '',
                'port' => '',
                'directory' => $siteDir,
                'active' => false,
                'type' => 'html'
            ];
            
            // Verificar se o site está ativo no Nginx
            $nginxConfig = $nginxSitesEnabled . '/' . $siteName;
            $siteInfo['active'] = is_link($nginxConfig);
            
            // Obter porta do arquivo de configuração Nginx
            $siteInfo['port'] = getPortFromNginxConfig($siteName);
            
            // Construir URL
            $siteInfo['url'] = 'http://localhost:' . $siteInfo['port'];
            
            $sites[] = $siteInfo;
        }
    }
    
    echo json_encode([
        'success' => true,
        'sites' => $sites,
        'count' => count($sites)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
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