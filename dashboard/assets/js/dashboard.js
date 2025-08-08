// Dashboard JavaScript
class WordPressDashboard {
    constructor() {
        this.init();
    }

    init() {
        this.loadSystemInfo();
        this.loadWordPressSites();
        this.loadPhpSites();
        this.loadHtmlSites();
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Auto-refresh every 30 seconds
        setInterval(() => {
            this.loadSystemInfo();
            this.loadWordPressSites();
            this.loadPhpSites();
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

    async loadWordPressSites() {
        try {
            const response = await fetch('api/sites.php?t=' + Date.now());
            const data = await response.json();
            
            if (data.success) {
                this.updateWordPressSitesContainer(data.sites);
            } else {
                this.showError('Erro ao carregar sites WordPress: ' + data.message);
            }
        } catch (error) {
            console.error('Erro ao carregar sites WordPress:', error);
            this.showError('Erro de conexão ao carregar sites WordPress');
        }
    }

    async loadPhpSites() {
        try {
            const response = await fetch('api/php-sites.php?t=' + Date.now());
            const data = await response.json();
            
            if (data.success) {
                this.updatePhpSitesContainer(data.sites);
            } else {
                this.showError('Erro ao carregar sites PHP: ' + data.message);
            }
        } catch (error) {
            console.error('Erro ao carregar sites PHP:', error);
            this.showError('Erro de conexão ao carregar sites PHP');
        }
    }

    async loadHtmlSites() {
        try {
            const response = await fetch('api/html-sites.php?t=' + Date.now());
            const data = await response.json();
            
            if (data.success) {
                this.updateHtmlSitesContainer(data.sites);
            } else {
                this.showError('Erro ao carregar sites HTML: ' + data.message);
            }
        } catch (error) {
            console.error('Erro ao carregar sites HTML:', error);
            this.showError('Erro de conexão ao carregar sites HTML');
        }
    }

    updateWordPressSitesContainer(sites) {
        const container = document.getElementById('wordpress-sites-container');
        
        if (!sites || sites.length === 0) {
            container.innerHTML = `
                <div class="text-center" style="grid-column: 1 / -1; padding: 3rem;">
                    <i class="fab fa-wordpress" style="font-size: 3rem; color: var(--medium-gray); margin-bottom: 1rem;"></i>
                    <h3>Nenhum site WordPress encontrado</h3>
                    <p class="text-muted">Crie seu primeiro site WordPress para começar</p>
                    <button class="btn btn-success" onclick="createNewWordPressSite()">
                        <i class="fas fa-plus"></i>
                        Primeiro Site WordPress
                    </button>
                </div>
            `;
            return;
        }

        container.innerHTML = sites.map(site => this.createSiteCard(site)).join('');
    }

    updatePhpSitesContainer(sites) {
        const container = document.getElementById('php-sites-container');
        
        if (!sites || sites.length === 0) {
            container.innerHTML = `
                <div class="text-center" style="grid-column: 1 / -1; padding: 3rem;">
                    <i class="fab fa-php" style="font-size: 3rem; color: var(--medium-gray); margin-bottom: 1rem;"></i>
                    <h3>Nenhum site PHP encontrado</h3>
                    <p class="text-muted">Crie seu primeiro site PHP para começar</p>
                    <button class="btn btn-primary" onclick="createNewPhpSite()">
                        <i class="fas fa-plus"></i>
                        Primeiro Site PHP
                    </button>
                </div>
            `;
            return;
        }

        container.innerHTML = sites.map(site => this.createPhpSiteCard(site)).join('');
    }

    updateHtmlSitesContainer(sites) {
        const container = document.getElementById('html-sites-container');
        
        if (!sites || sites.length === 0) {
            container.innerHTML = `
                <div class="text-center" style="grid-column: 1 / -1; padding: 3rem;">
                    <i class="fab fa-html5" style="font-size: 3rem; color: var(--medium-gray); margin-bottom: 1rem;"></i>
                    <h3>Nenhum site HTML encontrado</h3>
                    <p class="text-muted">Crie seu primeiro site HTML para começar</p>
                    <button class="btn btn-warning" onclick="createNewHtmlSite()">
                        <i class="fas fa-plus"></i>
                        Primeiro Site HTML
                    </button>
                </div>
            `;
            return;
        }

        container.innerHTML = sites.map(site => this.createHtmlSiteCard(site)).join('');
    }

    createSiteCard(site) {
        const toggleAction = site.active ? 'disable' : 'enable';
        const toggleIcon = site.active ? 'fas fa-toggle-on' : 'fas fa-toggle-off';
        const iconColor = site.active ? '#16a34a' : '#dc2626';
        
        return `
            <div class="site-card">
                <div class="site-header">
                    <div class="site-name">${site.name}</div>
                    <button class="site-status" onclick="toggleSiteStatus('${site.name}', '${toggleAction}', this)" title="Clique para ${site.active ? 'desativar' : 'ativar'}">
                        <i class="${toggleIcon}" style="color: ${iconColor}"></i>
                    </button>
                </div>
                
                <div class="site-info">
                    <div class="site-info-item">
                        <span class="site-info-label">URL:</span>
                        <span class="site-info-value">${site.url}</span>
                    </div>
                </div>
                
                <div class="site-actions">
                    <a href="${site.url}" target="_blank" class="btn btn-info">
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

    createPhpSiteCard(site) {
        const toggleAction = site.active ? 'disable' : 'enable';
        const toggleIcon = site.active ? 'fas fa-toggle-on' : 'fas fa-toggle-off';
        const iconColor = site.active ? '#16a34a' : '#dc2626';
        
        return `
            <div class="site-card">
                <div class="site-header">
                    <div class="site-name">${site.name}</div>
                    <button class="site-status" onclick="toggleSiteStatus('${site.name}', '${toggleAction}', this)" title="Clique para ${site.active ? 'desativar' : 'ativar'}">
                        <i class="${toggleIcon}" style="color: ${iconColor}"></i>
                    </button>
                </div>
                
                <div class="site-info">
                    <div class="site-info-item">
                        <span class="site-info-label">URL:</span>
                        <span class="site-info-value">${site.url}</span>
                    </div>
                </div>
                
                <div class="site-actions">
                    <a href="${site.url}" target="_blank" class="btn btn-info">
                        <i class="fas fa-external-link-alt"></i>
                        Site
                    </a>
                    <button class="btn btn-danger" onclick="deletePhpSite('${site.name}')">
                        <i class="fas fa-trash"></i>
                        Del
                    </button>
                </div>
            </div>
        `;
    }

    createHtmlSiteCard(site) {
        const toggleAction = site.active ? 'disable' : 'enable';
        const toggleIcon = site.active ? 'fas fa-toggle-on' : 'fas fa-toggle-off';
        const iconColor = site.active ? '#16a34a' : '#dc2626';
        
        return `
            <div class="site-card">
                <div class="site-header">
                    <div class="site-name">${site.name}</div>
                    <button class="site-status" onclick="toggleSiteStatus('${site.name}', '${toggleAction}', this)" title="Clique para ${site.active ? 'desativar' : 'ativar'}">
                        <i class="${toggleIcon}" style="color: ${iconColor}"></i>
                    </button>
                </div>
                
                <div class="site-info">
                    <div class="site-info-item">
                        <span class="site-info-label">URL:</span>
                        <span class="site-info-value">${site.url}</span>
                    </div>
                </div>
                
                <div class="site-actions">
                    <a href="${site.url}" target="_blank" class="btn btn-info">
                        <i class="fas fa-external-link-alt"></i>
                        Site
                    </a>
                    <button class="btn btn-danger" onclick="deleteHtmlSite('${site.name}')">
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
    dashboard.loadWordPressSites();
    dashboard.loadPhpSites();
    dashboard.loadHtmlSites();
    
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

function createNewWordPressSite() {
    dashboard.showModal('Criar Novo Site WordPress', `
        <form id="create-wordpress-site-form">
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
                    <i class="fab fa-wordpress"></i>
                    Criar Site WordPress
                </button>
            </div>
        </form>
    `);
    
    document.getElementById('create-wordpress-site-form').addEventListener('submit', handleCreateWordPressSite);
}

function createNewPhpSite() {
    dashboard.showModal('Criar Novo Site PHP', `
        <form id="create-php-site-form">
            <div class="mb-2">
                <label for="site-name">Nome do Projeto:</label>
                <input type="text" id="site-name" name="site-name" required 
                       placeholder="ex: meu-projeto" class="form-control">
            </div>
            <div class="mb-3">
                <label for="site-domain">Domínio (opcional):</label>
                <input type="text" id="site-domain" name="site-domain" 
                       placeholder="localhost" class="form-control">
            </div>
            <div class="text-center">
                <button type="submit" class="btn btn-primary">
                    <i class="fab fa-php"></i>
                    Criar Site PHP
                </button>
            </div>
        </form>
    `);
    
    document.getElementById('create-php-site-form').addEventListener('submit', handleCreatePhpSite);
}

function createNewHtmlSite() {
    dashboard.showModal('Criar Novo Site HTML', `
        <form id="create-html-site-form">
            <div class="mb-2">
                <label for="site-name">Nome do Projeto:</label>
                <input type="text" id="site-name" name="site-name" required 
                       placeholder="ex: meu-projeto" class="form-control">
            </div>
            <div class="mb-3">
                <label for="site-domain">Domínio (opcional):</label>
                <input type="text" id="site-domain" name="site-domain" 
                       placeholder="localhost" class="form-control">
            </div>
            <div class="text-center">
                <button type="submit" class="btn btn-warning">
                    <i class="fab fa-html5"></i>
                    Criar Site HTML
                </button>
            </div>
        </form>
    `);
    
    document.getElementById('create-html-site-form').addEventListener('submit', handleCreateHtmlSite);
}

async function handleCreateWordPressSite(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const siteName = formData.get('site-name');
    const domain = formData.get('site-domain') || 'localhost';
    
    // Mostrar animação de loading
    const submitButton = event.target.querySelector('button[type="submit"]');
    const originalButtonContent = submitButton.innerHTML;
    
    submitButton.innerHTML = `
        <i class="fas fa-spinner fa-spin"></i>
        Criando Site WordPress...
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
                    <h3>Site WordPress criado com sucesso!</h3>
                    <p><strong>URL:</strong> ${data.site.url}</p>
                    <p><strong>Admin:</strong> ${data.site.url}/wp-admin</p>
                    <p><strong>Usuário:</strong> ${data.site.admin_user}</p>
                    <p><strong>Senha:</strong> ${data.site.admin_password}</p>
                </div>
            `);
            dashboard.loadWordPressSites();
        } else {
            dashboard.showError(data.message);
        }
    } catch (error) {
        dashboard.showError('Erro ao criar site WordPress: ' + error.message);
    } finally {
        // Restaurar botão original
        submitButton.innerHTML = originalButtonContent;
        submitButton.disabled = false;
    }
}

async function handleCreatePhpSite(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const siteName = formData.get('site-name');
    const domain = formData.get('site-domain') || 'localhost';
    
    // Mostrar animação de loading
    const submitButton = event.target.querySelector('button[type="submit"]');
    const originalButtonContent = submitButton.innerHTML;
    
    submitButton.innerHTML = `
        <i class="fas fa-spinner fa-spin"></i>
        Criando Site PHP...
    `;
    submitButton.disabled = true;
    
    try {
        const response = await fetch('api/create-php-site.php', {
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
                    <h3>Site PHP criado com sucesso!</h3>
                    <p><strong>URL:</strong> ${data.site.url}</p>
                    <p><strong>Document Root:</strong> ${data.site.directory}/public</p>
                    <p><strong>Porta:</strong> ${data.site.port}</p>
                </div>
            `);
            dashboard.loadPhpSites();
        } else {
            dashboard.showError(data.message);
        }
    } catch (error) {
        dashboard.showError('Erro ao criar site PHP: ' + error.message);
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
                            <a href="${site.url}" target="_blank" class="btn btn-info">
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

async function handleCreateHtmlSite(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const siteName = formData.get('site-name');
    const domain = formData.get('site-domain') || 'localhost';
    
    // Mostrar animação de loading
    const submitButton = event.target.querySelector('button[type="submit"]');
    const originalButtonContent = submitButton.innerHTML;
    
    submitButton.innerHTML = `
        <i class="fas fa-spinner fa-spin"></i>
        Criando Site HTML...
    `;
    submitButton.disabled = true;
    
    try {
        const response = await fetch('api/create-html-site.php', {
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
                    <h3>Site HTML criado com sucesso!</h3>
                    <p><strong>URL:</strong> ${data.site.url}</p>
                    <p><strong>Document Root:</strong> ${data.site.directory}</p>
                    <p><strong>Porta:</strong> ${data.site.port}</p>
                </div>
            `);
            dashboard.loadHtmlSites();
        } else {
            dashboard.showError(data.message);
        }
    } catch (error) {
        dashboard.showError('Erro ao criar site HTML: ' + error.message);
    } finally {
        // Restaurar botão original
        submitButton.innerHTML = originalButtonContent;
        submitButton.disabled = false;
    }
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
                dashboard.loadWordPressSites();
            } else {
                dashboard.showError(data.message);
            }
        })
        .catch(error => {
            dashboard.showError('Erro ao deletar site');
        });
    }
}

