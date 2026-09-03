import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../auth/login_screen.dart';
import 'manage_services_screen.dart';
import 'admin_appointments_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentService = AppointmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // STATS ROW
            StreamBuilder<List<AppointmentModel>>(
              stream: appointmentService.getAllAppointments(),
              builder: (context, snapshot) {
                int total = 0;
                int pending = 0;
                int confirmed = 0;

                if (snapshot.hasData) {
                  total = snapshot.data!.length;
                  pending = snapshot.data!.where((a) => a.status == 'pending').length;
                  confirmed = snapshot.data!.where((a) => a.status == 'confirmed').length;
                }

                return Row(
                  children: [
                    _buildStatCard('Total', total.toString(), Colors.blue),
                    _buildStatCard('Pending', pending.toString(), Colors.orange),
                    _buildStatCard('Confirmed', confirmed.toString(), Colors.green),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // MENU CARDS
            _buildMenuCard(
              context,
              Icons.content_cut,
              'Manage Services',
              'Add, edit or remove salon services',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageServicesScreen())),
            ),
            _buildMenuCard(
              context,
              Icons.calendar_today,
              'All Appointments',
              'Confirm or cancel customer bookings',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAppointmentsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
