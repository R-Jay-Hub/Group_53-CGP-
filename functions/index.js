// ============================================================
// FILE: backend-config/functions/index.js
// SAVE TO: brewmind_app/functions/index.js
// ============================================================
// Firebase Cloud Functions
// These run on Google's servers automatically.
//
// HOW TO DEPLOY:
//   cd functions
//   npm install
//   firebase deploy --only functions
// ============================================================

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// ============================================================
// FUNCTION 1: Birthday Points
// Runs every day at 8:00 AM.
// Checks all users whose birthday matches today.
// Awards +50 star points to each matching user.
// ============================================================
exports.awardBirthdayPoints = functions.pubsub
  .schedule('0 8 * * *')       // Cron: every day at 8:00 AM
  .timeZone('Asia/Kuala_Lumpur')
  .onRun(async (context) => {
    const today = new Date();
    // Format today as MM-DD (e.g., "03-10" for March 10)
    const mmdd =
      String(today.getMonth() + 1).padStart(2, '0') + '-' +
      String(today.getDate()).padStart(2, '0');

    console.log(`Checking birthdays for date: ${mmdd}`);

    // Get all users
    const usersSnap = await db.collection('users').get();
    const batch = db.batch(); // Batch write for efficiency

    let count = 0;
    usersSnap.forEach(doc => {
      const user = doc.data();
      // user.birthday is stored as "YYYY-MM-DD", so slice last 5 chars for MM-DD
      const userBdayMMDD = user.birthday ? user.birthday.slice(5) : null;

      if (userBdayMMDD === mmdd) {
        console.log(`Birthday found for: ${user.name} (${doc.id})`);

        // Award 50 points to the user
        batch.update(doc.ref, {
          starPoints: admin.firestore.FieldValue.increment(50)
        });

        // Also update leaderboard
        const lbRef = db.collection('leaderboard').doc(doc.id);
        batch.update(lbRef, {
          points: admin.firestore.FieldValue.increment(50),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });

        count++;
      }
    });

    await batch.commit();
    console.log(`Birthday points awarded to ${count} users.`);
    return null;
  });


// ============================================================
// FUNCTION 2: Order Status Notification
// Triggered whenever an order document is updated in Firestore.
// Sends a push notification to the customer via FCM.
// ============================================================
exports.onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send notification if status actually changed
    if (before.status === after.status) return null;

    const newStatus = after.status;
    const userId = after.userID;

    // Get the user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return null;
    }

    // Build notification message based on status
    const statusMessages = {
      preparing: { title: '☕ Your order is being prepared!', body: 'Our baristas are working on it.' },
      ready:     { title: '✅ Your order is ready!', body: 'Come pick up your drink!' },
      completed: { title: '⭐ Enjoy your drink!', body: 'Thanks for visiting BrewMind. +10 points earned!' },
      cancelled: { title: '❌ Order cancelled', body: 'Your order has been cancelled. Contact us for help.' },
    };

    const msg = statusMessages[newStatus];
    if (!msg) return null;

    // Send FCM notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: msg.title,
        body: msg.body,
      },
      android: {
        notification: { sound: 'default', channelId: 'brewmind_orders' }
      },
      apns: {
        payload: { aps: { sound: 'default' } }
      }
    });

    console.log(`Notification sent to ${userId}: ${msg.title}`);
    return null;
  });


// ============================================================
// FUNCTION 3: Reservation Confirmation
// Triggered when a new reservation is created.
// Sends a confirmation notification to the customer.
// ============================================================
exports.onNewReservation = functions.firestore
  .document('reservations/{resId}')
  .onCreate(async (snap, context) => {
    const res = snap.data();
    const userId = res.userID;

    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    const userName = userDoc.data()?.name?.split(' ')[0] || 'there';

    if (!fcmToken) return null;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '🗓 Reservation received!',
        body: `Hi ${userName}! Table ${res.tableNumber} is reserved for ${res.date} at ${res.time}. +5 points earned!`,
      }
    });

    return null;
  });


// ============================================================
// FUNCTION 4: Rebuild Leaderboard Rankings
// Runs every hour to re-compute ranks for all users.
// This keeps rank numbers accurate as points change.
// ============================================================
exports.rebuildLeaderboard = functions.pubsub
  .schedule('0 * * * *')  // Every hour
  .onRun(async () => {
    const snap = await db.collection('leaderboard')
      .orderBy('points', 'desc')
      .get();

    const batch = db.batch();
    snap.docs.forEach((doc, index) => {
      batch.update(doc.ref, { rank: index + 1 });
    });

    await batch.commit();
    console.log(`Leaderboard ranks rebuilt for ${snap.size} users.`);
    return null;
  });
