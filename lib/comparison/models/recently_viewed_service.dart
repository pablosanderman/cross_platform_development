import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../shared/models/models.dart';

/// Service to track and persist recently viewed events
class RecentlyViewedService {
  static const String _fileName = 'recently_viewed_events.json';
  static const int _maxRecentEvents = 20;
  
  List<Event> _recentEvents = [];
  
  /// Get the list of recently viewed events (up to 9 for UI display)
  List<Event> get recentEvents => _recentEvents.take(9).toList();
  
  /// Add an event to the recently viewed list
  void addEvent(Event event) {
    // Remove if already exists to avoid duplicates
    _recentEvents.removeWhere((e) => e.id == event.id);
    
    // Add to beginning of list
    _recentEvents.insert(0, event);
    
    // Keep only the most recent events
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents = _recentEvents.take(_maxRecentEvents).toList();
    }
    
    // Persist to storage
    _saveToStorage();
  }
  
  /// Load recently viewed events from storage
  Future<void> loadFromStorage() async {
    try {
      if (kIsWeb) {
        // For web, we'll use a simple in-memory storage
        // In a real app, you might use localStorage or IndexedDB
        return;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as List;
        _recentEvents = jsonData
            .map((json) => Event.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // If loading fails, start with empty list
      _recentEvents = [];
    }
  }
  
  /// Save recently viewed events to storage
  Future<void> _saveToStorage() async {
    try {
      if (kIsWeb) {
        // For web, we'll skip persistence
        return;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      final jsonData = _recentEvents.map((event) => event.toJson()).toList();
      
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      // If saving fails, continue silently
      debugPrint('Failed to save recently viewed events: $e');
    }
  }
  
  /// Clear all recently viewed events
  void clear() {
    _recentEvents.clear();
    _saveToStorage();
  }
}