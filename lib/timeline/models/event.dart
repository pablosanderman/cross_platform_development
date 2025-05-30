import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String description;
  final String author;
  final DateTime startTime;
  final DateTime? endTime;
  final Coordinates coordinates;
  final String eventType;
  final List<FileAttachment> fileAttachments;
  final List<String> tags;
  final Map<String, dynamic> additionalData;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.startTime,
    this.endTime,
    required this.coordinates,
    required this.eventType,
    required this.fileAttachments,
    required this.tags,
    required this.additionalData,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      author: json['author'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      coordinates: Coordinates.fromJson(json['coordinates']),
      eventType: json['eventType'],
      fileAttachments: (json['fileAttachments'] as List)
          .map((attachment) => FileAttachment.fromJson(attachment))
          .toList(),
      tags: List<String>.from(json['tags']),
      additionalData: Map<String, dynamic>.from(json)
        ..removeWhere(
          (key, value) => [
            'id',
            'title',
            'description',
            'author',
            'startTime',
            'endTime',
            'coordinates',
            'eventType',
            'fileAttachments',
            'tags',
          ].contains(key),
        ),
    );
  }

  Duration get duration {
    if (endTime == null) {
      // For ongoing events, show a default duration of 1 hour
      return const Duration(hours: 1);
    }
    return endTime!.difference(startTime);
  }

  bool get isOngoing => endTime == null;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    author,
    startTime,
    endTime,
    coordinates,
    eventType,
    fileAttachments,
    tags,
    additionalData,
  ];
}

class Coordinates extends Equatable {
  final double latitude;
  final double longitude;
  final double elevation;
  final double? depth;

  const Coordinates({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    this.depth,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      elevation: json['elevation'].toDouble(),
      depth: json['depth']?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, elevation, depth];
}

class FileAttachment extends Equatable {
  final String filename;
  final String type;
  final int size;
  final String url;

  const FileAttachment({
    required this.filename,
    required this.type,
    required this.size,
    required this.url,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      filename: json['filename'],
      type: json['type'],
      size: json['size'],
      url: json['url'],
    );
  }

  @override
  List<Object?> get props => [filename, type, size, url];
}
