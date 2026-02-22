// js/app.js
// Main application. Imports api.js functions; all render functions are async.
// Loaded as ES module in index.html.

import * as api from './api.js';

// ─────────────────────────────────────────────────────────────────
// BOOT
// ─────────────────────────────────────────────────────────────────

let currentUser = null;
let currentTenant = { name: 'ČEZ Distribuce, a.s.' };

// Demo users — no Supabase auth required
const DEMO_USERS = {
  'admin@energo.cz':    { full_name: 'Jan Novák',   role: 'Administrátor' },
  'operator@energo.cz': { full_name: 'Eva Marková',  role: 'Operátor' },
  'odectare@energo.cz': { full_name: 'Pavel Kříž',   role: 'Odečtář' },
};

async function boot() {
  // Skip auth — go straight to app
  enterApp('Jan Novák', 'Administrátor');
}

// ─────────────────────────────────────────────────────────────────
// AUTH
// ─────────────────────────────────────────────────────────────────

function enterApp(name, role) {
  // Hide login popup
  const ls = document.getElementById('login-screen');
  ls.style.opacity = '0';
  ls.style.transition = 'opacity .25s ease';
  setTimeout(() => { ls.style.display = 'none'; ls.style.opacity = ''; ls.style.transition = ''; }, 260);

  // Set user info in sidebar
  const initials = name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();
  document.getElementById('user-avatar').textContent = initials;
  document.getElementById('user-name').textContent   = name;
  document.getElementById('user-role').textContent   = role;

  nav('dashboard');
}

window.doLogin = function () {
  const email = document.getElementById('email-input').value.trim();
  const btn   = document.querySelector('#login-screen .btn-primary');

  btn.disabled = true;
  btn.textContent = 'Přihlašuji…';

  setTimeout(() => {
    const u = DEMO_USERS[email] || { full_name: email || 'Uživatel', role: 'Uživatel' };
    enterApp(u.full_name, u.role);
  }, 400);
};

window.doLogout = function () {
  const ls = document.getElementById('login-screen');
  ls.style.display = 'flex';
  ls.style.opacity = '1';
  // Reset button
  const btn = document.querySelector('#login-screen .btn-primary');
  if (btn) { btn.disabled = false; btn.textContent = 'Přihlásit se →'; }
};

window.setDemo = function (role) {
  const map = {
    admin:    'admin@energo.cz',
    operator: 'operator@energo.cz',
    reader:   'odectare@energo.cz',
  };
  const el = document.getElementById('email-input');
  if (el && map[role]) el.value = map[role];
};

// ─────────────────────────────────────────────────────────────────
// NAVIGATION
// ─────────────────────────────────────────────────────────────────

const SCREEN_TITLES = {
  dashboard: ['Dashboard', 'Přehled systému'],
  customers: ['Zákazníci', 'Správa zákazníků'],
  contracts: ['Smlouvy', 'Správa smluv a OPM'],
  meters:    ['Měřidla & Odečty', 'AMR/AMI dálkový odečet'],
  invoices:  ['Faktury', 'Fakturace a vyúčtování'],
  advances:  ['Zálohy', 'Rozpis zálohových plateb'],
  payments:  ['Platby & Párování', 'Bankovní výpisy a párování'],
  runt:      ['RÚNT – Teplo', 'Rozúčtování nákladů na teplo'],
  reporting: ['Reporting', 'Výkazy a analýzy'],
  admin:     ['Administrace', 'Systémová nastavení'],
};

window.nav = function (screen) {
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  const active = document.querySelector(`.nav-item[onclick*="'${screen}'"]`);
  if (active) active.classList.add('active');

  const [title, sub] = SCREEN_TITLES[screen] || [screen, ''];
  document.getElementById('topbar-title').textContent = title;
  document.getElementById('topbar-sub').textContent =
    `${currentTenant.name} · ${sub}`;

  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.querySelectorAll(`[data-screen="${screen}"]`).forEach(s =>
    s.classList.add('active'));

  const renders = {
    dashboard: renderDashboard,
    customers: renderCustomers,
    contracts: renderContracts,
    meters:    renderMeters,
    invoices:  renderInvoices,
    advances:  renderAdvances,
    payments:  renderPayments,
    runt:      renderRunt,
    reporting: renderReporting,
    admin:     renderAdmin,
  };
  const fn = renders[screen];
  if (fn) fn();
};

// ─────────────────────────────────────────────────────────────────
// LOADING / ERROR HELPERS
// ─────────────────────────────────────────────────────────────────

function setContent(html) {
  document.getElementById('content').innerHTML = html;
}

function loadingState(msg = 'Načítám data…') {
  return `<div class="loading-state"><div class="spinner"></div><span>${msg}</span></div>`;
}

function errorState(msg) {
  return `<div class="empty-state"><div class="icon">⚠️</div><p>${msg}</p>
    <button class="btn btn-outline btn-sm" onclick="nav('${currentScreen}')">Zkusit znovu</button></div>`;
}

let currentScreen = 'dashboard';

// ─────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────

async function renderDashboard() {
  currentScreen = 'dashboard';
  setContent(loadingState('Načítám přehled…'));

  let kpi, activity;
  try {
    [kpi, activity] = await Promise.all([
      api.getDashboardKpis().catch(() => null),
      api.getDashboardActivity().catch(() => []),
    ]);
  } catch (e) {
    setContent(errorState('Nepodařilo se načíst dashboard: ' + e.message));
    return;
  }

  // Fallback to prototype values if view not yet created
  const k = kpi || {
    active_customers: 4180, active_contracts: 6240,
    invoiced_ytd_m: 84.2, collected_ytd_m: 79.1,
    overdue_count: 112, overdue_czk_m: 1.4,
    unmatched_payments: 12,
  };

  const act = activity.length ? activity : [
    { created_at: new Date().toISOString(), icon: '✅', title: 'Faktura FAK-2026-04812 zaplacena', detail: 'Karel Dvořák · 4 280 Kč' },
    { created_at: new Date().toISOString(), icon: '🔴', title: 'Měřidlo MET-EE-44230 offline', detail: 'Restaurace U Kohouta · >24h' },
    { created_at: new Date().toISOString(), icon: '📄', title: 'Dávka faktur vystavena', detail: '284 faktur · Únor 2026' },
    { created_at: new Date().toISOString(), icon: '💰', title: 'Import výpisu ČSOB', detail: '847 transakcí · 835 spárováno' },
  ];

  setContent(`
  <div class="kpi-grid">
    <div class="kpi-card blue">
      <div class="kpi-label">Aktivní zákazníci</div>
      <div class="kpi-value">${k.active_customers.toLocaleString('cs')}</div>
      <div class="kpi-sub">multikomoditní</div>
    </div>
    <div class="kpi-card green">
      <div class="kpi-label">Vyfakturováno YTD</div>
      <div class="kpi-value">${k.invoiced_ytd_m.toFixed(1)} M Kč</div>
      <div class="kpi-sub">Inkaso ${k.collected_ytd_m.toFixed(1)} M Kč</div>
    </div>
    <div class="kpi-card amber">
      <div class="kpi-label">Po splatnosti</div>
      <div class="kpi-value">${k.overdue_count.toLocaleString('cs')}</div>
      <div class="kpi-sub">${k.overdue_czk_m.toFixed(1)} M Kč · pohledávky</div>
    </div>
    <div class="kpi-card red">
      <div class="kpi-label">Nespárované platby</div>
      <div class="kpi-value">${k.unmatched_payments}</div>
      <div class="kpi-sub">čeká na párování</div>
    </div>
  </div>

  <div class="grid-main-side">
    <div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">Fakturace leden–únor 2026 (Kč)</div>
        </div>
        <canvas id="chart-main" height="130"></canvas>
      </div>
    </div>
    <div>
      <div class="card">
        <div class="card-header"><div class="card-title">Poslední aktivita</div></div>
        <div class="activity-list">
          ${act.map(a => `
            <div class="activity-item">
              <div class="activity-icon">${a.icon || '📋'}</div>
              <div>
                <div class="activity-title">${a.title}</div>
                <div class="activity-sub">${a.detail || ''}</div>
              </div>
            </div>`).join('')}
        </div>
      </div>
    </div>
  </div>`);

  // Draw chart
  new Chart(document.getElementById('chart-main'), {
    type: 'bar',
    data: {
      labels: ['EE','GAS','VODA','CZT'],
      datasets: [
        { label: 'Leden', data: [42100000, 8400000, 2100000, 12400000], backgroundColor: 'rgba(59,130,246,.7)' },
        { label: 'Únor',  data: [38800000, 7900000, 2300000, 11200000], backgroundColor: 'rgba(16,185,129,.7)' },
      ],
    },
    options: {
      responsive: true,
      plugins: { legend: { labels: { color: '#94A3C0', font: { size: 11 } } } },
      scales: {
        x: { ticks: { color: '#5A6E8C' }, grid: { color: 'rgba(255,255,255,.04)' } },
        y: { ticks: { color: '#5A6E8C', callback: v => (v/1e6).toFixed(1)+'M' }, grid: { color: 'rgba(255,255,255,.06)' } },
      },
    },
  });
}

