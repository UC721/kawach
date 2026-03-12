import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/risk_analysis_service.dart';
import '../services/danger_zone_service.dart';
import '../services/predictive_danger_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class RiskAlertScreen extends StatelessWidget {
  const RiskAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final risk = context.watch<RiskAnalysisService>();
    final predictive = context.watch<PredictiveDangerService>();

    final riskColor = risk.riskLevel == 'HIGH'
        ? AppColors.danger
        : risk.riskLevel == 'MODERATE'
            ? AppColors.warning
            : AppColors.safe;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Risk Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    risk.riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Composite Risk Score: ${risk.compositeScore.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Score bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: risk.compositeScore / 10,
                      backgroundColor: Colors.white12,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(riskColor),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Risk factors
            if (risk.alerts.isNotEmpty) ...[
              const Text('Risk Factors',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...risk.alerts.map((alert) => _AlertTile(alert: alert)),
              const SizedBox(height: 24),
            ],
            // AI Predictive analysis
            const Text('AI Predictive Analysis',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(predictive.getRiskLabel(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...predictive.riskFactors.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: Colors.white54),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(f,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13))),
                          ],
                        ),
                      )),
                  if (predictive.riskFactors.isEmpty)
                    const Text(
                      'No significant risk factors detected currently.',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Refresh button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Analysis'),
                onPressed: () async {
                  try {
                    final pos = await context
                        .read<LocationService>()
                        .getCurrentPosition();
                    if (context.mounted) {
                      await context.read<RiskAnalysisService>().analyzeCurrentRisk(
                        lat: pos.latitude,
                        lng: pos.longitude,
                        dangerZoneService:
                            context.read<DangerZoneService>(),
                        predictiveService:
                            context.read<PredictiveDangerService>(),
                      );
                    }
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(alert,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }
}
