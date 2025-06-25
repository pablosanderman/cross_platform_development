import 'package:equatable/equatable.dart';
import 'discussion.dart';

/// {@template event_location}
/// Represents the location information for an event
/// {@endtemplate}
class EventLocation extends Equatable {
  /// {@macro event_location}
  const EventLocation({
    required this.name,
    this.lat,
    this.lng,
  });

  /// Human-readable name of the location
  final String name;

  /// Latitude coordinate (optional)
  final double? lat;

  /// Longitude coordinate (optional)
  final double? lng;

  /// Whether this location has geographic coordinates
  bool get hasCoordinates => lat != null && lng != null;

  /// Creates an EventLocation from JSON
  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      name: json['name'] as String,
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
    );
  }

  /// Converts EventLocation to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }

  @override
  List<Object?> get props => [name, lat, lng];
}

/// {@template event_date_range}
/// Represents the date range for an event
/// {@endtemplate}
class EventDateRange extends Equatable {
  /// {@macro event_date_range}
  const EventDateRange({
    required this.start,
    this.end,
  });

  /// Start date/time of the event
  final DateTime start;

  /// End date/time of the event (null for point events)
  final DateTime? end;

  /// Whether this is a period event (has duration)
  bool get hasDuration => end != null;

  /// Duration of the event (null for point events)
  Duration? get duration {
    if (end == null) return null;
    return end!.difference(start);
  }

  /// Creates an EventDateRange from JSON
  factory EventDateRange.fromJson(Map<String, dynamic> json) {
    return EventDateRange(
      start: DateTime.parse(json['start'] as String),
      end: json['end'] != null ? DateTime.parse(json['end'] as String) : null,
    );
  }

  /// Converts EventDateRange to JSON
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      if (end != null) 'end': end!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [start, end];
}

/// {@template event_v2}
/// Updated event model supporting the new schema with discussions and attachments
/// {@endtemplate}
class EventV2 extends Equatable {
  /// {@macro event_v2}
  const EventV2({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.description,
    required this.dateRange,
    required this.uniqueData,
    required this.attachments,
    required this.discussion,
  });

  /// Unique identifier for the event
  final String id;

  /// Title of the event
  final String title;

  /// Type of event (point, period, grouped)
  final String type;

  /// Location information for the event
  final EventLocation location;

  /// Description of the event
  final String description;

  /// Date range for the event
  final EventDateRange dateRange;

  /// Event-specific data (flexible object)
  final Map<String, dynamic> uniqueData;

  /// List of attachments associated with this event
  final List<EventAttachment> attachments;

  /// Discussion thread for this event
  final List<DiscussionMessage> discussion;

  /// Whether this event has geographic coordinates
  bool get hasCoordinates => location.hasCoordinates;

  /// Whether this event has a duration
  bool get hasDuration => dateRange.hasDuration;

  /// Get the effective start time for timeline positioning
  DateTime get effectiveStartTime => dateRange.start;

  /// Get the effective end time for timeline positioning
  DateTime? get effectiveEndTime => dateRange.end;

  /// Get top-level discussion messages (not replies)
  List<DiscussionMessage> get topLevelMessages {
    return discussion.where((msg) => !msg.isReply).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get replies to a specific message
  List<DiscussionMessage> getRepliesTo(String messageId) {
    return discussion.where((msg) => msg.replyTo == messageId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get attachment by ID
  EventAttachment? getAttachment(String attachmentId) {
    try {
      return attachments.firstWhere((att) => att.id == attachmentId);
    } catch (e) {
      return null;
    }
  }

  /// Creates an EventV2 from JSON
  factory EventV2.fromJson(Map<String, dynamic> json) {
    return EventV2(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      location: EventLocation.fromJson(json['location'] as Map<String, dynamic>),
      description: json['description'] as String,
      dateRange: EventDateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
      uniqueData: Map<String, dynamic>.from(json['uniqueData'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>)
          .map((att) => EventAttachment.fromJson(att as Map<String, dynamic>))
          .toList(),
      discussion: (json['discussion'] as List<dynamic>)
          .map((msg) => DiscussionMessage.fromJson(msg as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts EventV2 to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'location': location.toJson(),
      'description': description,
      'dateRange': dateRange.toJson(),
      'uniqueData': uniqueData,
      'attachments': attachments.map((att) => att.toJson()).toList(),
      'discussion': discussion.map((msg) => msg.toJson()).toList(),
    };
  }

  /// Creates a copy of this EventV2 with the given fields replaced
  EventV2 copyWith({
    String? id,
    String? title,
    String? type,
    EventLocation? location,
    String? description,
    EventDateRange? dateRange,
    Map<String, dynamic>? uniqueData,
    List<EventAttachment>? attachments,
    List<DiscussionMessage>? discussion,
  }) {
    return EventV2(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      dateRange: dateRange ?? this.dateRange,
      uniqueData: uniqueData ?? this.uniqueData,
      attachments: attachments ?? this.attachments,
      discussion: discussion ?? this.discussion,
    );
  }

  @override
  List<Object> get props => [
        id,
        title,
        type,
        location,
        description,
        dateRange,
        uniqueData,
        attachments,
        discussion,
      ];
}