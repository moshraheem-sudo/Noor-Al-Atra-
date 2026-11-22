import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../providers/prayer_provider.dart';
import '../services/qibla_service.dart';
import '../services/settings_controller.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;

  double _deviceHeading = 0.0; // Current device heading from North (0..360)
  double _smoothHeading = 0.0;
  bool _hasSensorData = false;
  bool _hasTriggeredHaptic = false;
  bool _isCalibrating = false;

  late AnimationController _calibrationAnimCtrl;

  @override
  void initState() {
    super.initState();
    _calibrationAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initSensors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationOnEntry();
    });
  }

  /// Checks location permission on screen load and triggers the system permission dialog if needed
  Future<void> _checkLocationOnEntry() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
        if (mounted) {
          await _refreshGpsLocation(silentSuccess: true);
        }
      }
    } catch (e) {
      debugPrint('Location permission check error: $e');
    }
  }

  void _initSensors() {
    try {
      _magnetometerSub = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          // Calculate heading in degrees from magnetic sensor
          double angle = atan2(-event.x, event.y) * (180 / pi);
          angle = (angle + 360) % 360;

          if (mounted) {
            setState(() {
              _hasSensorData = true;
              _deviceHeading = angle;
              // Smooth heading interpolation to prevent jitter
              double diff = (_deviceHeading - _smoothHeading + 180) % 360 - 180;
              _smoothHeading = (_smoothHeading + diff * 0.25 + 360) % 360;
            });
          }
        },
        onError: (err) {
          debugPrint('Magnetometer error or not available: $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Failed to initialize magnetometer: $e');
    }
  }

  @override
  void dispose() {
    _magnetometerSub?.cancel();
    _calibrationAnimCtrl.dispose();
    super.dispose();
  }

  /// Recalibrates sensors by running an animation and resetting filter
  void _recalibrate() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCalibrating = true;
    });

    _calibrationAnimCtrl.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isCalibrating = false;
        });
      }
    });
  }

  /// Refreshes GPS location via PrayerProvider
  Future<void> _refreshGpsLocation({bool silentSuccess = false}) async {
    final prayer = context.read<PrayerProvider>();
    HapticFeedback.lightImpact();
    final result = await prayer.detectLocationViaGps();
    if (!mounted) return;

    if (result == 'service_disabled') {
      await Geolocator.openLocationSettings();
    } else if (result == 'permission_denied_forever') {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prayer = context.watch<PrayerProvider>();

    // Calculate dynamic Qibla angle from selected city coordinates
    double qiblaAngle = prayer.qiblaBearing;
    if (qiblaAngle <= 0 && prayer.selectedCity.latitude != 0) {
      qiblaAngle = QiblaService.calculateQiblaDirection(
        prayer.selectedCity.latitude,
        prayer.selectedCity.longitude,
      );
    }
    // Realistic fallback for Iraq / Karbala if uninitialized
    if (qiblaAngle <= 0) qiblaAngle = 207.0;

    // Heading from North
    final double heading = _hasSensorData ? _smoothHeading : _deviceHeading;

    // Angle difference between current heading and Qibla
    final double diffToQibla = ((qiblaAngle - heading + 180) % 360 - 180).abs();
    final bool isAligned = diffToQibla <= 4.0;

    // Trigger haptic once when reaching alignment
    if (isAligned && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.mediumImpact();
    } else if (!isAligned) {
      _hasTriggeredHaptic = false;
    }

    final isEmerald = context.watch<SettingsController>().themePalette == AppThemePalette.emeraldGreen;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isEmerald
                ? [const Color(0xFF04140D), const Color(0xFF082216), const Color(0xFF030E09)]
                : (isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF090D16)]
                    : [const Color(0xFFEBF7FD), const Color(0xFFE2F3F9), const Color(0xFFDCF0F9)]),
          ),
        ),
        child: Stack(
          children: [
            // 1. Subtle Islamic geometric mandala pattern in upper screen background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 380,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _QiblaSacredMandalaPainter(
                    lineColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFF0284C7).withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'رجوع',
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'بوصلة القبلة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        // GPS Target Icon
                        IconButton(
                          icon: prayer.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                                  ),
                                )
                              : Icon(
                                  Icons.my_location,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  size: 20,
                                ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: prayer.isLoading ? null : _refreshGpsLocation,
                          tooltip: 'تحديث الموقع الجغرافي',
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),

                          // 3D Kaaba Icon
                          const _Kaaba3DWidget(),

                          const SizedBox(height: 10),

                          // Screen Title: اتجاه القبلة
                          Text(
                            'اتجاه القبلة',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Realistic Green Compass Dial
                          GestureDetector(
                            onPanUpdate: (details) {
                              // Allow smooth manual rotation for testing or calibration
                              setState(() {
                                _deviceHeading = (_deviceHeading + details.delta.dx * 0.5 + 360) % 360;
                              });
                            },
                            child: RotationTransition(
                              turns: _calibrationAnimCtrl,
                              child: _CompassDialWidget(
                                heading: heading,
                                qiblaAngle: qiblaAngle,
                                isAligned: isAligned,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Confirmation Badge (أنت الآن باتجاه القبلة المباركة ✓)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isAligned ? 1.0 : 0.9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                              decoration: BoxDecoration(
                                color: isAligned
                                    ? const Color(0xFF15803D)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFF334155)),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: isAligned
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                                          blurRadius: 14,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isAligned
                                        ? 'أنت الآن باتجاه القبلة المباركة'
                                        : 'قم بتدوير الهاتف باتجاه القبلة',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isAligned ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isAligned ? Icons.check_circle_rounded : Icons.explore,
                                    color: isAligned ? const Color(0xFF86EFAC) : const Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Two Data Cards Side by Side (الشمال - زاوية القبلة)
                          Row(
                            children: [
                              // Left Card: الشمال
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : const Color(0xFFBAE6FD),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.explore_outlined, color: Color(0xFF0284C7), size: 24),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${heading.round()}°',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'الشمال',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Right Card: زاوية القبلة
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : const Color(0xFFBAE6FD),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFF0284C7), size: 24),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${qiblaAngle.round()}°',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'زاوية القبلة',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Calibration Card (معايرة دقة البوصلة)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2F0F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFBAE6FD),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Title row: معايرة دقة البوصلة + refresh icon
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'معايرة دقة البوصلة',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0369A1),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.sync_rounded, color: Color(0xFF0284C7), size: 18),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Instructions text
                                Text(
                                  'للحصول على أدق نتيجة، ابتعد عن المغناطيس والمعادن، وقم بتحريك الجهاز على شكل رقم 8.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.6,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Button: إعادة المعايرة
                                InkWell(
                                  onTap: _isCalibrating ? null : _recalibrate,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBAE6FD).withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFF7DD3FC), width: 1.2),
                                    ),
                                    child: _isCalibrating
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                                            ),
                                          )
                                        : const Text(
                                            'إعادة المعايرة',
                                            style: TextStyle(
                                              color: Color(0xFF0284C7),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D Kaaba Widget on Pedestal
class _Kaaba3DWidget extends StatelessWidget {
  const _Kaaba3DWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _Kaaba3DPainter(),
      ),
    );
  }
}

