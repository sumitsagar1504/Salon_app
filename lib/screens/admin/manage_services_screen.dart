import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../services/salon_service.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final SalonService _salonService = SalonService();

  void _showServiceDialog([ServiceModel? service]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: service?.name ?? '');
    final descController = TextEditingController(text: service?.description ?? '');
    final priceController = TextEditingController(text: service?.price.toString() ?? '');
    final durationController = TextEditingController(text: service?.durationMinutes.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service == null ? 'Add Service' : 'Edit Service'),
        content: SingleChildScrollView(
          child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final price = double.tryParse(value ?? '');
                  return price == null || !price.isFinite || price < 0 ? 'Enter a valid price' : null;
                },
              ),
              TextFormField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final duration = int.tryParse(value ?? '');
                  return duration == null || duration <= 0 ? 'Enter a valid duration' : null;
                },
              ),
            ],
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newService = ServiceModel(
                id: service?.id ?? '',
                name: nameController.text.trim(),
                description: descController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0.0,
                durationMinutes: int.tryParse(durationController.text) ?? 0,
                imageUrl: service?.imageUrl ?? '',
              );

              try {
                if (service == null) {
                  await _salonService.addService(newService);
                } else {
                  await _salonService.updateService(newService);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Service saved.')));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Could not save service. Please try again.')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteService(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _salonService.deleteService(id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Could not delete service.')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: _salonService.getServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Services could not be loaded.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No services yet. Add one!'));
          }

          final services = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.description, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('₹${service.price} | ${service.durationMinutes} min',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showServiceDialog(service),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteService(service.id),
                      ),
                    ],
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
