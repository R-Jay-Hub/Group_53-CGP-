
function renderReservations() {
  const tbody = document.getElementById('reservationsBody');
  if (!tbody) return;

  if (!allReservations.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="loading-cell">No reservations yet.</td></tr>';
    return;
  }

  tbody.innerHTML = allReservations.map(r => `
    <tr>
      <td><span style="font-family:'DM Mono',monospace;font-size:11px">${r.firestoreId?.slice(0,8)}…</span></td>
      <td style="font-weight:500;color:var(--text)">${r.userName || r.userID?.slice(0,8) || '—'}</td>
      <td>${r.date || '—'}</td>
      <td style="font-family:'DM Mono',monospace">${r.time || '—'}</td>
      <td>Table ${r.tableNumber || '—'}</td>
      <td>${r.partySize || 1} guests</td>
      <td><span class="badge badge-${r.status}">${r.status}</span></td>
      <td style="display:flex;gap:6px">
        ${r.status === 'pending' ? `
          <button class="action-btn" onclick="confirmReservation('${r.firestoreId}')">✓ Confirm</button>
          <button class="action-btn del" onclick="cancelReservation('${r.firestoreId}')">✕ Cancel</button>
        ` : r.status === 'confirmed' ? `
          <button class="action-btn del" onclick="cancelReservation('${r.firestoreId}')">✕ Cancel</button>
        ` : `
          <button class="action-btn" disabled style="opacity:.4;cursor:not-allowed">Cancelled</button>
        `}
      </td>
    </tr>
  `).join('');
}

async function cancelReservation(firestoreId) {
  if (!confirm('Cancel this reservation?')) return;
  try {
    await fb().updateDoc(fb().doc(getDB(), 'reservations', firestoreId), { status: 'cancelled' });
    showToast('✓ Reservation cancelled in Firestore');
  } catch (e) {
    showToast('Failed: ' + e.message, 'error');
  }
}

function updateDateDisplay() {
  const d = new Date();
  d.setDate(d.getDate() + currentDateOffset);
  const el = document.getElementById('currentDateDisplay');
  if (el) el.textContent = d.toLocaleDateString('en-MY', { weekday: 'short', day: 'numeric', month: 'long' });
}

function changeDate(offset) {
  currentDateOffset += offset;
  updateDateDisplay();
}

