import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/prayer_provider.dart';
import '../services/settings_controller.dart';
import '../services/muezzin_download_service.dart';
import '../services/adhan_scheduler_service.dart';
import '../services/proximity_wakelock_service.dart';
import '../services/app_notification_service.dart';
import 'prayer_times_screen.dart';

/// Dynamic Color Palette Resolver for Prayer Settings Screen
class _PrayerSettingsColors {
  final Color bg;
  final Color appBarBg;
  final Color appBarFg;
  final Color cardBg;
  final Color cardBorder;
  final Color iconBoxBg;
  final Color accent;
  final Color goldAccent;
  final Color textTitle;
  final Color textSub;
  final Color innerCardBg;
  final Color innerCardBorder;
  final Color selectedTileBg;
  final Color selectedTileBorder;
  final Color buttonBg;
  final Color buttonFg;
  final Color switchActiveTrack;
  final Color switchActiveThumb;
  final Color switchInactiveTrack;
  final Color switchInactiveThumb;
  final Color divider;
  final Color arrowColor;

  const _PrayerSettingsColors({
    required this.bg,
    required this.appBarBg,
    required this.appBarFg,
    required this.cardBg,
    required this.cardBorder,
    required this.iconBoxBg,
    required this.accent,
    required this.goldAccent,
    required this.textTitle,
    required this.textSub,
    required this.innerCardBg,
    required this.innerCardBorder,
    required this.selectedTileBg,
    required this.selectedTileBorder,
    required this.buttonBg,
    required this.buttonFg,
    required this.switchActiveTrack,
    required this.switchActiveThumb,
    required this.switchInactiveTrack,
    required this.switchInactiveThumb,
    required this.divider,
    required this.arrowColor,
  });

