
function renderLeaderboard() {
  const podium = document.getElementById('podiumRow');
  const list   = document.getElementById('leaderboardList');
  if (!list) return;

  if (!allLeaderboard.length) {
    if (podium) podium.innerHTML = '';
    list.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">⭐</div>
      <div class="empty-state-text">No leaderboard data yet.<br>
        <small>Points are awarded when users place orders and make reservations.</small>
      </div>
    </div>`;
    return;
  }

  const colors = ['#c8965a', '#7eb8a4', '#d4856a', '#a89bc0'];
  const top3   = allLeaderboard.slice(0, 3);

//List orders

  if (podium && top3.length) {
    const display = top3.length >= 3 ? [top3[1], top3[0], top3[2]] : [top3[0]];
    const ranks   = top3.length >= 3 ? [2, 1, 3] : [1];
    podium.innerHTML = display.map((u, idx) => {
      const rank = ranks[idx];
      return `
        <div class="podium-card ${rank === 1 ? 'first' : ''}">
          <div class="podium-rank">${rank}</div>
          <div class="podium-avatar" style="background:${colors[rank % colors.length]}">${(u.name || 'U')[0].toUpperCase()}</div>
          <div class="podium-name">${u.name || '—'}</div>
          <div class="podium-points">${u.points || 0}</div>
          <div class="podium-pts-label">Star Points</div>
          ${rank === 1 ? '<div style="font-size:24px;margin-top:8px">👑</div>' : ''}
        </div>`;
    }).join('');
  }

  list.innerHTML = allLeaderboard.map((u, i) => `
    <div class="lb-row">
      <span class="lb-rank">${String(i + 1).padStart(2, '0')}</span>
      <div class="lb-avatar" style="background:${colors[i % colors.length]}">${(u.name || 'U')[0].toUpperCase()}</div>
      <div>
        <div class="lb-name">${u.name || '—'}</div>
        <div style="font-size:11px;color:var(--text3)">${u.email || ''}</div>
      </div>
      <span class="lb-points">${u.points || 0} ⭐</span>
      ${i < 3 ? `<span class="lb-badge-star">${['🥇', '🥈', '🥉'][i]}</span>` : ''}
    </div>
  `).join('');
}

