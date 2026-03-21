
function renderDrinks(data = allDrinks) {
  const grid = document.getElementById('drinksGrid');
  if (!grid) return;

  const filtered = drinkFilter === 'all' ? data : data.filter(d => d.moodTag === drinkFilter);

  if (!filtered.length) {
    grid.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">☕</div>
      <div class="empty-state-text">
        ${allDrinks.length === 0
          ? 'No drinks in Firestore yet.<br><small>Click "+ Add New Drink" to add your first drink.</small>'
          : 'No drinks match this filter.'}
      </div>
    </div>`;
    return;
  }

  grid.innerHTML = filtered.map(d => `
    <div class="drink-card">
      <span class="drink-emoji">${d.emoji || '☕'}</span>
      <div class="drink-name">${d.name || '—'}</div>
      <div class="drink-desc">${d.description || ''}</div>
      <div class="allergen-tags">${(d.allergens || []).map(a => `<span class="allergen-tag">⚠ ${a}</span>`).join('')}</div>
      <div class="drink-meta" style="margin-top:10px">
        <span class="drink-price">Rs ${parseFloat(d.price||0).toFixed(2)}</span>
        <span class="mood-tag ${d.moodTag}">${moodEmoji(d.moodTag)} ${d.moodTag || ''}</span>
      </div>
      ${!d.available ? '<div style="font-size:10px;color:var(--red);margin-top:6px">⚠ Hidden from app</div>' : ''}
      <div class="drink-actions">
        <button class="action-btn" onclick="editDrink('${d.firestoreId}')">✎ Edit</button>
        <button class="action-btn del" onclick="deleteDrink('${d.firestoreId}','${(d.name||'').replace(/'/g,'\\\'') }')">✕ Delete</button>
      </div>
    </div>
  `).join('');
}

function moodEmoji(mood) {
  return { happy: '😊', relaxed: '😌', stressed: '😰', tired: '😴', energetic: '⚡' }[mood] || '';
}

function filterDrinks(mood, btn) {
  drinkFilter = mood;
  document.querySelectorAll('.ftab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  renderDrinks();
}

function searchDrinks(q) {
  const query = q.toLowerCase();
  renderDrinks(allDrinks.filter(d =>
    (d.name || '').toLowerCase().includes(query) ||
    (d.description || '').toLowerCase().includes(query)
  ));
}

function openDrinkModal(drink = null) {
  editingDrinkId = drink ? drink.firestoreId : null;
  document.getElementById('drinkModalTitle').textContent = drink ? 'Edit Drink' : 'Add New Drink';
  document.getElementById('drinkName').value      = drink?.name        || '';
  document.getElementById('drinkPrice').value     = drink?.price       || '';
  document.getElementById('drinkDesc').value      = drink?.description || '';
  document.getElementById('drinkMood').value      = drink?.moodTag     || '';
  document.getElementById('drinkCat').value       = drink?.category    || 'Coffee';
  document.getElementById('drinkEmoji').value     = drink?.emoji       || '';
  document.getElementById('drinkAvailable').value = drink?.available === false ? 'false' : 'true';
  document.querySelectorAll('.allergen-grid input').forEach(cb => {
    cb.checked = (drink?.allergens || []).includes(cb.value);
  });
  document.getElementById('drinkModal').classList.add('open');
}

function closeDrinkModal() {
  document.getElementById('drinkModal').classList.remove('open');
  editingDrinkId = null;
}

function editDrink(firestoreId) {
  const drink = allDrinks.find(d => d.firestoreId === firestoreId);
  if (drink) openDrinkModal(drink);
}

async function deleteDrink(firestoreId, name) {
  if (!confirm(`Delete "${name}" from Firestore? This cannot be undone.`)) return;
  try {
    await fb().deleteDoc(fb().doc(getDB(), 'drinks', firestoreId));
    showToast(`✓ "${name}" deleted from Firestore`);
  } catch (e) {
    showToast('Delete failed: ' + e.message, 'error');
  }
}

async function saveDrink() {
  const name      = document.getElementById('drinkName').value.trim();
  const price     = parseFloat(document.getElementById('drinkPrice').value);
  const desc      = document.getElementById('drinkDesc').value.trim();
  const moodTag   = document.getElementById('drinkMood').value;
  const category  = document.getElementById('drinkCat').value;
  const emoji     = document.getElementById('drinkEmoji').value.trim() || '☕';
  const available = document.getElementById('drinkAvailable').value === 'true';
  const allergens = [...document.querySelectorAll('.allergen-grid input:checked')].map(cb => cb.value);

  if (!name || isNaN(price) || !moodTag) {
    showToast('⚠ Please fill in Name, Price, and Mood Tag', 'error');
    return;
  }

  const drinkData = { name, price, description: desc, moodTag, category, emoji, available, allergens };
  const btn = document.getElementById('saveDrinkBtn');
  btn.textContent = 'Saving...';
  btn.disabled    = true;

  try {
    if (editingDrinkId) {
      await fb().updateDoc(fb().doc(getDB(), 'drinks', editingDrinkId), drinkData);
      showToast(`✓ "${name}" updated in Firestore`);
    } else {
      drinkData.createdAt = fb().serverTimestamp();
      await fb().addDoc(fb().collection(getDB(), 'drinks'), drinkData);
      showToast(`✓ "${name}" added to Firestore`);
    }
    closeDrinkModal();
  } catch (e) {
    showToast('Save failed: ' + e.message, 'error');
    console.error('Save drink error:', e);
  } finally {
    btn.textContent = '💾 Save to Firebase';
    btn.disabled    = false;
  }
}

