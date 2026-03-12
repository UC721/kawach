import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Animated danger warning banner displayed when user enters a risky zone.
class DangerWarningBanner extends StatefulWidget {
  final String riskLevel;
  final List<String> alerts;

  const DangerWarningBanner({
    super.key,
    required this.riskLevel,
    this.alerts = const [],
  });

  @override
  State<DangerWarningBanner> createState() =>
      _DangerWarningBannerState();
}

class _DangerWarningBannerState extends State<DangerWarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bannerColor {
    switch (widget.riskLevel) {
      case 'HIGH':
        return AppColors.danger;
      case 'MODERATE':
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bannerColor.withOpacity(0.15 * _anim.value + 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _bannerColor.withOpacity(0.5 * _anim.value)),
        ),
        child: Row(
          children: [
            Icon(
              widget.riskLevel == 'HIGH'
                  ? Icons.warning_rounded
                  : Icons.info_outline_rounded,
              color: _bannerColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ${widget.riskLevel} RISK ZONE',
                    style: TextStyle(
                      color: _bannerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.alerts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.alerts.first,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _bannerColor, size: 20),
          ],
        ),
      ),
    );
  }
}
