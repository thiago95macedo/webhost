<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    if (!isset($_GET['name'])) {
        throw new Exception('Nome do site é obrigatório');
    }
    
    $siteName = trim($_GET['name']);
    
    if (empty($siteName)) {
        throw new Exception('Nome do site não pode estar vazio');
    }
    
    $siteInfo = getDetailedSiteInfo($siteName);
    
    if (!$siteInfo) {
        throw new Exception('Site não encontrado');
    }
    
    echo json_encode([
        'success' => true,
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

function getDetailedSiteInfo($siteName) {
    $webRoot = '/opt/webhost/sites/wordpress';
    $infoDir = '/opt/webhost/site-info';
    $apacheSitesEnabled = '/etc/apache2/sites-enabled';
$apacheSitesAvailable = '/etc/apache2/sites-available';
    
    $siteDir = $webRoot . '/' . $siteName;
    $wpConfigFile = $siteDir . '/wp-config.php';
    $infoFile = $infoDir . '/' . $siteName . '-info.txt';
    
    // Check if site exists
    if (!is_dir($siteDir) || !file_exists($wpConfigFile)) {
        return null;
    }
    
    $siteInfo = [
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
        ],
        'apache_config' => [
            'enabled' => false,
            'config_file' => '',
            'log_files' => []
        ],
        'wordpress' => [
            'version' => '',
            'language' => 'pt_BR',
            'debug_mode' => false,
            'auto_updates' => true
        ]
    ];
    
    // Check if site is active
    $apacheConfig = $apacheSitesEnabled . '/' . $siteName . '.conf';
$siteInfo['active'] = file_exists($apacheConfig);

// Get port from Apache config
$siteInfo['port'] = getPortFromApacheConfig($siteName);
    
    // Build URL
    $siteInfo['url'] = 'http://localhost:' . $siteInfo['port'];
    
    // Get creation date
    $siteInfo['created_at'] = date('Y-m-d H:i:s', filemtime($siteDir));
    
    // Get database info from wp-config.php
    $dbInfo = getDatabaseInfoFromWpConfig($wpConfigFile);
    if ($dbInfo) {
        $siteInfo['database'] = array_merge($siteInfo['database'], $dbInfo);
    }
    
    // Get admin info from info file
    if (file_exists($infoFile)) {
        $adminInfo = getAdminInfoFromFile($infoFile);
        if ($adminInfo) {
            $siteInfo['admin'] = array_merge($siteInfo['admin'], $adminInfo);
        }
    }
    
    // Get Apache config info
$apacheConfigFile = $apacheSitesAvailable . '/' . $siteName . '.conf';
if (file_exists($apacheConfigFile)) {
    $siteInfo['apache_config']['config_file'] = $apacheConfigFile;
    $siteInfo['apache_config']['enabled'] = $siteInfo['active'];
    
    // Get log files
    $accessLog = "/var/log/apache2/$siteName-access.log";
    $errorLog = "/var/log/apache2/$siteName-error.log";
    
    $siteInfo['apache_config']['log_files'] = [
            'access' => file_exists($accessLog) ? $accessLog : null,
            'error' => file_exists($errorLog) ? $errorLog : null
        ];
    }
    
    // Get WordPress info
    $wpInfo = getWordPressInfo($siteDir);
    if ($wpInfo) {
        $siteInfo['wordpress'] = array_merge($siteInfo['wordpress'], $wpInfo);
    }
    
    return $siteInfo;
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
    
    // Extract database password
    if (preg_match("/define\(\s*'DB_PASSWORD',\s*'([^']*)'\s*\);/", $content, $matches)) {
        $dbInfo['password'] = $matches[1];
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
    
    // Extract admin user from CREDENCIAIS DO ADMINISTRADOR section
    if (preg_match('/CREDENCIAIS DO ADMINISTRADOR:.*?- Usuário:\s+(\S+)/s', $content, $matches)) {
        $adminInfo['user'] = trim($matches[1]);
    }
    
    // Extract admin password from CREDENCIAIS DO ADMINISTRADOR section
    if (preg_match('/CREDENCIAIS DO ADMINISTRADOR:.*?- Senha:\s+(\S+)/s', $content, $matches)) {
        $adminInfo['password'] = trim($matches[1]);
    }
    
    // Extract admin email from CREDENCIAIS DO ADMINISTRADOR section
    if (preg_match('/CREDENCIAIS DO ADMINISTRADOR:.*?- Email:\s+(\S+)/s', $content, $matches)) {
        $adminInfo['email'] = trim($matches[1]);
    }
    
    return $adminInfo;
}

function getWordPressInfo($siteDir) {
    $wpInfo = [];
    
    // Get WordPress version
    $versionFile = $siteDir . '/wp-includes/version.php';
    if (file_exists($versionFile)) {
        $versionContent = file_get_contents($versionFile);
        if (preg_match("/\\\$wp_version\s*=\s*'([^']+)'/", $versionContent, $matches)) {
            $wpInfo['version'] = $matches[1];
        }
    }
    
    // Get WordPress configuration
    $wpConfigFile = $siteDir . '/wp-config.php';
    if (file_exists($wpConfigFile)) {
        $configContent = file_get_contents($wpConfigFile);
        
        // Check debug mode
        if (preg_match("/define\(\s*'WP_DEBUG',\s*(true|false)\s*\);/", $configContent, $matches)) {
            $wpInfo['debug_mode'] = $matches[1] === 'true';
        }
        
        // Check auto updates
        if (preg_match("/define\(\s*'WP_AUTO_UPDATE_CORE',\s*(true|false)\s*\);/", $configContent, $matches)) {
            $wpInfo['auto_updates'] = $matches[1] === 'true';
        }
        
        // Check language
        if (preg_match("/define\(\s*'WPLANG',\s*'([^']+)'\s*\);/", $configContent, $matches)) {
            $wpInfo['language'] = $matches[1];
        }
    }
    
    return $wpInfo;
}
?> 