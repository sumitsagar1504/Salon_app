import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';

class BookAppointmentScreen extends StatefulWidget {
  final ServiceModel service;
  const BookAppointmentScreen({super.key, required this.service});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = _nextBookableDate();
  String? _selectedTimeSlot;
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _slotError;
  bool _priorityRequested = false;
  final TextEditingController _priorityNoteController = TextEditingController();
  String? _priorityError;

  final List<String> _allSlots = appointmentSlots;

  static DateTime _nextBookableDate() {
    var date = DateTime.now().add(const Duration(days: 1));
    if (date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  @override
  void dispose() {
    _priorityNoteController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookedSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final booked = await AppointmentService().getBookedSlots(
        widget.service.id,
        dateStr,
      );
      if (!mounted) return;
      setState(() {
        _bookedSlots = booked;
        _slotError = null;
        _isLoadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slotError = 'Availability could not be loaded. Please try again.';
        _isLoadingSlots = false;
      });
    }
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
    if (_isSubmitting || _isLoadingSlots || _slotError != null) return;
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }
    if (_priorityRequested &&
        (_priorityNoteController.text.trim().length < 10 ||
            _priorityNoteController.text.trim().length > 500)) {
      setState(
        () => _priorityError = 'Describe your request in 10 to 500 characters.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please sign in again.');

      final userData = await AuthService().getUserData(user.uid);
      if (userData == null) {
        throw StateError('Your account could not be loaded.');
      }

      final appointment = AppointmentModel(
        id: '',
        customerId: user.uid,
        customerName: userData.name,
        customerEmail: user.email ?? userData.email,
        serviceId: widget.service.id,
        serviceName: widget.service.name,
        servicePrice: widget.service.price,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        timeSlot: _selectedTimeSlot!,
        status: 'pending',
        priorityRequested: _priorityRequested,
        priorityNote: _priorityRequested
            ? _priorityNoteController.text.trim()
            : '',
        priorityStatus: _priorityRequested ? 'requested' : 'none',
      );

      await AppointmentService().bookAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent to the salon.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError ? e.message : 'Booking failed. Please try again.',
            ),
          ),
        );
        _fetchBookedSlots();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reserve your visit')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Service Summary
                const SectionLabel('Selected service'),
                const SizedBox(height: 10),
                Card(
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
                            Icons.spa_outlined,
                            color: SalonTheme.blush,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.service.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${widget.service.durationMinutes} min · ₹${widget.service.price}',
                                style: const TextStyle(color: SalonTheme.taupe),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Select Date
                const SectionLabel('1 · Choose a date'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Select Time Slot
                const SectionLabel('2 · Choose a time'),
                const SizedBox(height: 8),
                if (_slotError != null) ...[
                  Text(
                    _slotError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchBookedSlots,
                    child: const Text('Retry'),
                  ),
                ] else if (_isLoadingSlots)
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
                        onSelected: isBooked
                            ? null
                            : (selected) {
                                setState(() {
                                  _selectedTimeSlot = selected ? slot : null;
                                });
                              },
                        selectedColor: SalonTheme.ink,
                        labelStyle: TextStyle(
                          color: _selectedTimeSlot == slot
                              ? Colors.white
                              : SalonTheme.ink,
                        ),
                        disabledColor: Colors.grey[300],
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 30),

                const SectionLabel('3 · Your preferences'),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: const Text('Request priority service'),
                          subtitle: const Text(
                            'Describe what you need. The salon will quote any extra fee before you decide.',
                          ),
                          value: _priorityRequested,
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(() {
                                  _priorityRequested = value;
                                  _priorityError = null;
                                }),
                        ),
                        if (_priorityRequested) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _priorityNoteController,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              labelText: 'What do you need?',
                              hintText:
                                  'Tell the salon about your timing or service needs',
                              errorText: _priorityError,
                            ),
                            onChanged: (_) {
                              if (_priorityError != null) {
                                setState(() => _priorityError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your booking stays pending until the salon quotes a fee and you accept it. No extra charge is applied automatically.',
                            style: TextStyle(color: SalonTheme.taupe),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Base service price: ₹${widget.service.price}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_priorityRequested)
                  const Text(
                    'Priority fee: pending salon quote',
                    style: TextStyle(color: SalonTheme.taupe),
                  ),
                const SizedBox(height: 24),

                // Section 4: Send request
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedTimeSlot == null ||
                            _isSubmitting ||
                            _isLoadingSlots ||
                            _slotError != null
                        ? null
                        : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isSubmitting
                          ? 'Reserving your time…'
                          : _priorityRequested
                          ? 'Send booking and priority request'
                          : 'Request appointment',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
