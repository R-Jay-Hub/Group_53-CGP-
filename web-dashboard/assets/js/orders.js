
function renderOrders() {
  const board = document.getElementById('ordersBoard');
  if (!board) return;

  const filtered = orderFilter === 'all'
    ? allOrders
    : allOrders.filter(o => o.status === orderFilter);

  if (!filtered.length) {
    board.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">◎</div>
      <div class="empty-state-text">No orders found.<br>
        <small>Orders placed in the mobile app appear here in real time.</small>
      </div>
    </div>`;
    return;
  }

  board.innerHTML = filtered.map(o => {
    const items    = (o.drinkList || []).map(d => `${d.name}${d.quantity > 1 ? ' ×' + d.quantity : ''}`).join(', ') || '—';
    const dateStr  = o.date?.toLocaleString?.('en-MY', { hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' }) || '—';
    const customer = o.userName || o.userID?.slice(0, 10) || 'Customer';
    return `
    <div class="order-row">
      <span class="order-id" style="font-family:'DM Mono',monospace;font-size:11px;color:var(--text3)">${o.firestoreId?.slice(0,8)}…</span>
      <span class="order-customer">${customer}</span>
      <span class="order-items">${items}</span>
      <span class="order-total">Rs ${parseFloat(o.totalPrice||0).toFixed(2)}</span>
      <span class="order-date">${dateStr}</span>
      <span class="badge badge-${o.status}">${o.status}</span>
      <button class="order-action-btn" onclick="openOrderModal('${o.firestoreId}')">Update</button>
    </div>`;
  }).join('');
}

function filterOrders(status, btn) {
  orderFilter = status;
  document.querySelectorAll('.sfilt').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  renderOrders();
}

function openOrderModal(firestoreId) {
  editingOrderId = firestoreId;
  const order    = allOrders.find(o => o.firestoreId === firestoreId);
  const items    = (order?.drinkList || []).map(d => d.name).join(', ') || 'Unknown items';
  document.getElementById('orderModalInfo').textContent = `Order ${firestoreId?.slice(0,8)}… — ${items}`;
  document.getElementById('orderModal').classList.add('open');
}

function closeOrderModal() {
  document.getElementById('orderModal').classList.remove('open');
  editingOrderId = null;
}

async function updateOrderStatus(status) {
  if (!editingOrderId) return;
  try {
    await fb().updateDoc(fb().doc(getDB(), 'orders', editingOrderId), { status });
    showToast(`✓ Order status → ${status} (saved to Firestore)`);
    closeOrderModal();
  } catch (e) {
    showToast('Update failed: ' + e.message, 'error');
  }
}

