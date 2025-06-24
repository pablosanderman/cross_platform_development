import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/comparison_bloc.dart';
import '../widget/widget.dart';

/// Main comparison page that provides the floating comparison list
/// and selection overlay as overlays on top of other content
class ComparisonPage extends StatelessWidget {
  final Widget child;
  
  const ComparisonPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main content (timeline/map view)
        child,
        
        // Floating comparison list (bottom-right)
        const FloatingComparisonList(),
        
        // Selection overlay (full screen modal)
        const ComparisonSelectionOverlay(),
      ],
    );
  }
}