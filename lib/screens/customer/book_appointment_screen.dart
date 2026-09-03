import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final ServiceModel service;
  const BookAppointmentScreen({super.key, required this.service});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;

  final List<String> _allSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM",
    "12:00 PM", "02:00 PM", "03:00 PM",
    "04:00 PM", "05:00 PM", "06:00 PM"
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  Future<void> _fetchBookedSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
    });
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final booked = await AppointmentService().getBookedSlots(widget.service.id, dateStr);
    
    setState(() {
      _bookedSlots = booked;
      _isLoadingSlots = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime val) => val.weekday != DateTime.sunday,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchBookedSlots();
    }
  }

  void _confirmBooking() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userData = await AuthService().getUserData(user.uid);
      if (userData == null) return;

      final appointment = AppointmentModel(
        id: '',
        customerId: user.uid,
        customerName: userData.name,
        customerEmail: userData.email,
        serviceId: widget.service.id,
        serviceName: widget.service.name,
        servicePrice: widget.service.price,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        timeSlot: _selectedTimeSlot!,
        status: 'pending',
      );

      await AppointmentService().bookAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Service Summary
            Card(
              elevation: 2,
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Price: ₹${widget.service.price}'),
                    Text('Duration: ${widget.service.durationMinutes} min'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Select Date
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Select Time Slot
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _allSlots.map((slot) {
                  final isBooked = _bookedSlots.contains(slot);
                  return ChoiceChip(
                    label: Text(slot),
                    selected: _selectedTimeSlot == slot,
                    onSelected: isBooked ? null : (selected) {
                      setState(() {
                        _selectedTimeSlot = selected ? slot : null;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedTimeSlot == slot ? Colors.white : Colors.black,
                    ),
                    disabledColor: Colors.grey[300],
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),

            // Section 4: Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirm Booking', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
