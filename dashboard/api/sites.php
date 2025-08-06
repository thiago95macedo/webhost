<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

try {
    $sites = getWordPressSites();
    
    echo json_encode([
        'success' => true,
        'sites' => $sites,
        'count' => count($sites),
        'timestamp' => date('Y-m-d H:i:s')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao obter lista de sites: ' . $e->getMessage()
    ]);
}

function getWordPressSites() {
    $sites = [];
    $webRoot = '/opt/webhost/sites/wordpress';
    $infoDir = '/opt/webhost/site-info';
    $apacheSitesEnabled = '/etc/apache2/sites-enabled';
    
    // Check if web root directory exists
    if (!is_dir($webRoot)) {
        return $sites;
    }
    
    // Scan for WordPress sites
    $siteDirs = glob($webRoot . '/*', GLOB_ONLYDIR);
    
    foreach ($siteDirs as $siteDir) {
        $siteName = basename($siteDir);
        $wpConfigFile = $siteDir . '/wp-config.php';
        
        // Check if it's a WordPress site
        if (!file_exists($wpConfigFile)) {
            continue;
        }
        
        $site = [
            'name' => $siteName,
            'directory' => $siteDir,
            'active' => false,
            'url' => '',
            'port' => '',
            'created_at' => '',
            'database' => [
                'name' => '',
                'user' => '',
                'host' => 'localhost'
            ],
            'admin' => [
                'user' => 'admin',
                'email' => 'admin@localhost'
            ]
        ];
        
        // Check if site is active (Apache enabled)
        $apacheConfig = $apacheSitesEnabled . '/' . $siteName . '.conf';
        $site['active'] = file_exists($apacheConfig);
        
        // Get port from Apache config
        $site['port'] = getPortFromApacheConfig($siteName);
        
        // Build URL
        $site['url'] = 'http://localhost:' . $site['port'];
        
        // Get creation date
        $site['created_at'] = date('Y-m-d H:i:s', filemtime($siteDir));
        
        // Get database info from wp-config.php
        $dbInfo = getDatabaseInfoFromWpConfig($wpConfigFile);
        if ($dbInfo) {
            $site['database'] = array_merge($site['database'], $dbInfo);
        }
        
        // Get admin info from info file
        $infoFile = $infoDir . '/' . $siteName . '-info.txt';
        if (file_exists($infoFile)) {
            $adminInfo = getAdminInfoFromFile($infoFile);
            if ($adminInfo) {
                $site['admin'] = array_merge($site['admin'], $adminInfo);
            }
        }
        
        $sites[] = $site;
    }
    
    // Sort sites by creation date (newest first)
    usort($sites, function($a, $b) {
        return strtotime($b['created_at']) - strtotime($a['created_at']);
    });
    
    return $sites;
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

function getDatabaseInfoFromWpConfig($wpConfigFile) {
    $content = file_get_contents($wpConfigFile);
    
    $dbInfo = [];
    
    // Extract database name
    if (preg_match("/define\(\s*'DB_NAME',\s*'([^']+)'\s*\);/", $content, $matches)) {
        $dbInfo['name'] = $matches[1];
    }
    
    // Extract database user
    if (preg_match("/define\(\s*'DB_USER',\s*'([^']+)'\s*\);/", $content, $matches)) {
        $dbInfo['user'] = $matches[1];
    }
    
    // Extract database host
    if (preg_match("/define\(\s*'DB_HOST',\s*'([^']+)'\s*\);/", $content, $matches)) {
        $dbInfo['host'] = $matches[1];
    }
    
    return $dbInfo;
}

function getAdminInfoFromFile($infoFile) {
    $content = file_get_contents($infoFile);
    
    $adminInfo = [];
    
    // Extract admin user
    if (preg_match('/Usuário:\s+(\S+)/', $content, $matches)) {
        $adminInfo['user'] = $matches[1];
    }
    
    // Extract admin email
    if (preg_match('/Email:\s+(\S+)/', $content, $matches)) {
        $adminInfo['email'] = $matches[1];
    }
    
    return $adminInfo;
}
?> 