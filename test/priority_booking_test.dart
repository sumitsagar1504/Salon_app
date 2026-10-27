import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/models/appointment_model.dart';

void main() {
  AppointmentModel appointment({
    bool priorityRequested = false,
    String priorityStatus = 'none',
    double priorityFee = 0,
  }) => AppointmentModel(
    id: 'appointment-1',
    customerId: 'customer-1',
    customerName: 'Alex',
    customerEmail: 'alex@example.com',
    serviceId: 'service-1',
    serviceName: 'Haircut',
    servicePrice: 500,
    date: '2026-11-10',
    timeSlot: '10:00 AM',
    status: 'pending',
    priorityRequested: priorityRequested,
    priorityNote: priorityRequested ? 'Earlier slot if possible' : '',
    priorityStatus: priorityStatus,
    priorityFee: priorityFee,
  );

  test('priority quote is not included in price until accepted', () {
    expect(
      appointment(
        priorityRequested: true,
        priorityStatus: 'quoted',
        priorityFee: 125,
      ).totalPrice,
      500,
    );
    expect(
      appointment(
        priorityRequested: true,
        priorityStatus: 'accepted',
        priorityFee: 125,
      ).totalPrice,
      625,
    );
    expect(
      appointment(
        priorityRequested: true,
        priorityStatus: 'declined',
        priorityFee: 125,
      ).totalPrice,
      500,
    );
  });

  test(
    'older appointments without priority fields remain standard bookings',
    () {
      final old = AppointmentModel.fromMap({
        'customerId': 'customer-1',
        'servicePrice': 500,
        'status': 'pending',
      }, 'old-appointment');
      expect(old.priorityRequested, false);
      expect(old.priorityStatus, 'none');
      expect(old.totalPrice, 500);
    },
  );

  test('priority request fields are included in new booking documents', () {
    final data = appointment(
      priorityRequested: true,
      priorityStatus: 'requested',
    ).toMap();
    expect(data['priorityRequested'], true);
    expect(data['priorityStatus'], 'requested');
    expect(data['priorityFee'], 0);
    expect(data['priorityNote'], 'Earlier slot if possible');
  });
}
