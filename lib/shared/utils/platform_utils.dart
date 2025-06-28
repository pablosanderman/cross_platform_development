import 'dart:io';

/// Utility class for platform detection and platform-specific behavior
class PlatformUtils {
  /// Returns true if running on a desktop platform (Windows, macOS, Linux)
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  /// Returns true if running on a mobile platform (iOS, Android)
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  /// Returns true if running on the web
  static bool get isWeb => identical(0, 0.0);
}