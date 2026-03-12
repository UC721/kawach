import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fake_call_service.dart';
import '../utils/constants.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FakeCallService>().triggerFakeCall();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fakeCall = context.watch<FakeCallService>();

    if (fakeCall.isCallActive) {
      return _buildActiveCall(context, fakeCall);
    }
    return _buildIncomingCall(context, fakeCall);
  }

  Widget _buildIncomingCall(BuildContext context, FakeCallService fakeCall) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Caller info
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface,
              child: Text(
                fakeCall.callerName.isNotEmpty
                    ? fakeCall.callerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              fakeCall.callerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Incoming call...',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
            const Spacer(),
            // Answer / Decline row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CallBtn(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: () async {
                      await fakeCall.endCall();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _CallBtn(
                    icon: Icons.call,
                    color: Colors.green,
                    label: 'Answer',
                    onTap: fakeCall.answerCall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCall(BuildContext context, FakeCallService fakeCall) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.security_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(height: 20),
            Text(
              fakeCall.callerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const _CallTimer(),
            const Spacer(),
            // Call controls
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CallControlBtn(icon: Icons.mic_off, label: 'Mute'),
                SizedBox(width: 32),
                _CallControlBtn(icon: Icons.dialpad, label: 'Keypad'),
                SizedBox(width: 32),
                _CallControlBtn(icon: Icons.volume_up, label: 'Speaker'),
              ],
            ),
            const SizedBox(height: 40),
            _CallBtn(
              icon: Icons.call_end,
              color: Colors.red,
              label: 'End',
              onTap: () async {
                await fakeCall.endCall();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

class _CallTimer extends StatefulWidget {
  const _CallTimer();

  @override
  State<_CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<_CallTimer> {
  int _seconds = 0;
  late final timer = Stream.periodic(const Duration(seconds: 1),
      (i) => i + 1).listen((s) => setState(() => _seconds = s));

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return Text('$m:$s',
        style:
            const TextStyle(color: Colors.white60, fontSize: 20));
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallBtn(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 14)),
      ],
    );
  }
}

class _CallControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CallControlBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white12,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