// ─────────────────────────────────────────────────────────────────
// CUSTOMERS
// ─────────────────────────────────────────────────────────────────

let _customers = [];

async function renderCustomers() {
  currentScreen = 'customers';
  setContent(loadingState('Načítám zákazníky…'));

  try {
    _customers = await api.getCustomers();
  } catch (e) {
    setContent(errorState('Chyba načítání zákazníků: ' + e.message));
    return;
  }

  setContent(`
  <div class="filters-bar">
    <div class="search-box">
      <span class="search-icon">🔍</span>
      <input type="text" placeholder="Hledat zákazníka, IČ, adresu…" oninput="filterCustomers(this.value)">
    </div>
    <select class="filter-select" id="cust-status-filter" onchange="filterCustomers('')">
      <option value="">Všechny stavy</option>
      <option value="active">Aktivní</option>
      <option value="warning">Upomínka</option>
      <option value="blocked">Blokovaný</option>
    </select>
    <select class="filter-select">
      <option>Všechny komodity</option>
      <option>⚡ Elektřina</option><option>🔥 Plyn</option>
      <option>💧 Voda</option><option>♨️ Teplo</option>
    </select>
    <button class="btn btn-blue btn-sm" style="margin-left:auto" onclick="openNewCustomerModal()">+ Nový zákazník</button>
  </div>
  <div class="card">
    <div class="table-wrap">
      <table id="customers-table">
        <thead>
          <tr>
            <th>ID zákazníka</th><th>Název / Jméno</th><th>Typ</th>
            <th>Adresa</th><th>Komodity</th><th>Stav</th><th>Saldo</th><th>Riziko</th>
          </tr>
        </thead>
        <tbody id="customers-tbody"></tbody>
      </table>
    </div>
  </div>`);

  filterCustomers('');
}

window.filterCustomers = function (q) {
  const statusF = document.getElementById('cust-status-filter')?.value || '';
  const rows = _customers.filter(c =>
    (q === '' || (c.name || '').toLowerCase().includes(q.toLowerCase()) || (c.code || '').includes(q)) &&
    (statusF === '' || c.status === statusF)
  );

  const cmdColor = { EE:'badge-blue', GAS:'badge-amber', WATER:'badge-green', HEAT:'badge-red' };
  const cmdLabel = { EE:'⚡ EE', GAS:'🔥 GAS', WATER:'💧 H₂O', HEAT:'♨️ CZT' };
  const statusBadge = { active:'badge-green', warning:'badge-amber', blocked:'badge-red' };
  const statusLabel = { active:'● Aktivní', warning:'● Upomínka', blocked:'✕ Blokován' };
  const riskColor   = { low:'badge-green', medium:'badge-amber', high:'badge-red' };
  const riskLabel   = { low:'Nízké', medium:'Střední', high:'Vysoké' };

  const commodities = r => (r.customer_commodities || []).map(x => x.commodity);

  const tbody = document.getElementById('customers-tbody');
  if (!tbody) return;
  tbody.innerHTML = rows.map(r => {
    const cmds = commodities(r);
    const bal  = r.balance_czk || 0;
    const balStr = bal > 0 ? `+${bal.toLocaleString('cs')}` : bal.toLocaleString('cs');
    const balColor = bal > 0 ? 'var(--green)' : bal < 0 ? 'var(--red)' : 'var(--text3)';
    return `<tr onclick="openCustomerModal('${r.id}')">
      <td class="mono" style="color:var(--blue2)">${r.code || r.id}</td>
      <td style="font-weight:600">${r.name}</td>
      <td><span class="badge ${r.type==='PO'?'badge-violet':'badge-gray'}">${r.type}</span></td>
      <td style="color:var(--text2);font-size:12.5px">${r.address || '—'}</td>
      <td>${cmds.map(k => `<span class="badge ${cmdColor[k]||'badge-gray'}" style="margin-right:3px">${cmdLabel[k]||k}</span>`).join('')}</td>
      <td><span class="badge ${statusBadge[r.status]||'badge-gray'}">${statusLabel[r.status]||r.status}</span></td>
      <td class="mono" style="color:${balColor};font-weight:600">${balStr} Kč</td>
      <td><span class="badge ${riskColor[r.risk_level]||'badge-gray'}">${riskLabel[r.risk_level]||'—'}</span></td>
    </tr>`;
  }).join('');
};

window.openCustomerModal = async function (id) {
  openModal(`<div class="loading-state"><div class="spinner"></div></div>`);
  let c;
  try {
    c = await api.getCustomer(id);
  } catch (e) {
    openModal(`<div class="empty-state"><p>Chyba načítání: ${e.message}</p></div>`);
    return;
  }
  const bal = c.balance_czk || 0;
  const balStr = bal > 0 ? `+${bal.toLocaleString('cs')}` : bal.toLocaleString('cs');
  openModal(`
    <div class="modal-header">
      <div>
        <div class="modal-title">${c.name}</div>
        <div style="font-size:12px;color:var(--text3);font-family:var(--font-m);margin-top:2px">
          ${c.code || c.id} · ${c.type==='PO'?'Právnická osoba':'Fyzická osoba'}
        </div>
      </div>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="detail-row"><span class="detail-label">Adresa</span><span class="detail-value">${c.address||'—'}</span></div>
    <div class="detail-row"><span class="detail-label">Kontakt</span><span class="detail-value">${c.phone||'—'}</span></div>
    <div class="detail-row"><span class="detail-label">E-mail</span><span class="detail-value">${c.email||'—'}</span></div>
    <div class="detail-row"><span class="detail-label">Bankovní spojení</span><span class="detail-value mono">${c.bank_account||'—'}</span></div>
    <div class="detail-row"><span class="detail-label">Saldo účtu</span>
      <span class="detail-value" style="color:${bal<0?'var(--red)':'var(--green)'}">${balStr} Kč</span></div>
    <div style="display:flex;gap:8px;margin-top:20px">
      <button class="btn btn-blue" onclick="showToast('🧾','Nová faktura vytvořena','green');closeModal()">+ Faktura</button>
      <button class="btn btn-outline" onclick="showToast('📧','E-mail odeslán','blue');closeModal()">📧 Kontaktovat</button>
      <button class="btn btn-outline" onclick="nav('invoices');closeModal()">Faktury →</button>
    </div>`);
};

window.openNewCustomerModal = function () {
  openModal(`
    <div class="modal-header">
      <div class="modal-title">Nový zákazník</div>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="form-field"><label>Typ subjektu</label>
      <select class="filter-select" style="width:100%" id="nc-type"><option value="FO">Fyzická osoba</option><option value="PO">Právnická osoba / Firma</option></select></div>
    <div class="form-field"><label>Jméno / Název firmy</label>
      <input type="text" class="filter-select" style="width:100%" id="nc-name" placeholder="Karel Dvořák"></div>
    <div class="form-field"><label>Adresa</label>
      <input type="text" class="filter-select" style="width:100%" id="nc-address" placeholder="Jiráskova 14, Praha 2"></div>
    <div class="form-field"><label>E-mail</label>
      <input type="email" class="filter-select" style="width:100%" id="nc-email"></div>
    <button class="btn btn-blue" style="margin-top:8px" onclick="submitNewCustomer()">Uložit zákazníka →</button>`);
};

