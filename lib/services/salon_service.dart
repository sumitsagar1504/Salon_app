import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class SalonService {
  final CollectionReference _servicesCollection = FirebaseFirestore.instance
      .collection('services');

  Stream<List<ServiceModel>> getServicesStream() {
    return _servicesCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addService(ServiceModel service) async {
    await _servicesCollection.add(service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    await _servicesCollection.doc(service.id).update(service.toMap());
  }

  Future<void> deleteService(String serviceId) async {
    await _servicesCollection.doc(serviceId).delete();
  }
}
