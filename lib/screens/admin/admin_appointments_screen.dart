import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Appointments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentList('all'),
            _buildAppointmentList('pending'),
            _buildAppointmentList('confirmed'),
            _buildAppointmentList('cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(String filter) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Appointments could not be loaded.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No appointments found.'));
        }

        var appointments = snapshot.data!;
        if (filter == 'pending') {
          appointments = appointments.where((a) => a.status == 'pending').toList();
        } else if (filter == 'confirmed') {
          appointments = appointments.where((a) => a.status == 'confirmed').toList();
        } else if (filter == 'cancelled') {
          appointments = appointments.where((a) => a.status == 'cancelled').toList();
        }

        if (appointments.isEmpty) {
          return const Center(child: Text('No appointments found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appointment.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(appointment.customerEmail,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        _buildStatusBadge(appointment.status),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(appointment.serviceName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Price: ₹${appointment.servicePrice}',
                        style: TextStyle(color: Theme.of(context).primaryColor)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(appointment.date))),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(appointment.timeSlot),
                      ],
                    ),
                    if (appointment.status == 'pending') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _appointmentService.updateAppointmentStatus(appointment.id, 'confirmed');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Appointment confirmed.')));
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not confirm appointment.')));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Confirm'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Cancel appointment?'),
                                    content: Text('Cancel ${appointment.customerName}’s ${appointment.serviceName} booking?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep booking')),
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Cancel booking')),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                try {
                                  await _appointmentService.updateAppointmentStatus(appointment.id, 'cancelled');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Appointment cancelled.')));
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not cancel appointment.')));
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
