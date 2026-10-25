import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../services/salon_service.dart';
import 'book_appointment_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final SalonService _salonService = SalonService();
  String _query = '';

  String _getServiceImage(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('hair')) {
      return 'https://images.pexels.com/photos/3993444/pexels-photo-3993444.jpeg?auto=compress&cs=tinysrgb&w=600';
    } else if (lowerName.contains('facial') || lowerName.contains('skin')) {
      return 'https://images.pexels.com/photos/3762871/pexels-photo-3762871.jpeg?auto=compress&cs=tinysrgb&w=600';
    } else if (lowerName.contains('massage') || lowerName.contains('spa')) {
      return 'https://images.pexels.com/photos/3865676/pexels-photo-3865676.jpeg?auto=compress&cs=tinysrgb&w=600';
    } else if (lowerName.contains('nail') || lowerName.contains('mani') || lowerName.contains('pedi')) {
      return 'https://images.pexels.com/photos/3997391/pexels-photo-3997391.jpeg?auto=compress&cs=tinysrgb&w=600';
    } else if (lowerName.contains('makeup')) {
      return 'https://images.pexels.com/photos/3738339/pexels-photo-3738339.jpeg?auto=compress&cs=tinysrgb&w=600';
    }
    return 'https://images.pexels.com/photos/3319891/pexels-photo-3319891.jpeg?auto=compress&cs=tinysrgb&w=600';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our services'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search services',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.toLowerCase().trim()),
            ),
          ),
        ),
        Expanded(child: StreamBuilder<List<ServiceModel>>(
        stream: _salonService.getServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Services could not be loaded. Please try again.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No services available yet.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          final services = snapshot.data!.where((service) =>
              service.name.toLowerCase().contains(_query) ||
              service.description.toLowerCase().contains(_query)).toList();
          if (services.isEmpty) {
            return const Center(child: Text('No services match your search.'));
          }
          return LayoutBuilder(builder: (context, constraints) => GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth < 650 ? 1 : constraints.maxWidth < 1050 ? 2 : 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 340,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final imageUrl = service.imageUrl.isNotEmpty ? service.imageUrl : _getServiceImage(service.name);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.purple.shade50,
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.purple.shade200),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service.description,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${service.price}',
                                      style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    Text(
                                      '${service.durationMinutes}m',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BookAppointmentScreen(service: service),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 36),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('BOOK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ));
        },
      )),]),
    );
  }
}
