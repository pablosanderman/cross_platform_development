import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// {@template group}
/// Represents a user group in the volcanic monitoring system
/// {@endtemplate}
class Group extends Equatable {
  /// {@macro group}
  const Group({
    required this.id,
    required this.label,
    required this.color,
  });

  /// Unique identifier for the group
  final String id;

  /// Display label for the group
  final String label;

  /// Color hex code for the group badge/chip
  final String color;

  /// Gets the Flutter Color object from the hex string
  Color get colorValue {
    return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
  }

  /// Creates a Group from JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      label: json['label'] as String,
      color: json['color'] as String,
    );
  }

  /// Converts Group to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color': color,
    };
  }

  /// Creates a copy of this Group with the given fields replaced
  Group copyWith({
    String? id,
    String? label,
    String? color,
  }) {
    return Group(
      id: id ?? this.id,
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }

  @override
  List<Object> get props => [id, label, color];
}