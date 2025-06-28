import 'package:cross_platform_development/timeline_and_map_view.dart';
import 'package:cross_platform_development/groups/groups.dart';
import 'package:cross_platform_development/search/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/models.dart';
import 'nav_item_state.dart';

class NavItemsCubit extends Cubit<NavItemsState> {
  NavItemsCubit() : super(NavItemsState(items: _defaultNavItems));

  // Add menu items and their pages here.
  static final List<NavItem> _defaultNavItems = [
    NavItem(
      label: 'Map',
      page: TimelineMapView(),
      pageIndex: 0,
      requiresToggle: true,
    ),
    NavItem(
      label: 'Timeline',
      page: TimelineMapView(),
      pageIndex: 1,
      requiresToggle: true,
    ),
    NavItem(label: 'Group', page: GroupsPage(), pageIndex: 2),
    NavItem(label: 'Notifications', page: Container(), pageIndex: 3),
    NavItem(label: 'Search', page: SearchPage(), pageIndex: 4),
  ];

  void addNavItem(NavItem item) {
    final currentItems = List<NavItem>.from(state.items);
    currentItems.add(item);
    emit(NavItemsState(items: currentItems));
  }
}
