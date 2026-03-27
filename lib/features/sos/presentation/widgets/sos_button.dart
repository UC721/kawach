import 'package:flutter/material.dart';

// ============================================================
// SosActionButton – Clean-architecture SOS trigger widget
// ============================================================

/// Animated SOS button for the feature-module presentation layer.
///
/// Provides visual feedback through scale animation and colour changes
/// during the countdown phase.
class SosActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onCancel;
  final bool isCountingDown;
  final int countdownSeconds;

  const SosActionButton({
    super.key,
    required this.onPressed,
    this.onCancel,
    this.isCountingDown = false,
    this.countdownSeconds = 0,
  });

  @override
  State<SosActionButton> createState() => _SosActionButtonState();
}

class _SosActionButtonState extends State<SosActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCountingDown ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.isCountingDown ? widget.onCancel : widget.onPressed,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCountingDown
                ? const Color(0xFFFF6D00)
                : const Color(0xFFE53935),
            boxShadow: [
              BoxShadow(
                color: (widget.isCountingDown
                        ? const Color(0xFFFF6D00)
                        : const Color(0xFFE53935))
                    .withAlpha(100),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: widget.isCountingDown
                ? Text(
                    '${widget.countdownSeconds}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
