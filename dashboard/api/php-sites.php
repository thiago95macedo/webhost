<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    $webRoot = '/opt/webhost/sites/php';
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
                'type' => 'php'
            ];
            
            // Check if site is active
            $nginxConfig = $nginxSitesEnabled . '/' . $siteName;
            $siteInfo['active'] = is_link($nginxConfig);
            
            // Get port from nginx config
            $siteInfo['port'] = getPortFromNginxConfig($siteName);
            
            // Build URL
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