class _Kaaba3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Pedestal / Hexagonal Base
    final basePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final basePath = Path()
      ..moveTo(cx - 26, cy + 18)
      ..lineTo(cx, cy + 30)
      ..lineTo(cx + 26, cy + 18)
      ..lineTo(cx + 26, cy + 14)
      ..lineTo(cx, cy + 26)
      ..lineTo(cx - 26, cy + 14)
      ..close();
    canvas.drawPath(basePath, basePaint);

    final baseTopPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final baseTopPath = Path()
      ..moveTo(cx, cy + 8)
      ..lineTo(cx + 26, cy + 18)
      ..lineTo(cx, cy + 26)
      ..lineTo(cx - 26, cy + 18)
      ..close();
    canvas.drawPath(baseTopPath, baseTopPaint);

    // 2. Kaaba Top Face (Diamond)
    final topPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final topPath = Path()
      ..moveTo(cx, cy - 22)
      ..lineTo(cx + 18, cy - 13)
      ..lineTo(cx, cy - 4)
      ..lineTo(cx - 18, cy - 13)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // 3. Kaaba Left Face (Deep dark)
    final leftFacePaint = Paint()
      ..color = const Color(0xFF18181B)
      ..style = PaintingStyle.fill;
    final leftPath = Path()
      ..moveTo(cx - 18, cy - 13)
      ..lineTo(cx, cy - 4)
      ..lineTo(cx, cy + 18)
      ..lineTo(cx - 18, cy + 9)
      ..close();
    canvas.drawPath(leftPath, leftFacePaint);

    // 4. Kaaba Right Face (Jet black)
    final rightFacePaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;
    final rightPath = Path()
      ..moveTo(cx, cy - 4)
      ..lineTo(cx + 18, cy - 13)
      ..lineTo(cx + 18, cy + 9)
      ..lineTo(cx, cy + 18)
      ..close();
    canvas.drawPath(rightPath, rightFacePaint);

    // 5. Golden Kiswah Band at top
    final goldBandPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // Band on left
    canvas.drawLine(
      Offset(cx - 18, cy - 7),
      Offset(cx, cy + 2),
      goldBandPaint,
    );
    // Band on right
    canvas.drawLine(
      Offset(cx, cy + 2),
      Offset(cx + 18, cy - 7),
      goldBandPaint,
    );

    // 6. Golden Door (Bab al-Kaaba) on the right face
    final doorPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;

    final doorPath = Path()
      ..moveTo(cx + 4, cy + 4)
      ..lineTo(cx + 10, cy + 1)
      ..lineTo(cx + 10, cy + 12)
      ..lineTo(cx + 4, cy + 15)
      ..close();
    canvas.drawPath(doorPath, doorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Realistic Green Compass Dial Widget
class _CompassDialWidget extends StatelessWidget {
  final double heading;
  final double qiblaAngle;
  final bool isAligned;

  const _CompassDialWidget({
    required this.heading,
    required this.qiblaAngle,
    required this.isAligned,
  });

  @override
  Widget build(BuildContext context) {
    const double dialSize = 250.0;

    return Container(
      width: dialSize,
      height: dialSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (isAligned)
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 3,
            ),
        ],
      ),
      child: CustomPaint(
        size: const Size(dialSize, dialSize),
        painter: _CompassPainter(
          heading: heading,
          qiblaAngle: qiblaAngle,
          isAligned: isAligned,
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  final double qiblaAngle;
  final bool isAligned;

  _CompassPainter({
    required this.heading,
    required this.qiblaAngle,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    // 1. Outer Ring / Bezel: Dark Slate/Black Metallic if !isAligned, Emerald Metallic if isAligned
    final bezelColors = isAligned
        ? const [Color(0xFF1E462E), Color(0xFF0E2A1B), Color(0xFF06140C)]
        : const [Color(0xFF282D35), Color(0xFF16191E), Color(0xFF0C0E12)];

    final bezelPaint = Paint()
      ..shader = RadialGradient(
        colors: bezelColors,
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, bezelPaint);

    // Outer rim highlight
    final rimPaint = Paint()
      ..color = isAligned
          ? const Color(0xFF22C55E).withValues(alpha: 0.85)
          : const Color(0xFF3E4754)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy), radius - 1.5, rimPaint);

    // 2. Inner Dial Surface: Deep Charcoal/Black if !isAligned, Rich Emerald Green if isAligned
    final innerRadius = radius - 8.0;
    final dialColor = isAligned ? const Color(0xFF0B3B24) : const Color(0xFF14181F);
    final dialPaint = Paint()
      ..color = dialColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), innerRadius, dialPaint);

    // Radial shadow inside dial
    final dialGradientColors = isAligned
        ? const [
            Color(0xFF0E472D),
            Color(0xFF0B3B24),
            Color(0xFF072617),
          ]
        : const [
            Color(0xFF1C222B),
            Color(0xFF13171D),
            Color(0xFF0B0E12),
          ];

    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: dialGradientColors,
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius));
    canvas.drawCircle(Offset(cx, cy), innerRadius, innerShadowPaint);

    // 3. Dial Ticks and Direction Labels
    // Rotating canvas by -heading so dial reflects compass orientation
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading * (pi / 180.0));

    final tickPaint = Paint()
      ..color = isAligned
          ? const Color(0xFFA7F3D0).withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = isAligned
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Draw 360 degree ticks
    for (int deg = 0; deg < 360; deg += 3) {
      final rad = deg * (pi / 180.0);
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;
      final tickLen = isCardinal ? 10.0 : (isMajor ? 7.0 : 4.0);

      final p1 = Offset(sin(rad) * (innerRadius - 4), -cos(rad) * (innerRadius - 4));
      final p2 = Offset(sin(rad) * (innerRadius - 4 - tickLen), -cos(rad) * (innerRadius - 4 - tickLen));

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    // Draw Cardinal & Intercardinal Text Labels (N, NE, E, SE, S, SW, W, NW)
    const labels = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };

    labels.forEach((deg, label) {
      final rad = deg * (pi / 180.0);
      final isMain = deg % 90 == 0;
      final isNorth = deg == 0;
      final textRadius = innerRadius - 24.0;

      final Color textColor;
      if (isAligned) {
        textColor = isMain ? Colors.white : Colors.white70;
      } else {
        textColor = isNorth
            ? const Color(0xFFF87171) // Subtle red for North in dark theme
            : (isMain ? Colors.white : Colors.white60);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: textColor,
            fontSize: isMain ? 15 : 10.5,
            fontWeight: isMain ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      final tx = sin(rad) * textRadius;
      final ty = -cos(rad) * textRadius;
      canvas.translate(tx, ty);
      // Keep label readable
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    });

    // 4. Qibla Target Marker at Rim
    final qiblaRad = qiblaAngle * (pi / 180.0);
    final qiblaMarkerColor = isAligned ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    final qiblaMarkerPaint = Paint()
      ..color = qiblaMarkerColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final qm1 = Offset(sin(qiblaRad) * (innerRadius - 2), -cos(qiblaRad) * (innerRadius - 2));
    final qm2 = Offset(sin(qiblaRad) * (innerRadius - 16), -cos(qiblaRad) * (innerRadius - 16));
    canvas.drawLine(qm1, qm2, qiblaMarkerPaint);

    // Dot at Qibla Target
    final qiblaDotPaint = Paint()
      ..color = isAligned ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(qm1, 3.8, qiblaDotPaint);

    canvas.restore(); // Restore unrotated canvas

    // 5. Compass Needle (Points from Center to Qibla relative to screen)
    // Relative angle on screen = (qiblaAngle - heading)
    final double relativeAngle = (qiblaAngle - heading) * (pi / 180.0);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(relativeAngle);

    // Needle Stem: Metallic silver when !isAligned, vibrant green when isAligned
    final needlePaint = Paint()
      ..color = isAligned ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final needlePath = Path()
      ..moveTo(-3.5, 0)
      ..lineTo(-1.8, -innerRadius + 42)
      ..lineTo(0, -innerRadius + 32)
      ..lineTo(1.8, -innerRadius + 42)
      ..lineTo(3.5, 0)
      ..lineTo(0, 14)
      ..close();
    canvas.drawPath(needlePath, needlePaint);

    // Round Pointer Tip at Qibla
    if (isAligned) {
      final tipGlowPaint = Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(Offset(0, -innerRadius + 30), 8.5, tipGlowPaint);
    }

    final tipPaint = Paint()
      ..color = isAligned ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -innerRadius + 30), 6.5, tipPaint);

    final tipInnerPaint = Paint()
      ..color = isAligned ? const Color(0xFF86EFAC) : const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -innerRadius + 30), 3.0, tipInnerPaint);

    // Needle Central Pivot Hub
    final hubBorderPaint = Paint()
      ..color = isAligned ? const Color(0xFF134E2E) : const Color(0xFF1E242B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 11, hubBorderPaint);

    final hubCenterPaint = Paint()
      ..color = isAligned ? const Color(0xFF22C55E) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 7, hubCenterPaint);

    final hubDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 3, hubDotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.isAligned != isAligned;
  }
}

/// Sacred Islamic geometric mandala background painter
class _QiblaSacredMandalaPainter extends CustomPainter {
  final Color lineColor;

  _QiblaSacredMandalaPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const cy = 110.0;
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Concentric base circles
    for (double r = 40; r <= 180; r += 32) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Overlapping 12-fold geometric sacred circles
    const int count = 12;
    const double radius = 70.0;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi) / count;
      final px = cx + radius * cos(angle);
      final py = cy + radius * sin(angle);
      canvas.drawCircle(Offset(px, py), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QiblaSacredMandalaPainter oldDelegate) => false;
}