import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final CollectionReference _appointmentsCollection =
      FirebaseFirestore.instance.collection('appointments');

  Future<void> bookAppointment(AppointmentModel appointment) async {
    await _appointmentsCollection.add(appointment.toMap());
  }

  Stream<List<AppointmentModel>> getCustomerAppointments(String customerId) {
    return _appointmentsCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _appointmentsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _appointmentsCollection.doc(appointmentId).update({'status': status});
  }

  Future<List<String>> getBookedSlots(String serviceId, String date) async {
    QuerySnapshot snapshot = await _appointmentsCollection
        .where('serviceId', isEqualTo: serviceId)
        .where('date', isEqualTo: date)
        .get();

    return snapshot.docs.map((doc) {
      return (doc.data() as Map<String, dynamic>)['timeSlot'] as String;
    }).toList();
  }
}
