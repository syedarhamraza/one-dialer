import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import '../l10n/l10n.dart';

/// Floating scroll-to-top circular button matching Screenshot 2.
/// Appears when actively scrolling down past [threshold], and automatically
/// disappears when scrolling stops after [hideDelay].
class OneUIScrollToTopButton extends StatefulWidget {
  final ScrollController scrollController;
  final double threshold;
  final Duration hideDelay;

  const OneUIScrollToTopButton({
    super.key,
    required this.scrollController,
    this.threshold = 120.0,
    this.hideDelay = const Duration(milliseconds: 1000),
  });

  @override
  State<OneUIScrollToTopButton> createState() => _OneUIScrollToTopButtonState();
}

class _OneUIScrollToTopButtonState extends State<OneUIScrollToTopButton> {
  bool _isVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant OneUIScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final offset = widget.scrollController.offset;

    if (offset <= widget.threshold) {
      if (_isVisible) {
        _hideTimer?.cancel();
        _hideTimer = null;
        setState(() {
          _isVisible = false;
        });
      }
      return;
    }

    // Actively scrolling past threshold: show button and refresh auto-hide timer
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }

    // Cancel existing timer and restart
    if (_hideTimer?.isActive ?? false) {
      _hideTimer!.cancel();
    }
    _hideTimer = Timer(widget.hideDelay, () {
      if (mounted && _isVisible) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _scrollToTop() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_isVisible) {
      setState(() {
        _isVisible = false;
      });
    }
    widget.scrollController.animateTo(0.0, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_isVisible,
      child: AnimatedScale(
        scale: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: Semantics(
            button: true,
            label: context.l10n.scrollToTop,
            child: GestureDetector(
              onTap: _scrollToTop,
              child: OneUIGlassSurface.circle(
                size: 46,
                child: Icon(Icons.keyboard_arrow_up_rounded, color: context.palette.textPrimary, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
