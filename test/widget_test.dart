// Smoke Tests for Volcano Monitoring Dashboard
// Based on teacher's definition: "should open all screens and test at least one major piece of functionality"

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/groups/groups.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:cross_platform_development/comparison/comparison.dart';
import 'package:cross_platform_development/navigation/nav_item/nav_item.dart';
import 'package:cross_platform_development/shared/discussion/cubit/discussion_cubit.dart';

void main() {
  group('Volcano MonitoringDashboard Smoke Tests', () {
    testWidgets('Timeline Page Smoke Test', (WidgetTester tester) async {
      // Create a simple test app with TimelinePage
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) =>
                TimelineCubit(eventsRepository: const EventsRepository()),
            child: const Scaffold(body: TimelinePage()),
          ),
        ),
      );

      // Verify TimelinePage loads without crashing
      expect(find.byType(TimelinePage), findsOneWidget);
      expect(find.byType(TimelineView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Groups Page Smoke Test', (WidgetTester tester) async {
      // Create a simple test app with GroupsPage
      await tester.pumpWidget(
        MaterialApp(home: const Scaffold(body: GroupsPage())),
      );

      // Verify Groups page loads without crashing
      expect(find.byType(GroupsPage), findsOneWidget);
      expect(find.byType(GroupsView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Navigation Items Smoke Test', (WidgetTester tester) async {
      // Test NavItemsCubit functionality
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => NavItemsCubit(),
            child: Scaffold(
              body: BlocBuilder<NavItemsCubit, NavItemsState>(
                builder: (context, state) {
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(state.items[index].label));
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify navigation items exist
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Event Repository Smoke Test', (WidgetTester tester) async {
      // Test that events repository can be created
      final eventsRepository = const EventsRepository();

      expect(eventsRepository, isNotNull);
      expect(eventsRepository, isA<EventsRepository>());
    });

    testWidgets('BLoC State Management Smoke Test', (
      WidgetTester tester,
    ) async {
      // Test multiple BLoCs working together
      final eventsRepository = const EventsRepository();
      final discussionRepository = const DiscussionRepository();
      final recentlyViewedService = RecentlyViewedService();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => NavItemsCubit()),
            BlocProvider(create: (_) => GroupsBloc()),
            BlocProvider(
              create: (_) => TimelineCubit(eventsRepository: eventsRepository),
            ),
            BlocProvider(create: (_) => EventVisibilityCubit()),
            BlocProvider(
              create: (_) => ComparisonBloc(
                eventsRepository: eventsRepository,
                recentlyViewedService: recentlyViewedService,
              ),
            ),
            BlocProvider(
              create: (_) =>
                  DiscussionCubit(discussionRepository: discussionRepository),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // Test that all BLoCs are accessible
                  context.read<NavItemsCubit>();
                  context.read<GroupsBloc>();
                  context.read<TimelineCubit>();
                  context.read<EventVisibilityCubit>();
                  context.read<ComparisonBloc>();
                  context.read<DiscussionCubit>();

                  return const Center(child: Text('BLoCs Initialized'));
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('BLoCs Initialized'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Timeline Events Loading Smoke Test', (
      WidgetTester tester,
    ) async {
      // Test that timeline can load and display events
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) =>
                TimelineCubit(eventsRepository: const EventsRepository()),
            child: Scaffold(
              body: BlocBuilder<TimelineCubit, TimelineState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Text('Events: ${state.events.length}'),
                      Text('Loading: ${state.isLoading}'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify timeline state is accessible
      expect(find.textContaining('Events:'), findsOneWidget);
      expect(find.textContaining('Loading:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Groups BLoC Functionality Smoke Test', (
      WidgetTester tester,
    ) async {
      // Test Groups BLoC state management
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => GroupsBloc(),
            child: Scaffold(
              body: BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Text('Groups State: ${state.runtimeType}'),
                      ElevatedButton(
                        onPressed: () {
                          context.read<GroupsBloc>().add(LoadGroups());
                        },
                        child: const Text('Load Groups'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Test button interaction
      await tester.tap(find.text('Load Groups'));
      await tester.pump();

      expect(find.text('Load Groups'), findsOneWidget);
      expect(find.textContaining('Groups State:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Event Visibility Controls Smoke Test', (
      WidgetTester tester,
    ) async {
      // Test event visibility functionality
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => EventVisibilityCubit(),
            child: Scaffold(
              body: BlocBuilder<EventVisibilityCubit, EventVisibilityState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Text('Panel Open: ${state.panelOpen}'),
                      ElevatedButton(
                        onPressed: () {
                          context.read<EventVisibilityCubit>().togglePanel();
                        },
                        child: const Text('Toggle Panel'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Test toggle functionality
      expect(find.text('Panel Open: false'), findsOneWidget);

      await tester.tap(find.text('Toggle Panel'));
      await tester.pump();

      expect(find.text('Panel Open: true'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Recently Viewed Service Smoke Test', (
      WidgetTester tester,
    ) async {
      // Test recently viewed service functionality
      final service = RecentlyViewedService();

      // Test that service is created and has empty initial state
      expect(service, isNotNull);
      expect(service.recentEvents, isEmpty);

      // Create a mock event to test the service
      final mockEvent = Event(
        id: 'test-1',
        title: 'Test Event',
        description: 'Test Description',
        type: EventType.point,
        location: const EventLocation(
          name: 'Test Location',
          lat: 0.0,
          lng: 0.0,
        ),
        dateRange: EventDateRange(start: DateTime.now()),
        uniqueData: const {},
        attachments: const [],
        discussion: const [],
      );

      service.addEvent(mockEvent);
      final recentEvents = service.recentEvents;

      expect(recentEvents, isNotEmpty);
      expect(recentEvents.first.id, equals('test-1'));
    });

    testWidgets('Overall Component Integration Smoke Test', (
      WidgetTester tester,
    ) async {
      // Test that key components can work together
      final eventsRepository = const EventsRepository();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => TimelineCubit(eventsRepository: eventsRepository),
            ),
            BlocProvider(create: (_) => EventVisibilityCubit()),
            BlocProvider(create: (_) => GroupsBloc()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  BlocBuilder<TimelineCubit, TimelineState>(
                    builder: (context, state) {
                      return Text('Timeline Events: ${state.events.length}');
                    },
                  ),
                  BlocBuilder<EventVisibilityCubit, EventVisibilityState>(
                    builder: (context, state) {
                      return Text('Visibility Panel: ${state.panelOpen}');
                    },
                  ),
                  BlocBuilder<GroupsBloc, GroupsState>(
                    builder: (context, state) {
                      return Text('Groups State: ${state.runtimeType}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify all components are working
      expect(find.textContaining('Timeline Events:'), findsOneWidget);
      expect(find.textContaining('Visibility Panel:'), findsOneWidget);
      expect(find.textContaining('Groups State:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
