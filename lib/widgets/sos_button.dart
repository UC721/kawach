import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Animated pulsating SOS button with hold-to-activate pattern.
class SosButton extends StatefulWidget {
  final VoidCallback onActivate;
  final double size;

  const SosButton({
    super.key,
    required this.onActivate,
    this.size = 180,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    _pressController.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return GestureDetector(
      onTap: widget.onActivate,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _scaleAnim]),
        builder: (_, __) => Transform.scale(
          scale: _scaleAnim.value,
          child: SizedBox(
            width: size * _pulseAnim.value + 40,
            height: size * _pulseAnim.value + 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: size + 40,
                  height: size + 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger.withOpacity(
                        _isPressed ? 0.2 : 0.1 * _pulseAnim.value),
                  ),
                ),
                // Middle ring
                Container(
                  width: size + 20,
                  height: size + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger.withOpacity(
                        _isPressed ? 0.3 : 0.15 * _pulseAnim.value),
                  ),
                ),
                // Main button
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _isPressed
                            ? const Color(0xFFB71C1C)
                            : AppColors.danger,
                        const Color(0xFF7B0000),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withOpacity(0.6),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        'Tap to Alert',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
