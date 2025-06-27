import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'events_repository.dart';

/// {@template discussion_repository}
/// Repository for managing discussion data persistence operations.
/// Handles adding messages, replies, and attachments to event discussions.
/// {@endtemplate}
class DiscussionRepository {
  /// {@macro discussion_repository}
  const DiscussionRepository({
    EventsRepository? eventsRepository,
  }) : _eventsRepository = eventsRepository ?? const EventsRepository();

  final EventsRepository _eventsRepository;
  static const String _eventsKey = 'events_data';
  static const String _discussionsKey = 'event_discussions';

  /// Load events from the main repository
  Future<List<Event>> _loadEvents() async {
    return await _eventsRepository.loadEvents();
  }

  /// Load discussions from persistent storage
  Future<Map<String, List<DiscussionMessage>>> _loadDiscussions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_discussionsKey);
    
    if (storedData != null) {
      final data = jsonDecode(storedData) as Map<String, dynamic>;
      final discussions = <String, List<DiscussionMessage>>{};
      
      for (final entry in data.entries) {
        final messages = (entry.value as List<dynamic>)
            .map((m) => DiscussionMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        discussions[entry.key] = messages;
      }
      
      return discussions;
    }
    
    return {};
  }

  /// Save discussions to persistent storage
  Future<void> _saveDiscussions(Map<String, List<DiscussionMessage>> discussions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    
    for (final entry in discussions.entries) {
      data[entry.key] = entry.value.map((m) => m.toJson()).toList();
    }
    
    await prefs.setString(_discussionsKey, jsonEncode(data));
  }


  /// Add a new message to an event's discussion
  Future<bool> addMessage(String eventId, DiscussionMessage message) async {
    try {
      // Load existing discussions
      final discussions = await _loadDiscussions();
      
      // Get current messages for this event (or empty list if none)
      final currentMessages = discussions[eventId] ?? <DiscussionMessage>[];
      
      // Add the new message
      final updatedMessages = [...currentMessages, message];
      discussions[eventId] = updatedMessages;
      
      // Save back to persistent storage
      await _saveDiscussions(discussions);
      
      return true;
    } catch (e) {
      // Error adding message
      return false;
    }
  }

  /// Add a reply to an existing message in an event's discussion
  Future<bool> addReply(String eventId, String parentMessageId, DiscussionMessage reply) async {
    try {
      // Load existing discussions
      final discussions = await _loadDiscussions();
      
      // Get current messages for this event (or empty list if none)
      final currentMessages = discussions[eventId] ?? <DiscussionMessage>[];
      
      // Create a reply message with the parentMessageId set as replyTo
      final replyMessage = reply.copyWith(replyTo: parentMessageId);
      final updatedMessages = [...currentMessages, replyMessage];
      discussions[eventId] = updatedMessages;
      
      // Save back to persistent storage
      await _saveDiscussions(discussions);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add an attachment to an event's discussion
  Future<bool> addAttachment(String eventId, EventAttachment attachment, String authorId) async {
    try {
      // Load existing discussions
      final discussions = await _loadDiscussions();
      
      // Get current messages for this event (or empty list if none)
      final currentMessages = discussions[eventId] ?? <DiscussionMessage>[];
      
      // Create a new message with the attachment
      final attachmentMessage = DiscussionMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        author: authorId,
        timestamp: DateTime.now(),
        body: 'Shared attachment: ${attachment.label}',
        replyTo: null,
        attachments: [attachment.id],
      );
      
      final updatedMessages = [...currentMessages, attachmentMessage];
      discussions[eventId] = updatedMessages;
      
      // Save back to persistent storage
      await _saveDiscussions(discussions);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get an event with updated discussion data
  Future<Event?> getEventWithDiscussion(String eventId) async {
    try {
      // Load the event from main repository
      final events = await _loadEvents();
      Event? event;
      
      try {
        event = events.firstWhere((e) => e.id == eventId);
      } catch (e) {
        // Event not found in main repository - this is OK for old events
        // We'll create a minimal Event for old event IDs
        // Event not found in main repository, create minimal event for discussions
        event = Event(
          id: eventId,
          title: 'Event $eventId', // Fallback title
          type: EventType.point,
          location: const EventLocation(name: 'Unknown'),
          description: 'Event loaded for discussion',
          dateRange: EventDateRange(start: DateTime.now()),
          uniqueData: const {},
          attachments: const [],
          discussion: const [],
        );
      }
      
      // Load discussions for this event
      final discussions = await _loadDiscussions();
      final eventDiscussions = discussions[eventId] ?? <DiscussionMessage>[];
      
      // Return the event with the loaded discussions
      return event.copyWith(discussion: eventDiscussions);
    } catch (e) {
      // Error getting event with discussion
      return null;
    }
  }

  /// Clear persistent data (useful for development/testing)
  Future<void> clearPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsKey);
  }
}