  factory _PrayerSettingsColors.fromPalette(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.icyBlue:
        return const _PrayerSettingsColors(
          bg: Color(0xFFEAF4FB),
          appBarBg: Color(0xFFEAF4FB),
          appBarFg: Color(0xFF1B3A57),
          cardBg: Colors.white,
          cardBorder: Color(0xFFD0E6F7),
          iconBoxBg: Color(0xFFE0F2FE),
          accent: Color(0xFF0284C7),
          goldAccent: Color(0xFFD97706),
          textTitle: Color(0xFF1B3A57),
          textSub: Color(0xFF64748B),
          innerCardBg: Color(0xFFF8FAFC),
          innerCardBorder: Color(0xFFE2E8F0),
          selectedTileBg: Color(0xFFEFF6FF),
          selectedTileBorder: Color(0xFF3B82F6),
          buttonBg: Color(0xFFE0F2FE),
          buttonFg: Color(0xFF0284C7),
          switchActiveTrack: Color(0xFF90CAF9),
          switchActiveThumb: Color(0xFF1B3A57),
          switchInactiveTrack: Color(0xFFE2E8F0),
          switchInactiveThumb: Colors.white,
          divider: Color(0xFFE2E8F0),
          arrowColor: Color(0xFF64748B),
        );
      case AppThemePalette.royalDark:
        return const _PrayerSettingsColors(
          bg: Color(0xFF0B1120),
          appBarBg: Color(0xFF0B1120),
          appBarFg: Colors.white,
          cardBg: Color(0xFF1E293B),
          cardBorder: Color(0xFF334155),
          iconBoxBg: Color(0xFF0F233C),
          accent: Color(0xFF38BDF8),
          goldAccent: Color(0xFFFBBF24),
          textTitle: Colors.white,
          textSub: Color(0xFF94A3B8),
          innerCardBg: Color(0xFF162235),
          innerCardBorder: Color(0xFF334155),
          selectedTileBg: Color(0xFF1E3A5F),
          selectedTileBorder: Color(0xFF38BDF8),
          buttonBg: Color(0xFF1E3A5F),
          buttonFg: Color(0xFF38BDF8),
          switchActiveTrack: Color(0xFF38BDF8),
          switchActiveThumb: Colors.white,
          switchInactiveTrack: Color(0xFF334155),
          switchInactiveThumb: Colors.white70,
          divider: Color(0xFF334155),
          arrowColor: Colors.white54,
        );
      case AppThemePalette.emeraldGreen:
        return const _PrayerSettingsColors(
          bg: Color(0xFF04140D),
          appBarBg: Color(0xFF04140D),
          appBarFg: Colors.white,
          cardBg: Color(0xFF082216),
          cardBorder: Color(0xFF14452F),
          iconBoxBg: Color(0xFF133621),
          accent: Color(0xFF25D366),
          goldAccent: Color(0xFFFBBF24),
          textTitle: Colors.white,
          textSub: Color(0xFFA7C4B5),
          innerCardBg: Color(0xFF0B1E13),
          innerCardBorder: Color(0xFF1B4D2B),
          selectedTileBg: Color(0xFF0F3B26),
          selectedTileBorder: Color(0xFF25D366),
          buttonBg: Color(0xFF133621),
          buttonFg: Color(0xFF25D366),
          switchActiveTrack: Color(0xFFFBBF24),
          switchActiveThumb: Color(0xFF04140D),
          switchInactiveTrack: Color(0xFF1E3D2F),
          switchInactiveThumb: Colors.white70,
          divider: Color(0xFF1B4D2B),
          arrowColor: Colors.white54,
        );
    }
  }
}

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> with WidgetsBindingObserver {
  bool _isBatteryIgnored = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBatteryStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBatteryStatus();
    }
  }

  Future<void> _checkBatteryStatus() async {
    final ignored = await ProximityWakeLockService().isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _isBatteryIgnored = ignored;
      });
    }
  }

  // Accordion expanded states (Card 1 expanded by default)
  final Map<int, bool> _expandedState = {
    0: true,  // الموقع والمدينة الحالية
    1: false, // إعدادات الحساب الجعفري والمواقيت الشرعية
    2: false, // التعديل اليدوي لمواقيت الصلاة
    3: false, // إظهار وإخفاء المواقيت
    4: false, // تنبيهات أوقات الصلاة والأذان
    5: false, // صوت الأذان
  };

  void _toggleAccordion(int index) {
    setState(() {
      _expandedState[index] = !(_expandedState[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final settings = context.watch<SettingsController>();
    final colors = _PrayerSettingsColors.fromPalette(settings.themePalette);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: _buildAppBar(context, colors),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 90),
          children: [
            // 1️⃣ Card 1: الموقع والمدينة الحالية
            _buildAccordionCard(
              index: 0,
              icon: Icons.location_on_rounded,
              title: 'الموقع والمدينة الحالية',
              subtitle: 'المدينة: ${prayer.selectedCity.displayName} • محفوظة وثابتة في النظام',
              content: _buildLocationCardContent(context, prayer, colors),
              colors: colors,
            ),
            const SizedBox(height: 12),

            // 2️⃣ Card 2: إعدادات الحساب الجعفري والمواقيت الشرعية
            _buildAccordionCard(
              index: 1,
              icon: Icons.tune_rounded,
              title: 'إعدادات الحساب الجعفري والمواقيت الشرعية',
              subtitle: 'طرق الحساب وحساب منتصف الليل الشرعي',
              content: _buildCalculationMethodsContent(settings, colors),
              colors: colors,
            ),
            const SizedBox(height: 12),

            // 3️⃣ Card 3: التعديل اليدوي لمواقيت الصلاة
            _buildAccordionCard(
              index: 2,
              icon: Icons.access_time_rounded,
              title: 'التعديل اليدوي لمواقيت الصلاة',
              subtitle: 'تقديم أو تأخير دقائق لكل صلاة بشكل منفرد',
              content: _buildManualOffsetsContent(settings, prayer, colors),
              colors: colors,
            ),
            const SizedBox(height: 12),

            // 4️⃣ Card 4: إظهار وإخفاء المواقيت
            _buildAccordionCard(
              index: 3,
              icon: Icons.visibility_rounded,
              title: 'إظهار وإخفاء المواقيت',
              subtitle: 'تخصيص البطاقات الظاهرة في الواجهة',
              content: _buildVisibilityContent(settings, colors),
              colors: colors,
            ),
            const SizedBox(height: 12),

            // 5️⃣ Card 5: تنبيهات أوقات الصلاة والأذان
            _buildAccordionCard(
              index: 4,
              icon: Icons.notifications_active_rounded,
              title: 'تنبيهات أوقات الصلاة والأذان',
              subtitle: 'إعداد تنبيهات الأذان والأصوات',
              content: _buildAlertsContent(context, settings, colors),
              colors: colors,
            ),
            const SizedBox(height: 12),

            // 6️⃣ Card 6: صوت الأذان ومصادر الصوت المعتمدة
            _buildAccordionCard(
              index: 5,
              icon: Icons.record_voice_over_rounded,
              title: 'صوت الأذان',
              subtitle: '${settings.selectedMuezzin} • يدعم تخصيص كل صلاة',
              content: _buildMuezzinContent(settings, colors),
              colors: colors,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- AppBar ---
  PreferredSizeWidget _buildAppBar(BuildContext context, _PrayerSettingsColors colors) {
    return AppBar(
      backgroundColor: colors.appBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 2,
      leading: IconButton(
        icon: Icon(Icons.arrow_forward_rounded, color: colors.appBarFg, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        tooltip: 'رجوع',
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'إعدادات المواقيت',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colors.appBarFg,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: colors.accent, size: 20),
          onPressed: () {},
        ),
      ],
    );
  }

  // --- Accordion Card Wrapper ---
  Widget _buildAccordionCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
    required _PrayerSettingsColors colors,
  }) {
    final isExpanded = _expandedState[index] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? colors.accent.withValues(alpha: 0.6) : colors.cardBorder,
          width: isExpanded ? 1.2 : 1.0,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleAccordion(index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.iconBoxBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: colors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: colors.textTitle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: colors.textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? colors.accent : colors.arrowColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            Divider(color: colors.divider.withValues(alpha: 0.7), height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 1️⃣ Card 1: الموقع والمدينة الحالية Content
  // ==========================================
  Widget _buildLocationCardContent(
    BuildContext context,
    PrayerProvider prayer,
    _PrayerSettingsColors colors,
  ) {
    final city = prayer.selectedCity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inner City Card
        InkWell(
          onTap: () => _showCityPicker(context, prayer, colors),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.innerCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.innerCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🕌 ', style: TextStyle(fontSize: 18)),
                        Text(
                          city.displayName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colors.textTitle,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.iconBoxBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.innerCardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: colors.accent, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'موقع ثابت',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${city.nameAr} - ${city.countryAr} • ${city.latitude.toStringAsFixed(4)}°N, ${city.longitude.toStringAsFixed(4)}°E (GMT +3)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    color: colors.textSub,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: colors.accent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'محفوظة في مجلدات التطبيق • جاهزة للعمل بدون إنترنت (Offline)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // GPS Location Button
        ElevatedButton(
          onPressed: () async {
            final err = await prayer.detectLocationViaGps();
            if (!context.mounted) return;
            if (err == 'service_disabled') {
              await Geolocator.openLocationSettings();
            } else if (err == 'permission_denied_forever') {
              await Geolocator.openAppSettings();
            } else if (err != null && err != 'permission_denied') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err, style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: Colors.red[900],
                ),
              );
            } else if (err == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تحديد موقعك بدقة: ${prayer.selectedCity.displayName}', style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: const Color(0xFF166534),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.buttonBg,
            foregroundColor: colors.buttonFg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.my_location_rounded, color: colors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'تحديد الموقع الحالي عبر GPS 🎯',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // City Picker (Delegates to official GPS Saved Cities Picker)
  void _showCityPicker(BuildContext context, PrayerProvider prayer, _PrayerSettingsColors colors) {
    PrayerTimesScreen.showCityPicker(context);
  }

  // ==========================================
  // 2️⃣ Card 2: إعدادات الحساب الجعفري والمواقيت الشرعية
  // ==========================================
  Widget _buildCalculationMethodsContent(SettingsController settings, _PrayerSettingsColors colors) {
    final prayer = context.read<PrayerProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة حساب وقت الفجر والمغرب:',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 10),

        // Method 1: Kafeel / Sistani
        _buildMethodRadioTile(
          title: 'جعفري (مركز الكفيل / السيد السيستاني)',
          subtitle: 'زاوية الفجر 18.0° • زاوية المغرب 4.0°\n(المعتمد في العراق)',
          value: 'kafeel',
          groupValue: settings.calculationMethod,
          onChanged: (val) async {
            await settings.setCalculationMethod(val);
            await prayer.fetchPrayerTimes();
          },
          colors: colors,
        ),
        const SizedBox(height: 8),

        // Method 2: Tehran
        _buildMethodRadioTile(
          title: 'جعفري (جامعة طهران)',
          subtitle: 'زاوية الفجر 17.7° • زاوية المغرب 4.5°',
          value: 'tehran',
          groupValue: settings.calculationMethod,
          onChanged: (val) async {
            await settings.setCalculationMethod(val);
            await prayer.fetchPrayerTimes();
          },
          colors: colors,
        ),
        const SizedBox(height: 8),

        // Method 3: Lewa Qom
        _buildMethodRadioTile(
          title: 'جعفري (معهد ليفا، قم)',
          subtitle: 'زاوية الفجر 16.0° • زاوية المغرب 4.0°',
          value: 'lewa_qom',
          groupValue: settings.calculationMethod,
          onChanged: (val) async {
            await settings.setCalculationMethod(val);
            await prayer.fetchPrayerTimes();
          },
          colors: colors,
        ),

        const SizedBox(height: 18),
        Text(
          'طريقة حساب منتصف الليل الشرعي:',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 10),

        // Midnight 1: To Fajr
        _buildMethodRadioTile(
          title: 'من الغروب إلى الفجر',
          subtitle: 'المعتمد فقهياً في المذهب الجعفري (المنتصف بين الغروب وطلوع الفجر)',
          value: 'fajr',
          groupValue: settings.midnightMethod,
          onChanged: (val) async {
            await settings.setMidnightMethod(val);
            await prayer.fetchPrayerTimes();
          },
          colors: colors,
        ),
        const SizedBox(height: 8),

        // Midnight 2: To Sunrise
        _buildMethodRadioTile(
          title: 'من الغروب إلى الشروق',
          subtitle: 'المنتصف الفلكي العام (المنتصف بين غروب الشمس وشروقها)',
          value: 'sunrise',
          groupValue: settings.midnightMethod,
          onChanged: (val) async {
            await settings.setMidnightMethod(val);
            await prayer.fetchPrayerTimes();
          },
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildMethodRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
    required _PrayerSettingsColors colors,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.selectedTileBg : colors.innerCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.selectedTileBorder : colors.innerCardBorder,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: colors.accent,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? colors.accent : colors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      color: colors.textSub,
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

  // ==========================================
  // 3️⃣ Card 3: التعديل اليدوي لمواقيت الصلاة
  // ==========================================
  Widget _buildManualOffsetsContent(
    SettingsController settings,
    PrayerProvider prayer,
    _PrayerSettingsColors colors,
  ) {
    final times = prayer.prayerTimes;

    final prayerData = [
      {'key': 'fajr', 'name': 'صلاة الفجر', 'icon': '🌅', 'time': times?.fajr ?? '04:33'},
      {'key': 'sunrise', 'name': 'الشروق', 'icon': '☀️', 'time': times?.sunrise ?? '05:55'},
      {'key': 'dhuhr', 'name': 'صلاة الظهر', 'icon': '🕐', 'time': times?.dhuhr ?? '11:56'},
      {'key': 'asr', 'name': 'صلاة العصر', 'icon': '🌤️', 'time': times?.asr ?? '15:20'},
      {'key': 'sunset', 'name': 'الغروب', 'icon': '🌇', 'time': times?.sunset ?? '17:55'},
      {'key': 'maghrib', 'name': 'صلاة المغرب', 'icon': '🌙', 'time': times?.maghrib ?? '18:10'},
      {'key': 'isha', 'name': 'صلاة العشاء', 'icon': '✨', 'time': times?.isha ?? '18:58'},
      {'key': 'midnight', 'name': 'منتصف الليل', 'icon': '🌌', 'time': times?.midnight ?? '23:14'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'يمكنك زيادة أو إنقاص وقت أي صلاة بالدقائق بشكل يدوي (مع الحفاظ الكامل على دقة باقي الحسابات الفلكية والمعادلات):',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            color: colors.textSub,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ...prayerData.map((p) {
          final key = p['key'] as String;
          final name = p['name'] as String;
          final icon = p['icon'] as String;
          final time = p['time'] as String;
          final currentOffset = settings.prayerOffsets[key] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.innerCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.innerCardBorder),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textTitle,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: colors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),

                // - and + controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Plus button
                    _buildOffsetButton(
                      icon: Icons.add,
                      onTap: () async {
                        await settings.setPrayerOffset(key, currentOffset + 1);
                        await prayer.fetchPrayerTimes();
                      },
                      colors: colors,
                    ),
                    const SizedBox(width: 8),

                    // Value Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.iconBoxBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.innerCardBorder),
                      ),
                      child: Text(
                        '$currentOffset د',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Minus button
                    _buildOffsetButton(
                      icon: Icons.remove,
                      onTap: () async {
                        await settings.setPrayerOffset(key, currentOffset - 1);
                        await prayer.fetchPrayerTimes();
                      },
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOffsetButton({
    required IconData icon,
    required VoidCallback onTap,
    required _PrayerSettingsColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.iconBoxBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.innerCardBorder),
        ),
        child: Icon(icon, color: colors.textTitle, size: 16),
      ),
    );
  }

  // ==========================================
  // 4️⃣ Card 4: إظهار وإخفاء المواقيت
  // ==========================================
  Widget _buildVisibilityContent(SettingsController settings, _PrayerSettingsColors colors) {
    final list = [
      {'key': 'fajr', 'name': 'صلاة الفجر', 'sub': 'أذان الفجر الشرعي', 'icon': '🌅'},
      {'key': 'sunrise', 'name': 'الشروق', 'sub': 'شروق الشمس ونهاية وقت الفجر', 'icon': '☀️'},
      {'key': 'dhuhr', 'name': 'صلاة الظهر', 'sub': 'أذان الظهرين (الظهر والعصر)', 'icon': '🕐'},
      {'key': 'asr', 'name': 'صلاة العصر', 'sub': 'وقت فضيلة صلاة العصر', 'icon': '🌤️'},
      {'key': 'sunset', 'name': 'الغروب', 'sub': 'غروب قرص الشمس', 'icon': '🌇'},
      {'key': 'maghrib', 'name': 'صلاة المغرب', 'sub': 'أذان المغربين (المغرب والعشاء)', 'icon': '🌙'},
      {'key': 'isha', 'name': 'صلاة العشاء', 'sub': 'وقت فضيلة صلاة العشاء', 'icon': '✨'},
      {'key': 'midnight', 'name': 'منتصف الليل', 'sub': 'منتصف الليل الشرعي (نهاية وقت العشائين)', 'icon': '🌌'},
    ];

    return Column(
      children: list.map((item) {
        final key = item['key'] as String;
        final name = item['name'] as String;
        final sub = item['sub'] as String;
        final icon = item['icon'] as String;
        final isVisible = settings.prayerVisibility[key] ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.innerCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.innerCardBorder),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textTitle,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isVisible,
                activeThumbColor: colors.switchActiveThumb,
                activeTrackColor: colors.switchActiveTrack,
                inactiveThumbColor: colors.switchInactiveThumb,
                inactiveTrackColor: colors.switchInactiveTrack,
                onChanged: (val) => settings.setPrayerVisibility(key, val),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // 5️⃣ Card 5: تنبيهات أوقات الصلاة والأذان
  // ==========================================
  Widget _buildAlertsContent(
    BuildContext context,
    SettingsController settings,
    _PrayerSettingsColors colors,
  ) {
    final prayers = [
      {'key': 'fajr', 'name': 'صلاة الفجر', 'enabled': settings.notifyFajr, 'icon': '🌅'},
      {'key': 'dhuhr', 'name': 'صلاة الظهر', 'enabled': settings.notifyDhuhr, 'icon': '☀️'},
      {'key': 'asr', 'name': 'صلاة العصر', 'enabled': settings.notifyAsr, 'icon': '🌤️'},
      {'key': 'maghrib', 'name': 'صلاة المغرب', 'enabled': settings.notifyMaghrib, 'icon': '🌙'},
      {'key': 'isha', 'name': 'صلاة العشاء', 'enabled': settings.notifyIsha, 'icon': '✨'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...prayers.map((p) {
          final key = p['key'] as String;
          final name = p['name'] as String;
          final enabled = p['enabled'] as bool;
          final icon = p['icon'] as String;
          final alertType = settings.prayerAlertTypes[key] ?? 'full';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.innerCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.innerCardBorder),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textTitle,
                        ),
                      ),
                      Text(
                        _getAlertTypeName(alertType),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          color: colors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),

                // Customize Alert Button
                IconButton(
                  icon: Icon(Icons.tune_rounded, color: colors.accent, size: 20),
                  tooltip: 'تخصيص نغمة وتنبيه الصلاة',
                  onPressed: () => _showPrayerAlertTypeModal(context, settings, key, name, colors),
                ),

                // Switch
                Switch(
                  value: enabled,
                  activeThumbColor: colors.switchActiveThumb,
                  activeTrackColor: colors.switchActiveTrack,
                  inactiveThumbColor: colors.switchInactiveThumb,
                  inactiveTrackColor: colors.switchInactiveTrack,
                  onChanged: (val) => settings.setPrayerNotification(key, val),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        // Pre-prayer 15-minute alert toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.innerCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.innerCardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.alarm_rounded, color: colors.goldAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيه مبكر قبل الصلاة بـ 15 دقيقة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textTitle,
                      ),
                    ),
                    Text(
                      'تذكير بالاستعداد للوضوء والصلاة في وقت الفضيلة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.notifyPrePrayer15Min,
                activeThumbColor: colors.switchActiveThumb,
                activeTrackColor: colors.switchActiveTrack,
                inactiveThumbColor: colors.switchInactiveThumb,
                inactiveTrackColor: colors.switchInactiveTrack,
                onChanged: (val) => settings.setNotifyPrePrayer15Min(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Sticky Notification Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.innerCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.innerCardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.push_pin_rounded, color: colors.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإشعار الدائم لمواقيت الصلاة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textTitle,
                      ),
                    ),
                    Text(
                      'عرض شريط دائم في لوحة إشعارات النظام بالصلاة القادمة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.stickyPrayerNotification,
                activeThumbColor: colors.switchActiveThumb,
                activeTrackColor: colors.switchActiveTrack,
                inactiveThumbColor: colors.switchInactiveThumb,
                inactiveTrackColor: colors.switchInactiveTrack,
                onChanged: (val) => settings.setStickyPrayerNotification(val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Real Battery Optimization & Doze Bypass Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isBatteryIgnored
                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0D281E) : const Color(0xFFF0FDF4))
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B1F0E) : const Color(0xFFFFFBEB)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isBatteryIgnored
                  ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFF86EFAC))
                  : const Color(0xFFF59E0B).withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isBatteryIgnored ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: _isBatteryIgnored ? const Color(0xFF10B981) : const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBatteryIgnored
                          ? 'حماية الأذان من موفر الطاقة (مستثنى بنجاح ✅)'
                          : 'تنبيه إجباري: تحسين البطارية قد يؤخر الأذان! ⚠️',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _isBatteryIgnored
                            ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isBatteryIgnored
                    ? 'التطبيق مستثنى حالياً من قيود توفير الطاقة بنظام أندرويد. ستنطلق التنبيهات والأذان في وقتها الشرعي التام بالثانية حتى عند إغلاق الشاشة.'
                    : 'يقوم نظام أندرويد بوضع التطبيق في النوم العميق لتوفير الطاقة، مما يؤخر التنبيهات حتى فتح قفل الشاشة. يرجى استثناء التطبيق لضمان الأذان في وقته بدقة.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              if (!_isBatteryIgnored) ...[
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AppNotificationService().requestPermissionsAndBatteryOptimization();
                      await _checkBatteryStatus();
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'استثناء التطبيق من قيود البطارية الآن ⚡',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ProximityWakeLockService().openBatterySettings();
                  },
                  icon: Icon(
                    Icons.settings_suggest_rounded,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  label: Text(
                    'فتح إعدادات بطارية النظام يدوياً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Test Ringing Button
        ElevatedButton.icon(
          onPressed: () => AdhanSchedulerService().testAdhanSound(context),
          icon: Icon(Icons.volume_up_rounded, color: colors.accent, size: 20),
          label: Text(
            'تجربة رنين وإشعار الأذان الآن 🔊',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: colors.accent,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.buttonBg,
            foregroundColor: colors.buttonFg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  String _getAlertTypeName(String type) {
    switch (type) {
      case 'full':
        return 'أذان كامل بصوت المؤذن';
      case 'takbeer':
        return 'تكبيرات الأذان فقط';
      case 'short':
        return 'إشعار صوتي قصير';
      case 'vibrate':
        return 'اهتزاز فقط';
      case 'silent':
        return 'صامت';
      default:
        return 'أذان كامل بصوت المؤذن';
    }
  }

  void _showPrayerAlertTypeModal(
    BuildContext context,
    SettingsController settings,
    String prayerKey,
    String prayerName,
    _PrayerSettingsColors colors,
  ) {
    final current = settings.prayerAlertTypes[prayerKey] ?? 'full';

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تخصيص تنبيه $prayerName',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textTitle,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAlertTypeRadio('أذان كامل بصوت المؤذن', 'full', current, (v) {
                  settings.setPrayerAlertType(prayerKey, v);
                  Navigator.pop(ctx);
                }, colors),
                _buildAlertTypeRadio('تكبيرات الأذان فقط', 'takbeer', current, (v) {
                  settings.setPrayerAlertType(prayerKey, v);
                  Navigator.pop(ctx);
                }, colors),
                _buildAlertTypeRadio('إشعار صوتي قصير (تنبيه)', 'short', current, (v) {
                  settings.setPrayerAlertType(prayerKey, v);
                  Navigator.pop(ctx);
                }, colors),
                _buildAlertTypeRadio('اهتزاز فقط', 'vibrate', current, (v) {
                  settings.setPrayerAlertType(prayerKey, v);
                  Navigator.pop(ctx);
                }, colors),
                _buildAlertTypeRadio('صامت (بدون صوت ولا اهتزاز)', 'silent', current, (v) {
                  settings.setPrayerAlertType(prayerKey, v);
                  Navigator.pop(ctx);
                }, colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertTypeRadio(
    String title,
    String val,
    String groupVal,
    ValueChanged<String> onChanged,
    _PrayerSettingsColors colors,
  ) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: colors.textTitle)),
      value: val,
      groupValue: groupVal,
      activeColor: colors.accent,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  // ==========================================
  // 6️⃣ Card 6: صوت الأذان ومصادر الصوت المعتمدة
  // ==========================================
  Widget _buildMuezzinContent(SettingsController settings, _PrayerSettingsColors colors) {
    final muezzins = MuezzinDownloadService.muezzins;
    final downloadService = MuezzinDownloadService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...muezzins.map((m) {
        final isSelected = settings.selectedMuezzin == m.name || settings.selectedMuezzin == m.id;
        final isPlaying = downloadService.isPlaying && downloadService.currentlyPlayingId == m.id;
        final isDownloading = downloadService.isMuezzinDownloading(m.id);

        return FutureBuilder<bool>(
          future: downloadService.isMuezzinDownloaded(m.id),
          builder: (context, snapshot) {
            final isDownloaded = snapshot.data ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.selectedTileBg : colors.innerCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? colors.selectedTileBorder : colors.innerCardBorder,
                  width: isSelected ? 1.2 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Radio selection
                      Radio<String>(
                        value: m.name,
                        groupValue: settings.selectedMuezzin,
                        activeColor: colors.accent,
                        onChanged: (val) {
                          if (val != null) {
                            settings.setSelectedMuezzin(val);
                          }
                        },
                      ),
                      const SizedBox(width: 4),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? colors.accent : colors.textTitle,
                              ),
                            ),
                            Text(
                              m.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.5,
                                color: colors.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Play/Pause Preview Button
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: colors.accent,
                          size: 32,
                        ),
                        onPressed: () {
                          downloadService.playPreview(m, onStateChange: () {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                    ],
                  ),

                  // Offline status badge & Download button
                  Padding(
                    padding: const EdgeInsets.only(right: 48, left: 8, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isDownloaded) ...[
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: colors.accent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'محفوظ محلياً (Offline Ready) 🟢',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10.5,
                                  color: colors.accent,
                                ),
                              ),
                            ],
                          ),
                        ] else if (isDownloading) ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'جارٍ التنزيل في الذاكرة...',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: colors.goldAccent),
                              ),
                            ],
                          ),
                        ] else ...[
                          InkWell(
                            onTap: () async {
                              setState(() {});
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await downloadService.downloadMuezzin(m);
                              if (mounted) {
                                setState(() {});
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? 'تم تنزيل أذان ${m.name} بنجاح ✅' : 'تعذر التنزيل. تحقق من الاتصال.',
                                      style: const TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    backgroundColor: colors.cardBg,
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.cloud_download_rounded, color: colors.goldAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'تنزيل للعمل بدون إنترنت ⬇️',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10.5,
                                    color: colors.goldAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          m.durationText,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: colors.textSub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),

      const SizedBox(height: 16),

      // Divider & Header for Custom Muezzin Per Prayer (اسفل الصوتيات الأساسية)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, color: colors.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تخصيص مؤذن لكل صلاة (متقدم)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                  Text(
                    'يمكنك اختيار مؤذن مختلف لكل فريضة (مثال: أسامة للفجر، عامر للظهر)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      color: colors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // 5 Prayers customization list
      ..._buildPerPrayerMuezzinTiles(settings, colors, muezzins, downloadService),
    ],
  );
}

  List<Widget> _buildPerPrayerMuezzinTiles(
    SettingsController settings,
    _PrayerSettingsColors colors,
    List<MuezzinItem> muezzins,
    MuezzinDownloadService downloadService,
  ) {
    final prayers = [
      {'key': 'fajr', 'name': 'صلاة الفجر', 'icon': Icons.wb_twilight_rounded},
      {'key': 'dhuhr', 'name': 'صلاة الظهر', 'icon': Icons.wb_sunny_rounded},
      {'key': 'asr', 'name': 'صلاة العصر', 'icon': Icons.wb_cloudy_rounded},
      {'key': 'maghrib', 'name': 'صلاة المغرب', 'icon': Icons.nights_stay_rounded},
      {'key': 'isha', 'name': 'صلاة العشاء', 'icon': Icons.bedtime_rounded},
    ];

    return prayers.map((p) {
      final pKey = p['key'] as String;
      final pName = p['name'] as String;
      final pIcon = p['icon'] as IconData;
      final customMuezzin = settings.prayerMuezzins[pKey];
      final isCustom = customMuezzin != null && customMuezzin.isNotEmpty && customMuezzin != 'default';
      final activeMuezzin = isCustom ? customMuezzin : settings.selectedMuezzin;

      // Find MuezzinItem for preview
      final activeMuezzinItem = muezzins.firstWhere(
        (m) => m.name == activeMuezzin || m.id == activeMuezzin,
        orElse: () => muezzins.first,
      );
      final isPlaying = downloadService.isPlaying && downloadService.currentlyPlayingId == activeMuezzinItem.id;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCustom ? colors.selectedTileBg : colors.innerCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCustom ? colors.selectedTileBorder : colors.innerCardBorder,
            width: isCustom ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Prayer Icon Box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCustom ? colors.accent.withOpacity(0.15) : colors.iconBoxBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(pIcon, color: isCustom ? colors.accent : colors.goldAccent, size: 20),
            ),
            const SizedBox(width: 10),

            // Prayer and Selected Muezzin Info
            Expanded(
              child: InkWell(
                onTap: () => _showPrayerMuezzinSelector(context, settings, colors, pKey, pName, muezzins),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isCustom ? activeMuezzin : 'المؤذن الافتراضي ($activeMuezzin)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
                              color: isCustom ? colors.accent : colors.textSub,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'مخصص',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Play Preview Button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: isCustom ? colors.accent : colors.textSub,
                size: 26,
              ),
              tooltip: 'استماع',
              onPressed: () {
                downloadService.playPreview(activeMuezzinItem, onStateChange: () {
                  if (mounted) setState(() {});
                });
              },
            ),

            // Reset to Default button if custom
            if (isCustom)
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.textSub, size: 20),
                tooltip: 'إعادة للمؤذن الافتراضي',
                onPressed: () {
                  settings.setPrayerMuezzin(pKey, null);
                },
              ),

            // Change Muezzin Button
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, color: colors.arrowColor, size: 14),
              onPressed: () => _showPrayerMuezzinSelector(context, settings, colors, pKey, pName, muezzins),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showPrayerMuezzinSelector(
    BuildContext context,
    SettingsController settings,
    _PrayerSettingsColors colors,
    String prayerKey,
    String prayerName,
    List<MuezzinItem> muezzins,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentChoice = settings.prayerMuezzins[prayerKey] ?? 'default';

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      'اختر صوت الأذان لـ $prayerName',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اختر مؤذناً مخصصاً أو اعتمد الصوت الافتراضي العام',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: colors.textSub,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Option 1: Default Muezzin
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: currentChoice == 'default' ? colors.selectedTileBg : colors.innerCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentChoice == 'default' ? colors.selectedTileBorder : colors.innerCardBorder,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Radio<String>(
                          value: 'default',
                          groupValue: currentChoice,
                          activeColor: colors.accent,
                          onChanged: (val) {
                            settings.setPrayerMuezzin(prayerKey, null);
                            Navigator.pop(ctx);
                          },
                        ),
                        title: Text(
                          'المؤذن الافتراضي العام',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: currentChoice == 'default' ? colors.accent : colors.textTitle,
                          ),
                        ),
                        subtitle: Text(
                          settings.selectedMuezzin,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: colors.textSub),
                        ),
                        onTap: () {
                          settings.setPrayerMuezzin(prayerKey, null);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),

                    // Options: Specific Muezzins
                    ...muezzins.map((m) {
                      final isSelected = currentChoice == m.name || currentChoice == m.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.selectedTileBg : colors.innerCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? colors.selectedTileBorder : colors.innerCardBorder,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Radio<String>(
                            value: m.name,
                            groupValue: currentChoice,
                            activeColor: colors.accent,
                            onChanged: (val) {
                              settings.setPrayerMuezzin(prayerKey, val);
                              Navigator.pop(ctx);
                            },
                          ),
                          title: Text(
                            m.name,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? colors.accent : colors.textTitle,
                            ),
                          ),
                          subtitle: Text(
                            m.title,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: colors.textSub),
                          ),
                          trailing: Text(
                            m.durationText,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: colors.textSub),
                          ),
                          onTap: () {
                            settings.setPrayerMuezzin(prayerKey, m.name);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}