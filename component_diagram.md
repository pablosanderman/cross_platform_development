# Volcano Monitoring Dashboard - Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  FLUTTER APPLICATION                                    │
│                              Volcano Monitoring Dashboard                              │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    ENTRY POINT                                         │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│  main.dart                                                                              │
│  ├── Repository Initialization                                                         │
│  ├── Service Setup (RecentlyViewedService)                                             │
│  ├── MultiBlocProvider Setup                                                           │
│  ├── Desktop Window Configuration (bitsdojo_window)                                    │
│  └── MyApp Widget Launch                                                               │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   CORE APP LAYER                                       │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│  app.dart - MyApp Widget                                                               │
│  ├── MaterialApp Configuration                                                         │
│  ├── Platform Detection (Desktop/Mobile)                                               │
│  ├── WindowBorder (Desktop) / SafeArea (Mobile)                                        │
│  └── Main Layout Container                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              STATE MANAGEMENT LAYER                                    │
│                                  (BLoC Pattern)                                        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │ NavigationBloc  │  │    MapCubit     │  │  TimelineCubit  │  │ ComparisonBloc  │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ • Page routing  │  │ • Map events    │  │ • Timeline rows │  │ • Event compare │   │
│  │ • Split ratios  │  │ • Markers       │  │ • Scroll state  │  │ • Recently viewed│  │
│  │ • Overlays      │  │ • Popups        │  │ • Transform     │  │ • Selection     │   │
│  │ • Event details │  │ • Clustering    │  │ • Filtering     │  │                 │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│                                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │   GroupsBloc    │  │EventVisibility  │  │  NavItemsCubit  │  │ DiscussionCubit │   │
│  │                 │  │     Cubit       │  │                 │  │                 │   │
│  │ • Group CRUD    │  │ • Show/hide     │  │ • Dynamic nav   │  │ • Messages      │   │
│  │ • User roles    │  │ • Event filters │  │ • Page items    │  │ • Threads       │   │
│  │ • Permissions   │  │ • Visibility    │  │ • Navigation    │  │ • Attachments   │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│                                                                                         │
│  ┌─────────────────┐                                                                   │
│  │GenericSearchBloc│                                                                   │
│  │                 │                                                                   │
│  │ • Search query  │                                                                   │
│  │ • Results       │                                                                   │
│  │ • Filtering     │                                                                   │
│  └─────────────────┘                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   DATA LAYER                                           │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              REPOSITORIES                                       │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │   │
│  │  │ EventsRepository│  │ GroupsRepository│  │ UsersRepository │                │   │
│  │  │                 │  │                 │  │                 │                │   │
│  │  │ • Load events   │  │ • Group data    │  │ • User data     │                │   │
│  │  │ • Filter by     │  │ • CRUD ops      │  │ • Authentication│                │   │
│  │  │   coordinates   │  │ • Members       │  │ • Profiles      │                │   │
│  │  │ • Date filtering│  │                 │  │                 │                │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐                                                           │   │
│  │  │DiscussionRepo   │                                                           │   │
│  │  │                 │                                                           │   │
│  │  │ • Messages      │                                                           │   │
│  │  │ • Threads       │                                                           │   │
│  │  │ • Attachments   │                                                           │   │
│  │  └─────────────────┘                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                                SERVICES                                        │   │
│  │                                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    RecentlyViewedService                                │   │   │
│  │  │                                                                         │   │   │
│  │  │  • Track viewed events                                                 │   │   │
│  │  │  • Comparison event list                                               │   │   │
│  │  │  • Event history                                                       │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  DOMAIN MODELS                                         │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │     Event       │  │  EventLocation  │  │ EventDateRange  │  │EventAttachment  │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ • id, title     │  │ • name, lat/lng │  │ • start, end    │  │ • file data     │   │
│  │ • type, location│  │ • coordinates   │  │ • time span     │  │ • metadata      │   │
│  │ • dateRange     │  │                 │  │                 │  │                 │   │
│  │ • uniqueData    │  │                 │  │                 │  │                 │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│                                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │  LegacyEvent    │  │DiscussionMessage│  │      User       │  │     Group       │   │
│  │                 │  │                 │  │                 │  │                 │   │
│  │ • v1 format     │  │ • message data  │  │ • profile info  │  │ • members       │   │
│  │ • compatibility │  │ • attachments   │  │ • permissions   │  │ • roles         │   │
│  │                 │  │ • thread        │  │                 │  │ • settings      │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│                                                                                         │
│  ┌─────────────────┐                                                                   │
│  │ComparisonEvent  │                                                                   │
│  │     Item        │                                                                   │
│  │                 │                                                                   │
│  │ • Selected      │                                                                   │
│  │   events        │                                                                   │
│  │ • Comparison    │                                                                   │
│  │   metadata      │                                                                   │
│  └─────────────────┘                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 UI COMPONENTS                                          │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            MAIN LAYOUT                                          │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐                                                           │   │
│  │  │ NavigationView  │                                                           │   │
│  │  │                 │                                                           │   │
│  │  │ • Top nav bar   │                                                           │   │
│  │  │ • Dynamic items │                                                           │   │
│  │  │ • Page routing  │                                                           │   │
│  │  └─────────────────┘                                                           │   │
│  │                                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                        SPLIT VIEW LAYOUTS                              │   │   │
│  │  │                                                                         │   │   │
│  │  │  ┌─────────────────────────┐  ┌─────────────────────────────────────┐   │   │   │
│  │  │  │  ResizableSplitView     │  │  _VerticalResizableSplitView       │   │   │   │
│  │  │  │      (Desktop)          │  │         (Mobile)                   │   │   │   │
│  │  │  │                         │  │                                     │   │   │   │
│  │  │  │ • Horizontal split      │  │ • Vertical split                   │   │   │   │
│  │  │  │ • Resizable divider     │  │ • Touch-optimized                  │   │   │   │
│  │  │  │ • Mouse interaction     │  │ • Gesture handling                 │   │   │   │
│  │  │  └─────────────────────────┘  └─────────────────────────────────────┘   │   │   │
│  │  │                                                                         │   │   │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │                TimelineMapPill (Mobile)                        │   │   │   │
│  │  │  │                                                                 │   │   │   │
│  │  │  │ • Toggle between timeline/map                                  │   │   │   │
│  │  │  │ • Mobile-specific UI                                           │   │   │   │
│  │  │  └─────────────────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         FEATURE COMPONENTS                                     │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │   │
│  │  │  TimelinePage   │  │    MapPage      │  │ ComparisonPage  │                │   │
│  │  │                 │  │                 │  │                 │                │   │
│  │  │ • Event rows    │  │ • Event markers │  │ • Event compare │                │   │
│  │  │ • Scrolling     │  │ • Map controls  │  │ • Side-by-side  │                │   │
│  │  │ • Filtering     │  │ • Clustering    │  │ • Analysis      │                │   │
│  │  │ • Transform     │  │ • Interactions  │  │                 │                │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐                                                           │   │
│  │  │   GroupsPage    │                                                           │   │
│  │  │                 │                                                           │   │
│  │  │ • Group list    │                                                           │   │
│  │  │ • User mgmt     │                                                           │   │
│  │  │ • Permissions   │                                                           │   │
│  │  └─────────────────┘                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            OVERLAY COMPONENTS                                  │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │   │
│  │  │EventDetailsPanel│  │ AddEventOverlay │  │EventVisibility  │                │   │
│  │  │                 │  │                 │  │    Panel        │                │   │
│  │  │ • Event info    │  │ • Creation form │  │                 │                │   │
│  │  │ • Smart position│  │ • Validation    │  │ • Show/hide     │                │   │
│  │  │ • Dynamic size  │  │ • Submit        │  │ • Filters       │                │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐                                      │   │
│  │  │ComparisonSelect │  │   EventPopup    │                                      │   │
│  │  │    Overlay      │  │                 │                                      │   │
│  │  │                 │  │ • Map marker    │                                      │   │
│  │  │ • Event picker  │  │   popup         │                                      │   │
│  │  │ • Selection UI  │  │ • Quick info    │                                      │   │
│  │  └─────────────────┘  └─────────────────┘                                      │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                      FLOATING ACTION BUTTONS                                   │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐                                      │   │
│  │  │  AddEventFab    │  │EventVisibility  │                                      │   │
│  │  │                 │  │      Fab        │                                      │   │
│  │  │ • Add new event │  │                 │                                      │   │
│  │  │ • Form trigger  │  │ • Toggle panel  │                                      │   │
│  │  │                 │  │ • Visibility    │                                      │   │
│  │  └─────────────────┘  └─────────────────┘                                      │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         SHARED WIDGETS                                         │   │
│  │                                                                                 │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │   │
│  │  │   UTCTimer      │  │  SearchWidget   │  │  CustomDialogs  │                │   │
│  │  │                 │  │                 │  │                 │                │   │
│  │  │ • Real-time     │  │ • Generic       │  │ • Confirmation  │                │   │
│  │  │ • UTC display   │  │ • Reusable      │  │ • Form dialogs  │                │   │
│  │  │ • Sync timer    │  │ • Search logic  │  │ • Alerts        │                │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                            PLATFORM ADAPTATIONS                                        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                               DESKTOP                                          │   │
│  │                      (Windows, macOS, Linux)                                   │   │
│  │                                                                                 │   │
│  │  • bitsdojo_window custom controls                                             │   │
│  │  • Horizontal ResizableSplitView                                               │   │
│  │  • Mouse hover interactions                                                    │   │
│  │  • Keyboard shortcuts                                                          │   │
│  │  • WindowBorder decoration                                                     │   │
│  │  • Initial size: 1200x800, Min: 900x600                                       │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              MOBILE                                            │   │
│  │                         (iOS, Android)                                         │   │
│  │                                                                                 │   │
│  │  • Vertical _VerticalResizableSplitView                                        │   │
│  │  • TimelineMapPill toggle                                                      │   │
│  │  • Touch-optimized gestures                                                    │   │
│  │  • SafeArea handling                                                           │   │
│  │  • Responsive FAB positioning                                                  │   │
│  │  • Platform-specific icons                                                     │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                                WEB                                             │   │
│  │                                                                                 │   │
│  │  • Progressive Web App capabilities                                            │   │
│  │  • Web-optimized performance                                                   │   │
│  │  • Browser compatibility                                                       │   │
│  │  • Responsive design                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 DATA FLOW                                              │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  USER ACTION → UI COMPONENT → BLOC EVENT → BLOC LOGIC → STATE CHANGE → UI UPDATE       │
│                                                                                         │
│  EXAMPLES:                                                                              │
│  • Select Event → Timeline → NavigationBloc → Event Selected → MapCubit → Marker       │
│  • Add Event → FAB → AddEventOverlay → EventsRepository → Timeline/Map Update          │
│  • Filter Events → Visibility Panel → EventVisibilityCubit → Timeline/Map Filter      │
│  • Compare Events → Comparison Page → ComparisonBloc → RecentlyViewedService           │
│                                                                                         │
│  CROSS-COMPONENT COMMUNICATION:                                                         │
│  • TimelineCubit ←→ MapCubit (bidirectional via setter injection)                     │
│  • NavigationBloc coordinates all overlay and page state                               │
│  • ComparisonBloc tracks events across Timeline and Map                                │
│  • EventVisibilityCubit affects both Timeline and Map filtering                       │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              KEY ARCHITECTURAL PATTERNS                                │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  • BLoC Pattern: Reactive state management with event-driven architecture              │
│  • Repository Pattern: Data access abstraction with clean interfaces                   │
│  • Dependency Injection: Service and BLoC providers via MultiBlocProvider              │
│  • Observer Pattern: BLoC state streaming for reactive UI updates                      │
│  • Command Pattern: BLoC events as commands for state mutations                        │
│  • Composite Pattern: Widget composition hierarchy with reusable components            │
│  • Strategy Pattern: Platform-specific adaptations and responsive layouts              │
│  • Singleton Pattern: Shared services like RecentlyViewedService                       │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Relationships Summary

### Key Dependencies:
- **UI Components** depend on **BLoCs/Cubits** for state management
- **BLoCs/Cubits** depend on **Repositories** for data access
- **Repositories** work with **Domain Models** for data structure
- **Cross-component communication** via NavigationBloc coordination
- **Platform adaptations** handled at the UI layer with responsive design

### Critical Integrations:
1. **Timeline ↔ Map Synchronization**: Events selected in timeline highlight on map
2. **Comparison System**: Recently viewed events tracked across components
3. **Overlay Management**: NavigationBloc coordinates all overlay states
4. **Event Filtering**: EventVisibilityCubit affects both timeline and map displays
5. **Responsive Layout**: Platform detection drives layout component selection

This architecture provides clean separation of concerns, testable business logic, and maintainable cross-platform code with robust state management.