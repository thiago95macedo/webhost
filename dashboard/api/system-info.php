<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    $systemInfo = [
        'cpu' => getCpuInfo(),
        'memory' => getMemoryInfo(),
        'disk' => getDiskInfo(),
        'network' => getNetworkInfo()
    ];

    echo json_encode([
        'success' => true,
        'data' => $systemInfo,
        'timestamp' => date('Y-m-d H:i:s')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao obter informações do sistema: ' . $e->getMessage()
    ]);
}

function getCpuInfo() {
    $cpuInfo = [];
    
    // CPU Model
    $cpuModel = shell_exec("cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs");
    $cpuInfo['model'] = trim($cpuModel) ?: 'CPU Desconhecido';
    
    // CPU Cores
    $cpuCores = shell_exec("nproc");
    $cpuInfo['cores'] = (int)trim($cpuCores) ?: 1;
    
    // CPU Usage
    $cpuUsage = shell_exec("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1");
    $cpuInfo['usage'] = (float)trim($cpuUsage) ?: 0;
    
    return $cpuInfo;
}

function getMemoryInfo() {
    $memoryInfo = [];
    
    // Get memory info from /proc/meminfo
    $memInfo = file_get_contents('/proc/meminfo');
    
    // Total memory
    preg_match('/MemTotal:\s+(\d+)/', $memInfo, $matches);
    $total = (int)($matches[1] ?? 0) * 1024; // Convert KB to bytes
    
    // Available memory
    preg_match('/MemAvailable:\s+(\d+)/', $memInfo, $matches);
    $available = (int)($matches[1] ?? 0) * 1024; // Convert KB to bytes
    
    // Used memory
    $used = $total - $available;
    
    $memoryInfo['total'] = $total;
    $memoryInfo['used'] = $used;
    $memoryInfo['available'] = $available;
    $memoryInfo['usage_percent'] = $total > 0 ? round(($used / $total) * 100, 2) : 0;
    
    return $memoryInfo;
}

function getDiskInfo() {
    $diskInfo = [];
    
    // Get disk usage for root filesystem
    $dfOutput = shell_exec("df / | tail -1");
    $parts = preg_split('/\s+/', trim($dfOutput));
    
    if (count($parts) >= 4) {
        $total = (int)$parts[1] * 1024; // Convert 1K blocks to bytes
        $used = (int)$parts[2] * 1024;
        $available = (int)$parts[3] * 1024;
        
        $diskInfo['total'] = $total;
        $diskInfo['used'] = $used;
        $diskInfo['available'] = $available;
        $diskInfo['usage_percent'] = $total > 0 ? round(($used / $total) * 100, 2) : 0;
        $diskInfo['filesystem'] = $parts[0];
    } else {
        $diskInfo['total'] = 0;
        $diskInfo['used'] = 0;
        $diskInfo['available'] = 0;
        $diskInfo['usage_percent'] = 0;
        $diskInfo['filesystem'] = 'Desconhecido';
    }
    
    return $diskInfo;
}

function getNetworkInfo() {
    $networkInfo = [];
    
    // Count active network interfaces
    $interfaces = shell_exec("ip link show | grep 'state UP' | wc -l");
    $networkInfo['interfaces'] = (int)trim($interfaces) ?: 0;
    
    // Get primary IP address
    $primaryIP = shell_exec("hostname -I | awk '{print $1}'");
    $networkInfo['primary_ip'] = trim($primaryIP) ?: '127.0.0.1';
    
    // Get hostname
    $hostname = shell_exec("hostname");
    $networkInfo['hostname'] = trim($hostname) ?: 'localhost';
    
    return $networkInfo;
}
?> 