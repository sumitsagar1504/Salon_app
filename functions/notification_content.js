const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
})[char]);

function money(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? `₹${amount.toFixed(2)}` : 'Price unavailable';
}

function bookingMail(appointment) {
  const subject = 'New salon appointment to review';
  const lines = [
    'A customer has requested an appointment.',
    `Customer: ${appointment.customerName ?? 'Customer'}`,
    `Service: ${appointment.serviceName ?? 'Service'}`,
    `When: ${appointment.date ?? ''} at ${appointment.timeSlot ?? ''}`,
    `Base price: ${money(appointment.servicePrice)}`,
  ];
  if (appointment.priorityRequested === true) {
    lines.push('Priority request: Yes');
    lines.push(`Customer request: ${appointment.priorityNote ?? ''}`);
  }
  lines.push('Sign in to the salon dashboard to review this booking.');
  return { subject, text: lines.join('\n'), html: `<p>${lines.map(escapeHtml).join('</p><p>')}</p>` };
}

function confirmationMail(appointment) {
  const subject = 'Your salon appointment is confirmed';
  const lines = [
    'Your appointment has been confirmed.',
    `Service: ${appointment.serviceName ?? 'Service'}`,
    `When: ${appointment.date ?? ''} at ${appointment.timeSlot ?? ''}`,
    `Total agreed price: ${money(Number(appointment.servicePrice || 0) +
      (appointment.priorityStatus === 'accepted' ? Number(appointment.priorityFee || 0) : 0))}`,
    'Open The Salon to see your appointment details.',
  ];
  return { subject, text: lines.join('\n'), html: `<p>${lines.map(escapeHtml).join('</p><p>')}</p>` };
}

function quoteMail(appointment) {
  const subject = 'Review your salon priority quote';
  const lines = [
    'The salon has quoted an extra fee for your priority request.',
    `Service: ${appointment.serviceName ?? 'Service'}`,
    `Base price: ${money(appointment.servicePrice)}`,
    `Extra priority fee: ${money(appointment.priorityFee)}`,
    `Total if accepted: ${money(Number(appointment.servicePrice || 0) + Number(appointment.priorityFee || 0))}`,
    'Open The Salon to accept or decline the quote. No extra fee is applied unless you accept it.',
  ];
  return { subject, text: lines.join('\n'), html: `<p>${lines.map(escapeHtml).join('</p><p>')}</p>` };
}

function updateKind(before, after) {
  if (before.status === 'pending' && after.status === 'confirmed') return 'confirmed';
  if (before.priorityStatus === 'requested' && after.priorityStatus === 'quoted' && after.status === 'pending') return 'quoted';
  return null;
}

module.exports = { bookingMail, confirmationMail, quoteMail, updateKind };
