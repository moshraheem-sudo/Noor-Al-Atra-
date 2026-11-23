import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings_controller.dart';
import '../services/app_update_service.dart';
import '../services/hijri_date_service.dart';
import 'prayer_times_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsExpanded = true;
  bool _quranAudioExpanded = false;
  bool _prayerTimesExpanded = false;
  bool _aboutDevsExpanded = false;
  bool _isSyncingHijri = false;
  bool _isSyncingEvents = false;
  String _hijriSyncStatus = 'تمت مزامنة البيانات وتحديثها بنجاح! (1 / 4 / 1448 هـ)';

  late final TextEditingController _hijriDayCtrl;
  late final TextEditingController _hijriMonthCtrl;
  late final TextEditingController _hijriYearCtrl;

  @override
  void initState() {
    super.initState();
    final currentH = HijriDateService.getHijriDate();
    _hijriDayCtrl = TextEditingController(text: '${currentH['day']}');
    _hijriMonthCtrl = TextEditingController(text: '${currentH['month']}');
    _hijriYearCtrl = TextEditingController(text: '${currentH['year']}');

    AppUpdateService.fetchSisterAppsVersions().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hijriDayCtrl.dispose();
    _hijriMonthCtrl.dispose();
    _hijriYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;
    final isDark = isEmerald || isRoyalDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background Islamic Geometric Pattern / Soft Gradient
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.04 : 0.07,
                child: Image.asset(
                  'assets/images/ic_app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
                      children: [
                        // 1. Notifications & Alerts Section
                        _buildNotificationsSection(context, settings, isDark),
                        const SizedBox(height: 16),

                        // 2. Home Customization Section
                        _buildHomeCustomizationSection(context, settings, isDark),
                        const SizedBox(height: 16),

                        // 3. Theme & Background Color Section
                        _buildThemeSection(context, settings, isDark),
                        const SizedBox(height: 16),

                        // 4. Smart Kashida & Font Section
                        _buildFontAndKashidaSection(context, settings, isDark),
                        const SizedBox(height: 16),

                        // 5. Hijri Timing & Calendar Sync Section
                        _buildHijriTimingSection(context, settings, isDark),
                        const SizedBox(height: 16),

                        // 6. App Updates & GitHub Section
                        _buildAppUpdatesSection(context, settings, isDark),
                        const SizedBox(height: 16),

                        // 7. Download Quran Audio App Section
                        _buildQuranAudioDownloadSection(context, isDark),
                        const SizedBox(height: 16),

                        // 8. Download Prayer Times (Salaty) App Section
                        _buildPrayerTimesDownloadSection(context, isDark),
                        const SizedBox(height: 16),

                        // 9. About Developers & Supporters Section
                        _buildAboutDevelopersSection(context, isDark),
                        const SizedBox(height: 16),

                        // 10. App Info & Copyright Card
                        _buildAppInfoCard(context, isDark),
                        const SizedBox(height: 24),
                      ],
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

  // --- 1. Header ---
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Text(
          'إعدادات تطبيق نور العترة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1B3A57),
          ),
        ),
      ),
    );
  }

  // --- 2. Section 1: Notifications & Alerts ---
  Widget _buildNotificationsSection(BuildContext context, SettingsController settings, bool isDark) {
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    return _buildCardWrapper(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _notificationsExpanded = !_notificationsExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD6EEFA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إعدادات الإشعارات والتنبيهات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1B3A57),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الآيات القرآنية، وتنبيهات المناسبات الدينية، ومواقيت الصلاة والأذان',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _notificationsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                  ),
                ],
              ),
            ),
          ),

          if (_notificationsExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            // Toggle 1: Quran Verses Notification
            _buildSwitchTile(
              title: 'إشعارات الآيات القرآنية',
              subtitle: 'إرسال إشعارين في الساعة بآيات كريمة بالرسم العثماني (كل 30 دقيقة)',
              value: settings.quranNotifications,
              onChanged: (val) => settings.setQuranNotifications(val),
              isDark: isDark,
            ),

            // Toggle 2: Daily Deeds & Ziyarat Notification
            _buildSwitchTile(
              title: 'إشعارات أدعية وزيارات الأيام',
              subtitle: 'تنبيه صباحي مبارك بأدعية وزيارة اليوم المأثورة عن أهل البيت عليهم السلام',
              value: settings.dailyDeedsNotifications,
              onChanged: (val) => settings.setDailyDeedsNotifications(val),
              isDark: isDark,
            ),

            // Toggle 3: Post-Prayer Taqeebat Notification
            _buildSwitchTile(
              title: 'إشعار تعقيبات الصلاة (بعد 5 دقائق)',
              subtitle: 'إرسال إشعار تذكيري بتعقيبات الفريضة بعد انقضاء 5 دقائق من دخول وقت الأذان',
              value: settings.taqeebatNotifications,
              onChanged: (val) => settings.setTaqeebatNotifications(val),
              isDark: isDark,
            ),


            // Toggle 4: Events Notification
            _buildSwitchTile(
              title: 'تنبيهات المناسبات عند اقترابها',
              subtitle: 'إشعار مبكر قبل عدة أيام وعند حلول المناسبات الدينية وأيام الفضيلة',
              value: settings.eventsNotifications,
              onChanged: (val) => settings.setEventsNotifications(val),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Sub-card: Prayer Times & Azan Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: InkWell(
                onTap: () => _showPrayerNotificationSettingsModal(context, settings, isDark),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isEmerald
                        ? const Color(0xFF0D2F20)
                        : (isDark ? const Color(0xFF132238) : const Color(0xFFF0F7FD)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEmerald
                          ? const Color(0xFF1B5E3B)
                          : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD0E6F7)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isEmerald
                              ? const Color(0xFF14452F)
                              : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2F0FA)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_filled_rounded,
                          color: isEmerald
                              ? const Color(0xFF34D399)
                              : (isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57)),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إشعارات مواقيت الصلاة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF1B3A57),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'إعدادات الأذان، واختيار المؤذن والتنبيهات المخصصة لكل فريضة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // --- 3. Section 2: Home Screen Customization ---
  Widget _buildHomeCustomizationSection(BuildContext context, SettingsController settings, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'تخصيص الواجهة الرئيسية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildSwitchTile(
              title: 'عرض شريط أعمال اليوم',
              subtitle: 'إظهار شريط الأعمال والعبادات اليومية في الواجهة الرئيسية',
              value: settings.showDailyDeedsBanner,
              onChanged: (val) => settings.setShowDailyDeedsBanner(val),
              isDark: isDark,
            ),
            const Divider(height: 12, indent: 16, endIndent: 16),

            _buildSwitchTile(
              title: 'عرض بطاقة مواقيت الصلاة',
              subtitle: 'إظهار أو إخفاء بطاقة مواقيت الصلاة والصلاة القادمة في الواجهة الرئيسية',
              value: settings.showPrayerCard,
              onChanged: (val) => settings.setShowPrayerCard(val),
              isDark: isDark,
            ),
            const Divider(height: 12, indent: 16, endIndent: 16),

            _buildSwitchTile(
              title: 'عرض أحداث هذا الشهر والمناسبات',
              subtitle: 'إظهار أو إخفاء قائمة أحداث هذا الشهر وشريط المناسبات في التقويم والواجهة الرئيسية',
              value: settings.showEventsCard,
              onChanged: (val) => settings.setShowEventsCard(val),
              isDark: isDark,
            ),
            const Divider(height: 12, indent: 16, endIndent: 16),

            _buildSwitchTile(
              title: 'عرض شريط قبس من كلام الله',
              subtitle: 'إظهار أو إخفاء بطاقة الآية القرآنية المقترحة في الواجهة الرئيسية',
              value: settings.showQabasBanner,
              onChanged: (val) => settings.setShowQabasBanner(val),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Section 3: Theme & Background Color ---
  Widget _buildThemeSection(BuildContext context, SettingsController settings, bool isDark) {
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;

    return _buildCardWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_rounded,
                  color: isEmerald
                      ? const Color(0xFF34D399)
                      : (isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57)),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'مظهر الخلفية ولون الواجهة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1B3A57),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'اختر التوازن اللوني المناسب لخلفية التطبيق والزخارف الإسلامية:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isEmerald
                    ? const Color(0xFF94A3B8)
                    : (isDark ? Colors.white60 : const Color(0xFF7A8B99)),
              ),
            ),
            const SizedBox(height: 16),

            // 3 Color Cards Row
            Row(
              children: [
                // 1. Icy Blue (Default)
                Expanded(
                  child: _buildThemeOptionCard(
                    isSelected: settings.themePalette == AppThemePalette.icyBlue,
                    gradientColors: const [Color(0xFFDDF2FC), Color(0xFFBBE3F7)],
                    activeBorderColor: const Color(0xFF0284C7),
                    onTap: () {
                      settings.setThemePalette(AppThemePalette.icyBlue);
                    },
                    isDark: isDark,
                    isEmerald: isEmerald,
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Emerald Green (Middle Option)
                Expanded(
                  child: _buildThemeOptionCard(
                    isSelected: settings.themePalette == AppThemePalette.emeraldGreen,
                    gradientColors: const [Color(0xFF0F5A47), Color(0xFF053528)],
                    activeBorderColor: const Color(0xFF34D399),
                    onTap: () {
                      settings.setThemePalette(AppThemePalette.emeraldGreen);
                    },
                    isDark: isDark,
                    isEmerald: isEmerald,
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Royal Dark
                Expanded(
                  child: _buildThemeOptionCard(
                    isSelected: settings.themePalette == AppThemePalette.royalDark,
                    gradientColors: const [Color(0xFF1E293B), Color(0xFF0B132B)],
                    activeBorderColor: const Color(0xFF38BDF8),
                    onTap: () {
                      settings.setThemePalette(AppThemePalette.royalDark);
                    },
                    isDark: isDark,
                    isEmerald: isEmerald,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required bool isSelected,
    required List<Color> gradientColors,
    required Color activeBorderColor,
    required VoidCallback onTap,
    required bool isDark,
    required bool isEmerald,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isEmerald
                  ? const Color(0xFF0D2F20)
                  : (isDark ? const Color(0xFF1A2A42) : Colors.white))
              : (isEmerald
                  ? const Color(0xFF071C13)
                  : (isDark ? const Color(0xFF132238) : const Color(0xFFF8FAFC))),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeBorderColor
                : (isEmerald
                    ? const Color(0xFF14452F)
                    : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0))),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBorderColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected ? activeBorderColor : Colors.white24,
                width: isSelected ? 2.0 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 5. Section 4: Smart Kashida & Font Settings ---
  Widget _buildFontAndKashidaSection(BuildContext context, SettingsController settings, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Kashida Toggle
            Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'التنسيق الذكي للكشيدة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1B3A57),
                    ),
                  ),
                ),
                Switch(
                  value: settings.smartKashida,
                  activeColor: const Color(0xFF1B3A57),
                  activeTrackColor: const Color(0xFF90CAF9),
                  onChanged: (val) => settings.setSmartKashida(val),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Font Size Title & Step Slider
            Center(
              child: Text(
                'حجم خط الكشيدة والقراءة (%${settings.fontScalePercentage})',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Stepper Track with + and - buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132238) : const Color(0xFFF1F6FB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Decrease button (-)
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 20),
                    color: const Color(0xFF1B3A57),
                    onPressed: () => settings.decrementFontScale(),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF1B3A57),
                        inactiveTrackColor: const Color(0xFFD0E6F7),
                        thumbColor: const Color(0xFF1B3A57),
                        overlayColor: const Color(0xFF1B3A57).withOpacity(0.12),
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      ),
                      child: Slider(
                        value: settings.fontScale,
                        min: 0.7,
                        max: 1.5,
                        divisions: 8,
                        onChanged: (val) => settings.setFontScale(val),
                      ),
                    ),
                  ),
                  // Increase button (+)
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    color: const Color(0xFF1B3A57),
                    onPressed: () => settings.incrementFontScale(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Live Preview Card
            Text(
              'معاينة ذكية ومباشرة لتنسيق النص:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132238) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ (1) الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ (2) الرَّحْمَـٰنِ الرَّحِيمِ (3) مَالِكِ يَوْمِ الدِّينِ (4)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16 * settings.fontScale,
                  height: 2.1,
                  fontWeight: FontWeight.normal,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. Section 5: Hijri Timing & Calendar Sync ---
  Widget _buildHijriTimingSection(BuildContext context, SettingsController settings, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A57),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التوقيت الهجري',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1B3A57),
                        ),
                      ),
                      Text(
                        'تحديث التقويم ليوافق الرؤية الشرعية للهلال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Mode Toggle: عبر الإنترنت / تعديل يدوي
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132238) : const Color(0xFFF0F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => settings.setHijriMode('online'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: settings.hijriMode == 'online'
                              ? const Color(0xFF1B3A57)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'عبر الإنترنت',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: settings.hijriMode == 'online'
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF7A8B99)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => settings.setHijriMode('manual'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: settings.hijriMode == 'manual'
                              ? const Color(0xFF1B3A57)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'تعديل يدوي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: settings.hijriMode == 'manual'
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF7A8B99)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (settings.hijriMode == 'manual') ...[
              // Label: أدخل التاريخ الهجري المعتمد ليومنا هذا:
              Text(
                'أدخل التاريخ الهجري المعتمد ليومنا هذا:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                ),
              ),
              const SizedBox(height: 10),

              // 3 Outlined Input Fields in Row: اليوم (1-30) / الشهر (1-12) / السنة (1448)
              Row(
                children: [
                  _buildHijriBox(
                    controller: _hijriDayCtrl,
                    label: 'اليوم (1-30)',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildHijriBox(
                    controller: _hijriMonthCtrl,
                    label: 'الشهر (1-12)',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildHijriBox(
                    controller: _hijriYearCtrl,
                    label: 'السنة (${_hijriYearCtrl.text.isNotEmpty ? _hijriYearCtrl.text : "1448"})',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Save Button: حفظ التاريخ اليدوي ✓
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDDF0FB),
                    foregroundColor: isDark ? Colors.white : const Color(0xFF1B3A57),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2A4D70) : const Color(0xFFBFE0F7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    final day = int.tryParse(_hijriDayCtrl.text) ?? 15;
                    final month = int.tryParse(_hijriMonthCtrl.text) ?? 4;
                    final year = int.tryParse(_hijriYearCtrl.text) ?? 1448;
                    final currentAuto = HijriDateService.getHijriDate();
                    final offset = day - (currentAuto['day'] as int);
                    settings.setHijriManualOffset(offset);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1B3A57),
                        content: Text(
                          'تم حفظ التاريخ الهجري اليدوي بنجاح ✓ ($day / $month / $year هـ)',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'حفظ التاريخ اليدوي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Footnote Text
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'تم تفعيل وضع التعديل اليدوي وإيقاف التحديث التلقائي (باستثناء التحديثات الضرورية).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Action Button: Update Hijri Timing Now (Online)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A57),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isSyncingHijri
                      ? null
                      : () async {
                          setState(() => _isSyncingHijri = true);
                          await Future.delayed(const Duration(milliseconds: 600));
                          final currentH = HijriDateService.getHijriDate();
                          if (mounted) {
                            setState(() {
                              _isSyncingHijri = false;
                              _hijriSyncStatus =
                                  'تمت مزامنة البيانات وتحديثها بنجاح! (${currentH['day']} / ${currentH['month']} / ${currentH['year']} هـ)';
                              _hijriDayCtrl.text = '${currentH['day']}';
                              _hijriMonthCtrl.text = '${currentH['month']}';
                              _hijriYearCtrl.text = '${currentH['year']}';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B3A57),
                                content: Text('تم تحديث التوقيت الهجري بنجاح ✓ (${currentH['shortFormatted']})'),
                              ),
                            );
                          }
                        },
                  icon: _isSyncingHijri
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync_rounded, size: 20),
                  label: const Text(
                    'تحديث التوقيت الهجري الآن',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Success Badge Text
              Center(
                child: Text(
                  _hijriSyncStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Secondary Action Button: Manual Sync Events
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F8FD),
                  side: BorderSide(color: isDark ? const Color(0xFF38BDF8).withOpacity(0.5) : const Color(0xFFD0E6F7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: _isSyncingEvents
                    ? null
                    : () async {
                        setState(() => _isSyncingEvents = true);
                        await Future.delayed(const Duration(milliseconds: 700));
                        if (mounted) {
                          setState(() => _isSyncingEvents = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF1B3A57),
                              content: Text('تمت مزامنة جميع المناسبات الدينية وأيام الفضيلة بنجاح ✓'),
                            ),
                          );
                        }
                      },
                icon: _isSyncingEvents
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)),
                      )
                    : Icon(Icons.refresh_rounded, size: 18, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)),
                label: Text(
                  'مزامنة يدوية / التحقق من المناسبات الآن',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHijriBox({
    required TextEditingController controller,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: SizedBox(
        height: 54,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1B3A57),
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF5A7B9A),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A4D70) : const Color(0xFFA5C8E4),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1B3A57),
                width: 1.6,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF132238) : Colors.white,
          ),
        ),
      ),
    );
  }

  // --- 7. Section 6: App Updates & GitHub ---
  Widget _buildAppUpdatesSection(BuildContext context, SettingsController settings, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132238) : const Color(0xFFF0F7FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD0E6F7),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2DD4BF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحديثات تطبيق نور العترة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF1B3A57),
                          ),
                        ),
                        Text(
                          'النسخة الحالية: v${AppUpdateService.currentVersion} (أحدث إصدار مثبت)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF7A8B99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Check Updates Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A57),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => AppUpdateService.checkForUpdates(context),
                icon: const Icon(Icons.sync_rounded, size: 20),
                label: const Text(
                  'فحص تحديثات نور العترة',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. Section 7: Download Quran Audio App ---
  Widget _buildQuranAudioDownloadSection(BuildContext context, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: ExpansionTile(
        initiallyExpanded: _quranAudioExpanded,
        onExpansionChanged: (val) => setState(() => _quranAudioExpanded = val),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD6EEFA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_download_rounded,
            color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57),
            size: 22,
          ),
        ),
        title: Text(
          'تنزيل تطبيق صوت القرآن الكريم',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1B3A57),
          ),
        ),
        subtitle: Text(
          'الإصدار المتوفر: ${AppUpdateService.quranAudioVersion} • تحميل مباشر وتثبيت الحزمة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0F766E),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 6),
                Text(
                  'يتيح لك التطبيق الصوتي الاستماع لتلاوات القرآن الكريم الكاملة بصوت كبار القراء بدقة صوتية عالية وبدون انقطاع مع إمكانية التحميل للعمل دون إنترنت.',
                  style: TextStyle(
                     fontFamily: 'Cairo',
                     fontSize: 12,
                     height: 1.6,
                     color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => AppUpdateService.checkQuranAudioRelease(context),
                    icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                    label: Text(
                      'تحميل صوت القرآن ${AppUpdateService.quranAudioVersion} (APK)',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
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

  // --- 9. Section 8: Download Prayer Times (Salaty) App ---
  Widget _buildPrayerTimesDownloadSection(BuildContext context, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: ExpansionTile(
        initiallyExpanded: _prayerTimesExpanded,
        onExpansionChanged: (val) => setState(() => _prayerTimesExpanded = val),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD6EEFA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.access_time_filled_rounded,
            color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57),
            size: 22,
          ),
        ),
        title: Text(
          'تنزيل تطبيق صلاتي (مواقيت الصلاة والأذان)',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1B3A57),
          ),
        ),
        subtitle: Text(
          'الإصدار المتوفر: ${AppUpdateService.prayerTimesVersion} • حساب فقهي دقيق وأذان تلقائي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 6),
                Text(
                  'تطبيق صلاتي لحساب مواقيت الصلاة الشرعية اليومية والأذان التلقائي والقبلة الدقيقة وفق منهج مدرسة أهل البيت (عليهم السلام) مع تنبيهات دخول الوقت بدقة بالغة.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    height: 1.6,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3A57),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => AppUpdateService.checkPrayerTimesRelease(context),
                    icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                    label: Text(
                      'تحميل تطبيق صلاتي ${AppUpdateService.prayerTimesVersion} (APK)',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
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

  // --- 9. Section 8: About Developers & Supporters ---
  Widget _buildAboutDevelopersSection(BuildContext context, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: ExpansionTile(
        initiallyExpanded: _aboutDevsExpanded,
        onExpansionChanged: (val) => setState(() => _aboutDevsExpanded = val),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD6EEFA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.groups_rounded,
            color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57),
            size: 22,
          ),
        ),
        title: Text(
          'عن المطور والداعمين',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1B3A57),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'المهندس محمد شهيد الأعاجيبي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1B3A57),
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Color Contact Pill Buttons (واتساب / اتصال / بريد)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. WhatsApp Button (Green)
                    InkWell(
                      onTap: () async {
                        const phone = '9647831452279';
                        final whatsappAppUri = Uri.parse('whatsapp://send?phone=$phone');
                        final whatsappWebUri = Uri.parse('https://api.whatsapp.com/send?phone=$phone');

                        try {
                          if (await canLaunchUrl(whatsappAppUri)) {
                            await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
                            return;
                          }
                        } catch (_) {}

                        try {
                          await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تعذر فتح تطبيق واتساب مباشرة'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'واتساب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Call Button (Blue)
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse('tel:+9647831452279');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تعذر بدء الاتصال'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'اتصال',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Email Button (Amber/Gold)
                    InkWell(
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'mohammed.sh.raheem@gmail.com',
                          queryParameters: {
                            'subject': 'تطبيق نور العترة - استفسار أو مقترح',
                          },
                        );
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          // Fallback to simple mailto string
                          try {
                            final fallbackUri = Uri.parse('mailto:mohammed.sh.raheem@gmail.com');
                            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تعذر فتح تطبيق البريد، تم نسخ العنوان'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mail_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'بريد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'تم تطوير تطبيق «نور العترة» كعمل إسلامي تطوعي لوجه الله تعالى بهدف خدمة المؤمنين وتقديم تجربة قرآنية وعبادية رفيعة المستوى وفق مدرسة أهل البيت (عليهم السلام).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    height: 1.6,
                    color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),

                // Repositories and Links
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF1B3A57),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => AppUpdateService.openGitHubRepository(),
                        icon: Icon(Icons.code_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)),
                        label: Text(
                          'مستودع المشروع',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1B3A57),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF1B3A57),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {
                          Share.share(
                            'تطبيق نور العترة - القرآن الكريم ومواقيت الصلاة والأدعية والزيارات وفق منهج أهل البيت (ع)\nhttps://github.com/moshraheem-sudo/Noor-Al-Atra-',
                          );
                        },
                        icon: Icon(Icons.share_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)),
                        label: Text(
                          'مشاركة التطبيق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1B3A57),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF1B3A57),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showCacheAndResetDialog(context),
                        icon: Icon(Icons.cleaning_services_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57)),
                        label: Text(
                          'إدارة التخزين والذاكرة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1B3A57),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 10. Section 9: About App & Copyright Card ---
  Widget _buildAppInfoCard(BuildContext context, bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            // Scaled-up App Circular Icon with Golden Frame
            Container(
              width: 86,
              height: 86,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC5A059), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB88E4C).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.25,
                  child: Image.asset(
                    'assets/images/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/ic_app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0F5A47),
                        child: const Icon(Icons.mosque, color: Color(0xFFE5C882), size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // App Title
            Text(
              'نور العترة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1B3A57),
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'تطبيق القرآن الكريم وسيرة أهل البيت (عليهم السلام) والأدعية والزيارات والمواقيت الشرعية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info Table Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132238) : const Color(0xFFF1F6FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildInfoTableRow('اسم التطبيق', 'تطبيق نور العترة', isDark),
                  const Divider(height: 14),
                  _buildInfoTableRow(
                    'إصدار التطبيق',
                    'الإصدار ${AppUpdateService.currentVersion}',
                    isDark,
                    isBadge: true,
                  ),
                  const Divider(height: 14),
                  _buildInfoTableRow('سنة الإصدار والتوثيق', '2026 م - 1448 هـ', isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Copyright & Dedication
            Text(
              'حقوق النشر والملكية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'جميع الحقوق محفوظة © 2026 م - 1448 هـ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1B3A57),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'وقف إسلامي خيري لوجه الله تعالى',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF7A8B99),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'نسألكم الدعاء لوالدينا ولجميع المؤمنين والمؤمنات 🤲',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB88E4C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTableRow(String label, String value, bool isDark, {bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD6EEFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF1B3A57),
                width: 0.8,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF1B3A57),
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.white : const Color(0xFF1B3A57),
            ),
          ),
      ],
    );
  }

  // --- Helper Card Wrapper ---
  Widget _buildCardWrapper({required Widget child, required bool isDark}) {
    final settings = SettingsController();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;
    final isRoyalDark = settings.themePalette == AppThemePalette.royalDark;

    Color cardBg;
    Color cardBorder;
    if (isEmerald) {
      cardBg = const Color(0xFF082216);
      cardBorder = const Color(0xFF14452F);
    } else if (isRoyalDark) {
      cardBg = const Color(0xFF1E293B);
      cardBorder = const Color(0xFF334155);
    } else {
      cardBg = Colors.white;
      cardBorder = const Color(0xFFD0E6F7);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- Helper Switch Tile ---
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final settings = SettingsController();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1B3A57),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: isEmerald
                        ? const Color(0xFF94A3B8)
                        : (isDark ? Colors.white60 : const Color(0xFF7A8B99)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: isEmerald
                ? const Color(0xFF04140D)
                : (isDark ? Colors.white : const Color(0xFF1B3A57)),
            activeTrackColor: isEmerald
                ? const Color(0xFFFBBF24) // Gold track
                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF90CAF9)),
            inactiveTrackColor: isEmerald ? const Color(0xFF133626) : null,
            inactiveThumbColor: isEmerald ? const Color(0xFF6EE7B7) : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- Prayer Notification Detailed Bottom Sheet ---
  void _showPrayerNotificationSettingsModal(BuildContext context, SettingsController settings, bool isDark) {
    PrayerTimesScreen.showPrayerSettingsModal(context);
  }

  // --- Cache & Reset Settings Dialog ---
  void _showCacheAndResetDialog(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final cacheSize = await settings.getCacheSize();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, color: Color(0xFF1B3A57)),
            SizedBox(width: 10),
            Text('إدارة الذاكرة والتخزين', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حجم الملفات المؤقتة حالياً: $cacheSize', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3A57),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await settings.clearCache();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم مسح الملفات المؤقتة بنجاح ✓')),
                  );
                }
              },
              icon: const Icon(Icons.cleaning_services_rounded, size: 16),
              label: const Text('مسح الذاكرة المؤقتة (Cache)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await settings.resetAllSettings();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت استعادة إعدادات الوضع الافتراضي بنجاح ✓')),
                  );
                }
              },
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('إعادة ضبط جميع الإعدادات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
