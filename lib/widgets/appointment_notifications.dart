import 'dart:async';

import 'package:flutter/material.dart';

import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../theme/salon_theme.dart';
import 'salon_ui.dart';

/// Live in-app alerts derived from appointment records, so they also work on
/// Firebase projects that cannot deploy Cloud Functions yet.
class AppointmentNotifications extends StatefulWidget {
  const AppointmentNotifications({
    super.key,
    required this.owner,
    this.customerId,
  });

  final bool owner;
  final String? customerId;

  @override
  State<AppointmentNotifications> createState() =>
      _AppointmentNotificationsState();
}

class _AppointmentNotificationsState extends State<AppointmentNotifications> {
  StreamSubscription<List<AppointmentModel>>? _subscription;
  List<AppointmentModel> _appointments = const [];
  Map<String, String>? _lastEvents;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final service = AppointmentService();
    final stream = widget.owner
        ? service.getAllAppointments()
        : service.getCustomerAppointments(widget.customerId!);
    _subscription = stream.listen(
      (appointments) {
        final events = {
          for (final item in appointments)
            item.id: '${item.status}|${item.priorityStatus}',
        };
        final previous = _lastEvents;
        if (previous != null) {
          for (final item in appointments) {
            final old = previous[item.id];
            final message = widget.owner
                ? (old == null ? 'New booking from ${item.customerName}' : null)
                : (old != null &&
                          !old.endsWith('|quoted') &&
                          item.priorityStatus == 'quoted'
                      ? 'Your priority quote is ready to review'
                      : old != null &&
                            !old.startsWith('confirmed|') &&
                            item.status == 'confirmed'
                      ? 'Your ${item.serviceName} appointment is confirmed'
                      : null);
            if (message != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              });
              break;
            }
          }
        }
        if (mounted) {
          setState(() {
            _appointments = appointments;
            _lastEvents = events;
            _hasError = false;
          });
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showAlerts() {
    final items =
        _appointments
            .where(
              (item) => widget.owner
                  ? item.status == 'pending'
                  : item.priorityStatus == 'quoted' ||
                        item.status == 'confirmed' ||
                        item.status == 'cancelled',
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.owner ? 'Booking alerts' : 'Your updates'),
        content: SizedBox(
          width: 420,
          child: _hasError
              ? const Text(
                  'Updates could not be loaded. Check your connection and reopen this page.',
                )
              : items.isEmpty
              ? const Text('No appointment updates yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length > 20 ? 20 : items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final title = widget.owner
                        ? (item.priorityStatus == 'requested'
                              ? 'Priority quote requested'
                              : 'Booking needs review')
                        : item.priorityStatus == 'quoted'
                        ? 'Priority quote ready'
                        : item.status == 'confirmed'
                        ? 'Appointment confirmed'
                        : 'Appointment cancelled';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        widget.owner
                            ? Icons.event_note_outlined
                            : Icons.notifications_active_outlined,
                        color: SalonTheme.blush,
                      ),
                      title: Text(title),
                      subtitle: Text(
                        '${item.serviceName} · ${item.date} · ${item.timeSlot}',
                      ),
                      trailing: widget.owner ? null : StatusPill(item.status),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _appointments
        .where(
          (item) => widget.owner
              ? item.status == 'pending'
              : item.status == 'pending' && item.priorityStatus == 'quoted',
        )
        .length;
    return IconButton(
      tooltip: widget.owner ? 'Booking alerts' : 'Appointment updates',
      onPressed: _showAlerts,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
