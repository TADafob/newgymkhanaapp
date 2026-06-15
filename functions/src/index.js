const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { sendSMS, sendWhatsApp } = require('./africasTalking');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ── Helper: send FCM + persist to notifications_collection ───────────────────
async function sendReminder(userId, { title, body, type, extraData = {} }) {
  const userDoc = await db.collection('users_members').doc(userId).get();
  const fcmToken = userDoc.data()?.fcm_Token;
  const notifEnabled = userDoc.data()?.notifications_enabled;

  // Persist to in-app notifications always
  await db.collection('notifications_collection').add({
    recipientId: userId,
    title,
    type,
    description: body,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isNew: true,
    ...extraData,
  });

  // Send push only if token exists and notifications are enabled
  if (!fcmToken || notifEnabled === false) return;

  await messaging.send({
    token: fcmToken,
    notification: { title, body },
    android: {
      priority: 'high',
      notification: { channelId: 'booking_updates' },
    },
    apns: {
      payload: { aps: { alert: { title, body }, sound: 'default' } },
    },
  });
}

// ── 1. Booking Reminders (runs daily at 7 AM EAT) ────────────────────────────
exports.bookingReminders = onSchedule('every day 04:00', async () => {
  const now = new Date();
  const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const in25h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

  const snap = await db.collection('bookings_collection')
    .where('start_Time', '>=', admin.firestore.Timestamp.fromDate(in24h))
    .where('start_Time', '<=', admin.firestore.Timestamp.fromDate(in25h))
    .where('reaction.status', '==', 'approved')
    .get();

  const promises = snap.docs.map((doc) => {
    const d = doc.data();
    const startTime = d.start_Time?.toDate();
    const timeStr = startTime
      ? startTime.toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' })
      : '';
    return sendReminder(d.user_Id, {
      title: '📅 Booking Reminder',
      body: `Your ${d.facility_Type} booking is tomorrow at ${timeStr}. Don't forget!`,
      type: 'booking_reminder',
      extraData: { bookingId: doc.id },
    });
  });

  await Promise.allSettled(promises);
  console.log(`[bookingReminders] Processed ${snap.size} bookings`);
});

// ── 2. Unpaid Booking Reminders (runs daily at 8 AM EAT) ─────────────────────
exports.unpaidBookingReminders = onSchedule('every day 05:00', async () => {
  const now = new Date();
  const cutoff = new Date(now.getTime() - 24 * 60 * 60 * 1000); // older than 24h

  const snap = await db.collection('bookings_collection')
    .where('reaction.isPaid', '==', false)
    .where('reaction.status', '==', 'approved')
    .where('booking_Date', '<=', admin.firestore.Timestamp.fromDate(cutoff))
    .get();

  const promises = snap.docs.map((doc) => {
    const d = doc.data();
    return sendReminder(d.user_Id, {
      title: '💳 Payment Pending',
      body: `Your ${d.facility_Type} booking has an outstanding payment. Please settle it to keep your booking.`,
      type: 'payment_reminder',
      extraData: { bookingId: doc.id },
    });
  });

  await Promise.allSettled(promises);
  console.log(`[unpaidBookingReminders] Processed ${snap.size} bookings`);
});

// ── 3. Subscription Expiry Reminders (runs daily at 9 AM EAT) ────────────────
exports.subscriptionReminders = onSchedule('every day 06:00', async () => {
  const now = new Date();

  // Windows: 7 days out and 1 day out
  const windows = [
    { days: 7, label: 'in 7 days' },
    { days: 1, label: 'tomorrow' },
  ];

  for (const { days, label } of windows) {
    const windowStart = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
    const windowEnd   = new Date(windowStart.getTime() + 24 * 60 * 60 * 1000);

    const snap = await db.collection('subscriptions_collection')
      .where('expiryDate', '>=', admin.firestore.Timestamp.fromDate(windowStart))
      .where('expiryDate', '<=', admin.firestore.Timestamp.fromDate(windowEnd))
      .where('status', '==', 'active')
      .get();

    const promises = snap.docs.map((doc) => {
      const d = doc.data();
      return sendReminder(d.userId, {
        title: '⚠️ Subscription Expiring Soon',
        body: `Your ${d.subsPlan} subscription expires ${label}. Renew now to avoid interruption.`,
        type: 'subscription_reminder',
        extraData: { subsId: doc.id },
      });
    });

    await Promise.allSettled(promises);
    console.log(`[subscriptionReminders] ${days}d window: ${snap.size} subs`);
  }
});

// ── Africa's Talking: Send booking confirmation SMS + WhatsApp ────────────────
exports.sendBookingNotification = onCall(async (request) => {
  const { phone, facilityType, startTime, bookingId, channel = 'sms' } = request.data;

  if (!phone || !facilityType || !startTime) {
    throw new HttpsError('invalid-argument', 'phone, facilityType and startTime are required');
  }

  const message = `NRB Gymkhana: Your ${facilityType} booking on ${startTime} has been confirmed. Booking ID: ${bookingId}. See you there!`;

  try {
    const result = channel === 'whatsapp'
      ? await sendWhatsApp(phone, message)
      : await sendSMS(phone, message);

    console.log(`[sendBookingNotification] ${channel} sent to ${phone}`, result);
    return { success: true, result };
  } catch (err) {
    console.error('[sendBookingNotification] Error:', err);
    throw new HttpsError('internal', err.message);
  }
});

// ── Africa's Talking: Send subscription notification ─────────────────────────
exports.sendSubscriptionNotification = onCall(async (request) => {
  const { phone, subsPlan, expiryDate, type, channel = 'sms' } = request.data;
  // type: 'activated' | 'expiring_soon' | 'expired'

  if (!phone || !subsPlan) {
    throw new HttpsError('invalid-argument', 'phone and subsPlan are required');
  }

  const messages = {
    activated: `NRB Gymkhana: Your ${subsPlan} subscription is now active. Enjoy your membership!`,
    expiring_soon: `NRB Gymkhana: Your ${subsPlan} subscription expires on ${expiryDate}. Renew now to avoid interruption.`,
    expired: `NRB Gymkhana: Your ${subsPlan} subscription has expired. Renew today to regain access.`,
  };

  const message = messages[type] || messages['activated'];

  try {
    const result = channel === 'whatsapp'
      ? await sendWhatsApp(phone, message)
      : await sendSMS(phone, message);

    console.log(`[sendSubscriptionNotification] ${channel} sent to ${phone}`, result);
    return { success: true, result };
  } catch (err) {
    console.error('[sendSubscriptionNotification] Error:', err);
    throw new HttpsError('internal', err.message);
  }
});

// ── Africa's Talking: Sandbox test function ───────────────────────────────────
// Call this from the app or Firebase console to verify AT credentials work.
exports.testAfricasTalking = onCall(async (request) => {
  const { phone, channel = 'sms' } = request.data;

  if (!phone) {
    throw new HttpsError('invalid-argument', 'phone is required');
  }

  const message = `NRB Gymkhana TEST: Africa's Talking ${channel.toUpperCase()} integration is working! 🎉`;

  try {
    const result = channel === 'whatsapp'
      ? await sendWhatsApp(phone, message)
      : await sendSMS(phone, message);

    console.log(`[testAfricasTalking] ${channel} test sent to ${phone}`, result);
    return { success: true, result };
  } catch (err) {
    console.error('[testAfricasTalking] Error:', err);
    throw new HttpsError('internal', err.message);
  }
});
