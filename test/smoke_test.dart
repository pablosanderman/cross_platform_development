import 'package:cross_platform_development/comparison/models/recently_viewed_service.dart';
import 'package:cross_platform_development/navigation/nav_item/cubit/nav_item_cubit.dart';
import 'package:cross_platform_development/shared/event_visibility/cubit/event_visibility_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/app.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_bloc.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_event.dart';
import 'package:cross_platform_development/groups/bloc/groups_bloc.dart';
import 'package:cross_platform_development/groups/bloc/groups_event.dart';
import 'package:cross_platform_development/groups/bloc/groups_state.dart';
import 'package:cross_platform_development/timeline/cubit/timeline_cubit.dart';
import 'package:cross_platform_development/timeline/cubit/timeline_state.dart';
import 'package:cross_platform_development/map/cubit/map_cubit.dart';
import 'package:cross_platform_development/map/cubit/map_state.dart';
import 'package:cross_platform_development/comparison/bloc/comparison_bloc.dart';
import 'package:cross_platform_development/comparison/bloc/comparison_state.dart';
import 'package:cross_platform_development/shared/discussion/cubit/discussion_cubit.dart';
import 'package:cross_platform_development/shared/repositories/events_repository.dart';
import 'package:cross_platform_development/shared/repositories/discussion_repository.dart';

void main() {
  group('Smoke Tests - Application Initialization', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      // Test app initialization
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();
      
      // Verify app renders without throwing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('All BLoCs are provided correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify all BLoCs are accessible
      final BuildContext context = tester.element(find.byType(MaterialApp));
      
      expect(() => context.read<NavigationBloc>(), returnsNormally);
      expect(() => context.read<MapCubit>(), returnsNormally);
      expect(() => context.read<TimelineCubit>(), returnsNormally);
      expect(() => context.read<NavItemsCubit>(), returnsNormally);
      expect(() => context.read<GroupsBloc>(), returnsNormally);
      expect(() => context.read<EventVisibilityCubit>(), returnsNormally);
      expect(() => context.read<ComparisonBloc>(), returnsNormally);
      expect(() => context.read<DiscussionCubit>(), returnsNormally);
    });
  });

  group('Smoke Tests - Navigation Flow', () {
    testWidgets('Navigation system works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Test navigation to different screens
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final navigationBloc = context.read<NavigationBloc>();
      
      // Navigate to map (using actual event constructors)
      navigationBloc.add(ShowMap());
      await tester.pump();
      
      // Navigate to timeline
      navigationBloc.add(ShowTimeline());
      await tester.pump();
      
      // Navigate to groups
      navigationBloc.add(ChangePage(2));
      await tester.pump();
      
      // No crashes expected
      expect(tester.takeException(), isNull);
    });
  });

  group('Smoke Tests - Core Features', () {
    testWidgets('Timeline feature loads', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final timelineCubit = context.read<TimelineCubit>();
      
      // Test timeline initialization
      expect(timelineCubit.state, isA<TimelineState>());
      
      // Test loading events
      timelineCubit.loadEvents();
      await tester.pump();
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('Map feature loads', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final mapCubit = context.read<MapCubit>();
      
      // Test map initialization
      expect(mapCubit.state, isA<MapState>());
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('Groups feature loads', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final groupsBloc = context.read<GroupsBloc>();
      
      // Test groups initialization
      expect(groupsBloc.state, isA<GroupsState>());
      
      // Test loading groups
      groupsBloc.add(LoadGroups());
      await tester.pump();
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('Comparison feature loads', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final comparisonBloc = context.read<ComparisonBloc>();
      
      // Test comparison initialization
      expect(comparisonBloc.state, isA<ComparisonState>());
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('Discussion feature loads', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final discussionCubit = context.read<DiscussionCubit>();
      
      // Test discussion initialization
      expect(discussionCubit.state, isA<DiscussionState>());
      
      expect(tester.takeException(), isNull);
    });
  });

  group('Smoke Tests - Data Services', () {
    testWidgets('Events repository works', (WidgetTester tester) async {
      const eventsRepository = EventsRepository();
      
      // Test repository initialization
      expect(eventsRepository, isNotNull);
      
      // Test basic operations don't crash
      expect(() => eventsRepository.loadEvents(), returnsNormally);
    });

    testWidgets('Discussion repository works', (WidgetTester tester) async {
      const discussionRepository = DiscussionRepository();
      
      // Test repository initialization
      expect(discussionRepository, isNotNull);
      
      // Test basic operations don't crash
      expect(() => discussionRepository.getEventWithDiscussion("ev_2025_06_27_etna_paroxysm_001"), returnsNormally);
    });
  });

  group('Smoke Tests - UI Components', () {
    testWidgets('App renders main UI components', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Check for common UI elements
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      
      // No crashes expected
      expect(tester.takeException(), isNull);
    });

    testWidgets('Theme and styling loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify theme is set
      expect(materialApp.theme, isNotNull);
      
      expect(tester.takeException(), isNull);
    });
  });

  group('Smoke Tests - Error Handling', () {
    testWidgets('App handles BLoC errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify no uncaught exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('App observer handles events', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final navigationBloc = context.read<NavigationBloc>();
      
      // Trigger some events to test observer
      navigationBloc.add(ShowMap());
      await tester.pump();
      
      // Should not crash
      expect(tester.takeException(), isNull);
    });
  });
}

// Helper function to create test app with all required providers
Widget createTestApp() {
  const eventsRepository = EventsRepository();
  const discussionRepository = DiscussionRepository();
  final recentlyViewedService = RecentlyViewedService();

  final navigationBloc = NavigationBloc();
  final timelineCubit = TimelineCubit(eventsRepository: eventsRepository);
  final mapCubit = MapCubit(
    eventsRepository: eventsRepository,
    navigationBloc: navigationBloc,
    timelineCubit: timelineCubit,
  );
  
  timelineCubit.setMapCubit(mapCubit);
  
  final comparisonBloc = ComparisonBloc(
    eventsRepository: eventsRepository,
    recentlyViewedService: recentlyViewedService,
  );
  
  final discussionCubit = DiscussionCubit(
    discussionRepository: discussionRepository,
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: navigationBloc),
      BlocProvider.value(value: mapCubit),
      BlocProvider.value(value: timelineCubit),
      BlocProvider(create: (_) => NavItemsCubit()),
      BlocProvider(create: (_) => GroupsBloc()),
      BlocProvider(create: (_) => EventVisibilityCubit()),
      BlocProvider.value(value: comparisonBloc),
      BlocProvider.value(value: discussionCubit),
    ],
    child: const MyApp(),
  );
}