import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/comparison_bloc.dart';
import '../bloc/comparison_state.dart';
import '../../shared/models/models.dart';

class ComparisonResultsPage extends StatelessWidget {
  const ComparisonResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Comparison'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: BlocBuilder<ComparisonBloc, ComparisonState>(
        builder: (context, state) {
          if (state.comparisonList.isEmpty) {
            return const _EmptyComparisonState();
          }

          final events = state.comparisonList.map((item) => item.event).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _ComparisonHeader(events: events),
                const SizedBox(height: 32),
                
                // General Information Table
                _GeneralInformationTable(events: events),
                const SizedBox(height: 32),
                
                // Specific Information Table
                _SpecificInformationTable(events: events),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyComparisonState extends StatelessWidget {
  const _EmptyComparisonState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No Events to Compare',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add at least 2 events to start comparing',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  final List<Event> events;
  
  const _ComparisonHeader({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Comparison',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Comparing ${events.length} events',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        // Event summary cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: events.map((event) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getEventTypeColor(event.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getEventTypeColor(event.type).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.point:
        return Colors.orange;
      case EventType.period:
        return Colors.green;
      case EventType.grouped:
        return Colors.purple;
    }
  }
}

class _GeneralInformationTable extends StatelessWidget {
  final List<Event> events;
  
  const _GeneralInformationTable({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            columnWidths: {
              0: const FixedColumnWidth(150),
              for (int i = 1; i <= events.length; i++)
                i: const FlexColumnWidth(),
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                ),
                children: [
                  const _TableCell('Attribute', isHeader: true),
                  ...events.map((event) => _TableCell(
                        event.title,
                        isHeader: true,
                        maxLines: 2,
                      )),
                ],
              ),
              
              // Data rows
              _buildGeneralInfoRow('Location', (event) => _getLocation(event)),
              _buildGeneralInfoRow('Event Type', (event) => _getEventTypeText(event.type)),
              _buildGeneralInfoRow('Start Time', (event) => _formatDateTime(event.effectiveStartTime)),
              _buildGeneralInfoRow('End Time', (event) => _formatEndTime(event)),
              _buildGeneralInfoRow('Description', (event) => event.description ?? '—'),
              _buildGeneralInfoRow('Region', (event) => event.properties?['region']?.toString() ?? '—'),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildGeneralInfoRow(String attribute, String Function(Event) getValue) {
    return TableRow(
      children: [
        _TableCell(attribute, fontWeight: FontWeight.w500),
        ...events.map((event) => _TableCell(getValue(event))),
      ],
    );
  }

  String _getLocation(Event event) {
    final location = event.properties?['location']?.toString();
    final region = event.properties?['region']?.toString();
    
    if (location != null && region != null) {
      return '$location, $region';
    } else if (location != null) {
      return location;
    } else if (region != null) {
      return region;
    } else {
      return '—';
    }
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.point:
        return 'Point Event';
      case EventType.period:
        return 'Period Event';
      case EventType.grouped:
        return 'Grouped Event';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatEndTime(Event event) {
    final endTime = event.effectiveEndTime;
    if (endTime == null) return '—';
    return _formatDateTime(endTime);
  }
}

class _SpecificInformationTable extends StatelessWidget {
  final List<Event> events;
  
  const _SpecificInformationTable({required this.events});

  @override
  Widget build(BuildContext context) {
    // Get all unique property keys from all events
    final allPropertyKeys = <String>{};
    for (final event in events) {
      if (event.properties != null) {
        allPropertyKeys.addAll(event.properties!.keys);
      }
      if (event.aggregateData != null) {
        allPropertyKeys.addAll(event.aggregateData!.keys);
      }
    }

    // Remove common keys that are already in general info
    allPropertyKeys.removeWhere((key) => ['location', 'region', 'description'].contains(key));

    if (allPropertyKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specific Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            columnWidths: {
              0: const FixedColumnWidth(150),
              for (int i = 1; i <= events.length; i++)
                i: const FlexColumnWidth(),
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                ),
                children: [
                  const _TableCell('Attribute', isHeader: true),
                  ...events.map((event) => _TableCell(
                        event.title,
                        isHeader: true,
                        maxLines: 2,
                      )),
                ],
              ),
              
              // Data rows
              ...allPropertyKeys.map((key) => _buildSpecificInfoRow(key)),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildSpecificInfoRow(String key) {
    return TableRow(
      children: [
        _TableCell(_formatPropertyKey(key), fontWeight: FontWeight.w500),
        ...events.map((event) => _TableCell(_getPropertyValue(event, key))),
      ],
    );
  }

  String _formatPropertyKey(String key) {
    // Convert camelCase and snake_case to readable format
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _getPropertyValue(Event event, String key) {
    // Check properties first
    if (event.properties?[key] != null) {
      final value = event.properties![key];
      return _formatValue(value);
    }
    
    // Check aggregate data
    if (event.aggregateData?[key] != null) {
      final value = event.aggregateData![key];
      return _formatValue(value);
    }
    
    return '—';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    
    if (value is num) {
      // Format numbers nicely
      if (value == value.toInt()) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(2);
      }
    }
    
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    
    return value.toString();
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final FontWeight? fontWeight;
  final int maxLines;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.fontWeight,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: fontWeight ?? (isHeader ? FontWeight.w600 : FontWeight.normal),
          fontSize: isHeader ? 13 : 12,
          color: isHeader ? Colors.grey.shade800 : Colors.grey.shade700,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}