window.submitNewCustomer = async function () {
  const data = {
    type: document.getElementById('nc-type').value,
    name: document.getElementById('nc-name').value,
    address: document.getElementById('nc-address').value,
    email: document.getElementById('nc-email').value,
    status: 'active',
    risk_level: 'low',
    balance_czk: 0,
  };
  try {
    await api.upsertCustomer(data);
    showToast('✅', 'Zákazník uložen', 'green');
    closeModal();
    _customers = await api.getCustomers();
    filterCustomers('');
  } catch (e) {
    showToast('⚠️', 'Chyba: ' + e.message, 'red');
  }
};

// ─────────────────────────────────────────────────────────────────
// CONTRACTS
// ─────────────────────────────────────────────────────────────────

async function renderContracts() {
  currentScreen = 'contracts';
  setContent(loadingState('Načítám smlouvy…'));
  let contracts;
  try {
    contracts = await api.getContracts();
  } catch (e) {
    setContent(errorState('Chyba: ' + e.message)); return;
  }

  const sb = { active:'badge-green', expiring:'badge-amber', expired:'badge-red', draft:'badge-gray' };
  const sl = { active:'● Aktivní', expiring:'⚠ Expiruje', expired:'✕ Ukončena', draft:'Návrh' };
  const cb = { EE:'badge-blue', GAS:'badge-amber', WATER:'badge-green', HEAT:'badge-red' };
  const cl = { EE:'⚡ EE', GAS:'🔥 GAS', WATER:'💧 VODA', HEAT:'♨️ CZT' };

  setContent(`
  <div class="filters-bar">
    <div class="search-box"><span>🔍</span>
      <input type="text" placeholder="Hledat smlouvu, EAN, zákazníka…"></div>
    <select class="filter-select"><option>Všechny komodity</option>
      <option>EE</option><option>GAS</option><option>WATER</option><option>HEAT</option></select>
    <select class="filter-select"><option>Všechny stavy</option>
      <option>active</option><option>expiring</option><option>expired</option></select>
    <button class="btn btn-blue btn-sm" style="margin-left:auto"
      onclick="showToast('📄','Formulář nové smlouvy','blue')">+ Nová smlouva</button>
  </div>
  <div class="card">
    <div class="table-wrap">
      <table>
        <thead><tr><th>Číslo smlouvy</th><th>Zákazník</th><th>OPM / EAN</th><th>Komodita</th>
          <th>Tarif</th><th>Platnost od</th><th>Platnost do</th><th>Stav</th></tr></thead>
        <tbody>
          ${contracts.map(c => `<tr onclick="showToast('📄','Detail smlouvy ${c.contract_number}','blue')">
            <td class="mono" style="color:var(--blue2)">${c.contract_number}</td>
            <td style="font-weight:600">${c.customers?.name || '—'}</td>
            <td class="mono" style="font-size:12px;color:var(--text2)">${c.opm_id || '—'}</td>
            <td><span class="badge ${cb[c.commodity]||'badge-gray'}">${cl[c.commodity]||c.commodity}</span></td>
            <td class="mono">${c.tariff_code}</td>
            <td class="mono">${fmtDate(c.valid_from)}</td>
            <td class="mono">${fmtDate(c.valid_to)}</td>
            <td><span class="badge ${sb[c.status]||'badge-gray'}">${sl[c.status]||c.status}</span></td>
          </tr>`).join('')}
        </tbody>
      </table>
    </div>
  </div>`);
}

// ─────────────────────────────────────────────────────────────────
// METERS
// ─────────────────────────────────────────────────────────────────

let _meters = [];
let meterCommodityFilter = 'all';
let meterStatusFilter = '';
let meterSearchQ = '';

async function renderMeters() {
  currentScreen = 'meters';
  setContent(loadingState('Načítám měřidla…'));
  try {
    _meters = await api.getMeters();
  } catch (e) {
    setContent(errorState('Chyba: ' + e.message)); return;
  }

  setContent(`
  <div class="commodity-bar">
    <div class="commodity-chip active ee" onclick="filterMeters('all',this)">Vše</div>
    <div class="commodity-chip ee" onclick="filterMeters('EE',this)">⚡ Elektřina</div>
    <div class="commodity-chip gas" onclick="filterMeters('GAS',this)">🔥 Plyn</div>
    <div class="commodity-chip water" onclick="filterMeters('WATER',this)">💧 Voda</div>
    <div class="commodity-chip heat" onclick="filterMeters('HEAT',this)">♨️ Teplo</div>
  </div>
  <div class="filters-bar">
    <div class="search-box" style="max-width:300px">
      <span>🔍</span>
      <input type="text" placeholder="Hledat měřidlo, ID, EAN…" oninput="filterMeterSearch(this.value)">
    </div>
    <select class="filter-select" onchange="filterMeterStatus(this.value)">
      <option value="">Všechny stavy</option>
      <option value="online">Online</option>
      <option value="warning">Varování</option>
      <option value="offline">Offline</option>
    </select>
    <button class="btn btn-outline btn-sm" onclick="showToast('🗺️','Trasy odečtářů','blue')">🗺️ Odečtové trasy</button>
  </div>
  <div class="meter-grid" id="meter-grid"></div>`);

  renderMeterCards(_meters);
}

window.filterMeters = function (commodity, el) {
  meterCommodityFilter = commodity;
  document.querySelectorAll('.commodity-chip').forEach(c => c.classList.remove('active'));
  if (el) el.classList.add('active');
  applyMeterFilters();
};
window.filterMeterStatus = function (s) { meterStatusFilter = s; applyMeterFilters(); };
window.filterMeterSearch = function (q) { meterSearchQ = q; applyMeterFilters(); };

function applyMeterFilters() {
  const res = _meters.filter(m =>
    (meterCommodityFilter === 'all' || m.commodity === meterCommodityFilter) &&
    (meterStatusFilter === '' || m.meter_status === meterStatusFilter) &&
    (meterSearchQ === '' || m.meter_code.includes(meterSearchQ) ||
      (m.name || '').toLowerCase().includes(meterSearchQ.toLowerCase()))
  );
  renderMeterCards(res);
}

function renderMeterCards(meters) {
  const cIcons = { EE:'⚡', GAS:'🔥', WATER:'💧', HEAT:'♨️' };
  const sLabels = { online:'● Online', warning:'● Varování', offline:'✕ Offline' };
  const sBadge  = { online:'badge-green', warning:'badge-amber', offline:'badge-red' };
  document.getElementById('meter-grid').innerHTML = meters.map(m => `
    <div class="meter-card ${m.meter_status}" onclick="openMeterModal('${m.id}')">
      <div class="meter-header">
        <div>
          <div class="meter-id">${m.meter_code}</div>
          <div class="meter-name">${m.name}</div>
          <div class="meter-type">${m.meter_type}</div>
        </div>
        <div style="font-size:22px">${cIcons[m.commodity]||'📡'}</div>
      </div>
      <div class="meter-reading">
        <div class="meter-reading-val">${(m.current_reading||0).toLocaleString('cs')}</div>
        <div class="meter-reading-unit">${m.reading_unit||''}</div>
      </div>
      <div style="margin-bottom:8px">
        <span class="badge ${sBadge[m.meter_status]||'badge-gray'}">${sLabels[m.meter_status]||m.meter_status}</span>
        <span class="badge badge-gray" style="margin-left:4px">${m.ean_eic||'—'}</span>
      </div>
      <div class="meter-meta">
        <span>Odečet: ${fmtDateTime(m.last_read_at)}</span>
        <span>Kalibrace: ${m.calibration_date ? m.calibration_date.slice(0,7) : '—'}</span>
      </div>
    </div>`).join('');
}

window.openMeterModal = function (id) {
  const m = _meters.find(x => x.id === id);
  if (!m) return;
  openModal(`
    <div class="modal-header">
      <div>
        <div class="modal-title">${m.meter_code}</div>
        <div style="font-size:12px;color:var(--text3);font-family:var(--font-m);margin-top:2px">
          ${m.name} · ${m.meter_type}
        </div>
      </div>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    ${m.meter_status==='offline'?'<div class="alert red">🔴 Měřidlo je offline déle než 24 hodin. Zkontrolujte komunikační modul.</div>':''}
    ${m.meter_status==='warning'?'<div class="alert amber">⚠️ Měřidlo neodeslalo data déle než 48 hodin. Dočasný výpadek GSM.</div>':''}
    <div class="detail-row"><span class="detail-label">EAN / EIC</span><span class="detail-value">${m.ean_eic}</span></div>
    <div class="detail-row"><span class="detail-label">Aktuální stav</span>
      <span class="detail-value" style="font-size:16px;color:var(--blue2)">${(m.current_reading||0).toLocaleString('cs')} ${m.reading_unit}</span></div>
    <div class="detail-row"><span class="detail-label">Protokol</span><span class="detail-value">${m.protocol||'—'}</span></div>
    <div class="detail-row"><span class="detail-label">Kalibrace do</span>
      <span class="detail-value">${m.calibration_date ? m.calibration_date.slice(0,7) : '—'}</span></div>
    <div style="display:flex;gap:8px;margin-top:20px">
      <button class="btn btn-blue" onclick="showToast('📡','Manuální odečet spuštěn','green');closeModal()">📡 Odečíst nyní</button>
      <button class="btn btn-outline" onclick="showToast('🔔','Výpadek hlášen techniku','amber');closeModal()">🔔 Hlásit výpadek</button>
    </div>`);
};

