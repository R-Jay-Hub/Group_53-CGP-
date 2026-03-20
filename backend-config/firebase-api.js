// =============================================
//   BREWMIND — FIREBASE BACKEND CONFIG & API
//   firebase-config.js
// =============================================
// INSTRUCTIONS: Replace all values below with
// your actual Firebase project credentials.
// Get them from: Firebase Console > Project Settings > General
// =============================================

import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getMessaging } from "firebase/messaging";

// ── YOUR FIREBASE CONFIG ──────────────────────
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const messaging = getMessaging(app);


// =============================================
//   FIRESTORE COLLECTION SCHEMAS
// =============================================
//
// COLLECTION: users
// Document ID: Firebase Auth UID
// Fields:
//   userID      : string   (same as doc ID)
//   name        : string
//   email       : string
//   allergies   : string[] (e.g. ["milk","nuts"])
//   birthday    : string   (e.g. "1998-05-14")
//   starPoints  : number   (default 0)
//   createdAt   : timestamp
//   fcmToken    : string   (for push notifications)
//
// COLLECTION: drinks
// Document ID: auto-generated
// Fields:
//   drinkID     : string
//   name        : string
//   description : string
//   ingredients : string[]
//   allergens   : string[]
//   nutrition   : map { calories, caffeine, fat, sugar }
//   price       : number
//   moodTag     : string   (happy|relaxed|stressed|tired|energetic)
//   category    : string
//   emoji       : string
//   available   : boolean
//   createdAt   : timestamp
//
// COLLECTION: orders
// Document ID: auto-generated
// Fields:
//   orderID     : string
//   userID      : string
//   drinkList   : array of { drinkID, name, quantity, price }
//   totalPrice  : number
//   status      : string  (pending|preparing|ready|completed|cancelled)
//   date        : timestamp
//   notes       : string
//
// COLLECTION: reservations
// Document ID: auto-generated
// Fields:
//   reservationID : string
//   userID        : string
//   date          : string  (e.g. "2026-03-10")
//   time          : string  (e.g. "14:00")
//   tableNumber   : number
//   partySize     : number
//   status        : string  (pending|confirmed|cancelled)
//   createdAt     : timestamp
//
// COLLECTION: leaderboard
// Document ID: userID
// Fields:
//   userID      : string
//   name        : string
//   points      : number
//   rank        : number  (updated by Cloud Function)
//   lastUpdated : timestamp
//
// =============================================


// =============================================
//   API HELPER FUNCTIONS
// =============================================

import {
  collection, doc, getDoc, getDocs, addDoc,
  updateDoc, deleteDoc, query, where, orderBy,
  limit, serverTimestamp, increment, onSnapshot
} from "firebase/firestore";

// ── AUTH API ──────────────────────────────────
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  updateProfile
} from "firebase/auth";

/**
 * Register a new user
 * @param {string} name - Display name
 * @param {string} email
 * @param {string} password
 * @param {string} birthday - ISO date string
 * @param {string[]} allergies - array of allergen strings
 */
export async function registerUser(name, email, password, birthday, allergies = []) {
  const cred = await createUserWithEmailAndPassword(auth, email, password);
  await updateProfile(cred.user, { displayName: name });

  await setDoc(doc(db, "users", cred.user.uid), {
    userID: cred.user.uid,
    name,
    email,
    allergies,
    birthday,
    starPoints: 0,
    createdAt: serverTimestamp()
  });

  return cred.user;
}

/**
 * Login user
 */
export async function loginUser(email, password) {
  return await signInWithEmailAndPassword(auth, email, password);
}

/**
 * Logout
 */
export async function logoutUser() {
  return await signOut(auth);
}

/**
 * Send password reset email
 */
export async function resetPassword(email) {
  return await sendPasswordResetEmail(auth, email);
}


// ── DRINKS API ────────────────────────────────

/**
 * Get all available drinks
 */
