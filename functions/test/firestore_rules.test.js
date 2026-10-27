const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } =
  require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, writeBatch } = require('firebase/firestore');

let environment;
let nextId = 0;

test.before(async () => {
  const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
  assert.ok(emulatorHost, 'Start this test through firebase emulators:exec --only firestore');
  const [host, port] = emulatorHost.split(':');
  environment = await initializeTestEnvironment({
    projectId: 'salon-priority-rules-test',
    firestore: {
      host,
      port: Number(port),
      rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8'),
    },
  });
});

test.after(async () => {
  if (environment) await environment.cleanup();
});

test('priority fee needs owner quote, customer acceptance and owner confirmation', async () => {
  const suffix = ++nextId;
  const appointmentId = `appointment-${suffix}`;
  const slotId = `service-${suffix}|2026-11-10|10:00 AM`;
  const serviceId = `service-${suffix}`;
  const customerUid = `customer-${suffix}`;
  const ownerUid = `owner-${suffix}`;
  const customer = environment.authenticatedContext(customerUid, {
    email: `customer${suffix}@example.com`,
  }).firestore();
  const owner = environment.authenticatedContext(ownerUid, {
    email: `owner${suffix}@example.com`,
  }).firestore();
  const stranger = environment.authenticatedContext(`stranger-${suffix}`).firestore();

  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'admins', ownerUid), { uid: ownerUid });
    await setDoc(doc(db, 'services', serviceId), { name: 'Haircut', price: 500 });
  });

  const customerAppointment = doc(customer, 'appointments', appointmentId);
  const booking = writeBatch(customer);
  booking.set(customerAppointment, {
    customerId: customerUid, customerName: 'Alex',
    customerEmail: `customer${suffix}@example.com`, serviceId,
    serviceName: 'Haircut', servicePrice: 500, date: '2026-11-10',
    timeSlot: '10:00 AM', status: 'pending', createdAt: new Date(),
    priorityRequested: true, priorityNote: 'Please help with an earlier visit',
    priorityFee: 0, priorityStatus: 'requested',
  });
  booking.set(doc(customer, 'bookingSlots', slotId), {
    appointmentId, serviceId, date: '2026-11-10', timeSlot: '10:00 AM',
  });
  await assertSucceeds(booking.commit());

  await assertFails(getDoc(doc(stranger, 'appointments', appointmentId)));
  await assertFails(updateDoc(customerAppointment, { priorityFee: 99999, priorityStatus: 'accepted' }));
  await assertFails(updateDoc(customerAppointment, { status: 'confirmed' }));
  await assertFails(updateDoc(doc(owner, 'appointments', appointmentId), { status: 'confirmed' }));

  await assertSucceeds(updateDoc(doc(owner, 'appointments', appointmentId), {
    priorityFee: 125, priorityStatus: 'quoted',
  }));
  await assertFails(updateDoc(customerAppointment, { priorityFee: 1, priorityStatus: 'accepted' }));
  await assertSucceeds(updateDoc(customerAppointment, { priorityStatus: 'accepted' }));
  await assertSucceeds(updateDoc(doc(owner, 'appointments', appointmentId), {
    status: 'confirmed',
  }));

  const final = await getDoc(customerAppointment);
  assert.equal(final.data().priorityFee, 125);
  assert.equal(final.data().status, 'confirmed');
});

test('cancellation must release the slot in the same transaction', async () => {
  const serviceId = 'standard-service';
  const appointmentId = 'standard-appointment';
  const slotId = `${serviceId}|2026-11-11|11:00 AM`;
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'services', serviceId), {
      name: 'Style', price: 300,
    });
  });
  const customer = environment.authenticatedContext('standard-customer', {
    email: 'standard@example.com',
  }).firestore();
  const booking = writeBatch(customer);
  booking.set(doc(customer, 'appointments', appointmentId), {
    customerId: 'standard-customer', customerName: 'Sam',
    customerEmail: 'standard@example.com', serviceId,
    serviceName: 'Style', servicePrice: 300, date: '2026-11-11',
    timeSlot: '11:00 AM', status: 'pending', createdAt: new Date(),
  });
  booking.set(doc(customer, 'bookingSlots', slotId), {
    appointmentId, serviceId, date: '2026-11-11', timeSlot: '11:00 AM',
  });
  await assertSucceeds(booking.commit());
  await assertFails(updateDoc(doc(customer, 'appointments', appointmentId), {
    status: 'cancelled',
  }));
  const cancellation = writeBatch(customer);
  cancellation.update(doc(customer, 'appointments', appointmentId), { status: 'cancelled' });
  cancellation.delete(doc(customer, 'bookingSlots', slotId));
  await assertSucceeds(cancellation.commit());
  assert.equal((await getDoc(doc(customer, 'appointments', appointmentId))).data().status,
    'cancelled');
});
