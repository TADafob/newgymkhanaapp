require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');
const AfricasTalking = require('africastalking');

// ── Firebase Admin init ──────────────────────────────────────────────────────
// Download your service account key from:
// Firebase Console → Project Settings → Service Accounts → Generate new private key
// Save it as server/serviceAccountKey.json
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nrbgymkhanaapp',
});

const db = admin.firestore();
const app = express();
app.use(express.json());

// ── Africa's Talking init ─────────────────────────────────────────────────────
// For sandbox: AT_USERNAME=sandbox, AT_API_KEY=any_value
// For production: use your real credentials (Account Username and Production API Key)
const AT_USERNAME = (process.env.AT_USERNAME || 'sandbox').trim();
const AT_API_KEY = (process.env.AT_API_KEY || '').trim();

const at = AfricasTalking({
  username: AT_USERNAME,
  apiKey: AT_API_KEY,
});
const atSMS = at.SMS;

function normalizePhone(phone) {
  // Strip spaces/dashes, ensure E.164 format with +254 for Kenya
  let p = String(phone).replace(/[\s\-]/g, '');
  if (p.startsWith('0')) p = '+254' + p.slice(1);
  else if (p.startsWith('254') && !p.startsWith('+')) p = '+' + p;
  else if (!p.startsWith('+')) p = '+254' + p;
  return p;
}

async function sendSMS(to, message, from = null) {
  try {
    const numbers = (Array.isArray(to) ? to : [to]).map(normalizePhone);
    const options = { to: numbers, message, from: from || undefined };
    return await atSMS.send(options);
  } catch (err) {
    // Log the full AT error response for debugging
    console.error('[AT sendSMS error]', err?.response?.data || err.message);
    throw err;
  }
}

// ── AT: Send notification (SMS or WhatsApp) ───────────────────────────────────
app.post('/at/notify', async (req, res) => {
  const { phone, message, channel = 'sms', from } = req.body;
  if (!phone || !message) {
    return res.status(400).json({ error: 'phone and message are required' });
  }
  try {
    // For WhatsApp in Production, 'from' MUST be your registered WhatsApp channel number.
    // For SMS, 'from' is your Shortcode or Alphanumeric Sender ID.
    // If 'from' is omitted, Africa's Talking uses your account's default.
    const result = await sendSMS(phone, message, from);
    console.log(`[AT/${channel}] Sent to ${phone}:`, result);
    res.json({ success: true, result });
  } catch (err) {
    console.error('[AT notify error]', err);
    res.status(500).json({ error: err.message });
  }
});

// ── AT: Sandbox test endpoint ─────────────────────────────────────────────────
app.post('/at/test', async (req, res) => {
  const { phone, channel = 'sms' } = req.body;
  if (!phone) return res.status(400).json({ error: 'phone is required' });
  try {
    const result = await sendSMS(phone, `NRB Gymkhana TEST: Africa's Talking ${channel.toUpperCase()} is working! 🎉`);
    console.log(`[AT/test] Sent to ${phone}:`, result);
    res.json({ success: true, result });
  } catch (err) {
    console.error('[AT test error]', err);
    res.status(500).json({ error: err.message });
  }
});

// ── M-Pesa STK Callback ──────────────────────────────────────────────────────
// Safaricom POSTs to this endpoint after the user enters (or cancels) their PIN
app.post('/mpesa/callback', async (req, res) => {
  try {
    const body = req.body?.Body?.stkCallback;
    if (!body) {
      return res.status(400).json({ message: 'Invalid callback payload' });
    }

    const checkoutRequestId = body.CheckoutRequestID;
    const resultCode = body.ResultCode;          // 0 = success, 1032 = cancelled
    const resultDesc = body.ResultDesc;

    // Extract payment metadata when successful
    let mpesaReceiptNumber = null;
    let transactionDate = null;
    let phoneNumber = null;
    let amount = null;

    if (resultCode === 0 && body.CallbackMetadata?.Item) {
      for (const item of body.CallbackMetadata.Item) {
        if (item.Name === 'MpesaReceiptNumber') mpesaReceiptNumber = item.Value;
        if (item.Name === 'TransactionDate')    transactionDate    = item.Value;
        if (item.Name === 'PhoneNumber')        phoneNumber        = item.Value;
        if (item.Name === 'Amount')             amount             = item.Value;
      }
    }

    // Write result to Firestore — Flutter listens to this doc in real-time
    await db.collection('mpesa_callbacks').doc(checkoutRequestId).set({
      checkoutRequestId,
      resultCode,
      resultDesc,
      mpesaReceiptNumber,
      transactionDate,
      phoneNumber,
      amount,
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[M-Pesa] ${checkoutRequestId} → ResultCode ${resultCode}: ${resultDesc}`);
    res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch (err) {
    console.error('[M-Pesa callback error]', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// ── Health check ─────────────────────────────────────────────────────────────
app.get('/', (_, res) => res.send('NRB Gymkhana M-Pesa callback server running.'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
