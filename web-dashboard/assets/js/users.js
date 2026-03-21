
function renderUsers(data = allUsers) {
  const grid = document.getElementById('usersGrid');
  if (!grid) return;

  if (!data.length) {
    grid.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">◌</div>
      <div class="empty-state-text">No users yet.<br>
        <small>Users appear here when they register in the mobile app.</small>
      </div>
    </div>`;
    return;
  }

  const colors = ['#c8965a', '#7eb8a4', '#d4856a', '#a89bc0'];
  grid.innerHTML = data.map((u, i) => `
    <div class="user-card">
      <div class="user-avatar" style="background:${colors[i % colors.length]}">${(u.name || u.email || 'U')[0].toUpperCase()}</div>
      <div style="flex:1;min-width:0">
        <div class="user-name">${u.name || '—'}</div>
        <div class="user-email">${u.email || '—'}</div>
        <div class="user-stats">
          <div class="user-stat">⭐ <span>${u.starPoints || 0}</span> pts</div>
          <div class="user-stat">🎂 <span>${u.birthday || 'N/A'}</span></div>
        </div>
        <div class="allergy-list">
          ${(u.allergies || []).map(a => `<span class="allergy-chip">${a}</span>`).join('')}
          ${!(u.allergies?.length) ? '<span style="font-size:10px;color:var(--text3)">No allergies</span>' : ''}
        </div>
      </div>
    </div>
  `).join('');
}

function searchUsers(q) {
  const query = q.toLowerCase();
  renderUsers(allUsers.filter(u =>
    (u.name || '').toLowerCase().includes(query) ||
    (u.email || '').toLowerCase().includes(query)
  ));
}

