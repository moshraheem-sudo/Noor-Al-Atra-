import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_notification_service.dart';
import '../services/proximity_wakelock_service.dart';

class BatteryPermissionDialog extends StatelessWidget {
  const BatteryPermissionDialog({super.key});

  /// Check if dialog should be displayed (Android-only)
  static Future<void> checkAndShow(BuildContext context, {bool force = false}) async {
    if (!Platform.isAndroid) return;
    final isIgnored = await AppNotificationService().isBatteryOptimizationIgnored();
    if (isIgnored) return; // Battery optimization is already bypassed, do not show

    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt('battery_permission_dialog_last_shown') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      // Show every 12 hours if still restricted
      if (now - lastShown < 12 * 3600 * 1000) {
        return;
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BatteryPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      child: Dialog(
        backgroundColor: isDark ? const Color(0xFF0F1E16) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFFC09040).withValues(alpha: 0.4) : const Color(0xFFD97706).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Warning / Battery Icon Circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF261E0F) : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.battery_alert_rounded,
                      color: Color(0xFFD97706),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('⚠️ ', style: TextStyle(fontSize: 18)),
                      Flexible(
                        child: Text(
                          'تنبيه إجباري لدقة الأذان والتنبيهات',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subtitle / Description
                  Text(
                    'لوحظ أن موفّر طاقة البطارية بنظام أندرويد يقيّد عمل التطبيق، مما يؤخر رنين الأذان وإشعارات الصلاة حتى فتح شاشة الهاتف!\nلضمان انطلاق الأذان في وقته الشرعي بالثانية، يرجى استثناء التطبيق فوراً:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features Container Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF08170F) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1B4D2B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          icon: Icons.mosque_rounded,
                          title: 'إطلاق الأذان في وقته الشرعي التام',
                          subtitle: 'منع نظام أندرويد من تأخير الأذان أثناء قفل الشاشة أو السكون',
                          isDark: isDark,
                          iconColor: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.alarm_on_rounded,
                          title: 'تنبيهات اقتراب الصلاة والتعقيبات',
                          subtitle: 'التذكير قبل الأذان بـ 10 دقائق وبعده بالتعقيبات المأثورة بدقة',
                          isDark: isDark,
                          iconColor: const Color(0xFFD97706),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.shield_rounded,
                          title: 'حماية التطبيق من الإيقاف الإجباري',
                          subtitle: 'ضمان استمرار شريط مواقيت الصلاة المثبت في مركز الإشعارات',
                          isDark: isDark,
                          iconColor: const Color(0xFF0284C7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Button: Allow & Exclude from battery restrictions
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('battery_permission_dialog_last_shown', DateTime.now().millisecondsSinceEpoch);

                        // Request native battery exemption
                        await AppNotificationService().requestPermissionsAndBatteryOptimization();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'تم فتح طلب إذن استثناء البطارية لضمان دقة الأذان ✅',
                                      style: TextStyle(fontFamily: 'Cairo'),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: isDark ? const Color(0xFF0F3B26) : const Color(0xFF1B3A57),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 22),
                          SizedBox(width: 6),
                          Text(
                            'استثناء من توفير الطاقة الآن (مهم جداً)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Manual Settings Action Button
                  TextButton.icon(
                    onPressed: () async {
                      await ProximityWakeLockService().openBatterySettings();
                    },
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    label: Text(
                      'فتح إعدادات البطارية في الهاتف يدوياً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Skip / Later Button
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('battery_permission_dialog_last_shown', DateTime.now().millisecondsSinceEpoch);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'المتابعة لاحقاً (مع احتمال تأخر الأذان)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
