import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  throw new Error('Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON path.');
}
initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const apply = process.argv.includes('--apply');
const appointments = await db.collection('appointments').get();
const occupied = new Map();
const conflicts = [];
for (const doc of appointments.docs) {
  const data = doc.data();
  const today = new Date().toISOString().slice(0, 10);
  if (data.status === 'cancelled' || data.date < today) continue;
  const key = `${data.serviceId}|${data.date}|${data.timeSlot}`;
  if (occupied.has(key)) conflicts.push([key, occupied.get(key).id, doc.id]);
  else occupied.set(key, { id: doc.id, data });
}
if (conflicts.length) {
  for (const [slot, first, second] of conflicts) {
    console.error(`Conflict: ${slot} (${first}, ${second})`);
  }
  throw new Error('Resolve conflicting appointments before backfill. No writes made.');
}
const missing = [];
for (const [key, { id: appointmentId, data }] of occupied) {
  const ref = db.collection('bookingSlots').doc(key);
  const existing = await ref.get();
  if (existing.exists) {
    if (existing.data().appointmentId !== appointmentId) {
      throw new Error(`Existing slot conflicts with appointment ${appointmentId}: ${key}`);
    }
    continue;
  }
  missing.push({ ref, appointmentId, data });
}
if (apply) {
  for (const { ref, appointmentId, data } of missing) {
    await ref.create({ appointmentId,
      serviceId: data.serviceId, date: data.date, timeSlot: data.timeSlot });
  }
}
console.log(`${apply ? 'Created' : 'Would create'} ${missing.length} slot records.`);
