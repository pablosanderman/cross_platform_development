/// Timeline display constants
class TimelineConstants {
  // Layout dimensions
  static const double rowHeight = 80.0;
  static const double eventHeight = 50.0;
  static const double rulerHeight = 60.0;

  // Interactive viewer settings
  static const double minScale = 0.3;
  static const double maxScale = 3.0;

  // Event settings
  static const Duration defaultEventDuration = Duration(minutes: 180);
  static const double eventOpacity = 0.97;
  static const double fontSize = 14.0;
  static const double rulerFontSize = 12.0;

  // Timeline scaling
  static const double pixelsPerHour = 120.0;

  // Spacing and padding
  static const double eventSpacing = 8.0;
  static const double eventPadding = 12.0;
  static const double eventBorderRadius = 5.0;

  TimelineConstants._();
}
