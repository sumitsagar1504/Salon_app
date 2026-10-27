import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'my_appointments_screen.dart';
import 'services_screen.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const SalonBrand(compact: true),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SalonPage(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: SalonTheme.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 650;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Your personal salon'),
                      const SizedBox(height: 12),
                      Text(
                        'A moment for you.',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Explore thoughtful services and reserve your next visit in minutes.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: SalonTheme.blushSoft,
                              foregroundColor: SalonTheme.ink,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ServicesScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Explore services'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyAppointmentsScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('My appointments'),
                          ),
                        ],
                      ),
                    ],
                  );
                  if (compact) return copy;
                  return Row(
                    children: [
                      Expanded(flex: 3, child: copy),
                      const SizedBox(width: 30),
                      const Expanded(
                        child: Icon(
                          Icons.spa_outlined,
                          size: 110,
                          color: SalonTheme.champagne,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 34),
            const SectionLabel('Your schedule'),
            const SizedBox(height: 8),
            Text('Coming up', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (uid != null)
              StreamBuilder<List<AppointmentModel>>(
                stream: AppointmentService().getCustomerAppointments(uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SalonEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load appointments',
                      message:
                          'Check your connection and try again in a moment.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(minHeight: 2);
                  }
                  final upcoming =
                      snapshot.data!
                          .where(
                            (item) =>
                                item.date.compareTo(today) >= 0 &&
                                item.status != 'cancelled',
                          )
                          .toList()
                        ..sort(
                          (a, b) => '${a.date} ${a.timeSlot}'.compareTo(
                            '${b.date} ${b.timeSlot}',
                          ),
                        );
                  if (upcoming.isEmpty) {
                    return SalonEmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'Your calendar is open',
                      message:
                          'Find a service you love and reserve a time that works for you.',
                      action: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServicesScreen(),
                          ),
                        ),
                        child: const Text('Browse services'),
                      ),
                    );
                  }
                  final next = upcoming.first;
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(SalonTheme.radius),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAppointmentsScreen(),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: SalonTheme.blushSoft,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: SalonTheme.blush,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    next.serviceName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${DateFormat('EEE, MMM d').format(DateTime.parse(next.date))} · ${next.timeSlot}',
                                    style: const TextStyle(
                                      color: SalonTheme.taupe,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(next.status),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: SalonTheme.taupe,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
