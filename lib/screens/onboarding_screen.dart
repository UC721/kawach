import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/onboarding_service.dart';
import '../utils/constants.dart';
import '../widgets/immersive_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  static const _steps = <_OnboardingStep>[
    _OnboardingStep(
      icon: Icons.shield_outlined,
      title: 'Welcome to KAWACH',
      subtitle:
          'Your personal shield. A smart women-safety system that turns your '
          'phone into a guardian that never sleeps.',
      color: AppColors.primary,
    ),
    _OnboardingStep(
      icon: Icons.crisis_alert_outlined,
      title: 'One tap to SOS',
      subtitle:
          'Press the SOS button, shake, or speak a phrase. KAWACH shares your '
          'live location, captures evidence and alerts guards instantly.',
      color: Color(0xFFFF6D00),
    ),
    _OnboardingStep(
      icon: Icons.people_alt_outlined,
      title: 'Build your circle',
      subtitle:
          'Add trusted guardians and emergency contacts. They approve the '
          'relationship, and you approve theirs.',
      color: Color(0xFF00BFA5),
    ),
    _OnboardingStep(
      icon: Icons.local_hospital_outlined,
      title: 'Pre-fill your profile',
      subtitle:
          'Blood type, allergies, insurance and legal holder are shown to '
          'responders during an emergency. Set it up once, protect always.',
      color: Color(0xFF2979FF),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await context.read<OnboardingService>().complete();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _steps.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishing ? null : _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _StepView(step: _steps[i]),
                ),
              ),
              _buildDots(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _finishing
                        ? null
                        : () {
                            if (isLast) {
                              _finish();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                    icon: Icon(isLast
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward),
                    label: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepView extends StatelessWidget {
  final _OnboardingStep step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TiltCard(
            maxTilt: 0.15,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.color.withValues(alpha: 0.12),
                border: Border.all(color: step.color.withValues(alpha: 0.3)),
              ),
              child: Icon(step.icon, color: step.color, size: 52),
            ),
          ),
          const SizedBox(height: 40),
          Text(step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(step.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
