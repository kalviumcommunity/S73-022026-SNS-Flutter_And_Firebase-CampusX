import 'package:equatable/equatable.dart';

/// Model for user notification preferences
class NotificationPreferences extends Equatable {
  final bool announcements;
  final bool eventRegistrations;
  final bool teamMembership;
  final bool interviews;
  final bool eventReminders;
  final bool general;

  const NotificationPreferences({
    this.announcements = true,
    this.eventRegistrations = true,
    this.teamMembership = true,
    this.interviews = true,
    this.eventReminders = true,
    this.general = true,
  });

  /// Create from Firestore map
  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    
    return NotificationPreferences(
      announcements: map['announcements'] as bool? ?? true,
      eventRegistrations: map['eventRegistrations'] as bool? ?? true,
      teamMembership: map['teamMembership'] as bool? ?? true,
      interviews: map['interviews'] as bool? ?? true,
      eventReminders: map['eventReminders'] as bool? ?? true,
      general: map['general'] as bool? ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'announcements': announcements,
      'eventRegistrations': eventRegistrations,
      'teamMembership': teamMembership,
      'interviews': interviews,
      'eventReminders': eventReminders,
      'general': general,
    };
  }

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    bool? announcements,
    bool? eventRegistrations,
    bool? teamMembership,
    bool? interviews,
    bool? eventReminders,
    bool? general,
  }) {
    return NotificationPreferences(
      announcements: announcements ?? this.announcements,
      eventRegistrations: eventRegistrations ?? this.eventRegistrations,
      teamMembership: teamMembership ?? this.teamMembership,
      interviews: interviews ?? this.interviews,
      eventReminders: eventReminders ?? this.eventReminders,
      general: general ?? this.general,
    );
  }

  @override
  List<Object?> get props => [
        announcements,
        eventRegistrations,
        teamMembership,
        interviews,
        eventReminders,
        general,
      ];

  @override
  String toString() {
    return 'NotificationPreferences(announcements: $announcements, '
        'eventRegistrations: $eventRegistrations, teamMembership: $teamMembership, '
        'interviews: $interviews, eventReminders: $eventReminders, general: $general)';
  }

  /// Check if all notifications are enabled
  bool get allEnabled =>
      announcements &&
      eventRegistrations &&
      teamMembership &&
      interviews &&
      eventReminders &&
      general;

  /// Check if all notifications are disabled
  bool get allDisabled =>
      !announcements &&
      !eventRegistrations &&
      !teamMembership &&
      !interviews &&
      !eventReminders &&
      !general;
}