// ─────────────────────────────────────────────────────────────────
// INVOICES
// ─────────────────────────────────────────────────────────────────

async function renderInvoices() {
  currentScreen = 'invoices';
  setContent(loadingState('Načítám faktury…'));
  let invoices, stats;
  try {
    [invoices, stats] = await Promise.all([
      api.getInvoices(),
      api.getInvoiceStats().catch(() => null),
    ]);
  } catch (e) {
    setContent(errorState('Chyba: ' + e.message)); return;
  }

  const s = stats || { total: 4812, paid: 4520, sent: 180, overdue: 112, overdue_czk_m: 1.4 };

  const sb = { paid:'badge-green', sent:'badge-blue', overdue:'badge-red', draft:'badge-gray' };
  const sl = { paid:'✓ Zaplacena', sent:'→ Odesláno', overdue:'! Po splatnosti', draft:'Návrh' };
  const cb = { EE:'badge-blue', GAS:'badge-amber', HEAT:'badge-red', WATER:'badge-green' };
  const cl = { EE:'⚡ EE', GAS:'🔥 GAS', HEAT:'♨️ CZT', WATER:'💧 VODA' };

  setContent(`
  <div class="kpi-grid" style="margin-bottom:16px">
    <div class="kpi-card blue"><div class="kpi-label">Vystaveno</div>
      <div class="kpi-value" style="font-size:22px">${s.total.toLocaleString('cs')}</div><div class="kpi-sub">Únor 2026</div></div>
    <div class="kpi-card green"><div class="kpi-label">Zaplaceno</div>
      <div class="kpi-value" style="font-size:22px">${s.paid.toLocaleString('cs')}</div>
      <div class="kpi-sub">${((s.paid/s.total)*100).toFixed(1)} %</div></div>
    <div class="kpi-card amber"><div class="kpi-label">Odesláno</div>
      <div class="kpi-value" style="font-size:22px">${s.sent.toLocaleString('cs')}</div><div class="kpi-sub">čeká na platbu</div></div>
    <div class="kpi-card red"><div class="kpi-label">Po splatnosti</div>
      <div class="kpi-value" style="font-size:22px">${s.overdue.toLocaleString('cs')}</div>
      <div class="kpi-sub">${s.overdue_czk_m} M Kč</div></div>
  </div>
  <div class="filters-bar">
    <div class="search-box"><span>🔍</span>
      <input type="text" placeholder="Hledat číslo faktury, zákazníka…"></div>
    <select class="filter-select"><option>Všechny komodity</option>
      <option>EE</option><option>GAS</option><option>VODA</option><option>CZT</option></select>
    <select class="filter-select"><option>Všechny stavy</option>
      <option>Zaplaceno</option><option>Odesláno</option><option>Po splatnosti</option></select>
    <button class="btn btn-outline btn-sm"
      onclick="showToast('🏭','Hromadná fakturace spuštěna','blue')">🏭 Hromadná fakturace</button>
  </div>
  <div class="card">
    <div class="table-wrap">
      <table>
        <thead><tr><th>Číslo faktury</th><th>Zákazník</th><th>Typ</th><th>Komodita</th>
          <th>Období od</th><th>Základ DPH</th><th>Celkem s DPH</th><th>Stav</th><th></th></tr></thead>
        <tbody>
          ${invoices.map(inv => `
          <tr onclick="openInvoiceDetail('${inv.id}')">
            <td class="mono" style="color:var(--blue2)">${inv.invoice_number}</td>
            <td style="font-weight:600">${inv.customers?.name || '—'}</td>
            <td><span class="badge badge-gray">${inv.invoice_type || '—'}</span></td>
            <td><span class="badge ${cb[inv.commodity]||'badge-gray'}">${cl[inv.commodity]||inv.commodity}</span></td>
            <td class="mono" style="font-size:12px;color:var(--text2)">${fmtDate(inv.period_from)}</td>
            <td class="mono">${(inv.amount_net||0).toLocaleString('cs')} Kč</td>
            <td class="mono" style="font-weight:700">${(inv.total_czk||0).toLocaleString('cs')} Kč</td>
            <td><span class="badge ${sb[inv.status]||'badge-gray'}">${sl[inv.status]||inv.status}</span></td>
            <td><button class="btn btn-ghost btn-sm"
              onclick="event.stopPropagation();showToast('📄','PDF staženo','green')">📄</button></td>
          </tr>`).join('')}
        </tbody>
      </table>
    </div>
  </div>`);
}

window.openInvoiceDetail = async function (id) {
  openModal(`<div class="loading-state"><div class="spinner"></div></div>`);
  let inv;
  try {
    inv = await api.getInvoice(id);
  } catch (e) {
    openModal(`<div class="empty-state"><p>${e.message}</p></div>`); return;
  }
  openModal(`
    <div class="modal-header">
      <div><div class="modal-title">${inv.invoice_number}</div>
        <div style="font-size:12px;color:var(--text3);font-family:var(--font-m);margin-top:2px">
          ${inv.customers?.name || '—'} · ${fmtDate(inv.period_from)} – ${fmtDate(inv.period_to)}
        </div>
      </div>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="detail-row"><span class="detail-label">Typ dokladu</span><span class="detail-value">${inv.invoice_type||'—'}</span></div>
    <div class="detail-row"><span class="detail-label">Komodita</span><span class="detail-value">${inv.commodity}</span></div>
    <div style="margin:16px 0">
      <div class="calc-box">
        ${(inv.invoice_items||[]).map(item =>
          `<div class="calc-row"><span>${item.description}</span><span>${(item.amount||0).toLocaleString('cs')} Kč</span></div>`
        ).join('')}
        <div class="calc-row tax"><span>DPH</span><span>${(inv.vat_amount||0).toLocaleString('cs')} Kč</span></div>
        <div class="calc-row total"><span>Celkem k úhradě</span><span>${(inv.total_czk||0).toLocaleString('cs')} Kč</span></div>
      </div>
    </div>
    <div style="display:flex;gap:8px">
      <button class="btn btn-blue" onclick="showToast('📄','PDF staženo','green');closeModal()">📄 PDF</button>
      <button class="btn btn-outline" onclick="showToast('📧','Faktura odeslána','blue');closeModal()">📧 Odeslat</button>
      ${inv.status==='overdue'?'<button class="btn btn-outline" onclick="showToast(\'🔔\',\'Upomínka odeslána\',\'amber\');closeModal()">🔔 Upomínka</button>':''}
    </div>`);
};

// ─────────────────────────────────────────────────────────────────
// ADVANCES
// ─────────────────────────────────────────────────────────────────

let _schedules = [];
let _selScheduleId = null;
const SEASONAL_FACTORS = [1.6,1.5,1.3,0.9,0.5,0.3,0.2,0.2,0.4,0.8,1.2,1.6];

