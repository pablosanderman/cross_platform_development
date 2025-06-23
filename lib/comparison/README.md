# Event Comparison Feature

A comprehensive event comparison feature for the volcano monitoring dashboard that allows users to compare multiple geological events side-by-side.

## Features

### 1. Floating Comparison List (Bottom-Right)
- **Position**: Fixed floating widget in bottom-right corner (only visible on timeline/map page)
- **Accordion Style**: Collapsible/expandable list with smooth animations
- **Header**: Shows count (e.g., "2 Items - Compare list")
- **Content**: 
  - List of selected events with event names and locations
  - Remove button (X) for each event
  - "Compare" button (primary action)
  - Plus button (+) to add more events
- **Functionality**:
  - Persists across different pages/routes
  - Maximum of 10 events can be added
  - Shows appropriate messaging when empty
  - Remove events individually

### 2. Comparison Selection Overlay
- **Overlay**: Black transparent background (opacity ~0.7)
- **Modal Content**: Centered white container with rounded corners
- **Search**: Real-time event search by name, location, or region
- **Recently Viewed**: 3x3 grid of recent events (9 total)
- **Current List**: Shows currently selected events with remove options
- **Functionality**:
  - Prevents adding duplicate events
  - Shows max limit reached messaging
  - Handles empty states with helpful messages

### 3. Comparison Results Page
- **Navigation**: New route (/comparison)
- **Header**: Back button, "Event Comparison" title, Close button
- **General Information Table**: Location, Event Type, Start/End Time, Description, Region
- **Specific Information Table**: Event-specific attributes (magnitude, depth, temperature, etc.)
- **Responsive Design**: Handles various screen sizes
- **Data Formatting**: Uses "—" for attributes that don't apply to certain event types

## Integration Points

### Timeline Integration
- **Hover Actions**: When hovering over timeline events, shows "Add to Compare" button
- **Context Menu**: Right-click or long-press on events shows comparison options
- **Recently Viewed**: Events clicked in timeline are automatically tracked
- **Visual Feedback**: Shows different states (added, max reached, available)

### Navigation Integration
- Routes handled by main app navigation
- Deep linking support for shared comparisons
- Back button and close button support

### State Management
- **ComparisonBloc**: Global state management for comparison functionality
- **RecentlyViewedService**: Persistent storage of recently viewed events
- **Integration**: Works with existing NavigationBloc and TimelineCubit

## Usage

### Adding Events to Comparison
1. **From Timeline**: 
   - Hover over any event and click "Add to Compare" button
   - Right-click or long-press for context menu
2. **From Floating List**: 
   - Click "+" button when list is expanded
   - Click "Add Events" when list is empty
3. **From Selection Overlay**:
   - Search for events or browse recently viewed
   - Click add (+) button on any event card

### Viewing Comparison
1. Add at least 2 events to comparison list
2. Click "Compare" button in floating list
3. View detailed comparison tables
4. Use back button or close button to return

### Managing Comparison List
- **Remove**: Click X button on any event in the list
- **Clear All**: Available in the floating list options
- **Maximum**: 10 events maximum for performance
- **Persistence**: List persists across app sessions

## Technical Architecture

### State Management
```dart
ComparisonBloc
├── ComparisonState (events, visibility, search results)
├── ComparisonEvent (add, remove, search, navigate)
└── RecentlyViewedService (persistent storage)
```

### Widgets
```dart
lib/comparison/
├── bloc/ (state management)
├── models/ (data models)
├── view/ (pages and main views)
├── widget/ (reusable components)
└── comparison.dart (barrel exports)
```

### Integration
- **Main App**: ComparisonPage wraps timeline/map view
- **Timeline**: Context menu and hover actions
- **Navigation**: Routes in main MaterialApp
- **BLoC Providers**: Added to main.dart MultiBlocProvider

## Data Format

Events support rich comparison attributes from the data.json file:
- **Seismic Events**: magnitude, depth, tectonic type
- **Volcanic Events**: VEI, eruption type, ash height
- **Thermal Events**: temperature, fumarole data
- **Grouped Events**: aggregate statistics, member details

The comparison tables automatically adapt to show relevant attributes for each event type.