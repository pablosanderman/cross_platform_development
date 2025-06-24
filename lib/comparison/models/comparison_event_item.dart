import 'package:equatable/equatable.dart';
import '../../shared/models/models.dart';

/// Wrapper for events in the comparison list with additional metadata
class ComparisonEventItem extends Equatable {
  final Event event;
  final DateTime addedAt;

  const ComparisonEventItem({
    required this.event,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [event, addedAt];
}