async function renderAdvances() {
  currentScreen = 'advances';
  setContent(loadingState('Načítám zálohy…'));
  try {
    _schedules = await api.getAdvanceSchedules();
  } catch (e) {
    setContent(errorState('Chyba: ' + e.message)); return;
  }

  const active = _schedules.filter(s => s.status === 'active').length;
  const recalc = _schedules.filter(s => s.recalc_needed).length;

  setContent(`
  <div class="kpi-grid" style="margin-bottom:16px">
    <div class="kpi-card blue"><div class="kpi-label">Aktivní kalendáře</div>
      <div class="kpi-value" style="font-size:22px">${active}</div></div>
    <div class="kpi-card amber"><div class="kpi-label">Přepočty potřeba</div>
      <div class="kpi-value" style="font-size:22px">${recalc}</div></div>
  </div>
  <div class="tabs" id="adv-tabs">
    <div class="tab active" onclick="advTab(this,'calendar')">📋 Přehled kalendářů</div>
    <div class="tab" onclick="advTab(this,'months')">📆 Rozpis po měsících</div>
    <div class="tab" onclick="advTab(this,'calculator')">🧮 Kalkulátor</div>
    <div class="tab" onclick="advTab(this,'recalc')">🔄 Přepočty</div>
  </div>
  <div id="adv-tab-content"></div>`);

  advTab(document.querySelector('#adv-tabs .tab'), 'calendar');
}

window.advTab = function (el, tab) {
  document.querySelectorAll('#adv-tabs .tab').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  const fns = { calendar: advCalendar, months: advMonths, calculator: advCalculator, recalc: advRecalc };
  (fns[tab] || advCalendar)();
};

function advCalendar() {
  const cb = { EE:'badge-blue', GAS:'badge-amber', HEAT:'badge-red', WATER:'badge-green' };
  const cl = { EE:'⚡ EE', GAS:'🔥 GAS', HEAT:'♨️ CZT', WATER:'💧 H₂O' };
  document.getElementById('adv-tab-content').innerHTML = `
  <div class="card" style="margin-top:12px">
    <div class="table-wrap">
      <table>
        <thead><tr><th>Kód</th><th>Zákazník</th><th>Komodita</th><th>Tarif</th>
          <th>Záloha/měs (netto)</th><th>DPH</th><th>Záloha/měs (brutto)</th><th>Stav</th><th>Přepočet</th></tr></thead>
        <tbody>
          ${_schedules.map(s => `<tr onclick="selectScheduleForMonths('${s.id}')">
            <td class="mono" style="color:var(--blue2)">${s.schedule_code||s.id}</td>
            <td style="font-weight:600">${s.customers?.name || '—'}</td>
            <td><span class="badge ${cb[s.commodity]||'badge-gray'}">${cl[s.commodity]||s.commodity}</span></td>
            <td class="mono">${s.tariff_code||'—'}</td>
            <td class="mono">${(s.amount_net||0).toLocaleString('cs')} Kč</td>
            <td class="mono">${Math.round((s.vat_rate||0)*100)} %</td>
            <td class="mono" style="font-weight:700">${(s.amount_gross||0).toLocaleString('cs')} Kč</td>
            <td><span class="badge ${s.status==='active'?'badge-green':'badge-gray'}">${s.status==='active'?'Aktivní':'—'}</span></td>
            <td>${s.recalc_needed?'<span class="badge badge-amber">⚠ Nutný</span>':'<span class="badge badge-gray">OK</span>'}</td>
          </tr>`).join('')}
        </tbody>
      </table>
    </div>
  </div>`;
}

window.selectScheduleForMonths = function (id) {
  _selScheduleId = id;
  const tabs = document.querySelectorAll('#adv-tabs .tab');
  if (tabs[1]) tabs[1].click();
};

async function advMonths() {
  const el = document.getElementById('adv-tab-content');
  if (!_selScheduleId) {
    el.innerHTML = `<div class="empty-state" style="margin-top:16px">
      <div class="icon">📆</div><p>Vyberte zákazníka v záložce Přehled kalendářů</p></div>`;
    return;
  }
  el.innerHTML = `<div class="loading-state" style="margin-top:16px"><div class="spinner"></div></div>`;
  let months;
  try {
    months = await api.getAdvanceMonths(_selScheduleId);
  } catch (e) {
    el.innerHTML = errorState('Chyba: ' + e.message); return;
  }
  const sch = _schedules.find(s => s.id === _selScheduleId);
  const MONTHS_CS = ['Leden','Únor','Březen','Duben','Květen','Červen','Červenec','Srpen','Září','Říjen','Listopad','Prosinec'];
  const sb2 = { paid:'badge-green', pending:'badge-amber', overdue:'badge-red', future:'badge-gray' };
  const sl2 = { paid:'Zaplaceno', pending:'Čeká', overdue:'Po splatnosti', future:'Budoucí' };

  el.innerHTML = `
  <div style="margin:12px 0 8px;font-weight:700;font-size:14px">${sch?.customers?.name || ''} — ${sch?.tariff_code || ''}</div>
  <div class="card">
    <div class="table-wrap">
      <table>
        <thead><tr><th>Měsíc</th><th>Splatnost</th><th>Předpis (brutto)</th>
          <th>Základ DPH</th><th>DPH</th><th>Zaplaceno</th>
          <th>Datum platby</th><th>Saldo</th><th>Stav</th><th></th></tr></thead>
        <tbody>
          ${months.map((m, i) => {
            const vat = Math.round((m.amount_gross||0) - (m.amount_net||0));
            const balance = (m.amount_paid||0) - (m.amount_gross||0);
            const balColor = balance >= 0 ? 'var(--green)' : balance === 0 ? 'var(--text3)' : 'var(--red)';
            return `<tr style="${i === new Date().getMonth() ? 'background:rgba(59,130,246,.06)' : ''}">
              <td style="font-weight:600">${MONTHS_CS[m.month_number-1]||m.month_number}</td>
              <td class="mono" style="font-size:12px">${fmtDate(m.due_date)}</td>
              <td class="mono" style="font-weight:700">${(m.amount_gross||0).toLocaleString('cs')} Kč</td>
              <td class="mono">${(m.amount_net||0).toLocaleString('cs')} Kč</td>
              <td class="mono">${vat.toLocaleString('cs')} Kč</td>
              <td class="mono">${m.amount_paid ? m.amount_paid.toLocaleString('cs')+' Kč' : '—'}</td>
              <td class="mono" style="font-size:12px">${fmtDate(m.paid_date) || '—'}</td>
              <td class="mono" style="color:${balColor}; font-weight:700">${balance >= 0 ? '+' : ''}${balance.toLocaleString('cs')} Kč</td>
              <td><span class="badge ${sb2[m.payment_status]||'badge-gray'}">${sl2[m.payment_status]||m.payment_status}</span></td>
              <td>
                ${m.payment_status==='overdue' ? `<button class="btn btn-ghost btn-sm"
                  onclick="showToast('📧','Upomínka odeslána','amber')">Upomínka</button>` : ''}
                ${m.payment_status==='pending' ? `<button class="btn btn-ghost btn-sm"
                  onclick="showToast('✅','Platba zapsána','green')">Zaplatit</button>` : ''}
              </td>
            </tr>`;
          }).join('')}
        </tbody>
      </table>
    </div>
  </div>`;
}

function advCalculator() {
  document.getElementById('adv-tab-content').innerHTML = `
  <div class="card" style="margin-top:12px">
    <div class="card-header"><div class="card-title">Kalkulátor zálohového plánu</div></div>
    <div class="grid-2" style="gap:16px">
      <div>
        <div class="form-field"><label>Zákazník</label>
          <select class="filter-select" style="width:100%" id="calc-cust">
            ${_schedules.map(s => `<option value="${s.id}">${s.customers?.name || s.id}</option>`).join('')}
          </select></div>
        <div class="form-field"><label>Roční spotřeba (kWh / m³ / GJ)</label>
          <input type="number" class="filter-select" style="width:100%" id="calc-kwh" value="4560" oninput="calcPreview()"></div>
        <div class="form-field"><label>Distribuční cena (Kč/kWh)</label>
          <input type="number" class="filter-select" style="width:100%" id="calc-price" value="1.84" step="0.01" oninput="calcPreview()"></div>
        <div class="form-field"><label>Pevná platba (Kč/měsíc)</label>
          <input type="number" class="filter-select" style="width:100%" id="calc-fixed" value="213" oninput="calcPreview()"></div>
        <div class="form-field"><label>Sazba DPH</label>
          <select class="filter-select" style="width:100%" id="calc-vat" onchange="calcPreview()">
            <option value="0.21">21 %</option><option value="0.15">15 %</option><option value="0">0 %</option>
          </select></div>
        <div class="form-field"><label>Typ rozložení</label>
          <select class="filter-select" style="width:100%" id="calc-type" onchange="calcPreview()">
            <option value="equal">Rovnoměrné</option><option value="seasonal">Sezónní</option>
          </select></div>
      </div>
      <div id="calc-result"></div>
    </div>
  </div>`;
  calcPreview();
}

