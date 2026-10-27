import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

const appointmentSlots = [
  '09:00 AM',
  '10:00 AM',
  '11:00 AM',
  '12:00 PM',
  '02:00 PM',
  '03:00 PM',
  '04:00 PM',
  '05:00 PM',
  '06:00 PM',
];

class AppointmentService {
  final CollectionReference _appointmentsCollection = FirebaseFirestore.instance
      .collection('appointments');

  Future<void> bookAppointment(AppointmentModel appointment) async {
    final date = DateTime.tryParse(appointment.date);
    if (date == null ||
        date.isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )) {
      throw StateError('Choose a future appointment date.');
    }
    final lock = FirebaseFirestore.instance
        .collection('bookingSlots')
        .doc(
          '${appointment.serviceId}|${appointment.date}|${appointment.timeSlot}',
        );
    final doc = _appointmentsCollection.doc();
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final reserved = await transaction.get(lock);
      if (reserved.exists) {
        throw StateError(
          'This time has just been booked. Choose another slot.',
        );
      }
      transaction.set(doc, appointment.toMap());
      transaction.set(lock, {
        'appointmentId': doc.id,
        'serviceId': appointment.serviceId,
        'date': appointment.date,
        'timeSlot': appointment.timeSlot,
      });
    });
  }

  Stream<List<AppointmentModel>> getCustomerAppointments(String customerId) {
    return _appointmentsCollection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final appointments = snapshot.docs.map((doc) {
            return AppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          appointments.sort((a, b) => b.date.compareTo(a.date));
          return appointments;
        });
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _appointmentsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    if (status != 'confirmed' && status != 'cancelled') {
      throw ArgumentError('Invalid appointment status');
    }
    final doc = _appointmentsCollection.doc(appointmentId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (!snapshot.exists) throw StateError('Appointment no longer exists.');
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
        throw StateError('Only pending appointments can be changed.');
      }
      if (status == 'confirmed' &&
          data['priorityRequested'] == true &&
          data['priorityStatus'] != 'accepted' &&
          data['priorityStatus'] != 'declined') {
        throw StateError('Wait for the customer to accept the priority quote.');
      }
      final lock = FirebaseFirestore.instance
          .collection('bookingSlots')
          .doc('${data['serviceId']}|${data['date']}|${data['timeSlot']}');
      final reserved = await transaction.get(lock);
      transaction.update(doc, {'status': status});
      if (status == 'cancelled' &&
          reserved.exists &&
          (reserved.data() as Map<String, dynamic>)['appointmentId'] ==
              appointmentId) {
        transaction.delete(lock);
      }
    });
  }

  Future<void> quotePriority(String appointmentId, double fee) async {
    if (!fee.isFinite || fee <= 0 || fee > 100000) {
      throw ArgumentError('Enter an extra fee between ₹1 and ₹100,000.');
    }
    final doc = _appointmentsCollection.doc(appointmentId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (!snapshot.exists) throw StateError('Appointment no longer exists.');
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['status'] != 'pending' ||
          data['priorityRequested'] != true ||
          data['priorityStatus'] != 'requested') {
        throw StateError('This priority request can no longer be quoted.');
      }
      transaction.update(doc, {'priorityFee': fee, 'priorityStatus': 'quoted'});
    });
  }

  Future<void> respondToPriorityQuote(
    String appointmentId, {
    required bool accept,
  }) async {
    final doc = _appointmentsCollection.doc(appointmentId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (!snapshot.exists) throw StateError('Appointment no longer exists.');
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['status'] != 'pending' ||
          data['priorityRequested'] != true ||
          data['priorityStatus'] != 'quoted') {
        throw StateError('This priority quote is no longer available.');
      }
      transaction.update(doc, {
        'priorityStatus': accept ? 'accepted' : 'declined',
        if (!accept) 'priorityFee': 0,
      });
    });
  }

  Future<List<String>> getBookedSlots(String serviceId, String date) async {
    final slots = FirebaseFirestore.instance.collection('bookingSlots');
    final checks = await Future.wait(
      appointmentSlots.map((slot) => slots.doc('$serviceId|$date|$slot').get()),
    );
    return [
      for (var i = 0; i < checks.length; i++)
        if (checks[i].exists) appointmentSlots[i],
    ];
  }
}
