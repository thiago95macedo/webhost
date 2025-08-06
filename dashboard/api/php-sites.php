<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

try {
    $webRoot = '/opt/webhost/sites/php';
    $infoDir = '/opt/webhost/site-info';
    $apacheSitesEnabled = '/etc/apache2/sites-enabled';
    
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
            $apacheConfig = $apacheSitesEnabled . '/' . $siteName . '.conf';
            $siteInfo['active'] = is_link($apacheConfig);
            
            // Get port from apache config
            $siteInfo['port'] = getPortFromApacheConfig($siteName);
            
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

function getPortFromApacheConfig($siteName) {
    $apacheSitesAvailable = '/etc/apache2/sites-available';
    $configFile = $apacheSitesAvailable . '/' . $siteName . '.conf';
    
    if (!file_exists($configFile)) {
        return '80';
    }
    
    $configContent = file_get_contents($configFile);
    if (preg_match('/<VirtualHost\s+\*:(\d+)>/', $configContent, $matches)) {
        return $matches[1];
    }
    
    return '80';
}
?> 