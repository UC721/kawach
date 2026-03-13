import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/danger_zone_model.dart';

Future<List<LatLng>> calculateSafeRouteWeb({
  required LatLng origin,
  required LatLng destination,
  required List<DangerZoneModel> dangerZones,
}) async {
  final completer = Completer<List<LatLng>>();

  try {
    js.context.callMethod('eval', ["""
      (function() {
        var directionsService = new google.maps.DirectionsService();
        var request = {
          origin: { lat: ${origin.latitude}, lng: ${origin.longitude} },
          destination: { lat: ${destination.latitude}, lng: ${destination.longitude} },
          travelMode: 'WALKING',
          provideRouteAlternatives: true
        };

        directionsService.route(request, function(result, status) {
          if (status == 'OK') {
            var routes = result.routes;
            var safestPoints = [];
            var minScore = Infinity;

            for (var i = 0; i < routes.length; i++) {
              var route = routes[i];
              var points = route.overview_path.map(p => ({ lat: p.lat(), lng: p.lng() }));
              
              // Simplistic danger scoring in JS side (mirrors Dart logic)
              var score = 0;
              for (var j = 0; j < points.length; j += 3) {
                var p = points[j];
                ${dangerZones.map((z) => """
                  (function() {
                    var dLat = p.lat - ${z.lat};
                    var dLng = p.lng - ${z.lng};
                    var dist = Math.sqrt(dLat*dLat + dLng*dLng) * 111111;
                    if (dist < 400) {
                      var weight = ${z.severity == DangerSeverity.critical ? 500 : z.severity == DangerSeverity.high ? 200 : 50};
                      score += weight * Math.pow(1 - (dist / 400), 2);
                    }
                  })();
                """).join('\n')}
              }

              if (score < minScore) {
                minScore = score;
                safestPoints = points;
              }
            }
            window.dartSafeRouteResult = safestPoints;
            window.dartSafeRouteStatus = 'SUCCESS';
          } else {
            window.dartSafeRouteStatus = 'ERROR: ' + status;
          }
        });
      })();
    """]);

    // Poll for result
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final status = js.context['dartSafeRouteStatus'];
      if (status == 'SUCCESS') {
        timer.cancel();
        final List<dynamic> points = js.context['dartSafeRouteResult'];
        final result = points.map((p) => LatLng(p['lat'], p['lng'])).toList();
        completer.complete(result);
      } else if (status != null && status.toString().startsWith('ERROR')) {
        timer.cancel();
        completer.complete([]);
      }
      
      if (timer.tick > 25) { // 5 second timeout
        timer.cancel();
        completer.complete([]);
      }
    });

  } catch (e) {
    print('JS Interop Error: \$e');
    completer.complete([]);
  }

  return completer.future;
}
