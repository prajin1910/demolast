class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String organizerId;
  final String organizerName;
  final String? organizerEmail;
  final EventStatus status;
  final EventType type;
  final String? specialRequirements;
  final String? rejectionReason;
  final String? approvedBy;
  final String? rejectedBy;
  final DateTime submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final List<String> attendees;
  final String? department;
  final String? targetAudience;
  final int? maxAttendees;
  final String? contactEmail;
  final String? contactPhone;
  final String? requestedBy;
  final String? requestedByName;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDateTime,
    this.endDateTime,
    required this.organizerId,
    required this.organizerName,
    this.organizerEmail,
    required this.status,
    required this.type,
    this.specialRequirements,
    this.rejectionReason,
    this.approvedBy,
    this.rejectedBy,
    required this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    required this.attendees,
    this.department,
    this.targetAudience,
    this.maxAttendees,
    this.contactEmail,
    this.contactPhone,
    this.requestedBy,
    this.requestedByName,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startDateTime: DateTime.parse(json['startDateTime'] ?? DateTime.now().toIso8601String()),
      endDateTime: json['endDateTime'] != null ? DateTime.parse(json['endDateTime']) : null,
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? '',
      organizerEmail: json['organizerEmail'],
      status: EventStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] ?? 'PENDING').toString().toUpperCase(),
        orElse: () => EventStatus.PENDING,
      ),
      type: EventType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['type'] ?? 'ALUMNI_INITIATED').toString().toUpperCase(),
        orElse: () => EventType.ALUMNI_INITIATED,
      ),
      specialRequirements: json['specialRequirements'],
      rejectionReason: json['rejectionReason'],
      approvedBy: json['approvedBy'],
      rejectedBy: json['rejectedBy'],
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt']) : null,
      attendees: json['attendees'] != null ? List<String>.from(json['attendees']) : [],
      department: json['department'],
      targetAudience: json['targetAudience'],
      maxAttendees: json['maxAttendees'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      requestedBy: json['requestedBy'],
      requestedByName: json['requestedByName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerEmail': organizerEmail,
      'status': status.name.toUpperCase(),
      'type': type.name.toUpperCase(),
      'specialRequirements': specialRequirements,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'submittedAt': submittedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'attendees': attendees,
      'department': department,
      'targetAudience': targetAudience,
      'maxAttendees': maxAttendees,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
    };
  }
}

enum EventStatus {
  PENDING,
  APPROVED,
  REJECTED,
  CANCELLED,
  COMPLETED,
}

enum EventType {
  ALUMNI_INITIATED,
  MANAGEMENT_REQUESTED,
}

extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.PENDING:
        return 'Pending';
      case EventStatus.APPROVED:
        return 'Approved';
      case EventStatus.REJECTED:
        return 'Rejected';
      case EventStatus.CANCELLED:
        return 'Cancelled';
      case EventStatus.COMPLETED:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.PENDING:
        return const Color(0xFFF59E0B);
      case EventStatus.APPROVED:
        return const Color(0xFF059669);
      case EventStatus.REJECTED:
        return const Color(0xFFDC2626);
      case EventStatus.CANCELLED:
        return const Color(0xFF6B7280);
      case EventStatus.COMPLETED:
        return const Color(0xFF2563EB);
    }
  }
}