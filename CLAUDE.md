# Volcano Monitoring Dashboard - Flutter Cross-Platform Development

## Project Overview
This is a Flutter-based cross-platform volcano monitoring dashboard application that provides real-time visualization and analysis of geological events. The app features a sophisticated timeline and map interface for tracking seismic activities, eruptions, and other volcanic phenomena.

**Application Name**: Volcano Monitoring Dashboard  
**Framework**: Flutter  
**Architecture**: BLoC Pattern with State Management  
**Platforms**: Windows, macOS, Linux, iOS, Android, Web  

## Key Features

### Core Functionality
- **Timeline & Map Split View**: Resizable dual-pane interface showing chronological events and geographical visualization
- **Event Management**: Track point events (earthquakes) and period events (eruption phases) with detailed geological data
- **Event Comparison**: Compare multiple events with recently viewed service tracking
- **Real-time Data**: UTC timer integration for synchronized time display
- **Search System**: Generic search functionality for events and users
- **Group Management**: User group organization and management
- **Event Visibility Controls**: Filter and toggle event visibility with floating action button

### User Interface
- **Custom Desktop Window**: Uses `bitsdojo_window` for native desktop window controls
- **Resizable Panels**: Dynamic split views with user-adjustable ratios
- **Overlay System**: Event details panels with smart positioning
- **Navigation**: Multi-page navigation system with dynamic nav items
- **Material Design**: Consistent Material Design UI across all platforms

## Technical Architecture

### State Management (BLoC Pattern)
- **NavigationBloc**: Manages page navigation, split ratios, and layout state
- **MapCubit**: Handles map state, markers, and geographical data
- **TimelineCubit**: Manages timeline events and filtering
- **GroupsBloc**: Handles user group operations
- **ComparisonBloc**: Manages event comparison functionality
- **EventVisibilityCubit**: Controls event filtering and visibility
- **GenericSearchBloc**: Handles search operations across different data types

### Data Layer
- **EventsRepository**: Manages event data operations
- **UsersRepository**: Handles user data management  
- **GroupsRepository**: Manages group-related operations
- **RecentlyViewedService**: Tracks recently accessed events for comparison

### Key Dependencies
```yaml
# State Management
flutter_bloc: ^9.1.1
bloc: ^9.0.0
equatable: ^2.0.5

# UI & Desktop
bitsdojo_window: ^0.1.6
cupertino_icons: ^1.0.8

# Maps & Location
flutter_map: ^8.1.1
latlong2: ^0.9.1

# Utilities
uuid: ^4.5.1
intl: ^0.20.2
path_provider: ^2.1.5
shared_preferences: ^2.2.2
```

## File Structure

```
lib/
├── app.dart                    # Main app widget with layout logic
├── main.dart                   # App entry point with BLoC providers
├── app_observer.dart           # BLoC observer for debugging
├── comparison/                 # Event comparison feature
│   ├── bloc/                   # Comparison BLoC logic
│   ├── models/                 # Comparison data models
│   ├── view/                   # Comparison UI components
│   └── widget/                 # Comparison-specific widgets
├── groups/                     # User group management
├── map/                        # Map visualization
│   ├── cubit/                  # Map state management
│   └── view/                   # Map components (markers, popups)
├── navigation/                 # App navigation system
├── search/                     # Generic search functionality
├── shared/                     # Shared components and models
│   ├── models/                 # Core data models (Event, User, Group)
│   ├── repositories/           # Data access layer
│   └── event_visibility/       # Event filtering system
├── timeline/                   # Timeline visualization
├── utc_timer/                  # Real-time clock component
└── widgets/                    # Reusable UI components
```

## Development Commands

### Commit Message Guidelines
- Use conventional commit format with lowercase prefixes: `fix:`, `feat:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`
- Write commit messages as single sentences without bullet points
- Example: `fix: resolve overlapping FAB buttons by moving add event functionality to app level`

### Testing & Quality
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

### Data Management
```bash
# Run data migration scripts
dart run scripts/migrate_events.dart
```

## Data Structure

### Event Model
Events support both point events (earthquakes) and period events (eruptions):
```json
{
  "id": "ev_2025_01_15_etna_earthquake_001",
  "title": "M 4.2 earthquake near Etna",
  "type": "point", // or "period"
  "location": {
    "name": "Sicily, Italy",
    "lat": 37.7513,
    "lng": 14.9934
  },
  "dateRange": {
    "start": "2025-01-15T21:45:00Z",
    "end": "2025-01-15T22:00:00Z" // for period events
  },
  "uniqueData": {
    "magnitude": 4.2,
    "depthKm": 10.5,
    "region": "Etna"
  }
}
```

### Assets
- **events.json**: Current event data with v2 structure
- **users.json**: User account information
- **groups.json**: User group definitions
- **volcano_graph_image.webp**: Application imagery

## Platform-Specific Notes

### Desktop (Windows/macOS/Linux)
- Custom window controls with `bitsdojo_window`
- Resizable split views optimized for desktop interaction
- Keyboard shortcuts and desktop-specific UI patterns
- Initial window size: 1200x800, minimum: 900x600

### Mobile (iOS/Android)
- Touch-optimized gestures for map interaction
- Responsive layout adaptation for smaller screens
- Platform-specific icons and styling

### Web
- Progressive Web App capabilities
- Web-optimized performance and rendering
- Browser compatibility across modern web browsers

## Development Tips

### Debugging and Testing
- **Let the user handle app execution**: Do not attempt to run, debug, or hot reload the Flutter app yourself
- User will provide debug output and test results
- Focus on code analysis and fixes based on user feedback
- Add temporary print statements for debugging when needed (user will run and provide output)

### Working with BLoC
- Use `MultiBlocProvider` in main.dart for dependency injection
- Follow the established pattern: Event → Bloc → State → UI
- Utilize `BlocBuilder` and `BlocListener` for reactive UI updates

### Map Integration
- Events are displayed as markers with clustering support
- Map state is synchronized with timeline selection
- Custom markers for different event types and magnitudes

### Event Comparison
- Recently viewed events are automatically tracked
- Comparison mode allows side-by-side event analysis
- Floating comparison list shows selected events

### Navigation System
- Page-based navigation with dynamic nav items
- State preservation across page switches
- Split view ratios are maintained per session

## Performance Considerations
- Event data is loaded efficiently with repository pattern
- Map markers use clustering to handle large datasets
- State management minimizes unnecessary rebuilds
- Asset optimization for cross-platform deployment

---

*This CLAUDE.md file serves as your development companion for the Volcano Monitoring Dashboard. It provides context about the application architecture, development workflows, and platform-specific considerations to help with efficient Flutter development.*