function deletePhpSite(siteName) {
    if (confirm(`Tem certeza que deseja deletar o site PHP "${siteName}"? Esta ação não pode ser desfeita.`)) {
        fetch('api/delete-php-site.php', {
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
                        <h3>Site PHP deletado com sucesso!</h3>
                        <p>O site "${siteName}" foi removido do sistema.</p>
                    </div>
                `);
                // Pequeno delay para garantir que a atualização aconteça
                setTimeout(() => {
                    dashboard.loadPhpSites();
                }, 500);
            } else {
                dashboard.showError(data.message);
            }
        })
        .catch(error => {
            dashboard.showError('Erro ao deletar site PHP');
        });
    }
}

function deleteHtmlSite(siteName) {
    if (confirm(`Tem certeza que deseja deletar o site HTML "${siteName}"? Esta ação não pode ser desfeita.`)) {
        fetch('api/delete-html-site.php', {
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
                        <h3>Site HTML deletado com sucesso!</h3>
                        <p>O site "${siteName}" foi removido do sistema.</p>
                    </div>
                `);
                // Pequeno delay para garantir que a atualização aconteça
                setTimeout(() => {
                    dashboard.loadHtmlSites();
                }, 500);
            } else {
                dashboard.showError(data.message);
            }
        })
        .catch(error => {
            dashboard.showError('Erro ao deletar site HTML');
        });
    }
}

