// Dashboard JavaScript
class WordPressDashboard {
    constructor() {
        this.init();
    }

    init() {
        this.loadSystemInfo();
        this.loadSites();
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Auto-refresh every 30 seconds
        setInterval(() => {
            this.loadSystemInfo();
            this.loadSites();
        }, 30000);
    }

    async loadSystemInfo() {
        try {
            const response = await fetch('api/system-info.php');
            const data = await response.json();
            
            if (data.success) {
                this.updateSystemCards(data.data);
            }
        } catch (error) {
            console.error('Erro ao carregar informações do sistema:', error);
        }
    }

    updateSystemCards(data) {
        // CPU Info
        const cpuInfo = document.getElementById('cpu-info');
        if (cpuInfo) {
            cpuInfo.textContent = `${data.cpu.model} (${data.cpu.cores} cores)`;
        }

        // Memory Info
        const memoryInfo = document.getElementById('memory-info');
        if (memoryInfo) {
            const usedPercent = Math.round((data.memory.used / data.memory.total) * 100);
            memoryInfo.textContent = `${this.formatBytes(data.memory.used)} / ${this.formatBytes(data.memory.total)} (${usedPercent}%)`;
        }

        // Disk Info
        const diskInfo = document.getElementById('disk-info');
        if (diskInfo) {
            const usedPercent = Math.round((data.disk.used / data.disk.total) * 100);
            diskInfo.textContent = `${this.formatBytes(data.disk.used)} / ${this.formatBytes(data.disk.total)} (${usedPercent}%)`;
        }

        // Network Info
        const networkInfo = document.getElementById('network-info');
        if (networkInfo) {
            networkInfo.textContent = `${data.network.interfaces} interfaces ativas`;
        }
    }

    async loadSites() {
        try {
            const response = await fetch('api/sites.php');
            const data = await response.json();
            
            if (data.success) {
                this.updateSitesContainer(data.sites);
            } else {
                this.showError('Erro ao carregar sites: ' + data.message);
            }
        } catch (error) {
            console.error('Erro ao carregar sites:', error);
            this.showError('Erro de conexão ao carregar sites');
        }
    }

    updateSitesContainer(sites) {
        const container = document.getElementById('sites-container');
        
        if (!sites || sites.length === 0) {
            container.innerHTML = `
                <div class="text-center" style="grid-column: 1 / -1; padding: 3rem;">
                    <i class="fas fa-folder-open" style="font-size: 3rem; color: var(--medium-gray); margin-bottom: 1rem;"></i>
                    <h3>Nenhum site encontrado</h3>
                    <p class="text-muted">Crie seu primeiro site WordPress para começar</p>
                    <button class="btn btn-primary" onclick="createNewSite()">
                        <i class="fas fa-plus"></i>
                        Criar Primeiro Site
                    </button>
                </div>
            `;
            return;
        }

        container.innerHTML = sites.map(site => this.createSiteCard(site)).join('');
    }

    createSiteCard(site) {
        const statusClass = site.active ? 'status-active' : 'status-inactive';
        const statusText = site.active ? 'Ativo' : 'Inativo';
        
        return `
            <div class="site-card">
                <div class="site-header">
                    <div class="site-name">${site.name}</div>
                    <span class="site-status ${statusClass}">${statusText}</span>
                </div>
                
                <div class="site-info">
                    <div class="site-info-item">
                        <span class="site-info-label">URL:</span>
                        <span class="site-info-value">${site.url}</span>
                    </div>
                </div>
                
                <div class="site-actions">
                    <a href="${site.url}" target="_blank" class="btn btn-primary">
                        <i class="fas fa-external-link-alt"></i>
                        Site
                    </a>
                    <a href="${site.url}/wp-admin" target="_blank" class="btn btn-success">
                        <i class="fas fa-cog"></i>
                        Admin
                    </a>
                    <button class="btn btn-warning" onclick="showSiteInfo('${site.name}')">
                        <i class="fas fa-info-circle"></i>
                        Info
                    </button>
                    <button class="btn btn-danger" onclick="deleteSite('${site.name}')">
                        <i class="fas fa-trash"></i>
                        Del
                    </button>
                </div>
            </div>
        `;
    }

    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    showError(message) {
        this.showModal('Erro', `
            <div class="text-center">
                <i class="fas fa-exclamation-triangle" style="font-size: 3rem; color: var(--danger); margin-bottom: 1rem;"></i>
                <p>${message}</p>
            </div>
        `);
    }

    showModal(title, content) {
        const modal = document.getElementById('modal-overlay');
        const modalTitle = document.getElementById('modal-title');
        const modalBody = document.getElementById('modal-body');
        
        modalTitle.textContent = title;
        modalBody.innerHTML = content;
        modal.classList.add('active');
    }
}

