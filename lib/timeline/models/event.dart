import 'package:equatable/equatable.dart';

enum EventType { point, period, grouped }

/// Helper function for parsing nullable DateTime from JSON
DateTime? _parseNullableDate(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);

class Event extends Equatable {
  final String id;
  final EventType type;
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<GroupMember>? members;
  final DateTime? computedStart;
  final DateTime? computedEnd;
  final Map<String, dynamic>? properties;
  final Map<String, dynamic>? aggregateData;

  const Event({
    required this.id,
    required this.type,
    required this.title,
    this.startTime,
    this.endTime,
    this.members,
    this.computedStart,
    this.computedEnd,
    this.properties,
    this.aggregateData,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = EventType.values.firstWhere(
      (e) => e.name.toUpperCase() == typeString.toUpperCase(),
    );

    return Event(
      id: json['id'],
      type: type,
      title: json['title'],
      startTime: _parseNullableDate(json['startTime']),
      endTime: _parseNullableDate(json['endTime']),
      members: (json['members'] as List<dynamic>?)
          ?.map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      computedStart: _parseNullableDate(json['computedStart']),
      computedEnd: _parseNullableDate(json['computedEnd']),
      properties: json['properties'] as Map<String, dynamic>?,
      aggregateData: json['aggregateData'] as Map<String, dynamic>?,
    );
  }

  /// Get the effective start time for timeline positioning
  DateTime get effectiveStartTime {
    switch (type) {
      case EventType.point:
        return startTime!;
      case EventType.period:
        return startTime!;
      case EventType.grouped:
        return computedStart!;
    }
  }

  /// Get the effective end time for timeline positioning
  DateTime? get effectiveEndTime {
    switch (type) {
      case EventType.point:
        return null; // Point events have no duration
      case EventType.period:
        return endTime;
      case EventType.grouped:
        return computedEnd;
    }
  }

  /// Check if this event has a duration
  bool get hasDuration {
    return effectiveEndTime != null;
  }

  /// Get the duration of the event (null for point events)
  Duration? get duration {
    final end = effectiveEndTime;
    if (end == null) return null;
    return end.difference(effectiveStartTime);
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    startTime,
    endTime,
    members,
    computedStart,
    computedEnd,
    properties,
    aggregateData,
  ];
}

class GroupMember extends Equatable {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const GroupMember({
    required this.id,
    required this.timestamp,
    required this.data,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    // Extract id and timestamp, put everything else in data
    final data = Map<String, dynamic>.from(json);
    final id = data.remove('id') as String;
    final timestamp = DateTime.parse(data.remove('timestamp') as String);

    return GroupMember(id: id, timestamp: timestamp, data: data);
  }

  @override
  List<Object?> get props => [id, timestamp, data];
}
