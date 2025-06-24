import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation/navigation.dart';

/// A resizable split view widget that allows users to drag a divider to resize
/// the proportions between two child widgets horizontally.
class ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double splitRatio;
  final double minLeftWidth;
  final double minRightWidth;
  final double dividerWidth;
  final bool showDivider;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const ResizableSplitView({
    super.key,
    required this.leftChild,
    required this.rightChild,
    required this.splitRatio,
    this.minLeftWidth = 200.0,
    this.minRightWidth = 200.0,
    this.dividerWidth = 6.0,
    this.showDivider = true,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  double? _initialRatio;
  double? _startX;
  double? _availableWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        _availableWidth = availableWidth;

        // Calculate effective widths based on split ratio
        final effectiveDividerWidth = widget.showDivider ? widget.dividerWidth : 0.0;
        final contentWidth = availableWidth - effectiveDividerWidth;
        final leftWidth = contentWidth * widget.splitRatio;
        final rightWidth = contentWidth * (1.0 - widget.splitRatio);

        return Stack(
          children: [
            // Left child
            Positioned(
              left: 0,
              top: 0,
              width: leftWidth,
              height: constraints.maxHeight,
              child: ClipRect(child: widget.leftChild),
            ),
            // Right child
            Positioned(
              left: leftWidth + effectiveDividerWidth,
              top: 0,
              width: rightWidth,
              height: constraints.maxHeight,
              child: ClipRect(child: widget.rightChild),
            ),
            // Divider (resize handle)
            if (widget.showDivider)
              Positioned(
                left: leftWidth,
                top: 0,
                width: widget.dividerWidth,
                height: constraints.maxHeight,
                child: _ResizeDivider(
                  onDragStarted: () {
                    _initialRatio = widget.splitRatio;
                    widget.onDragStarted?.call();
                  },
                  onDragUpdate: (details) {
                    if (_initialRatio != null && _availableWidth != null) {
                      final deltaX = details.globalPosition.dx - (_startX ?? details.globalPosition.dx);
                      if (_startX == null) {
                        _startX = details.globalPosition.dx;
                        return;
                      }

                      // Calculate new ratio based on drag delta
                      final contentWidth = _availableWidth! - widget.dividerWidth;
                      final deltaRatio = deltaX / contentWidth;
                      final newRatio = _initialRatio! + deltaRatio;

                      // Apply minimum width constraints
                      final minLeftRatio = widget.minLeftWidth / contentWidth;
                      final minRightRatio = widget.minRightWidth / contentWidth;
                      final maxLeftRatio = 1.0 - minRightRatio;

                      final constrainedRatio = newRatio.clamp(minLeftRatio, maxLeftRatio);

                      // Update the split ratio via NavigationBloc
                      context.read<NavigationBloc>().add(UpdateSplitRatio(constrainedRatio));
                    }
                  },
                  onDragEnded: () {
                    _initialRatio = null;
                    _startX = null;
                    widget.onDragEnded?.call();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The visual divider that handles drag gestures for resizing
class _ResizeDivider extends StatefulWidget {
  final VoidCallback onDragStarted;
  final Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDragEnded;

  const _ResizeDivider({
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
  });

  @override
  State<_ResizeDivider> createState() => _ResizeDividerState();
}

class _ResizeDividerState extends State<_ResizeDivider> {
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onPanStart: (details) {
          setState(() => _isDragging = true);
          widget.onDragStarted();
        },
        onPanUpdate: widget.onDragUpdate,
        onPanEnd: (details) {
          setState(() => _isDragging = false);
          widget.onDragEnded();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _isDragging
                ? Colors.blue.withValues(alpha: 0.4)
                : _isHovering
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: _isDragging
                    ? Colors.blue.withValues(alpha: 0.8)
                    : _isHovering
                        ? Colors.blue.withValues(alpha: 0.6)
                        : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
              right: BorderSide(
                color: _isDragging
                    ? Colors.blue.withValues(alpha: 0.8)
                    : _isHovering
                        ? Colors.blue.withValues(alpha: 0.6)
                        : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                color: _isDragging
                    ? Colors.blue
                    : _isHovering
                        ? Colors.blue.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}