export async function getDrinks() {
  const q = query(collection(db, "drinks"), where("available", "==", true));
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

/**
 * Get drinks filtered by mood
 */
export async function getDrinksByMood(mood) {
  const q = query(
    collection(db, "drinks"),
    where("moodTag", "==", mood),
    where("available", "==", true)
  );
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

/**
 * Get drinks that don't contain specified allergens
 */
export async function getDrinksFiltered(userAllergens) {
  const drinks = await getDrinks();
  return drinks.filter(drink =>
    !drink.allergens.some(a => userAllergens.includes(a))
  );
}

/**
 * Add new drink (admin)
 */
export async function addDrink(drinkData) {
  return await addDoc(collection(db, "drinks"), {
    ...drinkData,
    available: true,
    createdAt: serverTimestamp()
  });
}

/**
 * Update drink (admin)
 */
export async function updateDrink(drinkId, updates) {
  return await updateDoc(doc(db, "drinks", drinkId), updates);
}

/**
 * Delete drink (admin)
 */
export async function deleteDrinkById(drinkId) {
  return await deleteDoc(doc(db, "drinks", drinkId));
}


// ── ORDERS API ────────────────────────────────

/**
 * Place a new order
 * Automatically awards 10 star points
 */
export async function placeOrder(userId, drinkList, totalPrice, notes = "") {
  const orderRef = await addDoc(collection(db, "orders"), {
    userID: userId,
    drinkList,
    totalPrice,
    notes,
    status: "pending",
    date: serverTimestamp()
  });

  // Award 10 star points per order
  await updateDoc(doc(db, "users", userId), {
    starPoints: increment(10)
  });

  // Update leaderboard
  await updateLeaderboard(userId, 10);

  return orderRef;
}

/**
 * Get orders for a specific user
 */
export async function getUserOrders(userId) {
  const q = query(
    collection(db, "orders"),
    where("userID", "==", userId),
    orderBy("date", "desc")
  );
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

/**
 * Get all orders (admin) — real-time listener
 */
export function subscribeToOrders(callback) {
  const q = query(collection(db, "orders"), orderBy("date", "desc"), limit(50));
  return onSnapshot(q, snap => {
    callback(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  });
}

/**
 * Update order status (admin)
 */
export async function updateOrderStatus(orderId, status) {
  return await updateDoc(doc(db, "orders", orderId), { status });
}


// ── RESERVATIONS API ──────────────────────────

/**
 * Create a table reservation
 * Automatically awards 5 star points
 */
export async function createReservation(userId, date, time, tableNumber, partySize) {
  const resRef = await addDoc(collection(db, "reservations"), {
    userID: userId,
    date,
    time,
    tableNumber,
    partySize,
    status: "pending",
    createdAt: serverTimestamp()
  });

  // Award 5 star points
  await updateDoc(doc(db, "users", userId), {
    starPoints: increment(5)
  });

  await updateLeaderboard(userId, 5);
  return resRef;
}

/**
 * Cancel a reservation
 */
export async function cancelReservation(reservationId) {
  return await updateDoc(doc(db, "reservations", reservationId), {
    status: "cancelled"
  });
}

/**
 * Get reservations for a date (admin)
 */
export async function getReservationsByDate(date) {
  const q = query(collection(db, "reservations"), where("date", "==", date));
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

/**
 * Check if a table is available
 */
export async function checkTableAvailability(date, time, tableNumber) {
  const q = query(
    collection(db, "reservations"),
    where("date", "==", date),
    where("time", "==", time),
    where("tableNumber", "==", tableNumber),
    where("status", "!=", "cancelled")
  );
  const snap = await getDocs(q);
  return snap.empty; // true = available
}


// ── LOYALTY / LEADERBOARD API ─────────────────

/**
 * Update leaderboard entry
 */
export async function updateLeaderboard(userId, pointsToAdd) {
  const lbRef = doc(db, "leaderboard", userId);
  const snap = await getDoc(lbRef);

  if (snap.exists()) {
    await updateDoc(lbRef, { points: increment(pointsToAdd), lastUpdated: serverTimestamp() });
  } else {
    const userSnap = await getDoc(doc(db, "users", userId));
    await setDoc(lbRef, {
      userID: userId,
      name: userSnap.data().name,
      points: pointsToAdd,
      lastUpdated: serverTimestamp()
    });
  }
}

/**
 * Get top N users for leaderboard
 */
export async function getLeaderboard(topN = 20) {
  const q = query(collection(db, "leaderboard"), orderBy("points", "desc"), limit(topN));
  const snap = await getDocs(q);
  return snap.docs.map((d, i) => ({ rank: i + 1, ...d.data() }));
}

/**
 * Award birthday bonus points (call this via Cloud Functions on user's birthday)
 */
export async function awardBirthdayPoints(userId) {
  const BIRTHDAY_BONUS = 50;
  await updateDoc(doc(db, "users", userId), {
    starPoints: increment(BIRTHDAY_BONUS)
  });
  await updateLeaderboard(userId, BIRTHDAY_BONUS);
}


// ── MOOD-BASED RECOMMENDATION ─────────────────

/**
 * Get recommended drinks based on mood + filter allergens
 */
export async function getMoodRecommendations(mood, userAllergens = []) {
  const moodDrinks = await getDrinksByMood(mood);
  if (userAllergens.length === 0) return moodDrinks;
  return moodDrinks.filter(d =>
    !d.allergens.some(a => userAllergens.includes(a))
  );
}
