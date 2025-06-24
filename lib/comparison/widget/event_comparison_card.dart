import 'package:flutter/material.dart';
import '../../shared/models/models.dart';

class EventComparisonCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isSelected;

  const EventComparisonCard({
    super.key,
    required this.event,
    this.onTap,
    this.trailing,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Event type indicator
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? Colors.blue.shade800 : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEventLocation(event),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatEventTime(event),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing widget
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
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

  String _getEventLocation(Event event) {
    final location = event.properties?['location']?.toString();
    final region = event.properties?['region']?.toString();
    
    if (location != null && region != null) {
      return '$location, $region';
    } else if (location != null) {
      return location;
    } else if (region != null) {
      return region;
    } else {
      return 'Unknown location';
    }
  }

  String _formatEventTime(Event event) {
    final start = event.effectiveStartTime;
    final end = event.effectiveEndTime;
    
    final dateFormat = '${start.day}/${start.month}/${start.year}';
    final timeFormat = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    
    if (end != null) {
      final endTimeFormat = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      return '$dateFormat $timeFormat - $endTimeFormat';
    } else {
      return '$dateFormat $timeFormat';
    }
  }
}