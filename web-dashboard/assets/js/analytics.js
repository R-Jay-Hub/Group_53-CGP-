

function loadAnalytics() {
  const days    = parseInt(document.getElementById('analyticsRange')?.value || '7');
  const cutoff  = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  cutoff.setHours(0, 0, 0, 0);

  const rangeOrders = allOrders.filter(o => o.date >= cutoff);
  const totalOrders = rangeOrders.length;
  const totalRev    = rangeOrders
    .filter(o => o.status === 'completed')
    .reduce((s, o) => s + parseFloat(o.totalPrice || 0), 0);
  const avgVal = totalOrders > 0 ? totalRev / totalOrders : 0;

  const el = id => document.getElementById(id);
  if (el('avgOrderVal'))    el('avgOrderVal').textContent    = `Rs ${avgVal.toFixed(2)}`;
  if (el('totalOrdersVal')) el('totalOrdersVal').textContent  = totalOrders;
  if (el('totalRevenueVal')) el('totalRevenueVal').textContent = `Rs ${totalRev.toFixed(2)}`;
  if (el('activeUsersVal')) el('activeUsersVal').textContent  = allUsers.length;

  setTimeout(() => {
    if (el('avgOrderBar'))     el('avgOrderBar').style.width     = Math.min(avgVal / 50 * 100, 100) + '%';
    if (el('totalOrdersBar'))  el('totalOrdersBar').style.width  = Math.min(totalOrders / 100 * 100, 100) + '%';
    if (el('totalRevenueBar')) el('totalRevenueBar').style.width = Math.min(totalRev / 5000 * 100, 100) + '%';
    if (el('activeUsersBar'))  el('activeUsersBar').style.width  = Math.min(allUsers.length / 50 * 100, 100) + '%';
  }, 100);

  renderRevenueTrendChart(rangeOrders, days);
  renderMoodChart(rangeOrders);
}

function renderRevenueTrendChart(orders, days) {
  const ctx = document.getElementById('revenueChart');
  if (!ctx) return;

  const labels = [], data = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(); d.setDate(d.getDate() - i); d.setHours(0, 0, 0, 0);
    const next = new Date(d); next.setDate(next.getDate() + 1);
    labels.push(d.toLocaleDateString('en-MY', { day: 'numeric', month: 'short' }));
    data.push(
      orders.filter(o => o.date >= d && o.date < next && o.status === 'completed')
            .reduce((s, o) => s + parseFloat(o.totalPrice || 0), 0)
    );
  }

  if (revenueChartInst) revenueChartInst.destroy();
  revenueChartInst = new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        data, borderColor: '#c8965a',
        backgroundColor: c => {
          const g = c.chart.ctx.createLinearGradient(0, 0, 0, 180);
          g.addColorStop(0, '#c8965a33'); g.addColorStop(1, '#c8965a00'); return g;
        },
        fill: true, tension: 0.4, borderWidth: 2, pointRadius: 0, pointHoverRadius: 4
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: true,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { maxTicksLimit: 7 } },
        y: { grid: { color: '#2e282033' }, border: { color: '#2e2820' }, beginAtZero: true }
      }
    }
  });
}

function renderMoodChart(orders) {
  const ctx = document.getElementById('moodChart');
  if (!ctx) return;

  const moodCounts = { happy: 0, relaxed: 0, stressed: 0, tired: 0, energetic: 0 };
  orders.forEach(o => {
    (o.drinkList || []).forEach(item => {
      const drink = allDrinks.find(d => d.name === item.name);
      if (drink?.moodTag && moodCounts.hasOwnProperty(drink.moodTag)) {
        moodCounts[drink.moodTag] += item.quantity || 1;
      }
    });
  });

  const labels = Object.keys(moodCounts);
  const values = Object.values(moodCounts);
  const colors = ['#f4c430', '#7eb8a4', '#a89bc0', '#d4856a', '#c8965a'];
  const total  = values.reduce((a, b) => a + b, 0) || 1;

  if (moodChartInst) moodChartInst.destroy();
  moodChartInst = new Chart(ctx, {
    type: 'doughnut',
    data: { labels, datasets: [{ data: values, backgroundColor: colors, borderColor: '#1a1714', borderWidth: 3 }] },
    options: { responsive: true, cutout: '68%', plugins: { legend: { display: false } } }
  });

  const moodEmojis = { happy: '😊', relaxed: '😌', stressed: '😰', tired: '😴', energetic: '⚡' };
  const legendEl = document.getElementById('moodLegend');
  if (legendEl) legendEl.innerHTML = labels.map((l, i) =>
    `<div class="legend-item"><span class="legend-dot" style="background:${colors[i]}"></span>${moodEmojis[l]} ${l} ${Math.round(values[i]/total*100)}%</div>`
  ).join('');
}

// Report_export

function exportReport() {
  const today = new Date().toLocaleDateString('en-MY');
  const start = new Date(); start.setHours(0,0,0,0);
  const todayOrders = allOrders.filter(o => o.date >= start);
  const rev = todayOrders.filter(o=>o.status==='completed').reduce((s,o)=>s+parseFloat(o.totalPrice||0),0);
  const todayStr = start.toISOString().slice(0,10);

  const csv = [
    `BrewMind Daily Report — ${today}`,
    '',
    `Total Orders Today,${todayOrders.length}`,
    `Revenue Today,Rs ${rev.toFixed(2)}`,
    `Active Reservations,${allReservations.filter(r=>r.date===todayStr&&r.status!=='cancelled').length}`,
    `Registered Users,${allUsers.length}`,
    '',
    'Order ID,Customer,Total,Status,Date',
    ...allOrders.slice(0, 50).map(o =>
      `${o.firestoreId?.slice(0,8)},${o.userName||'—'},Rs ${parseFloat(o.totalPrice||0).toFixed(2)},${o.status},${o.date?.toLocaleString('en-MY')||'—'}`
    )
  ].join('\n');

  const blob = new Blob([csv], { type: 'text/csv' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `brewmind-${today.replace(/\//g,'-')}.csv`;
  a.click();
  showToast('✓ Report downloaded as CSV');
}


// Confirm a reservation

async function confirmReservation(firestoreId) {
  try {
    await fb().updateDoc(fb().doc(getDB(), 'reservations', firestoreId), {
      status: 'confirmed'
    });
    showToast('✓ Reservation confirmed in Firebase');
  } catch (e) {
    showToast('Failed: ' + e.message, 'error');
  }
}

// Update reservation

async function updateReservationStatus(firestoreId, status) {
  try {
    await fb().updateDoc(fb().doc(getDB(), 'reservations', firestoreId), { status });
    showToast(`✓ Reservation updated → ${status}`);
  } catch (e) {
    showToast('Failed: ' + e.message, 'error');
  }
}