window.calcPreview = function () {
  const kwh   = parseFloat(document.getElementById('calc-kwh')?.value) || 0;
  const price = parseFloat(document.getElementById('calc-price')?.value) || 0;
  const fixed = parseFloat(document.getElementById('calc-fixed')?.value) || 0;
  const vat   = parseFloat(document.getElementById('calc-vat')?.value) || 0;
  const type  = document.getElementById('calc-type')?.value || 'equal';
  const MONTHS_CS = ['Led','Úno','Bře','Dub','Kvě','Čer','Čec','Srp','Zář','Říj','Lis','Pro'];
  const annualNet = kwh * price + fixed * 12;
  const monthlyNet = annualNet / 12;
  const monthlyGross = monthlyNet * (1 + vat);

  const el = document.getElementById('calc-result');
  if (!el) return;

  const rows = Array.from({length:12}, (_, i) => {
    const factor = type === 'seasonal' ? SEASONAL_FACTORS[i] : 1;
    const net   = type === 'seasonal' ? (annualNet / SEASONAL_FACTORS.reduce((a,b)=>a+b,0)) * factor : monthlyNet;
    const gross = net * (1 + vat);
    return `<tr><td>${MONTHS_CS[i]}</td>
      <td class="mono">${Math.round(net).toLocaleString('cs')} Kč</td>
      <td class="mono" style="font-weight:700">${Math.round(gross).toLocaleString('cs')} Kč</td></tr>`;
  }).join('');

  el.innerHTML = `
    <div class="calc-box" style="margin-bottom:12px">
      <div class="calc-row"><span>Roční náklad (netto)</span><span>${Math.round(annualNet).toLocaleString('cs')} Kč</span></div>
      <div class="calc-row"><span>Průměrná záloha/měs (netto)</span><span>${Math.round(monthlyNet).toLocaleString('cs')} Kč</span></div>
      <div class="calc-row total"><span>Záloha/měs (brutto)</span><span>${Math.round(monthlyGross).toLocaleString('cs')} Kč</span></div>
    </div>
    <table style="width:100%;font-size:12px">
      <thead><tr><th>Měsíc</th><th>Netto</th><th>Brutto</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`;
};

function advRecalc() {
  const needsRecalc = _schedules.filter(s => s.recalc_needed);
  document.getElementById('adv-tab-content').innerHTML = needsRecalc.length === 0
    ? `<div class="empty-state" style="margin-top:16px"><div class="icon">✅</div>
       <p>Žádné zálohy nevyžadují přepočet</p></div>`
    : `<div style="margin-top:12px;display:flex;flex-direction:column;gap:12px">
      ${needsRecalc.map(s => `
        <div class="card">
          <div class="card-header">
            <div>
              <div class="card-title">${s.customers?.name || '—'} — ${s.commodity}</div>
              <div style="font-size:12px;color:var(--text3);margin-top:2px">Smlouva ${s.contract_id || '—'} · Tarif ${s.tariff_code}</div>
            </div>
            <span class="badge badge-amber">⚠ Přepočet nutný</span>
          </div>
          <div class="grid-2" style="gap:12px;margin-top:8px">
            <div class="calc-box">
              <div class="calc-row"><span>Stávající záloha/měs</span><span>${(s.amount_gross||0).toLocaleString('cs')} Kč</span></div>
            </div>
            <div class="calc-box" style="border-color:var(--amber)">
              <div class="calc-row"><span>Nová záloha/měs (ERÚ 2026)</span>
                <span style="color:var(--amber)">${Math.round((s.amount_gross||0)*1.24).toLocaleString('cs')} Kč</span></div>
              <div class="calc-row" style="color:var(--red)"><span>Rozdíl</span>
                <span>+${Math.round((s.amount_gross||0)*0.24).toLocaleString('cs')} Kč</span></div>
            </div>
          </div>
          <div style="display:flex;gap:8px;margin-top:12px">
            <button class="btn btn-blue" onclick="approveRecalc('${s.id}')">✓ Schválit přepočet</button>
            <button class="btn btn-outline" onclick="showToast('📧','Zákazník informován','blue')">📧 Informovat zákazníka</button>
            <button class="btn btn-ghost" onclick="showToast('⏸','Přepočet odložen','amber')">Odložit</button>
          </div>
        </div>`).join('')}
    </div>`;
}

window.approveRecalc = async function (id) {
  const s = _schedules.find(x => x.id === id);
  if (!s) return;
  const newAmount = Math.round((s.amount_net||0) * 1.24);
  try {
    await api.approveRecalc(id, newAmount);
    showToast('✅', 'Přepočet schválen a uložen', 'green');
    _schedules = await api.getAdvanceSchedules();
    advRecalc();
  } catch (e) {
    showToast('⚠️', 'Chyba: ' + e.message, 'red');
  }
};

// ─────────────────────────────────────────────────────────────────
// PAYMENTS
// ─────────────────────────────────────────────────────────────────

let selPay = null, selInv = null;

async function renderPayments() {
  currentScreen = 'payments';
  setContent(loadingState('Načítám platby…'));
  let payments, openInvoices;
  try {
    [payments, openInvoices] = await Promise.all([
      api.getBankPayments({ matched: false }),
      api.getOpenInvoices(),
    ]);
  } catch (e) {
    setContent(errorState('Chyba: ' + e.message)); return;
  }

  setContent(`
  <div class="alert blue">ℹ️ Import výpisu · 22.2.2026 · 847 transakcí zpracováno ·
    835 spárováno automaticky · <strong>12 vyžaduje pozornost</strong>
    <button class="btn btn-outline btn-sm" style="margin-left:auto" onclick="showBankImportModal()">📥 Import</button>
  </div>
  <div class="match-container">
    <div class="match-panel">
      <div class="match-panel-header">📥 Nespárované platby</div>
      ${payments.map(p => `
        <div class="match-item" id="pay-${p.id}" onclick="selectPayment('${p.id}')">
          <div>
            <div style="font-weight:600;font-size:13px">${(p.amount_czk||0).toLocaleString('cs')} Kč</div>
            <div style="font-size:11px;color:var(--text3);font-family:var(--font-m)">${p.sender_name || '—'}</div>
            <div style="font-size:10.5px;color:var(--text3)">
              ${p.variable_symbol ? 'VS: '+p.variable_symbol : 'VS: —'} · ${p.sender_account||'—'}
            </div>
          </div>
        </div>`).join('')}
    </div>
    <div class="match-arrow">⇄</div>
    <div class="match-panel">
      <div class="match-panel-header">🧾 Otevřené faktury & zálohy</div>
      ${openInvoices.map(inv => `
        <div class="match-item" id="inv-${inv.id}" onclick="selectInvoice('${inv.id}')">
          <div>
            <div style="font-weight:600;font-size:13px">${(inv.total_czk||0).toLocaleString('cs')} Kč</div>
            <div style="font-size:11px;color:var(--text3)">${inv.customers?.name || '—'}</div>
            <div style="font-size:10.5px;color:var(--text3);font-family:var(--font-m)">${inv.invoice_number}</div>
          </div>
        </div>`).join('')}
    </div>
  </div>
  <div style="display:flex;gap:8px;margin-top:16px;align-items:center">
    <button class="btn btn-blue" onclick="doMatch()">✓ Spárovat vybrané</button>
    <button class="btn btn-outline" onclick="showToast('🤖','AI párování – navrhuje 3 shody','blue')">🤖 AI návrh</button>
    <button class="btn btn-outline" onclick="showToast('📥','Příkaz k vrácení přeplatku','green')">↩ Vrátit přeplatek</button>
    <span style="color:var(--text3);font-size:12px;margin-left:auto;font-family:var(--font-m)">
      Vyberte platbu a fakturu pro manuální párování
    </span>
  </div>`);
}

