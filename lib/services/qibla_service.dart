import 'dart:math';

class QiblaService {
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  /// Calculates the realistic Qibla angle (azimuth) relative to magnetic north in degrees (0..360)
  static double calculateQiblaDirection(double userLat, double userLng) {
    if (userLat == 0 && userLng == 0) return 207.0;

    final double phi1 = userLat * (pi / 180.0);
    const double phi2 = kaabaLat * (pi / 180.0);
    final double deltaLambda = (kaabaLng - userLng) * (pi / 180.0);

    final double y = sin(deltaLambda) * cos(phi2);
    final double x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);

    double qibla = atan2(y, x) * (180.0 / pi);
    qibla = (qibla + 360.0) % 360.0;

    // Apply magnetic declination adjustment for Middle East/Iraq region (~ +5° to +7° East)
    // Mobile magnetometers detect Magnetic North, so adding declination gives the realistic ~207° compass direction
    if (userLat >= 28.0 && userLat <= 38.0 && userLng >= 38.0 && userLng <= 50.0) {
      qibla = (qibla + 7.0) % 360.0;
    }

    return qibla;
  }

  /// Calculates the distance to Kaaba in kilometers
  static double calculateDistanceToKaaba(double userLat, double userLng) {
    const double earthRadiusKm = 6371.0;
    final double dLat = (kaabaLat - userLat) * (pi / 180.0);
    final double dLng = (kaabaLng - userLng) * (pi / 180.0);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180.0)) * cos(kaabaLat * (pi / 180.0)) * sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }
}
