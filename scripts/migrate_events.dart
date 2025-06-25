import 'dart:convert';
import 'dart:io';

/// Migration script to convert old data.json to new events.json format
/// Run with: dart run scripts/migrate_events.dart
Future<void> main() async {
  try {
    // Read the old data.json file
    final oldDataFile = File('data.json');
    if (!await oldDataFile.exists()) {
      print('Error: data.json not found');
      return;
    }

    final oldDataString = await oldDataFile.readAsString();
    final oldData = jsonDecode(oldDataString) as Map<String, dynamic>;
    final oldEvents = (oldData['events'] as List).cast<Map<String, dynamic>>();

    // Convert events to new format
    final newEvents = <Map<String, dynamic>>[];
    
    for (final oldEvent in oldEvents) {
      final newEvent = _convertEvent(oldEvent);
      newEvents.add(newEvent);
    }

    // Write the new events.json file
    final newEventsFile = File('events.json');
    final newEventsJson = jsonEncode(newEvents);
    await newEventsFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonDecode(newEventsJson))
    );

    print('✅ Migration completed successfully!');
    print('📁 Created events.json with ${newEvents.length} events');
    print('💡 You can now update your EventsRepository to use events.json');
    
  } catch (e) {
    print('❌ Migration failed: $e');
  }
}

Map<String, dynamic> _convertEvent(Map<String, dynamic> oldEvent) {
  // Generate semantic ID from title
  final title = oldEvent['title'] as String;
  final id = _generateEventId(title);
  
  // Map event type
  final oldType = oldEvent['type'] as String;
  final type = _mapEventType(oldType);
  
  // Extract location information
  final location = _extractLocation(oldEvent);
  
  // Extract date range
  final dateRange = _extractDateRange(oldEvent);
  
  // Convert properties to uniqueData
  final uniqueData = Map<String, dynamic>.from(oldEvent['properties'] ?? {});
  
  // Add aggregate data if it exists
  if (oldEvent.containsKey('aggregateData')) {
    uniqueData['aggregateData'] = oldEvent['aggregateData'];
  }
  
  // Add members data for grouped events
  if (oldEvent.containsKey('members')) {
    uniqueData['members'] = oldEvent['members'];
  }

  return {
    'id': id,
    'title': title,
    'type': type,
    'location': location,
    'description': _generateDescription(oldEvent),
    'dateRange': dateRange,
    'uniqueData': uniqueData,
    'attachments': _generateAttachments(oldEvent),
    'discussion': _generateSampleDiscussion(id),
  };
}

String _generateEventId(String title) {
  return 'ev_${title.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .substring(0, title.length > 30 ? 30 : title.length)}_${DateTime.now().millisecondsSinceEpoch % 1000}';
}

String _mapEventType(String oldType) {
  switch (oldType.toLowerCase()) {
    case 'point':
      return 'point';
    case 'period':
      return 'period';
    case 'grouped':
      return 'grouped';
    default:
      return 'unknown';
  }
}

Map<String, dynamic> _extractLocation(Map<String, dynamic> oldEvent) {
  final properties = oldEvent['properties'] as Map<String, dynamic>?;
  final location = properties?['location'] as String?;
  final region = properties?['region'] as String?;
  
  final lat = oldEvent['latitude'] as double?;
  final lng = oldEvent['longitude'] as double?;
  
  String locationName = 'Unknown Location';
  if (location != null && region != null) {
    locationName = '$location, $region';
  } else if (location != null) {
    locationName = location;
  } else if (region != null) {
    locationName = region;
  }
  
  return {
    'name': locationName,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
  };
}

Map<String, dynamic> _extractDateRange(Map<String, dynamic> oldEvent) {
  final startTime = oldEvent['startTime'] as String?;
  final endTime = oldEvent['endTime'] as String?;
  final computedStart = oldEvent['computedStart'] as String?;
  final computedEnd = oldEvent['computedEnd'] as String?;
  
  return {
    'start': startTime ?? computedStart ?? DateTime.now().toIso8601String(),
    if (endTime != null || computedEnd != null) 
      'end': endTime ?? computedEnd,
  };
}

String _generateDescription(Map<String, dynamic> oldEvent) {
  final properties = oldEvent['properties'] as Map<String, dynamic>?;
  final description = properties?['description'] as String?;
  
  if (description != null) {
    return description;
  }
  
  // Generate description based on event type and properties
  final type = oldEvent['type'] as String;
  switch (type.toLowerCase()) {
    case 'point':
      if (properties?.containsKey('magnitude') == true) {
        return 'Seismic event detected with magnitude ${properties!['magnitude']}';
      }
      return 'Point event requiring investigation and monitoring';
    case 'period':
      return 'Extended period of volcanic activity with sustained monitoring';
    case 'grouped':
      final memberCount = (oldEvent['members'] as List?)?.length ?? 0;
      return 'Grouped event series with $memberCount related occurrences';
    default:
      return 'Volcanic monitoring event requiring analysis';
  }
}

List<Map<String, dynamic>> _generateAttachments(Map<String, dynamic> oldEvent) {
  final attachments = <Map<String, dynamic>>[];
  
  // Generate sample attachments based on event type
  final type = oldEvent['type'] as String;
  final id = _generateEventId(oldEvent['title'] as String);
  
  switch (type.toLowerCase()) {
    case 'point':
      if ((oldEvent['properties'] as Map<String, dynamic>?)?.containsKey('magnitude') == true) {
        attachments.add({
          'id': '${id}_seismic_data',
          'file': 'seismic_readings.png',
          'mime': 'image/png',
          'label': 'Seismic readings chart'
        });
      }
      break;
    case 'period':
      attachments.add({
        'id': '${id}_timeline_chart',
        'file': 'activity_timeline.png',
        'mime': 'image/png',
        'label': 'Activity timeline'
      });
      break;
    case 'grouped':
      attachments.add({
        'id': '${id}_cluster_analysis',
        'file': 'cluster_analysis.pdf',
        'mime': 'application/pdf',
        'label': 'Cluster analysis report'
      });
      break;
  }
  
  return attachments;
}

List<Map<String, dynamic>> _generateSampleDiscussion(String eventId) {
  // Generate sample discussion threads for demonstration
  final discussions = <Map<String, dynamic>>[];
  
  // Add some sample messages
  discussions.add({
    'id': '${eventId}_msg_001',
    'author': 'u_dr_rossi',
    'ts': DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(),
    'body': 'Initial monitoring data shows elevated activity levels. Recommend continued observation.',
    'replyTo': null,
    'attachments': [],
  });
  
  discussions.add({
    'id': '${eventId}_msg_002',
    'author': 'u_dr_bianchi',
    'ts': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
    'body': 'Agreed. The seismic data correlates with thermal imaging anomalies.',
    'replyTo': '${eventId}_msg_001',
    'attachments': [],
  });
  
  discussions.add({
    'id': '${eventId}_msg_003',
    'author': 'u_prof_ferrari',
    'ts': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    'body': 'Updated risk assessment completed. Sharing preliminary findings.',
    'replyTo': null,
    'attachments': ['${eventId}_risk_assessment'],
  });
  
  return discussions;
}