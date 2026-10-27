const test = require('node:test');
const assert = require('node:assert/strict');
const { bookingMail, confirmationMail, quoteMail, updateKind } = require('../notification_content');

const appointment = {
  customerName: 'Alex <script>', serviceName: 'Haircut', servicePrice: 500,
  date: '2026-11-10', timeSlot: '10:00 AM', priorityRequested: true,
  priorityNote: 'Please book the earliest possible time <today>',
  priorityFee: 125, priorityStatus: 'accepted', status: 'pending',
};

test('booking mail escapes customer supplied HTML', () => {
  const mail = bookingMail(appointment);
  assert.match(mail.text, /Alex <script>/);
  assert.doesNotMatch(mail.html, /<script>/);
  assert.match(mail.html, /&lt;today&gt;/);
});

test('confirmation includes accepted priority fee only', () => {
  assert.match(confirmationMail(appointment).text, /₹625.00/);
  assert.match(confirmationMail({ ...appointment, priorityStatus: 'declined' }).text, /₹500.00/);
});

test('quote requests customer decision without claiming payment', () => {
  const mail = quoteMail(appointment);
  assert.match(mail.text, /₹625.00/);
  assert.match(mail.text, /unless you accept/);
});

test('only relevant state changes trigger customer mail', () => {
  assert.equal(updateKind({ status: 'pending' }, { status: 'confirmed' }), 'confirmed');
  assert.equal(updateKind({ status: 'pending', priorityStatus: 'requested' },
    { status: 'pending', priorityStatus: 'quoted' }), 'quoted');
  assert.equal(updateKind({ status: 'pending', priorityStatus: 'quoted' },
    { status: 'pending', priorityStatus: 'accepted' }), null);
});
