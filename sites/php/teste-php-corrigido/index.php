<?php
/**
 * Site PHP - Página Inicial
 * Gerado automaticamente pelo php-multi.sh
 */

// Configurações básicas
error_reporting(E_ALL);
ini_set('display_errors', 1);
date_default_timezone_set('America/Sao_Paulo');

// Informações do site
$site_name = 'teste-php-corrigido';
$site_url = 'http://localhost:9002';
$created_date = '2025-08-05 20:05:59';

?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($site_name); ?> - Site PHP</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #212529;
            background: linear-gradient(135deg, #0056b3 0%, #4d89ca 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .container {
            background: white;
            padding: 3rem;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
            width: 90%;
        }
        
        .logo {
            font-size: 3rem;
            margin-bottom: 1rem;
            color: #0056b3;
        }
        
        h1 {
            color: #212529;
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }
        
        .subtitle {
            color: #6c757d;
            margin-bottom: 2rem;
            font-size: 1.2rem;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin: 2rem 0;
        }
        
        .info-card {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 8px;
            border-left: 4px solid #0056b3;
        }
        
        .info-card h3 {
            color: #0056b3;
            margin-bottom: 0.5rem;
        }
        
        .status {
            background: #d4edda;
            color: #155724;
            padding: 0.75rem;
            border-radius: 5px;
            margin: 1rem 0;
            font-weight: bold;
        }
        
        .tech-stack {
            background: #e9ecef;
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
        }
        
        .tech-stack h3 {
            color: #343a40;
            margin-bottom: 0.5rem;
        }
        
        .tech-list {
            list-style: none;
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            justify-content: center;
        }
        
        .tech-item {
            background: #0056b3;
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 15px;
            font-size: 0.9rem;
        }
        
        .footer {
            margin-top: 2rem;
            padding-top: 1rem;
            border-top: 1px solid #e9ecef;
            color: #6c757d;
            font-size: 0.9rem;
        }
        
        .php-info {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 1rem;
            border-radius: 5px;
            margin: 1rem 0;
        }
        
        .php-info h3 {
            color: #856404;
            margin-bottom: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1><?php echo htmlspecialchars($site_name); ?></h1>
        <p class="subtitle">Site PHP funcionando perfeitamente!</p>
        
        <div class="status">
            ✅ Site PHP ativo e operacional
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>URL do Site</h3>
                <p><?php echo htmlspecialchars($site_url); ?></p>
            </div>
            <div class="info-card">
                <h3>Data de Criação</h3>
                <p><?php echo htmlspecialchars($created_date); ?></p>
            </div>
            <div class="info-card">
                <h3>Versão PHP</h3>
                <p><?php echo PHP_VERSION; ?></p>
            </div>
            <div class="info-card">
                <h3>Servidor Web</h3>
                <p>Nginx + PHP-FPM</p>
            </div>
        </div>
        
        <div class="tech-stack">
            <h3>Stack Tecnológica</h3>
            <ul class="tech-list">
                <li class="tech-item">PHP <?php echo PHP_VERSION; ?></li>
                <li class="tech-item">Nginx</li>
                <li class="tech-item">PHP-FPM</li>
                <li class="tech-item">Ubuntu/Debian</li>
            </ul>
        </div>
        
        <div class="php-info">
            <h3>Informações do PHP</h3>
            <p><strong>Extensões carregadas:</strong> <?php echo count(get_loaded_extensions()); ?></p>
            <p><strong>Memória limite:</strong> <?php echo ini_get('memory_limit'); ?></p>
            <p><strong>Upload máximo:</strong> <?php echo ini_get('upload_max_filesize'); ?></p>
            <p><strong>Timezone:</strong> <?php echo date_default_timezone_get(); ?></p>
        </div>
        
        <div class="footer">
            <p>Site criado automaticamente pelo <strong>php-multi.sh</strong></p>
            <p>Pronto para desenvolvimento! 🎉</p>
        </div>
    </div>
</body>
</html>
