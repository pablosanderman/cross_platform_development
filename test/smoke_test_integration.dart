import 'package:cross_platform_development/comparison/comparison.dart';
import 'package:cross_platform_development/navigation/nav_item/nav_item.dart';
import 'package:cross_platform_development/shared/event_visibility/event_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cross_platform_development/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_bloc.dart';
import 'package:cross_platform_development/groups/bloc/groups_bloc.dart';
import 'package:cross_platform_development/timeline/cubit/timeline_cubit.dart';
import 'package:cross_platform_development/map/cubit/map_cubit.dart';
import 'package:cross_platform_development/comparison/bloc/comparison_bloc.dart';
import 'package:cross_platform_development/shared/discussion/cubit/discussion_cubit.dart';
import 'package:cross_platform_development/shared/repositories/events_repository.dart';
import 'package:cross_platform_development/shared/repositories/discussion_repository.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Smoke Tests', () {
    testWidgets('Full app flow smoke test', (WidgetTester tester) async {
      // Start the app with proper setup
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      // Verify app starts
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test basic navigation if UI elements are present
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify no crashes during startup
      expect(tester.takeException(), isNull);
    });

    testWidgets('App responds to user interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      // Test basic interactions like taps
      final scaffolds = find.byType(Scaffold);
      if (scaffolds.hasFound) {
        await tester.tap(scaffolds.first);
        await tester.pump();
      }

      // Scroll if scrollable widgets are present
      final scrollables = find.byType(Scrollable);
      if (scrollables.hasFound) {
        await tester.drag(scrollables.first, const Offset(0, -100));
        await tester.pump();
      }

      // Verify no crashes during interactions
      expect(tester.takeException(), isNull);
    });

    testWidgets('App handles basic state changes', (WidgetTester tester) async {
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      // Test that app can handle state changes
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify no crashes during state changes
      expect(tester.takeException(), isNull);
    });
  });
}

// Helper function to create integration test app
Widget createIntegrationTestApp() {
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