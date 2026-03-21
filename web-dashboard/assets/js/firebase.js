
function listenToOrders() {
  console.log('📡 Connecting to Firestore: orders collection');
  const db = getDB();

  const q = fb().query(
    fb().collection(db, 'orders'),
    fb().limit(200)
  );

  unsubOrders = fb().onSnapshot(q,
    snapshot => {
      console.log(`✅ Orders received: ${snapshot.size} documents`);

      allOrders = snapshot.docs.map(d => {
        const data = d.data();
        return {
          firestoreId: d.id,
          ...data,
          date: data.date?.toDate?.() ?? (data.date ? new Date(data.date) : new Date())
        };
      });

      allOrders.sort((a, b) => b.date - a.date);

      // Update-pending_orders

      const pending = allOrders.filter(o => o.status === 'pending').length;
      const badge   = document.getElementById('badgeOrders');
      if (badge) badge.textContent = pending;

      updateDashboardStats();

      if (currentPage === 'dashboard') {
        renderRecentOrders();
        renderDashboardCharts();
      }
      if (currentPage === 'orders')    renderOrders();
      if (currentPage === 'analytics') loadAnalytics();
    },
    err => {
      console.error('❌ Orders error:', err.code, err.message);
      showToast(`Orders error: ${err.message}`, 'error');
    }
  );
}

//Firestore Reservations

function listenToReservations() {
  console.log('📡 Connecting to Firestore: reservations collection');
  const db = getDB();

  const q = fb().collection(db, 'reservations');

  unsubReservations = fb().onSnapshot(q,
    snapshot => {
      console.log(`✅ Reservations received: ${snapshot.size} documents`);

      allReservations = snapshot.docs.map(d => ({ firestoreId: d.id, ...d.data() }));

      allReservations.sort((a, b) => {
        const da = a.createdAt?.toDate?.() ?? new Date(a.date || 0);
        const db2 = b.createdAt?.toDate?.() ?? new Date(b.date || 0);
        return db2 - da;
      });

      updateDashboardStats();
      if (currentPage === 'reservations') renderReservations();
      if (currentPage === 'dashboard')    renderTodayReservations();
    },
    err => console.error('❌ Reservations error:', err.code, err.message)
  );
}

//FireStore Drinks

function listenToDrinks() {
  console.log('📡 Connecting to Firestore: drinks collection');
  const db = getDB();

  unsubDrinks = fb().onSnapshot(fb().collection(db, 'drinks'),
    snapshot => {
      console.log(`✅ Drinks received: ${snapshot.size} documents`);

      allDrinks = snapshot.docs.map(d => ({ firestoreId: d.id, ...d.data() }));

      allDrinks.sort((a, b) => (a.name || '').localeCompare(b.name || ''));

      const badge = document.getElementById('badgeDrinks');
      if (badge) badge.textContent = allDrinks.length;

      if (currentPage === 'drinks')    renderDrinks();
      if (currentPage === 'dashboard') renderDashboardDrinksChart();
    },
    err => {
      console.error('❌ Drinks error:', err.code, err.message);
      const grid = document.getElementById('drinksGrid');
      if (grid) grid.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-text">
            Firestore error: ${err.message}<br>
            <small>Check your Firestore rules in Firebase Console →<br>
            Firestore → Rules → set to allow read, write</small>
          </div>
        </div>`;
    }
  );
}

//Firestore Users
async function loadUsers() {
  console.log('📡 Loading users from Firestore');
  try {
    const snapshot = await fb().getDocs(fb().collection(getDB(), 'users'));
    console.log(`✅ Users received: ${snapshot.size} documents`);
    allUsers = snapshot.docs.map(d => ({ firestoreId: d.id, ...d.data() }));
    updateDashboardStats();
    if (currentPage === 'users') renderUsers();
  } catch (e) {
    console.error('❌ Users error:', e.code, e.message);
  }
}

//Firestore Leaderboard
async function loadLeaderboard() {
  console.log('📡 Loading leaderboard from Firestore');
  try {
    const snapshot = await fb().getDocs(fb().collection(getDB(), 'leaderboard'));
    console.log(`✅ Leaderboard received: ${snapshot.size} documents`);
    allLeaderboard = snapshot.docs.map(d => ({ firestoreId: d.id, ...d.data() }));
    // Sort by points descending
    allLeaderboard.sort((a, b) => (b.points || 0) - (a.points || 0));
    allLeaderboard.forEach((u, i) => u.rank = i + 1);
    if (currentPage === 'leaderboard') renderLeaderboard();
  } catch (e) {
    console.error('❌ Leaderboard error:', e.code, e.message);
  }
}


