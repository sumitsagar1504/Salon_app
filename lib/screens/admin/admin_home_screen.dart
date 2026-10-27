import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../auth/login_screen.dart';
import 'manage_services_screen.dart';
import 'admin_appointments_screen.dart';
import 'manage_admins_screen.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';
import '../../widgets/appointment_notifications.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentService = AppointmentService();

    return Scaffold(
      appBar: AppBar(
        title: const SalonBrand(compact: true),
        actions: [
          const AppointmentNotifications(owner: true),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SalonPage(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Owner workspace'),
              const SizedBox(height: 8),
              Text(
                'Your salon, at a glance',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage today’s bookings, services, and trusted team access.',
              ),
              const SizedBox(height: 28),

              // STATS ROW
              StreamBuilder<List<AppointmentModel>>(
                stream: appointmentService.getAllAppointments(),
                builder: (context, snapshot) {
                  int total = 0;
                  int pending = 0;
                  int confirmed = 0;

                  if (snapshot.hasData) {
                    total = snapshot.data!.length;
                    pending = snapshot.data!
                        .where((a) => a.status == 'pending')
                        .length;
                    confirmed = snapshot.data!
                        .where((a) => a.status == 'confirmed')
                        .length;
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'Appointment summary could not be loaded.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        'All bookings',
                        total.toString(),
                        Icons.event_note_outlined,
                        SalonTheme.taupe,
                      ),
                      _buildStatCard(
                        'Needs review',
                        pending.toString(),
                        Icons.schedule_rounded,
                        SalonTheme.warning,
                      ),
                      _buildStatCard(
                        'Confirmed',
                        confirmed.toString(),
                        Icons.check_circle_outline_rounded,
                        SalonTheme.success,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // MENU CARDS
              const SectionLabel('Management'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 760
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: width,
                        child: _buildMenuCard(
                          context,
                          Icons.content_cut_rounded,
                          'Services',
                          'Add, edit and curate your service menu',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageServicesScreen(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _buildMenuCard(
                          context,
                          Icons.calendar_month_outlined,
                          'Appointments',
                          'Review and update customer bookings',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminAppointmentsScreen(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _buildMenuCard(
                          context,
                          Icons.admin_panel_settings_outlined,
                          'Team access',
                          'Approve owners and add trusted admins',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageAdminsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SalonTheme.taupe,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(SalonTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SalonTheme.blushSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: SalonTheme.blush),
              ),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Text('Open', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
