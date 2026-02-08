import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class CustomToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFFE6F8F2);
      case ToastType.error:
        return const Color(0xFFFFEBEB);
      case ToastType.info:
        return const Color(0xFFE7F5FF);
    }
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF12B886);
      case ToastType.error:
        return Colors.redAccent;
      case ToastType.info:
        return Colors.blueAccent;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getBackgroundColor().withOpacity(0.85),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: _getAccentColor().withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIcon(),
                              color: _getAccentColor(),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _controller.reverse().then(
                                  (_) => widget.onDismiss(),
                                );
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.black.withAlpha(128),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress Bar at the bottom
                      Positioned(
                        bottom: 0,
                        left: 25,
                        right: 25,
                        child: _ProgressBar(
                          color: _getAccentColor(),
                          duration: const Duration(seconds: 3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Color color;
  final Duration duration;

  const _ProgressBar({required this.color, required this.duration});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pbController;

  @override
  void initState() {
    super.initState();
    _pbController = AnimationController(vsync: this, duration: widget.duration);
    _pbController.forward();
  }

  @override
  void dispose() {
    _pbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pbController,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: 1 - _pbController.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          minHeight: 3,
        );
      },
    );
  }
}
