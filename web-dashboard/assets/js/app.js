
// Firebase_access

const getDB   = () => window._db;
const getAuth = () => window._auth;
const fb      = () => window._fb;

// State

let currentPage      = 'dashboard';
let drinkFilter      = 'all';
let orderFilter      = 'all';
let editingDrinkId   = null;
let editingOrderId   = null;
let currentDateOffset = 0;

// Cached_Firestore_data

let allDrinks        = [];
let allOrders        = [];
let allReservations  = [];
let allUsers         = [];
let allLeaderboard   = [];

// Chart_instances
let ordersChartInst  = null;
let drinksChartInst  = null;
let revenueChartInst = null;
let moodChartInst    = null;

// Firestore_unsubscribe
let unsubOrders      = null;
let unsubReservations = null;
let unsubDrinks      = null;

// App_init

window.initApp = function () {
  console.log('🚀 initApp() called — starting Firestore connections');

  updateClock();
  setInterval(updateClock, 1000);
  setupNavigation();
  setupModalClosers();
  updateDateDisplay();

  // Connect_Firestore_listeners

  listenToOrders();
  listenToReservations();
  listenToDrinks();
  loadUsers();
  loadLeaderboard();


  renderDashboardCharts();
};


if (window._pendingInit) {
  window._pendingInit = false;
  window.initApp();
}

// Clock

function updateClock() {
  const el = document.getElementById('timeDisplay');
  if (el) el.textContent = new Date().toLocaleTimeString('en-MY',
    { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}

// Tosat

let _toastTimer;
function showToast(msg, type = '') {
  const t = document.getElementById('toast');
  if (!t) return;
  t.textContent = msg;
  t.className   = `toast show ${type}`;
  clearTimeout(_toastTimer);
  _toastTimer = setTimeout(() => t.classList.remove('show'), 3500);
}

// Side_bar

function toggleSidebar() {
  const sb = document.getElementById('sidebar');
  const mc = document.querySelector('.main-content');
  if (window.innerWidth > 768) {
    sb.classList.toggle('hidden');
    mc.classList.toggle('expanded');
  } else {
    sb.classList.toggle('mobile-open');
  }
}

// Navigation

function setupNavigation() {
  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', e => {
      e.preventDefault();
      navigate(item.dataset.page);
    });
  });
}

function navigate(page) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById(`page-${page}`)?.classList.add('active');
  document.querySelector(`[data-page="${page}"]`)?.classList.add('active');

  const titles = {
    dashboard: 'Dashboard', analytics: 'Analytics', drinks: 'Drink Menu',
    orders: 'Orders', reservations: 'Reservations', users: 'Customers', leaderboard: 'Leaderboard'
  };
  document.getElementById('pageTitle').textContent = titles[page] || page;
  currentPage = page;

  if (page === 'drinks')       renderDrinks();
  if (page === 'orders')       renderOrders();
  if (page === 'reservations') renderReservations();
  if (page === 'users')        renderUsers();
  if (page === 'leaderboard')  renderLeaderboard();
  if (page === 'analytics')    loadAnalytics();
}

// Modal

function setupModalClosers() {
  ['drinkModal', 'orderModal'].forEach(id => {
    document.getElementById(id)?.addEventListener('click', function (e) {
      if (e.target === this) this.classList.remove('open');
    });
  });
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') { closeDrinkModal(); closeOrderModal(); }
  });
}

// Auth

async function doLogin() {
  const email    = document.getElementById('loginEmail').value.trim();
  const password = document.getElementById('loginPassword').value;
  const errEl    = document.getElementById('loginError');
  const btn      = document.getElementById('loginBtn');

  errEl.textContent = '';
  if (!email || !password) {
    errEl.textContent = 'Please enter your email and password.';
    return;
  }

  btn.textContent = 'Signing in...';
  btn.disabled    = true;

  try {
    await fb().signInWithEmailAndPassword(getAuth(), email, password);
  } catch (e) {
    const msgs = {
      'auth/user-not-found':     'No account found with this email.',
      'auth/wrong-password':     'Incorrect password.',
      'auth/invalid-email':      'Please enter a valid email address.',
      'auth/invalid-credential': 'Invalid email or password.',
      'auth/too-many-requests':  'Too many attempts. Try again later.',
    };
    errEl.textContent = msgs[e.code] || `Login error: ${e.message}`;
  } finally {
    btn.textContent = 'Sign In';
    btn.disabled    = false;
  }
}

async function doLogout() {
  if (unsubOrders)       unsubOrders();
  if (unsubReservations) unsubReservations();
  if (unsubDrinks)       unsubDrinks();
  await fb().signOut(getAuth());
}

