<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WordPress Development Dashboard</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="dashboard-container">
        <!-- Header -->
        <header class="dashboard-header">
            <div class="header-content">
                <div class="logo">
                    <img src="images/logo.png" alt="WordPress Dev Dashboard" class="logo-image" style="width: 32px; height: 32px; object-fit: contain;">
                    <h1>WordPress Dev Dashboard</h1>
                </div>
                <div class="header-actions">
                    <button class="btn btn-refresh" onclick="refreshData()">
                        <i class="fas fa-sync-alt"></i>
                        Atualizar
                    </button>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="dashboard-main">
            <!-- System Info and Quick Actions Row -->
            <section class="dashboard-section">
                <div class="two-column-layout">
                    <!-- System Info Cards -->
                    <div class="column">
                        <h2 class="section-title">
                            <i class="fas fa-server"></i>
                            Informações do Sistema
                        </h2>
                        <div class="cards-grid">
                            <div class="info-card">
                                <div class="card-icon">
                                    <i class="fas fa-microchip"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Processador</h3>
                                    <p class="card-value" id="cpu-info">Carregando...</p>
                                </div>
                            </div>

                            <div class="info-card">
                                <div class="card-icon">
                                    <i class="fas fa-memory"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Memória RAM</h3>
                                    <p class="card-value" id="memory-info">Carregando...</p>
                                </div>
                            </div>

                            <div class="info-card">
                                <div class="card-icon">
                                    <i class="fas fa-hdd"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Disco</h3>
                                    <p class="card-value" id="disk-info">Carregando...</p>
                                </div>
                            </div>

                            <div class="info-card">
                                <div class="card-icon">
                                    <i class="fas fa-network-wired"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Rede</h3>
                                    <p class="card-value" id="network-info">Carregando...</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Actions -->
                    <div class="column">
                        <h2 class="section-title">
                            <i class="fas fa-bolt"></i>
                            Ações Rápidas
                        </h2>
                        <div class="quick-actions">
                            <div class="info-card" onclick="showSystemStatus()">
                                <div class="card-icon">
                                    <i class="fas fa-heartbeat"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Status do Sistema</h3>
                                    <p class="card-value">Monitorar</p>
                                </div>
                            </div>
                            <div class="info-card" onclick="showLogs()">
                                <div class="card-icon">
                                    <i class="fas fa-file-alt"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Ver Logs</h3>
                                    <p class="card-value">Visualizar</p>
                                </div>
                            </div>
                            <div class="info-card" onclick="backupAllSites()">
                                <div class="card-icon">
                                    <i class="fas fa-download"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Backup Geral</h3>
                                    <p class="card-value">Salvar</p>
                                </div>
                            </div>
                            <div class="info-card" onclick="showSettings()">
                                <div class="card-icon">
                                    <i class="fas fa-cog"></i>
                                </div>
                                <div class="card-content">
                                    <h3>Configurações</h3>
                                    <p class="card-value">Ajustar</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- WordPress Sites -->
            <section class="dashboard-section">
                <div class="section-header">
                    <h2 class="section-title">
                        <i class="fab fa-wordpress"></i>
                        Sites WordPress
                    </h2>
                    <button class="btn btn-success" onclick="createNewWordPressSite()">
                        <i class="fas fa-plus"></i>
                        Novo Site WordPress
                    </button>
                </div>
                <div class="sites-container" id="wordpress-sites-container">
                    <div class="loading-spinner">
                        <i class="fas fa-spinner fa-spin"></i>
                        <p>Carregando sites WordPress...</p>
                    </div>
                </div>
            </section>

            <!-- PHP Sites -->
            <section class="dashboard-section">
                <div class="section-header">
                    <h2 class="section-title">
                        <i class="fab fa-php"></i>
                        Sites PHP
                    </h2>
                    <button class="btn btn-primary" onclick="createNewPhpSite()">
                        <i class="fas fa-plus"></i>
                        Novo Site PHP
                    </button>
                </div>
                <div class="sites-container" id="php-sites-container">
                    <div class="loading-spinner">
                        <i class="fas fa-spinner fa-spin"></i>
                        <p>Carregando sites PHP...</p>
                    </div>
                </div>
            </section>
        </main>

        <!-- Footer -->
        <footer class="dashboard-footer">
            <p>&copy; 2025 Thiago Macêdo - WordPress Development Dashboard</p>
        </footer>
    </div>

    <!-- Modals -->
    <div id="modal-overlay" class="modal-overlay" onclick="closeModal()">
        <div class="modal-content" onclick="event.stopPropagation()">
            <div class="modal-header">
                <h3 id="modal-title">Modal</h3>
                <button class="modal-close" onclick="closeModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body" id="modal-body">
                <!-- Modal content will be inserted here -->
            </div>
        </div>
    </div>

    <script src="assets/js/dashboard.js"></script>
</body>
</html> 