// Global Functions
function refreshData() {
    dashboard.loadSystemInfo();
    dashboard.loadSites();
    
    // Show refresh feedback
    const btn = event.target.closest('.btn');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<i class="fas fa-check"></i> Atualizado!';
    btn.style.background = 'var(--success)';
    
    setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.background = '';
    }, 2000);
}

function createNewSite() {
    dashboard.showModal('Criar Novo Site', `
        <form id="create-site-form">
            <div class="mb-2">
                <label for="site-name">Nome do Site:</label>
                <input type="text" id="site-name" name="site-name" required 
                       placeholder="ex: meu-site" class="form-control">
            </div>
            <div class="mb-3">
                <label for="site-domain">Domínio (opcional):</label>
                <input type="text" id="site-domain" name="site-domain" 
                       placeholder="localhost" class="form-control">
            </div>
            <div class="text-center">
                <button type="submit" class="btn btn-success">
                    <i class="fas fa-plus"></i>
                    Criar Site
                </button>
            </div>
        </form>
    `);
    
    document.getElementById('create-site-form').addEventListener('submit', handleCreateSite);
}

async function handleCreateSite(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const siteName = formData.get('site-name');
    const domain = formData.get('site-domain') || 'localhost';
    
    // Mostrar animação de loading
    const submitButton = event.target.querySelector('button[type="submit"]');
    const originalButtonContent = submitButton.innerHTML;
    
    submitButton.innerHTML = `
        <i class="fas fa-spinner fa-spin"></i>
        Criando Site...
    `;
    submitButton.disabled = true;
    
    try {
        const response = await fetch('api/create-site.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name: siteName, domain: domain })
        });
        
        const data = await response.json();
        
        if (data.success) {
            closeModal();
            dashboard.showModal('Sucesso', `
                <div class="text-center">
                    <i class="fas fa-check-circle" style="font-size: 3rem; color: var(--success); margin-bottom: 1rem;"></i>
                    <h3>Site criado com sucesso!</h3>
                    <p><strong>URL:</strong> ${data.site.url}</p>
                    <p><strong>Admin:</strong> ${data.site.url}/wp-admin</p>
                    <p><strong>Usuário:</strong> ${data.site.admin_user}</p>
                    <p><strong>Senha:</strong> ${data.site.admin_password}</p>
                </div>
            `);
            dashboard.loadSites();
        } else {
            dashboard.showError(data.message);
        }
    } catch (error) {
        dashboard.showError('Erro ao criar site: ' + error.message);
    } finally {
        // Restaurar botão original
        submitButton.innerHTML = originalButtonContent;
        submitButton.disabled = false;
    }
}

