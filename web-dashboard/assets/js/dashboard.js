
function updateDashboardStats() {
  const today = new Date(); today.setHours(0, 0, 0, 0);
  const todayOrders = allOrders.filter(o => o.date >= today);

  const el = id => document.getElementById(id);
  if (el('statOrders'))       el('statOrders').textContent = todayOrders.length;
  if (el('statOrdersTrend'))  el('statOrdersTrend').textContent = `${todayOrders.length} orders placed today`;

  const revenue = todayOrders
    .filter(o => o.status === 'completed')
    .reduce((s, o) => s + (parseFloat(o.totalPrice) || 0), 0);
  if (el('statRevenue')) el('statRevenue').textContent = `Rs ${revenue.toFixed(2)}`;

  const todayStr = today.toISOString().slice(0, 10);
  const activeRes = allReservations.filter(r => r.date === todayStr && r.status !== 'cancelled').length;
  if (el('statReservations')) el('statReservations').textContent = activeRes;

  if (el('statUsers')) el('statUsers').textContent = allUsers.length;
}

// Dashboard_charts

function renderDashboardCharts() {
  Chart.defaults.color = '#9a8c7e';
  renderOrdersBarChart();
  renderDashboardDrinksChart();
}

function renderOrdersBarChart() {
  const ctx = document.getElementById('ordersChart');
  if (!ctx) return;

  const days = [], counts = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(); d.setDate(d.getDate() - i); d.setHours(0, 0, 0, 0);
    const next = new Date(d); next.setDate(next.getDate() + 1);
    days.push(d.toLocaleDateString('en-MY', { weekday: 'short' }));
    counts.push(allOrders.filter(o => o.date >= d && o.date < next).length);
  }

  if (ordersChartInst) ordersChartInst.destroy();
  ordersChartInst = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: days,
      datasets: [{
        label: 'Orders', data: counts,
        backgroundColor: c => {
          const g = c.chart.ctx.createLinearGradient(0, 0, 0, 200);
          g.addColorStop(0, '#c8965a'); g.addColorStop(1, '#c8965a22'); return g;
        },
        borderRadius: 6, borderSkipped: false
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: true,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { color: '#2e282015' }, border: { color: '#2e2820' } },
        y: { grid: { color: '#2e282033' }, border: { color: '#2e2820' }, beginAtZero: true, ticks: { precision: 0 } }
      }
    }
  });
}

function renderDashboardDrinksChart() {
  const ctx = document.getElementById('drinksChart');
  if (!ctx) return;

  const counts = {};
  allOrders.forEach(o => {
    (o.drinkList || []).forEach(item => {
      const name = item.name || 'Unknown';
      counts[name] = (counts[name] || 0) + (item.quantity || 1);
    });
  });

  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 4);
  const labels = sorted.length ? sorted.map(e => e[0]) : ['No orders yet'];
  const values = sorted.length ? sorted.map(e => e[1]) : [1];
  const colors = ['#c8965a', '#7eb8a4', '#d4856a', '#a89bc0'];
  const total  = values.reduce((a, b) => a + b, 0) || 1;

  if (drinksChartInst) drinksChartInst.destroy();
  drinksChartInst = new Chart(ctx, {
    type: 'doughnut',
    data: { labels, datasets: [{ data: values, backgroundColor: colors, borderColor: '#1a1714', borderWidth: 3 }] },
    options: { responsive: true, cutout: '72%', plugins: { legend: { display: false } } }
  });

  const legendEl = document.getElementById('drinksLegend');
  if (legendEl) legendEl.innerHTML = labels.map((l, i) =>
    `<div class="legend-item"><span class="legend-dot" style="background:${colors[i]}"></span>${l} ${Math.round(values[i]/total*100)}%</div>`
  ).join('');
}

function switchWeekChart(type, btn) {
  btn.closest('.chart-tabs').querySelectorAll('.chart-tab').forEach(t => t.classList.remove('active'));
  btn.classList.add('active');
  renderOrdersBarChart();
}

// Recent_orders

function renderRecentOrders() {
  const tbody = document.getElementById('recentOrdersBody');
  if (!tbody) return;

  if (!allOrders.length) {
    tbody.innerHTML = `<tr><td colspan="5" class="loading-cell">
      No orders yet. Orders placed in the mobile app will appear here instantly.
    </td></tr>`;
    return;
  }

  tbody.innerHTML = allOrders.slice(0, 6).map(o => {
    const items   = (o.drinkList || []).map(d => `${d.name}${d.quantity > 1 ? ' ×' + d.quantity : ''}`).join(', ') || '—';
    const dateStr = o.date?.toLocaleString?.('en-MY', { hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' }) || '—';
    const customer = o.userName || o.userID?.slice(0, 8) || 'Customer';
    return `<tr>
      <td><span style="font-family:'DM Mono',monospace;font-size:11px;color:var(--text3)">${o.firestoreId?.slice(0,8)}…</span></td>
      <td style="color:var(--text);font-weight:500">${customer}</td>
      <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--text2)">${items}</td>
      <td style="color:var(--accent);font-weight:600">Rs ${parseFloat(o.totalPrice||0).toFixed(2)}</td>
      <td><span class="badge badge-${o.status}">${o.status}</span></td>
    </tr>`;
  }).join('');
}

// Today_reservation

function renderTodayReservations() {
  const container = document.getElementById('todayReservations');
  if (!container) return;

  const todayStr = new Date().toISOString().slice(0, 10);
  const today    = allReservations.filter(r => r.date === todayStr && r.status !== 'cancelled');

  if (!today.length) {
    container.innerHTML = `<div style="padding:20px;color:var(--text3);font-size:13px;text-align:center">No reservations today.</div>`;
    return;
  }

  container.innerHTML = today.map(r => `
    <div class="res-card">
      <div class="res-time">${r.time || '—'}</div>
      <div class="res-info">
        <div class="res-name">${r.userName || r.userID?.slice(0,8) || 'Customer'}</div>
        <div class="res-detail">${r.partySize || 1} guests</div>
      </div>
      <div class="res-table">Table ${r.tableNumber || '—'}</div>
    </div>
  `).join('');
}