window.selectPayment = function (id) {
  selPay = id;
  document.querySelectorAll('.match-item').forEach(el => {
    if (el.id.startsWith('pay-')) el.classList.remove('selected');
  });
  document.getElementById('pay-'+id)?.classList.add('selected');
};
window.selectInvoice = function (id) {
  selInv = id;
  document.querySelectorAll('.match-item').forEach(el => {
    if (el.id.startsWith('inv-')) el.classList.remove('selected');
  });
  document.getElementById('inv-'+id)?.classList.add('selected');
};
window.doMatch = async function () {
  if (!selPay || !selInv) { showToast('⚠️','Vyberte platbu i fakturu','amber'); return; }
  try {
    await api.matchPayment(selPay, selInv);
    showToast('✅','Platba úspěšně spárována','green');
    selPay = null; selInv = null;
    await renderPayments();
  } catch (e) {
    showToast('⚠️','Chyba párování: '+e.message,'red');
  }
};
window.showBankImportModal = function () {
  openModal(`
    <div class="modal-header">
      <div class="modal-title">Import bankovního výpisu</div>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="form-field"><label>Banka / formát</label>
      <select class="filter-select" style="width:100%">
        <option>ČSOB – MT940</option><option>KB – ABO/GPC</option>
        <option>FIO – XML</option><option>Raiffeisenbank – CAMT.053</option>
      </select></div>
    <div style="border:2px dashed var(--border2);border-radius:var(--r);padding:32px;text-align:center;color:var(--text3);cursor:pointer;margin:12px 0"
      onclick="showToast('📁','Soubor nahrán – 847 transakcí','green');closeModal()">
      📁 Přetáhněte soubor nebo klikněte
    </div>
    <button class="btn btn-blue" onclick="showToast('✅','Import dokončen – 835/847 spárováno','green');closeModal()">Spustit import</button>`);
};

// ─────────────────────────────────────────────────────────────────
// RÚNT
// ─────────────────────────────────────────────────────────────────

async function renderRunt() {
  currentScreen = 'runt';
  setContent(loadingState('Načítám budovy…'));
  let buildings;
  const year = new Date().getFullYear() - 1;
  try {
    buildings = await api.getBuildings(year);
  } catch (e) {
    setContent(errorState('Chyba: ' + e.message)); return;
  }

  setContent(`
  <div class="alert blue">ℹ️ Rozúčtování dle vyhlášky č. 269/2015 Sb. · Roční vyúčtování za rok ${year}</div>
  <div class="grid-2" style="margin-bottom:16px">
    <div class="kpi-card amber">
      <div class="kpi-label">Celkové náklady</div>
      <div class="kpi-value" style="font-size:22px">
        ${buildings.reduce((s,b)=>s+(b.total_cost_czk||0),0).toLocaleString('cs')} Kč
      </div>
      <div class="kpi-sub">${buildings.length} budov</div>
    </div>
    <div class="kpi-card green">
      <div class="kpi-label">Dokončená vyúčtování</div>
      <div class="kpi-value" style="font-size:22px">
        ${buildings.filter(b=>b.status==='closed').length} / ${buildings.length}
      </div>
    </div>
  </div>
  <div class="card">
    <div class="card-header">
      <div class="card-title">Budovy – RÚNT teplo</div>
      <select class="filter-select" style="font-size:12px;padding:6px 10px">
        <option>Rok ${year}</option><option>Rok ${year-1}</option>
      </select>
    </div>
    <div class="building-tree" id="building-tree"></div>
  </div>`);

  renderBuildings(buildings);
}

function renderBuildings(buildings) {
  document.getElementById('building-tree').innerHTML = buildings.map((b, bi) => {
    const units = b.building_units || [];
    return `
    <div class="building-node">
      <div class="building-header" onclick="toggleBuilding(${bi})">
        <span class="building-icon">🏢</span>
        <div>
          <div style="font-weight:700;font-size:14px">${b.name}</div>
          <div style="font-size:12px;color:var(--text3)">
            ${b.unit_count} jednotek · Náklady: <strong style="color:var(--amber)">${(b.total_cost_czk||0).toLocaleString('cs')} Kč</strong>
          </div>
        </div>
        <span class="badge ${b.status==='closed'?'badge-green':'badge-amber'}" style="margin-left:auto">
          ${b.status==='closed'?'✓ Uzavřeno':'⏳ Rozpracováno'}
        </span>
        <span style="font-size:18px;transition:.2s" id="bld-arrow-${bi}">▼</span>
      </div>
      <div class="building-units" id="bld-units-${bi}" style="display:none">
        <table style="width:100%;font-size:13px">
          <thead><tr><th>Jednotka</th><th>EAN kalorimetru</th>
            <th>Základní složka</th><th>Spotřební složka</th><th>Celkem</th><th></th></tr></thead>
          <tbody>
            ${units.map(u => `<tr>
              <td>${u.unit_name}</td>
              <td class="mono" style="font-size:11px;color:var(--text3)">${u.ean||'—'}</td>
              <td class="mono">${(u.cost_fixed||0).toLocaleString('cs')} Kč</td>
              <td class="mono">${(u.cost_variable||0).toLocaleString('cs')} Kč</td>
              <td class="mono" style="font-weight:700">${(u.cost_total||0).toLocaleString('cs')} Kč</td>
              <td><button class="btn btn-ghost btn-sm" onclick="showToast('📄','Výzva k platbě odeslána','green')">📄 Vyúčtovat</button></td>
            </tr>`).join('')}
          </tbody>
        </table>
      </div>
    </div>`;
  }).join('');
}

window.toggleBuilding = function (i) {
  const el  = document.getElementById('bld-units-'+i);
  const arr = document.getElementById('bld-arrow-'+i);
  if (!el) return;
  const open = el.style.display === 'block';
  el.style.display = open ? 'none' : 'block';
  if (arr) arr.style.transform = open ? '' : 'rotate(180deg)';
};

// ─────────────────────────────────────────────────────────────────
// REPORTING
// ─────────────────────────────────────────────────────────────────

function renderReporting() {
  currentScreen = 'reporting';
  setContent(`
  <div class="kpi-grid" style="margin-bottom:16px">
    <div class="kpi-card blue"><div class="kpi-label">Obrat YTD</div>
      <div class="kpi-value">84.2 M Kč</div></div>
    <div class="kpi-card green"><div class="kpi-label">Inkaso YTD</div>
      <div class="kpi-value">79.1 M Kč</div></div>
    <div class="kpi-card amber"><div class="kpi-label">DSO</div>
      <div class="kpi-value">18.4 dní</div></div>
    <div class="kpi-card red"><div class="kpi-label">Pohledávky >90d</div>
      <div class="kpi-value">0.8 M Kč</div></div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-header"><div class="card-title">Obrat dle komodity</div></div>
      <canvas id="rpt-commodity" height="180"></canvas>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Pohledávky po splatnosti – stáří</div></div>
      <canvas id="rpt-aging" height="180"></canvas>
    </div>
  </div>`);

  new Chart(document.getElementById('rpt-commodity'), {
    type: 'doughnut',
    data: {
      labels: ['⚡ EE', '🔥 GAS', '💧 VODA', '♨️ CZT'],
      datasets: [{ data:[48.2, 18.4, 4.1, 13.5], backgroundColor:['#3B82F6','#F59E0B','#10B981','#EF4444'] }],
    },
    options: { responsive:true, plugins:{ legend:{ labels:{ color:'#94A3C0' } } } },
  });

  new Chart(document.getElementById('rpt-aging'), {
    type: 'bar',
    data: {
      labels: ['0–30d','31–60d','61–90d','>90d'],
      datasets: [{ data:[0.42, 0.18, 0.08, 0.08], backgroundColor:['#10B981','#F59E0B','#EF4444','#7C3AED'] }],
    },
    options: {
      responsive:true,
      plugins:{ legend:{ display:false } },
      scales: {
        x:{ ticks:{color:'#5A6E8C'}, grid:{color:'rgba(255,255,255,.04)'} },
        y:{ ticks:{color:'#5A6E8C', callback:v=>v+'M'}, grid:{color:'rgba(255,255,255,.06)'} },
      },
    },
  });
}

// ─────────────────────────────────────────────────────────────────
// ADMIN
// ─────────────────────────────────────────────────────────────────

async function renderAdmin() {
  currentScreen = 'admin';
  setContent(`
  <div class="tabs" id="admin-tabs">
    <div class="tab active" onclick="adminTab(this,'users')">👤 Uživatelé</div>
    <div class="tab" onclick="adminTab(this,'tariffs')">📋 Tarify</div>
    <div class="tab" onclick="adminTab(this,'tenant')">🏢 Tenant</div>
    <div class="tab" onclick="adminTab(this,'integrations')">🔌 Integrace</div>
  </div>
  <div id="admin-tab-content"></div>`);
  adminTab(document.querySelector('#admin-tabs .tab'), 'users');
}

