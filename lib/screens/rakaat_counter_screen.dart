import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/proximity_wakelock_service.dart';

enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
  free,
}

class PrayerConfig {
  final PrayerType type;
  final String name;
  final String subtitle;
  final int rakaat; // -1 for free
  final int totalSujood; // -1 for free
  final IconData icon;

  const PrayerConfig({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.rakaat,
    required this.totalSujood,
    required this.icon,
  });
}

class RakaatCounterScreen extends StatefulWidget {
  const RakaatCounterScreen({super.key});

  @override
  State<RakaatCounterScreen> createState() => _RakaatCounterScreenState();
}

class _RakaatCounterScreenState extends State<RakaatCounterScreen>
    with SingleTickerProviderStateMixin {
  static const List<PrayerConfig> prayers = [
    PrayerConfig(
      type: PrayerType.fajr,
      name: 'صلاة الصبح',
      subtitle: 'ركعتان • 4 سجدات',
      rakaat: 2,
      totalSujood: 4,
      icon: Icons.wb_twilight_rounded,
    ),
    PrayerConfig(
      type: PrayerType.dhuhr,
      name: 'صلاة الظهر',
      subtitle: '4 ركعات • 8 سجدات',
      rakaat: 4,
      totalSujood: 8,
      icon: Icons.wb_sunny_rounded,
    ),
    PrayerConfig(
      type: PrayerType.asr,
      name: 'صلاة العصر',
      subtitle: '4 ركعات • 8 سجدات',
      rakaat: 4,
      totalSujood: 8,
      icon: Icons.wb_cloudy_rounded,
    ),
    PrayerConfig(
      type: PrayerType.maghrib,
      name: 'صلاة المغرب',
      subtitle: '3 ركعات • 6 سجدات',
      rakaat: 3,
      totalSujood: 6,
      icon: Icons.nights_stay_rounded,
    ),
    PrayerConfig(
      type: PrayerType.isha,
      name: 'صلاة العشاء',
      subtitle: '4 ركعات • 8 سجدات',
      rakaat: 4,
      totalSujood: 8,
      icon: Icons.bedtime_rounded,
    ),
    PrayerConfig(
      type: PrayerType.free,
      name: 'عداد حر مفتوح',
      subtitle: 'للنوافل وصلاة الليل والتعقيبات',
      rakaat: -1,
      totalSujood: -1,
      icon: Icons.all_inclusive_rounded,
    ),
  ];

  PrayerConfig _selectedPrayer = prayers[0];

  // Counter States
  int _currentRakaa = 1;
  int _sujoodCountInRakaa = 0; // 0: none, 1: first sajdah, 2: second sajdah
  int _totalSujoodCompleted = 0;
  bool _isNear = false;
  bool _isPrayerFinished = false;

  // Settings
  bool _useProximitySensor = true;
  bool _keepScreenOn = true;
  bool _soundEnabled = true;

  // Stream & Audio Player
  StreamSubscription<int>? _proximitySubscription;
  final AudioPlayer _beepPlayer = AudioPlayer();

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _initScreenAndSensor();
  }

  Future<void> _initScreenAndSensor() async {
    if (_keepScreenOn) {
      await ProximityWakeLockService().enableKeepScreenOn();
    }
    try {
      await _beepPlayer.setVolume(1.0);
      await _beepPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
    } catch (_) {}
    _startProximityListener();
  }

  void _startProximityListener() {
    _proximitySubscription?.cancel();
    if (!_useProximitySensor) return;

    _proximitySubscription =
        ProximityWakeLockService().proximityStream.listen((event) {
      if (!mounted || _isPrayerFinished) return;
      _onProximityChanged(event);
    });
  }

  void _onProximityChanged(int event) {
    bool isClose = event > 0;
    if (isClose && !_isNear) {
      setState(() {
        _isNear = true;
      });
      _animController.forward();
    } else if (!isClose && _isNear) {
      setState(() {
        _isNear = false;
      });
      _animController.reverse();
      _registerSajdah(); // تم اكتمال سجدة واحدة عند الرفع
    }
  }

  void _registerSajdah() {
    if (_isPrayerFinished) return;

    setState(() {
      _totalSujoodCompleted++;

      if (_sujoodCountInRakaa == 0) {
        // السجدة الأولى
        _sujoodCountInRakaa = 1;
        HapticFeedback.lightImpact();
        _playSajdahSound();
      } else {
        // اكتملت السجدة الثانية -> تم احتساب ركعة كاملة
        if (_selectedPrayer.rakaat != -1 &&
            _currentRakaa >= _selectedPrayer.rakaat) {
          // اكتمال الصلاة المفروضة بالكامل
          _sujoodCountInRakaa = 2;
          _isPrayerFinished = true;
          HapticFeedback.heavyImpact();
          _playCompletionSound();
          _showCompletionDialog();
        } else {
          // اكتمال الركعة والانتقال للركعة التالية
          _sujoodCountInRakaa = 0;
          _currentRakaa++;
          HapticFeedback.mediumImpact();
          _playRakaaSound();
        }
      }
    });
  }

  Future<void> _playSajdahSound() async {
    if (!_soundEnabled) return;
    try {
      await _beepPlayer.stop();
      await _beepPlayer.play(BytesSource(RakaatAudioHelper.sajdahWav));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _playRakaaSound() async {
    if (!_soundEnabled) return;
    try {
      await _beepPlayer.stop();
      await _beepPlayer.play(BytesSource(RakaatAudioHelper.rakaaWav));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _playCompletionSound() async {
    if (!_soundEnabled) return;
    try {
      await _beepPlayer.stop();
      await _beepPlayer.play(BytesSource(RakaatAudioHelper.completeWav));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C2417),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 30),
            SizedBox(width: 10),
            Text(
              'تقبل الله طاعتكم 🤲',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'تمت ${_selectedPrayer.name} بفضل الله ورعايته.\nعدد الركعات: ${_selectedPrayer.rakaat}\nعدد السجدات: ${_selectedPrayer.totalSujood}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetCounter();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('إعادة البدء ↺', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _resetCounter() {
    setState(() {
      _currentRakaa = 1;
      _sujoodCountInRakaa = 0;
      _totalSujoodCompleted = 0;
      _isPrayerFinished = false;
      _isNear = false;
    });
    _animController.reset();
  }

  void _selectPrayer(PrayerConfig p) {
    setState(() {
      _selectedPrayer = p;
      _resetCounter();
    });
  }

  @override
  void dispose() {
    _proximitySubscription?.cancel();
    _animController.dispose();
    _beepPlayer.dispose();
    ProximityWakeLockService().disableKeepScreenOn();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF04140D) : const Color(0xFFF3F8F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'عداد الركع',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              tooltip: 'إعادة الضبط',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _resetCounter,
            ),
          ],
        ),
        body: SafeArea(
        child: Column(
          children: [
            // 1. Prayer Selection Horizontal List
            _buildPrayerSelector(),

            // 2. Expandable Settings Card
            _buildExpandableSettingsCard(),

            const Spacer(),

            // 3. Status Display (Rakaa & Sujood Cards)
            _buildCounterStatusDisplay(),

            const SizedBox(height: 16),

            // 4. Interactive Sajdah Target Circle (Tap or Proximity)
            _buildSajdahTargetCircle(),

            const Spacer(),

            // 5. Sensor Guidance / Proximity indicator
            _buildSensorGuideBadge(),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    ),
  );
}

  /// 1. Prayer Selector Chips
  Widget _buildPrayerSelector() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prayers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = prayers[index];
          final isSelected = _selectedPrayer.type == p.type;
          return ChoiceChip(
            avatar: Icon(
              p.icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF10B981),
            ),
            label: Text(
              p.name,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.white : null,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
              ),
            ),
            onSelected: (_) => _selectPrayer(p),
          );
        },
      ),
    );
  }

  bool _settingsExpanded = false;

  /// 2. Expandable Settings Card
  Widget _buildExpandableSettingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle button to expand/collapse settings
          InkWell(
            onTap: () => setState(() => _settingsExpanded = !_settingsExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  const Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _settingsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          // Expandable settings content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFF10B981), thickness: 0.3),
                  const SizedBox(height: 6),
                  _settingsToggleRow(
                    icon: Icons.sensors_rounded,
                    label: 'الحساس',
                    isActive: _useProximitySensor,
                    onChanged: (val) {
                      setState(() {
                        _useProximitySensor = val;
                        _startProximityListener();
                      });
                    },
                  ),
                  _settingsToggleRow(
                    icon: Icons.light_mode_rounded,
                    label: 'إبقاء الشاشة',
                    isActive: _keepScreenOn,
                    onChanged: (val) {
                      setState(() {
                        _keepScreenOn = val;
                        if (val) {
                          ProximityWakeLockService().enableKeepScreenOn();
                        } else {
                          ProximityWakeLockService().disableKeepScreenOn();
                        }
                      });
                    },
                  ),
                  _settingsToggleRow(
                    icon: Icons.volume_up_rounded,
                    label: 'التنبيه الصوتي',
                    isActive: _soundEnabled,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                    },
                  ),
                ],
              ),
            ),
            crossFadeState: _settingsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _settingsToggleRow({
    required IconData icon,
    required String label,
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? const Color(0xFF10B981) : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch(
              value: isActive,
              onChanged: onChanged,
              activeColor: const Color(0xFF10B981),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Counter Status Display
  Widget _buildCounterStatusDisplay() {
    final isFree = _selectedPrayer.rakaat == -1;

    String sajdahStatusText = '';
    if (_isPrayerFinished) {
      sajdahStatusText = 'تمت الصلاة بفضل الله';
    } else if (_sujoodCountInRakaa == 0) {
      sajdahStatusText = 'انتظار السجدة الأولى';
    } else if (_sujoodCountInRakaa == 1) {
      sajdahStatusText = 'تمت الأولى • انتظار الثانية';
    } else {
      sajdahStatusText = 'تمت السجدتان';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Rakaa Box
              Expanded(
                child: _buildMetricCard(
                  title: 'الركعة',
                  value: '$_currentRakaa',
                  subtitle: isFree ? 'مفتوح' : 'من ${_selectedPrayer.rakaat}',
                  color: const Color(0xFF0284C7),
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 10),
              // Sajdah Box
              Expanded(
                child: _buildMetricCard(
                  title: 'السجدة',
                  value: '$_sujoodCountInRakaa / 2',
                  subtitle: isFree
                      ? 'الكل: $_totalSujoodCompleted'
                      : '$_totalSujoodCompleted / ${_selectedPrayer.totalSujood}',
                  color: const Color(0xFF10B981),
                  icon: Icons.accessibility_new_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isPrayerFinished
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPrayerFinished
                    ? const Color(0xFF10B981)
                    : const Color(0xFF10B981).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPrayerFinished
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 15,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    sajdahStatusText,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Interactive Sajdah Target Circle (Tap or Proximity)
  Widget _buildSajdahTargetCircle() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _isPrayerFinished ? null : _registerSajdah,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPrayerFinished
                  ? [Colors.grey.shade600, Colors.grey.shade800]
                  : _isNear
                      ? [const Color(0xFF059669), const Color(0xFF047857)]
                      : [const Color(0xFF10B981), const Color(0xFF065F46)],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isNear ? const Color(0xFF059669) : const Color(0xFF10B981))
                    .withValues(alpha: _isNear ? 0.6 : 0.35),
                blurRadius: _isNear ? 30 : 16,
                spreadRadius: _isNear ? 4 : 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPrayerFinished
                        ? Icons.check_circle_outline_rounded
                        : _isNear
                            ? Icons.sensors_rounded
                            : Icons.touch_app_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPrayerFinished
                        ? 'اكتملت'
                        : _isNear
                            ? 'جاري السجود...'
                            : 'المس أو قرّب الهاتف',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  if (!_isPrayerFinished) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_sujoodCountInRakaa / 2',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 5. Sensor Guidance / Proximity indicator
  Widget _buildSensorGuideBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _useProximitySensor ? Icons.smartphone_rounded : Icons.touch_app_rounded,
            size: 16,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _useProximitySensor
                  ? 'الحساس يحتسب السجدة آلياً'
                  : 'الوضع اليدوي: انقر الدائرة لكل سجدة',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: Colors.grey,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مولد نغمات تنبيهات عداد الركع والسجود بتقنية توليد PCM WAV صوتية عالية النقاء
class RakaatAudioHelper {
  static Uint8List? _sajdahWav;
  static Uint8List? _rakaaWav;
  static Uint8List? _completeWav;

  /// نغمة احتساب السجدة الواحدة (نغمة نقية لطيفة 880 هرتز)
  static Uint8List get sajdahWav =>
      _sajdahWav ??= _generateMelody([
        const _AudioNote(880.0, 180), // A5
      ]);

  /// نغمة احتساب واكتمال الركعة (نغمة ثنائية متناغمة تصاعدية E5 -> A5)
  static Uint8List get rakaaWav =>
      _rakaaWav ??= _generateMelody([
        const _AudioNote(659.25, 120), // E5
        const _AudioNote(880.0, 220),  // A5
      ]);

  /// نغمة اكتمال الصلاة بالكامل (نغمة ثلاثية مباركة C5 -> E5 -> G5)
  static Uint8List get completeWav =>
      _completeWav ??= _generateMelody([
        const _AudioNote(523.25, 140), // C5
        const _AudioNote(659.25, 140), // E5
        const _AudioNote(783.99, 280), // G5
      ]);

  static Uint8List _generateMelody(List<_AudioNote> notes, {int sampleRate = 22050}) {
    final samples = <int>[];

    for (final note in notes) {
      final numSamples = (sampleRate * (note.durationMs / 1000.0)).round();
      final durationSec = note.durationMs / 1000.0;

      for (int i = 0; i < numSamples; i++) {
        final t = i / sampleRate;
        double envelope = 1.0;
        if (t < 0.01) {
          envelope = t / 0.01;
        } else {
          envelope = exp(-5.0 * (t - 0.01) / (durationSec - 0.01));
        }
        final sample = (sin(2 * pi * note.freq * t) * envelope * 24000).toInt();
        samples.add(sample);
      }
      final silenceSamples = (sampleRate * 0.015).round();
      for (int i = 0; i < silenceSamples; i++) {
        samples.add(0);
      }
    }

    final byteData = ByteData(44 + samples.length * 2);
    // RIFF chunk descriptor
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
    byteData.setUint8(8, 0x57);  // W
    byteData.setUint8(9, 0x41);  // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E

    // fmt sub-chunk
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little); // 16-bit

    // data sub-chunk
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, samples.length * 2, Endian.little);

    int offset = 44;
    for (final s in samples) {
      byteData.setInt16(offset, s.clamp(-32768, 32767), Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}

class _AudioNote {
  final double freq;
  final int durationMs;

  const _AudioNote(this.freq, this.durationMs);
}
