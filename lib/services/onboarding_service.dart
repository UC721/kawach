import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-run tutorial has been completed. Completed state is
/// stored locally so it works even before a user signs in.
class OnboardingService extends ChangeNotifier {
  static const String _key = 'kawach.onboarding.complete';

  bool _complete = false;
  bool get isComplete => _complete;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _complete = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _complete = true;
    notifyListeners();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    _complete = false;
    notifyListeners();
  }
}
