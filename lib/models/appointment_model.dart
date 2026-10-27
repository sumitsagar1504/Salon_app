import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final String date;
  final String timeSlot;
  final String status;
  final bool priorityRequested;
  final String priorityNote;
  final double priorityFee;
  final String priorityStatus;
  final DateTime? createdAt;

  double get totalPrice =>
      servicePrice + (priorityStatus == 'accepted' ? priorityFee : 0);

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.priorityRequested = false,
    this.priorityNote = '',
    this.priorityFee = 0,
    this.priorityStatus = 'none',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'date': date,
      'timeSlot': timeSlot,
      'status': status,
      'priorityRequested': priorityRequested,
      'priorityNote': priorityNote,
      'priorityFee': priorityFee,
      'priorityStatus': priorityStatus,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      servicePrice: (map['servicePrice'] ?? 0.0).toDouble(),
      date: map['date'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      status: map['status'] ?? 'pending',
      priorityRequested: map['priorityRequested'] == true,
      priorityNote: map['priorityNote'] as String? ?? '',
      priorityFee: (map['priorityFee'] as num?)?.toDouble() ?? 0,
      priorityStatus: map['priorityStatus'] as String? ?? 'none',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? serviceId,
    String? serviceName,
    double? servicePrice,
    String? date,
    String? timeSlot,
    String? status,
    bool? priorityRequested,
    String? priorityNote,
    double? priorityFee,
    String? priorityStatus,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      priorityRequested: priorityRequested ?? this.priorityRequested,
      priorityNote: priorityNote ?? this.priorityNote,
      priorityFee: priorityFee ?? this.priorityFee,
      priorityStatus: priorityStatus ?? this.priorityStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
