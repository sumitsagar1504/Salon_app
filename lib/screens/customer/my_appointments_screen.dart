import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  Future<void> _respondToQuote(
    AppointmentModel appointment, {
    required bool accept,
  }) async {
    if (accept) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Accept priority quote?'),
          content: Text(
            'Service ₹${appointment.servicePrice} + priority ₹${appointment.priorityFee} = ₹${appointment.servicePrice + appointment.priorityFee}. Payment is handled by the salon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Accept quote'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await _appointmentService.respondToPriorityQuote(
        appointment.id,
        accept: accept,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Quote accepted. The salon can now confirm your booking.'
                  : 'Extra fee declined. Your standard booking stays pending.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message
                  : 'Could not update the quote. Try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancel(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
          'Cancel ${appointment.serviceName} on ${appointment.date} at ${appointment.timeSlot}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _appointmentService.updateAppointmentStatus(
        appointment.id,
        'cancelled',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancellation failed. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: user == null
          ? const Center(child: Text('Please login to view appointments'))
          : StreamBuilder<List<AppointmentModel>>(
              stream: _appointmentService.getCustomerAppointments(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SalonEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load appointments',
                    message: 'Check your connection and try again.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SalonEmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No appointments yet',
                    message: 'When you reserve a service, it will appear here.',
                  );
                }

                final appointments = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      appointment.serviceName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    StatusPill(appointment.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEE, MMM d, yyyy').format(
                                        DateTime.parse(appointment.date),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      appointment.timeSlot,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text(
                                  'Base price: ₹${appointment.servicePrice}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: SalonTheme.blush,
                                  ),
                                ),
                                if (appointment.priorityRequested) ...[
                                  const SizedBox(height: 10),
                                  const SectionLabel('Priority request'),
                                  const SizedBox(height: 5),
                                  Text(appointment.priorityNote),
                                  const SizedBox(height: 7),
                                  Text(
                                    switch (appointment.priorityStatus) {
                                      'requested' =>
                                        'Waiting for the salon to quote any extra fee',
                                      'quoted' =>
                                        'Extra fee ₹${appointment.priorityFee} · Total ₹${appointment.servicePrice + appointment.priorityFee}',
                                      'accepted' =>
                                        'Accepted total: ₹${appointment.totalPrice}',
                                      'declined' =>
                                        'Extra fee declined · Standard price ₹${appointment.servicePrice}',
                                      _ => 'Priority details unavailable',
                                    },
                                    style: const TextStyle(
                                      color: SalonTheme.taupe,
                                    ),
                                  ),
                                  if (appointment.status == 'pending' &&
                                      appointment.priorityStatus ==
                                          'quoted') ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        FilledButton(
                                          onPressed: () => _respondToQuote(
                                            appointment,
                                            accept: true,
                                          ),
                                          child: const Text('Accept quote'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => _respondToQuote(
                                            appointment,
                                            accept: false,
                                          ),
                                          child: const Text(
                                            'Decline extra fee',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                                if (appointment.status == 'pending' &&
                                    appointment.date.compareTo(
                                          DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(DateTime.now()),
                                        ) >=
                                        0)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _cancel(appointment),
                                      child: const Text('Cancel appointment'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