function showSiteInfo(siteName) {
    fetch(`api/site-info.php?name=${encodeURIComponent(siteName)}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                const site = data.site;
                dashboard.showModal(`Informações do Site: ${site.name}`, `
                    <div class="site-info-details">
                        <div class="info-group">
                            <h4>Informações Gerais</h4>
                            <p><strong>URL:</strong> ${site.url}</p>
                            <p><strong>Porta:</strong> ${site.port}</p>
                            <p><strong>Diretório:</strong> ${site.directory}</p>
                            <p><strong>Status:</strong> <span class="site-status ${site.active ? 'status-active' : 'status-inactive'}">${site.active ? 'Ativo' : 'Inativo'}</span></p>
                        </div>
                        
                        <div class="info-group">
                            <h4>Banco de Dados</h4>
                            <p><strong>Database:</strong> ${site.database.name}</p>
                            <p><strong>Usuário:</strong> ${site.database.user}</p>
                            <p><strong>Senha:</strong> ${site.database.password || 'Não disponível'}</p>
                            <p><strong>Host:</strong> ${site.database.host}</p>
                        </div>
                        
                        <div class="info-group">
                            <h4>Administrador</h4>
                            <p><strong>Usuário:</strong> ${site.admin.user}</p>
                            <p><strong>Senha:</strong> ${site.admin.password || 'Não disponível'}</p>
                            <p><strong>Email:</strong> ${site.admin.email}</p>
                        </div>
                        
                        <div class="text-center mt-3">
                            <a href="${site.url}" target="_blank" class="btn btn-primary">
                                <i class="fas fa-external-link-alt"></i>
                                Acessar Site
                            </a>
                            <a href="${site.url}/wp-admin" target="_blank" class="btn btn-success">
                                <i class="fas fa-cog"></i>
                                Painel Admin
                            </a>
                        </div>
                    </div>
                `);
            } else {
                dashboard.showError(data.message);
            }
        })
        .catch(error => {
            dashboard.showError('Erro ao carregar informações do site');
        });
}

function deleteSite(siteName) {
    if (confirm(`Tem certeza que deseja deletar o site "${siteName}"? Esta ação não pode ser desfeita.`)) {
        fetch('api/delete-site.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name: siteName })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                dashboard.showModal('Sucesso', `
                    <div class="text-center">
                        <i class="fas fa-check-circle" style="font-size: 3rem; color: var(--success); margin-bottom: 1rem;"></i>
                        <h3>Site deletado com sucesso!</h3>
                        <p>O site "${siteName}" foi removido do sistema.</p>
                    </div>
                `);
                dashboard.loadSites();
            } else {
                dashboard.showError(data.message);
            }
        })
        .catch(error => {
            dashboard.showError('Erro ao deletar site');
        });
    }
}

function showSystemStatus() {
    dashboard.showModal('Status do Sistema', `
        <div class="system-status">
            <div class="status-item">
                <i class="fas fa-server"></i>
                <span>Nginx: <span class="status-active">Ativo</span></span>
            </div>
            <div class="status-item">
                <i class="fas fa-database"></i>
                <span>MySQL: <span class="status-active">Ativo</span></span>
            </div>
            <div class="status-item">
                <i class="fas fa-code"></i>
                <span>PHP-FPM: <span class="status-active">Ativo</span></span>
            </div>
            <div class="status-item">
                <i class="fas fa-shield-alt"></i>
                <span>Firewall: <span class="status-active">Ativo</span></span>
            </div>
        </div>
    `);
}

function showLogs() {
    dashboard.showModal('Logs do Sistema', `
        <div class="logs-container">
            <div class="log-section">
                <h4>Nginx Error Log</h4>
                <pre class="log-content">Carregando logs...</pre>
            </div>
            <div class="log-section">
                <h4>MySQL Log</h4>
                <pre class="log-content">Carregando logs...</pre>
            </div>
        </div>
    `);
    
    // Load logs asynchronously
    loadLogs();
}

async function loadLogs() {
    try {
        const response = await fetch('api/logs.php');
        const data = await response.json();
        
        if (data.success) {
            const logContents = document.querySelectorAll('.log-content');
            if (logContents[0]) logContents[0].textContent = data.logs.nginx || 'Nenhum log disponível';
            if (logContents[1]) logContents[1].textContent = data.logs.mysql || 'Nenhum log disponível';
        }
    } catch (error) {
        console.error('Erro ao carregar logs:', error);
    }
}

function backupAllSites() {
    dashboard.showModal('Backup Geral', `
        <div class="text-center">
            <i class="fas fa-download" style="font-size: 3rem; color: var(--primary-blue); margin-bottom: 1rem;"></i>
            <h3>Iniciando backup de todos os sites...</h3>
            <p>Esta operação pode demorar alguns minutos.</p>
            <div class="progress-bar">
                <div class="progress-fill"></div>
            </div>
        </div>
    `);
    
    // Simulate backup process
    simulateBackup();
}

function simulateBackup() {
    const progressFill = document.querySelector('.progress-fill');
    let progress = 0;
    
    const interval = setInterval(() => {
        progress += 10;
        progressFill.style.width = progress + '%';
        
        if (progress >= 100) {
            clearInterval(interval);
            setTimeout(() => {
                dashboard.showModal('Backup Concluído', `
                    <div class="text-center">
                        <i class="fas fa-check-circle" style="font-size: 3rem; color: var(--success); margin-bottom: 1rem;"></i>
                        <h3>Backup concluído com sucesso!</h3>
                        <p>Todos os sites foram salvos em /opt/webhost/backups/</p>
                    </div>
                `);
            }, 500);
        }
    }, 200);
}

function showSettings() {
    dashboard.showModal('Configurações', `
        <div class="settings-form">
            <div class="setting-group">
                <h4>Configurações Gerais</h4>
                <div class="setting-item">
                    <label>Auto-refresh (segundos):</label>
                    <input type="number" value="30" min="10" max="300">
                </div>
                <div class="setting-item">
                    <label>Porta padrão inicial:</label>
                    <input type="number" value="9001" min="1000" max="9999">
                </div>
            </div>
            
            <div class="setting-group">
                <h4>Notificações</h4>
                <div class="setting-item">
                    <label>
                        <input type="checkbox" checked> Mostrar notificações de sistema
                    </label>
                </div>
                <div class="setting-item">
                    <label>
                        <input type="checkbox" checked> Alertas de uso de recursos
                    </label>
                </div>
            </div>
            
            <div class="text-center mt-3">
                <button class="btn btn-primary">Salvar Configurações</button>
            </div>
        </div>
    `);
}

function closeModal() {
    const modal = document.getElementById('modal-overlay');
    modal.classList.remove('active');
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new WordPressDashboard();
});

// Close modal when clicking outside
document.addEventListener('click', (event) => {
    const modal = document.getElementById('modal-overlay');
    if (event.target === modal) {
        closeModal();
    }
});

// Close modal with Escape key
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        closeModal();
    }
}); 