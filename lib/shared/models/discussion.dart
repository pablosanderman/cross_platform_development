import 'package:equatable/equatable.dart';

/// {@template discussion_message}
/// Represents a message in an event discussion thread
/// {@endtemplate}
class DiscussionMessage extends Equatable {
  /// {@macro discussion_message}
  const DiscussionMessage({
    required this.id,
    required this.author,
    required this.timestamp,
    required this.body,
    required this.replyTo,
    required this.attachments,
  });

  /// Unique identifier for the message
  final String id;

  /// User ID of the message author
  final String author;

  /// Timestamp when the message was posted
  final DateTime timestamp;

  /// Text content of the message
  final String body;

  /// ID of the message this is replying to (null for top-level messages)
  final String? replyTo;

  /// List of attachment IDs referenced in this message
  final List<String> attachments;

  /// Whether this message is a reply to another message
  bool get isReply => replyTo != null;

  /// Creates a DiscussionMessage from JSON
  factory DiscussionMessage.fromJson(Map<String, dynamic> json) {
    return DiscussionMessage(
      id: json['id'] as String,
      author: json['author'] as String,
      timestamp: DateTime.parse(json['ts'] as String),
      body: json['body'] as String,
      replyTo: json['replyTo'] as String?,
      attachments: (json['attachments'] as List<dynamic>).cast<String>(),
    );
  }

  /// Converts DiscussionMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'ts': timestamp.toIso8601String(),
      'body': body,
      'replyTo': replyTo,
      'attachments': attachments,
    };
  }

  /// Creates a copy of this DiscussionMessage with the given fields replaced
  DiscussionMessage copyWith({
    String? id,
    String? author,
    DateTime? timestamp,
    String? body,
    String? replyTo,
    List<String>? attachments,
  }) {
    return DiscussionMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      body: body ?? this.body,
      replyTo: replyTo ?? this.replyTo,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [id, author, timestamp, body, replyTo, attachments];
}

/// {@template event_attachment}
/// Represents a file attachment associated with an event
/// {@endtemplate}
class EventAttachment extends Equatable {
  /// {@macro event_attachment}
  const EventAttachment({
    required this.id,
    required this.file,
    required this.mime,
    required this.label,
  });

  /// Unique identifier for the attachment
  final String id;

  /// File path or name of the attachment
  final String file;

  /// MIME type of the attachment
  final String mime;

  /// Human-readable label for the attachment
  final String label;

  /// Whether this attachment is an image
  bool get isImage => mime.startsWith('image/');

  /// Whether this attachment is a video
  bool get isVideo => mime.startsWith('video/');

  /// Whether this attachment is a PDF
  bool get isPdf => mime == 'application/pdf';

  /// Whether this attachment can be previewed inline
  bool get canPreview => isImage || isPdf;

  /// Creates an EventAttachment from JSON
  factory EventAttachment.fromJson(Map<String, dynamic> json) {
    return EventAttachment(
      id: json['id'] as String,
      file: json['file'] as String,
      mime: json['mime'] as String,
      label: json['label'] as String,
    );
  }

  /// Converts EventAttachment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file': file,
      'mime': mime,
      'label': label,
    };
  }

  /// Creates a copy of this EventAttachment with the given fields replaced
  EventAttachment copyWith({
    String? id,
    String? file,
    String? mime,
    String? label,
  }) {
    return EventAttachment(
      id: id ?? this.id,
      file: file ?? this.file,
      mime: mime ?? this.mime,
      label: label ?? this.label,
    );
  }

  @override
  List<Object> get props => [id, file, mime, label];
}