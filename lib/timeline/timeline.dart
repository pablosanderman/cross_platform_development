/// # Timeline API
///
/// A production-ready, highly flexible timeline component following
/// Muratori's API design principles for perfect granularity, redundancy,
/// coupling, retention, and flow control.
///
/// ## 🏗️ Pipeline Architecture
///
/// ```
/// TimelineCubit
///      ↓
/// TimelinePipeline
/// ├── 📁 TimelineDataService    → load data.json → parse events
/// ├── 🔄 TimelineSorter          → sort by timestamp
/// ├── 📐 TimelineWindowCalculator → calculate visible time range
/// └── 📋 TimelineRowBuilder      → layout non-overlapping rows
///      ↓
/// TimelineState → UI rebuilds
/// ```
///
/// ## 🚀 Quick Start
///
/// ### Basic Timeline
/// ```dart
/// // Default setup
/// TimelineFactory.createDefault()
///
/// // With custom theme
/// TimelinePage(
///   provider: TimelineCubit(),
///   theme: TimelineTheme(pixelsPerHour: 200),
/// )
/// ```
///
/// ### Testing & Mocking
/// ```dart
/// // Mock data for tests
/// TimelineFactory.createWithMockData([
///   Event(id: '1', title: 'Test Event'),
/// ])
///
/// // Pure widget (any state management)
/// TimelineFactory.createCore(
///   state: myState,
///   onLoadTimeline: () => myLoader(),
/// )
/// ```
///
/// ## 🔧 Advanced Composition
///
/// ### Custom Pipeline Services
/// ```dart
/// final customPipeline = TimelinePipeline(
///   dataService: NetworkDataService('https://api.example.com'),
///   sorter: PrioritySorter(),
///   windowCalculator: WeeklyWindowCalculator(),
///   rowBuilder: DensePackingRowBuilder(),
/// );
///
/// TimelinePage(
///   provider: TimelineCubit.withPipeline(customPipeline),
///   theme: TimelineTheme(rowHeight: 80),
/// )
/// ```
///
/// ### Service Implementations
/// ```dart
/// // Custom data loading
/// class NetworkDataService extends TimelineDataService {
///   NetworkDataService(String url) : super(
///     loadJson: () => http.get(Uri.parse(url)).then((r) => r.body),
///     parseEvents: (json) => MyEventParser.parse(json),
///   );
/// }
///
/// // Custom sorting
/// class PrioritySorter extends TimelineSorter {
///   PrioritySorter() : super((events) =>
///     events.sort((a, b) => a.priority.compareTo(b.priority)));
/// }
/// ```
///
/// ## 🎯 Granular Operations
///
/// ```dart
/// final cubit = TimelineCubit();
///
/// // Individual pipeline steps
/// final events = await cubit.loadData();  // Just load
/// cubit.sort(events);                     // Just sort
/// final window = cubit.calcWindow(events);// Just calculate window
/// final rows = cubit.layout(events);      // Just layout
///
/// // Micro-updates
/// cubit.addEvent(newEvent);    // Add one event
/// cubit.removeEvent(eventId);  // Remove one event
/// cubit.process(newEvents);    // Process new event list
/// ```
///
/// ## 🛡️ Error Handling
///
/// - All operations may throw `TimelineException` with descriptive messages
/// - Only `loadData()` operations are async - all others are synchronous
/// - Exceptions preserve full stack trace for debugging
/// - State updates provide user-friendly error messages
///
/// ## 🎨 Theming
///
/// ```dart
/// const theme = TimelineTheme(
///   pixelsPerHour: 150,      // Timeline zoom level
///   rowHeight: 60,           // Event row height
///   eventHeight: 40,         // Individual event height
///   fontSize: 14,            // Text size
///   eventOpacity: 0.8,       // Event transparency
/// );
/// ```
library;

// Core state and models
export 'cubit/timeline_state.dart';
export 'models/models.dart';

// Main timeline components
export 'cubit/timeline_cubit.dart';
export 'view/timeline_view.dart';
export 'view/timeline_page.dart';

// All timeline functionality is now self-contained in the above exports
