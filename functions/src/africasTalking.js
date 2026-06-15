const AfricasTalking = require('africastalking');

// ── Initialize with your credentials ─────────────────────────────────────────
// Set these in Firebase environment config:
//   firebase functions:config:set at.api_key="YOUR_KEY" at.username="YOUR_USERNAME"
// For sandbox testing, use username: "sandbox" and any api_key
const at = AfricasTalking({
  apiKey: process.env.AT_API_KEY || 'sandbox',
  username: process.env.AT_USERNAME || 'sandbox',
});

const sms = at.SMS;

/**
 * Send an SMS via Africa's Talking
 * @param {string|string[]} to - Phone number(s) in international format e.g. +254712345678
 * @param {string} message
 */
async function sendSMS(to, message) {
  const recipients = Array.isArray(to) ? to : [to];
  return sms.send({
    to: recipients,
    message,
    // Remove the `from` line if using sandbox (sandbox ignores sender ID)
    // from: 'GYMKHANA',
  });
}

/**
 * Send a WhatsApp message via Africa's Talking
 * Africa's Talking WhatsApp uses the same SMS API with a channel prefix.
 * NOTE: WhatsApp requires a registered sender & approved templates in production.
 * @param {string} to - Phone number in international format
 * @param {string} message
 */
async function sendWhatsApp(to, message) {
  // AT WhatsApp API endpoint (uses HTTP API directly as SDK may not expose it yet)
  const https = require('https');
  const querystring = require('querystring');

  const postData = querystring.stringify({
    username: process.env.AT_USERNAME || 'sandbox',
    to,
    message,
    channel: 'whatsapp',
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'api.africastalking.com',
        path: '/version1/messaging',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'apiKey': process.env.AT_API_KEY || 'sandbox',
          'Accept': 'application/json',
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => resolve(JSON.parse(data)));
      }
    );
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

module.exports = { sendSMS, sendWhatsApp };
