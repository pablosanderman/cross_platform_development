import 'package:flutter/cupertino.dart';

class NavItem {
  final String label;
  final Widget page;
  final int pageIndex;
  final bool requiresToggle;

  const NavItem({
    required this.label,
    required this.page,
    required this.pageIndex,
    this.requiresToggle = false,
  });
}
