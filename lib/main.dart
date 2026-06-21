import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env_config.dart';
import 'services/ai_guardian_service.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/background_sos_service.dart';
import 'services/camera_evidence_service.dart';
import 'services/danger_zone_service.dart';
import 'services/emergency_service.dart';
import 'services/evidence_vault_service.dart';
import 'services/guardian_network_service.dart';
import 'services/live_stream_service.dart';
import 'services/location_service.dart';
import 'services/mesh_relay_service.dart';
import 'services/motion_detection_service.dart';
import 'services/notification_service.dart';
import 'services/offline_emergency_service.dart';
import 'services/panic_detection_service.dart';
import 'services/predictive_danger_service.dart';
import 'services/risk_analysis_service.dart';
import 'services/route_safety_service.dart';
import 'services/shake_service.dart';
import 'services/safety_streamer_service.dart';
import 'services/siren_service.dart';
import 'services/sms_service.dart';
import 'services/sos_queue_manager.dart';
import 'services/user_service.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SosQueueManager.instance.initialize();

  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  } catch (error) {
    debugPrint('Supabase init skipped: $error');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => CameraEvidenceService()),
        ChangeNotifierProvider(create: (_) => EvidenceVaultService()),
        ChangeNotifierProvider(create: (_) => LiveStreamService()),
        ChangeNotifierProvider(create: (_) => SmsService()),
        ChangeNotifierProvider(create: (_) => DangerZoneService()),
        ChangeNotifierProvider(create: (_) => PredictiveDangerService()),
        ChangeNotifierProvider(create: (_) => RiskAnalysisService()),
        ChangeNotifierProvider(create: (_) => ShakeService()),
        ChangeNotifierProvider(create: (_) => SafetyStreamerService()),
        ChangeNotifierProvider(create: (_) => MotionDetectionService()),
        ChangeNotifierProvider(create: (_) => PanicDetectionService()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => GuardianNetworkService()),
        ChangeNotifierProvider(create: (_) => BackgroundSosService()),
        ChangeNotifierProvider(create: (_) => MeshRelayService()),
        ChangeNotifierProvider(
          create: (context) => OfflineEmergencyService(
            meshRelayService: context.read<MeshRelayService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => EmergencyService()),
        ChangeNotifierProvider(create: (_) => SirenService()),
        ChangeNotifierProvider(create: (_) => RouteSafetyService()),
        ChangeNotifierProvider(create: (_) => AiGuardianService()),
      ],
      child: const KawachApp(),
    ),
  );
}
