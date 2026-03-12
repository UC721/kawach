import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/emergency_service.dart';
import 'services/notification_service.dart';
import 'services/shake_service.dart';
import 'services/voice_service.dart';
import 'services/panic_detection_service.dart';
import 'services/motion_detection_service.dart';
import 'services/danger_zone_service.dart';
import 'services/risk_analysis_service.dart';
import 'services/predictive_danger_service.dart';
import 'services/guardian_network_service.dart';
import 'services/offline_emergency_service.dart';
import 'services/siren_service.dart';
import 'services/fake_call_service.dart';
import 'services/route_safety_service.dart';
import 'services/live_stream_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase using our mock options to prevent Android native crashes
  // when google-services.json is missing during early dev.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => EmergencyService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ShakeService()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => PanicDetectionService()),
        ChangeNotifierProvider(create: (_) => MotionDetectionService()),
        ChangeNotifierProvider(create: (_) => DangerZoneService()),
        ChangeNotifierProvider(create: (_) => RiskAnalysisService()),
        ChangeNotifierProvider(create: (_) => PredictiveDangerService()),
        ChangeNotifierProvider(create: (_) => GuardianNetworkService()),
        ChangeNotifierProvider(create: (_) => OfflineEmergencyService()),
        ChangeNotifierProvider(create: (_) => SirenService()),
        ChangeNotifierProvider(create: (_) => FakeCallService()),
        ChangeNotifierProvider(create: (_) => RouteSafetyService()),
        ChangeNotifierProvider(create: (_) => LiveStreamService()),
      ],
      child: const KawachApp(),
    ),
  );
}