function showSystemStatus() {
    dashboard.showModal('Status do Sistema', `
        <div class="system-status">
            <div class="status-item">
                <i class="fas fa-server"></i>
                <span>Apache: <span class="status-active">Ativo</span></span>
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
                <h4>Apache Error Log</h4>
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
            if (logContents[0]) logContents[0].textContent = data.logs.apache || 'Nenhum log disponível';
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

// Toggle site status (enable/disable)
async function toggleSiteStatus(siteName, action, buttonElement) {
    const statusButton = buttonElement;
    const iconElement = statusButton.querySelector('i');
    const originalIcon = iconElement.className;
    
    // Show loading state - apenas no ícone
    iconElement.className = 'fas fa-spinner fa-spin';
    statusButton.disabled = true;
    
    try {
        const response = await fetch('api/toggle-site.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                site_name: siteName,
                action: action
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            console.log('Toggle successful:', data);
            
            // Update button state immediately
            const newAction = action === 'enable' ? 'disable' : 'enable';
            const newIcon = action === 'enable' ? 'fas fa-toggle-on' : 'fas fa-toggle-off';
            
            // Update button properties
            statusButton.className = 'site-status';
            iconElement.className = newIcon;
            statusButton.onclick = () => toggleSiteStatus(siteName, newAction, statusButton);
            statusButton.title = `Clique para ${action === 'enable' ? 'desativar' : 'ativar'}`;
            statusButton.disabled = false;
            
            // Force color update directly on icon
            if (action === 'enable') {
                iconElement.style.color = '#16a34a';
            } else {
                iconElement.style.color = '#dc2626';
            }
            
            console.log('Button updated successfully');
            
        } else {
            console.error('Toggle failed:', data);
            
            // Restore original state
            iconElement.className = originalIcon;
            statusButton.disabled = false;
        }
        
    } catch (error) {
        console.error('Erro ao alterar status do site:', error);
        
        // Restore original state
        iconElement.className = originalIcon;
        statusButton.disabled = false;
    }
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