import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'my_appointments_screen.dart';
import 'services_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('THE SALON', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          ),
        ],
      ),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('A moment for you.', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text('Explore services and plan your next visit.'),
            const SizedBox(height: 24),
            Wrap(spacing: 12, runSpacing: 12, children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ServicesScreen())),
                icon: const Icon(Icons.add), label: const Text('Book a service')),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                icon: const Icon(Icons.event_note_outlined),
                label: const Text('My appointments')),
            ]),
            const SizedBox(height: 36),
            Text('Coming up', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (uid != null)
              StreamBuilder<List<AppointmentModel>>(
                stream: AppointmentService().getCustomerAppointments(uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Card(child: Padding(padding: EdgeInsets.all(20),
                      child: Text('Appointments could not be loaded.')));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final upcoming = snapshot.data!.where((item) =>
                    item.date.compareTo(today) >= 0 && item.status != 'cancelled').toList()
                    ..sort((a, b) => '${a.date} ${a.timeSlot}'.compareTo('${b.date} ${b.timeSlot}'));
                  if (upcoming.isEmpty) {
                    return const Card(child: Padding(padding: EdgeInsets.all(24),
                      child: Text('No upcoming appointments. Find a service you love.')));
                  }
                  final next = upcoming.first;
                  return Card(child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(next.serviceName),
                    subtitle: Text('${next.date} · ${next.timeSlot} · ${next.status}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                  ));
                },
              ),
          ],
        ),
      )),
    );
  }
}