window.adminTab = async function (el, tab) {
  document.querySelectorAll('#admin-tabs .tab').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  const container = document.getElementById('admin-tab-content');
  container.innerHTML = `<div class="loading-state" style="margin-top:16px"><div class="spinner"></div></div>`;

  if (tab === 'users') {
    let users;
    try { users = await api.getAppUsers(); } catch { users = []; }
    container.innerHTML = `<div class="card" style="margin-top:12px">
      <div class="card-header"><div class="card-title">Správa uživatelů</div>
        <button class="btn btn-blue btn-sm" onclick="showToast('👤','Formulář nového uživatele','blue')">+ Přidat</button></div>
      <div class="table-wrap"><table>
        <thead><tr><th>Jméno</th><th>E-mail</th><th>Role</th><th>Stav</th><th>Poslední přihlášení</th><th></th></tr></thead>
        <tbody>${users.map(u => `<tr>
          <td style="font-weight:600">
            <div style="display:flex;align-items:center;gap:8px">
              <div style="width:28px;height:28px;border-radius:50%;background:linear-gradient(135deg,#3B82F6,#8B5CF6);display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700">
                ${(u.full_name||u.email||'?').split(' ').map(x=>x[0]).join('').slice(0,2).toUpperCase()}
              </div>${u.full_name||u.email}
            </div>
          </td>
          <td class="mono" style="font-size:12px;color:var(--text2)">${u.email}</td>
          <td><span class="badge ${u.role==='admin'?'badge-violet':'badge-blue'}">${u.role}</span></td>
          <td><span class="badge ${u.status==='active'?'badge-green':'badge-gray'}">${u.status==='active'?'Aktivní':'Neaktivní'}</span></td>
          <td class="mono" style="font-size:12px;color:var(--text3)">${fmtDateTime(u.last_login_at)}</td>
          <td><button class="btn btn-ghost btn-sm" onclick="showToast('✏️','Editor uživatele','blue')">✏️</button></td>
        </tr>`).join('')}</tbody>
      </table></div></div>`;
  }

  if (tab === 'tariffs') {
    let tariffs;
    try { tariffs = await api.getTariffs(); } catch { tariffs = []; }
    const cb = { EE:'badge-blue', GAS:'badge-amber', WATER:'badge-green', HEAT:'badge-red' };
    container.innerHTML = `<div class="card" style="margin-top:12px">
      <div class="card-header"><div class="card-title">Tarify a cenová rozhodnutí ERÚ</div>
        <button class="btn btn-outline btn-sm" onclick="showToast('📥','Import ERÚ cenového rozhodnutí','blue')">📥 Import ERÚ</button></div>
      <div class="table-wrap"><table>
        <thead><tr><th>Kód</th><th>Název</th><th>Komodita</th><th>Pevná platba</th>
          <th>Distribuční cena</th><th>Platnost od</th><th>Stav</th></tr></thead>
        <tbody>${tariffs.map(t => `<tr onclick="showToast('📋','Detail tarifu ${t.code}','blue')">
          <td class="mono" style="color:var(--blue2);font-weight:700">${t.code}</td>
          <td style="font-size:13px">${t.name}</td>
          <td><span class="badge ${cb[t.commodity]||'badge-gray'}">${t.commodity}</span></td>
          <td class="mono">${t.fixed_fee_czk ? t.fixed_fee_czk.toLocaleString('cs')+' Kč' : '—'}</td>
          <td class="mono">${t.unit_price_czk ? t.unit_price_czk+' Kč/kWh' : '—'}</td>
          <td class="mono">${fmtDate(t.valid_from)}</td>
          <td><span class="badge badge-green">Aktivní</span></td>
        </tr>`).join('')}</tbody>
      </table></div></div>`;
  }

  if (tab === 'tenant') {
    container.innerHTML = `<div class="card" style="margin-top:12px">
      <div class="card-header"><div class="card-title">Multi-tenant konfigurace</div></div>
      <div class="detail-row"><span class="detail-label">Aktivní tenant</span><span class="detail-value">${currentTenant.name}</span></div>
      <div class="detail-row"><span class="detail-label">Fakturační perioda</span><span class="detail-value">Měsíční</span></div>
      <div class="detail-row"><span class="detail-label">Splatnost faktur</span><span class="detail-value">14 dní</span></div>
      <div class="detail-row"><span class="detail-label">Číslování faktur</span><span class="detail-value mono">FAK-{YYYY}-{NNNNN}</span></div>
      <div class="detail-row"><span class="detail-label">ERP systém</span><span class="detail-value">SAP – agregovaný export</span></div>
      <div class="detail-row"><span class="detail-label">OTE propojení</span>
        <span class="detail-value"><span class="badge badge-green">● Aktivní</span></span></div>
    </div>`;
  }

  if (tab === 'integrations') {
    let ints;
    try { ints = await api.getIntegrationStatus(); } catch { ints = []; }
    const fallback = [
      { icon:'⚡', name:'OTE Datahub', description:'Registrace OPM, 15min data', status:'online' },
      { icon:'🏦', name:'ČSOB Bank API', description:'Bankovní výpisy MT940', status:'online' },
      { icon:'🏭', name:'SAP ERP', description:'Agregovaný export faktur a DPH', status:'online' },
      { icon:'📡', name:'AMI Head-End', description:'15min data z 8 440 elektroměrů', status:'degraded' },
      { icon:'💧', name:'M-Bus Gateway', description:'Kalorimetry a vodoměry', status:'online' },
      { icon:'📧', name:'SendGrid', description:'E-mailová komunikace', status:'online' },
    ];
    const items = ints.length ? ints : fallback;
    const sb2 = { online:'badge-green', degraded:'badge-amber', offline:'badge-red' };
    const sl2 = { online:'● Online', degraded:'● Degradováno', offline:'✕ Offline' };
    container.innerHTML = `<div class="card" style="margin-top:12px">
      <div class="card-header"><div class="card-title">Stav integrací</div></div>
      ${items.map(i => `
        <div class="detail-row">
          <div style="display:flex;align-items:center;gap:8px">
            ${i.icon||'🔌'} <span>${i.name}</span>
            <span style="color:var(--text3);font-size:12px">· ${i.description||''}</span>
          </div>
          <span class="badge ${sb2[i.status]||'badge-gray'}">${sl2[i.status]||i.status}</span>
        </div>`).join('')}
    </div>`;
  }
};

// ─────────────────────────────────────────────────────────────────
// MODAL
// ─────────────────────────────────────────────────────────────────

window.openModal = function (html) {
  document.getElementById('modal-content').innerHTML = html;
  document.getElementById('modal').classList.add('open');
};
window.closeModal = function () {
  document.getElementById('modal').classList.remove('open');
};
document.getElementById('modal').addEventListener('click', function (e) {
  if (e.target === this) closeModal();
});

// ─────────────────────────────────────────────────────────────────
// TOASTS
// ─────────────────────────────────────────────────────────────────

window.showToast = function (icon, text, color) {
  const container = document.getElementById('toasts');
  const toast = document.createElement('div');
  toast.className = 'toast';
  const colors = { green:'var(--green)', blue:'var(--blue2)', amber:'var(--amber)', red:'var(--red)' };
  toast.innerHTML = `<span class="toast-icon">${icon}</span>
    <span class="toast-text" style="color:${colors[color]||colors.blue}">${text}</span>
    <span class="toast-close" onclick="this.parentElement.remove()">✕</span>`;
  container.appendChild(toast);
  setTimeout(() => toast.style.opacity = '0', 3500);
  setTimeout(() => toast.remove(), 4000);
};

// ─────────────────────────────────────────────────────────────────
// UTILS
// ─────────────────────────────────────────────────────────────────

function fmtDate(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleDateString('cs-CZ');
  } catch { return iso; }
}
function fmtDateTime(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString('cs-CZ', { dateStyle:'short', timeStyle:'short' });
  } catch { return iso; }
}

// ─────────────────────────────────────────────────────────────────
// KEYBOARD
// ─────────────────────────────────────────────────────────────────

document.getElementById('email-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') doLogin();
});

// ─────────────────────────────────────────────────────────────────
// START
// ─────────────────────────────────────────────────────────────────

boot();
