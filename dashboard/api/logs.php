<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    $logs = [
        'nginx' => getNginxLogs(),
        'mysql' => getMySQLLogs(),
        'system' => getSystemLogs()
    ];
    
    echo json_encode([
        'success' => true,
        'logs' => $logs,
        'timestamp' => date('Y-m-d H:i:s')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao obter logs: ' . $e->getMessage()
    ]);
}

function getNginxLogs() {
    $logs = [];
    
    // Nginx error log
    $errorLog = '/var/log/nginx/error.log';
    if (file_exists($errorLog) && is_readable($errorLog)) {
        $logs['error'] = getLastLines($errorLog, 50);
    } else {
        $logs['error'] = 'Log de erro do Nginx não disponível';
    }
    
    // Nginx access log
    $accessLog = '/var/log/nginx/access.log';
    if (file_exists($accessLog) && is_readable($accessLog)) {
        $logs['access'] = getLastLines($accessLog, 30);
    } else {
        $logs['access'] = 'Log de acesso do Nginx não disponível';
    }
    
    return $logs;
}

function getMySQLLogs() {
    $logs = [];
    
    // MySQL error log
    $errorLog = '/var/log/mysql/error.log';
    if (file_exists($errorLog) && is_readable($errorLog)) {
        $logs['error'] = getLastLines($errorLog, 50);
    } else {
        $logs['error'] = 'Log de erro do MySQL não disponível';
    }
    
    // MySQL slow query log (if enabled)
    $slowLog = '/var/log/mysql/slow.log';
    if (file_exists($slowLog) && is_readable($slowLog)) {
        $logs['slow'] = getLastLines($slowLog, 20);
    }
    
    return $logs;
}

function getSystemLogs() {
    $logs = [];
    
    // System messages
    $syslog = '/var/log/syslog';
    if (file_exists($syslog) && is_readable($syslog)) {
        $logs['syslog'] = getLastLines($syslog, 30);
    } else {
        $logs['syslog'] = 'Log do sistema não disponível';
    }
    
    // Kernel messages
    $kernlog = '/var/log/kern.log';
    if (file_exists($kernlog) && is_readable($kernlog)) {
        $logs['kernel'] = getLastLines($kernlog, 20);
    }
    
    return $logs;
}

function getLastLines($filename, $lines = 50) {
    if (!file_exists($filename) || !is_readable($filename)) {
        return 'Arquivo não encontrado ou não legível';
    }
    
    $file = new SplFileObject($filename);
    $file->seek(PHP_INT_MAX);
    $totalLines = $file->key();
    
    $start = max(0, $totalLines - $lines);
    $file->seek($start);
    
    $content = '';
    while (!$file->eof()) {
        $content .= $file->current();
        $file->next();
    }
    
    return trim($content);
}
?> 