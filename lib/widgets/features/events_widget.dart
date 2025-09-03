import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/event.dart';

class EventsWidget extends StatefulWidget {
  const EventsWidget({super.key});

  @override
  State<EventsWidget> createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  List<Event> _events = [];
  bool _isLoading = true;
  Event? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final response = await ApiService.getApprovedEvents();
      setState(() {
        _events = response.map((json) => Event.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to load events', ToastType.error);
    }
  }

  Future<void> _updateAttendance(String eventId, bool attending) async {
    try {
      await ApiService.updateAttendance(eventId, attending);
      await _loadEvents();
      
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast(
        attending ? 'Attendance confirmed!' : 'Attendance cancelled!',
        ToastType.success,
      );
    } catch (e) {
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to update attendance', ToastType.error);
    }
  }

  void _showEventDetails(Event event) {
    setState(() => _selectedEvent = event);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEventDetailsModal(event),
    );
  }

  Widget _buildEventDetailsModal(Event event) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAttending = event.attendees.contains(user?.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: event.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.type.name.replaceAll('_', ' '),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: event.status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Details
                  _buildDetailSection('Event Details', [
                    _buildDetailRow(LucideIcons.calendar, 'Date', DateFormat('MMMM dd, yyyy').format(event.startDateTime)),
                    _buildDetailRow(LucideIcons.clock, 'Time', DateFormat('hh:mm a').format(event.startDateTime)),
                    _buildDetailRow(LucideIcons.mapPin, 'Location', event.location),
                    _buildDetailRow(LucideIcons.users, 'Attendees', '${event.attendees.length}/${event.maxAttendees ?? 'Unlimited'}'),
                  ]),
                  const SizedBox(height: 24),

                  // Organizer Info
                  _buildDetailSection('Organizer', [
                    _buildDetailRow(LucideIcons.user, 'Name', event.organizerName),
                    if (event.organizerEmail != null)
                      _buildDetailRow(LucideIcons.mail, 'Email', event.organizerEmail!),
                    if (event.department != null)
                      _buildDetailRow(LucideIcons.building, 'Department', event.department!),
                  ]),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About This Event',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  if (event.specialRequirements != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Special Requirements',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.specialRequirements!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateAttendance(event.id, !isAttending);
                    },
                    icon: Icon(isAttending ? LucideIcons.x : LucideIcons.check),
                    label: Text(isAttending ? 'Cancel Attendance' : 'Confirm Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAttending ? AppTheme.errorColor : AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (event.organizerEmail != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Launch email
                      },
                      icon: const Icon(LucideIcons.mail),
                      label: const Text('Contact Organizer'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAttending = event.attendees.contains(user?.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.type.name.replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: event.status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Event Info
              Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(event.startDateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(LucideIcons.clock, size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('hh:mm a').format(event.startDateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(LucideIcons.user, size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    event.organizerName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEventDetails(event),
                      icon: const Icon(LucideIcons.eye, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAttendance(event.id, !isAttending),
                      icon: Icon(isAttending ? LucideIcons.x : LucideIcons.check, size: 16),
                      label: Text(isAttending ? 'Cancel' : 'Attend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAttending ? AppTheme.errorColor : AppTheme.accentColor,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Row(
          children: [
            const Icon(LucideIcons.calendar, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Text(
              'Events',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Events List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Events Available',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for upcoming events!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _events.length,
                      itemBuilder: (context, index) => _buildEventCard(_events[index]),
                    ),
        ),
      ],
    );
  }
}