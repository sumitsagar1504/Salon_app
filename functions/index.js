const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { defineSecret, defineString } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { bookingMail, confirmationMail, quoteMail, updateKind } = require('./notification_content');

initializeApp();

const apiKey = defineSecret('RESEND_API_KEY');
const mailFrom = defineString('MAIL_FROM');
const primaryOwnerUid = 'NIgb3JbjMBXGzaQaGKNfgGwNxyv1';

async function recipientEmail(uid) {
  if (typeof uid !== 'string' || !uid) return null;
  try {
    const user = await getAuth().getUser(uid);
    return !user.disabled && user.email ? user.email : null;
  } catch (error) {
    if (error.code === 'auth/user-not-found') return null;
    throw error;
  }
}

async function sendOnce(eventKey, uid, mail) {
  const address = await recipientEmail(uid);
  if (!address) return;

  const delivery = getFirestore().collection('mailDelivery').doc(`${eventKey}_${uid}`);
  if ((await delivery.get()).exists) return;

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey.value()}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': `${eventKey}_${uid}`,
    },
    body: JSON.stringify({ from: mailFrom.value(), to: [address],
      subject: mail.subject, text: mail.text, html: mail.html }),
  });
  if (!response.ok) {
    // Do not log the provider response: it may include recipient details.
    logger.error('Booking email provider rejected a send', { status: response.status, eventKey });
    if (response.status === 429 || response.status >= 500) {
      throw new Error(`Email provider temporarily unavailable (${response.status})`);
    }
    // Retrying a rejected sender address or API key cannot succeed on its own.
    await delivery.set({ failedAt: new Date(), eventKey, uid, providerStatus: response.status });
    return;
  }
  await delivery.set({ sentAt: new Date(), eventKey, uid });
}

async function sendToAdminAccounts(eventKey, mail) {
  const adminDocs = await getFirestore().collection('admins').get();
  const uids = new Set([primaryOwnerUid, ...adminDocs.docs.map((doc) => doc.id)]);
  const outcomes = await Promise.allSettled([...uids].map((uid) => sendOnce(eventKey, uid, mail)));
  if (outcomes.some((outcome) => outcome.status === 'rejected')) {
    throw new Error('One or more administrator booking emails failed');
  }
}

exports.notifyAdminsOfBooking = onDocumentCreated(
  { document: 'appointments/{appointmentId}', secrets: [apiKey], retry: true },
  async (event) => {
    const appointment = event.data?.data();
    if (!appointment || appointment.status !== 'pending') return;
    await sendToAdminAccounts(`booking_${event.params.appointmentId}`, bookingMail(appointment));
  },
);

exports.notifyCustomerOfUpdate = onDocumentUpdated(
  { document: 'appointments/{appointmentId}', secrets: [apiKey], retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const kind = updateKind(before, after);
    if (!kind) return;
    const mail = kind === 'confirmed' ? confirmationMail(after) : quoteMail(after);
    await sendOnce(`${kind}_${event.params.appointmentId}`, after.customerId, mail);
  },
);
