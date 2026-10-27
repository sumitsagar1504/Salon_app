import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  Future<void> _quotePriority(AppointmentModel appointment) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final fee = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quote priority fee'),
        scrollable: true,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.priorityNote),
              const SizedBox(height: 16),
              Text('Base price: ₹${appointment.servicePrice}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Extra fee (₹)',
                  helperText: 'Customer must accept before confirmation',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null ||
                          !amount.isFinite ||
                          amount <= 0 ||
                          amount > 100000
                      ? 'Enter ₹1 to ₹100,000'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  double.parse(controller.text.trim()),
                );
              }
            },
            child: const Text('Send quote'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (fee == null) return;
    try {
      await _appointmentService.quotePriority(appointment.id, fee);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Priority quote sent to the customer.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message
                  : 'Could not send quote. Try again.',
            ),
          ),
        );
      }
    }
  }

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
          appointments = appointments
              .where((a) => a.status == 'pending')
              .toList();
        } else if (filter == 'confirmed') {
          appointments = appointments
              .where((a) => a.status == 'confirmed')
              .toList();
        } else if (filter == 'cancelled') {
          appointments = appointments
              .where((a) => a.status == 'cancelled')
              .toList();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
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
                              Text(
                                appointment.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                appointment.customerEmail,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(appointment.status),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      appointment.serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Base price: ₹${appointment.servicePrice}',
                      style: const TextStyle(
                        color: SalonTheme.blush,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (appointment.priorityRequested) ...[
                      const SizedBox(height: 12),
                      const SectionLabel('Priority request'),
                      const SizedBox(height: 6),
                      Text(appointment.priorityNote),
                      const SizedBox(height: 6),
                      Text(switch (appointment.priorityStatus) {
                        'requested' => 'Extra fee awaiting your quote',
                        'quoted' =>
                          '₹${appointment.priorityFee} extra quoted · Awaiting customer',
                        'accepted' =>
                          'Quote accepted · Total ₹${appointment.totalPrice}',
                        'declined' =>
                          'Quote declined · Standard booking at ₹${appointment.servicePrice}',
                        _ => 'Priority details unavailable',
                      }, style: const TextStyle(color: SalonTheme.taupe)),
                      if (appointment.status == 'pending' &&
                          appointment.priorityStatus == 'requested') ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _quotePriority(appointment),
                          icon: const Icon(Icons.request_quote_outlined),
                          label: const Text('Quote extra fee'),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'EEE, MMM d, yyyy',
                              ).format(DateTime.parse(appointment.date)),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(appointment.timeSlot),
                          ],
                        ),
                      ],
                    ),
                    if (appointment.status == 'pending') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  appointment.priorityRequested &&
                                      appointment.priorityStatus !=
                                          'accepted' &&
                                      appointment.priorityStatus != 'declined'
                                  ? null
                                  : () async {
                                      try {
                                        await _appointmentService
                                            .updateAppointmentStatus(
                                              appointment.id,
                                              'confirmed',
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Appointment confirmed.',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not confirm appointment.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SalonTheme.success,
                                foregroundColor: Colors.white,
                              ),
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
                                    content: Text(
                                      'Cancel ${appointment.customerName}’s ${appointment.serviceName} booking?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Keep booking'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text('Cancel booking'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                try {
                                  await _appointmentService
                                      .updateAppointmentStatus(
                                        appointment.id,
                                        'cancelled',
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Appointment cancelled.'),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not cancel appointment.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
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
}
