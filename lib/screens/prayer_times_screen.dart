import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../services/settings_controller.dart';
import '../services/storage_service.dart';
import '../services/data_service.dart';
import '../models/city_location.dart';
import 'prayer_settings_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  /// Opens the official Prayer Times & Azan Settings Screen
  static void showPrayerSettingsModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrayerSettingsScreen()),
    );
  }

  /// Opens the authenticated official City Selector Sheet
  /// Shows ONLY cities detected and saved via GPS locally in the device system
  static void showCityPicker(BuildContext context) {
    final prayer = context.read<PrayerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSystemCities = DataService().cities;
            final savedGpsCities = StorageService().getSavedGpsCities();
            final Set<String> seenIds = {};
            final combinedList = <CityLocation>[];
            for (final c in savedGpsCities) {
              if (seenIds.add(c.id)) combinedList.add(c);
            }
            for (final c in allSystemCities) {
              if (seenIds.add(c.id)) combinedList.add(c);
            }

            final filteredCities = searchQuery.isEmpty
                ? combinedList
                : combinedList.where((c) {
                    final q = searchQuery.trim().toLowerCase();
                    return c.nameAr.toLowerCase().contains(q) ||
                        c.displayName.toLowerCase().contains(q) ||
                        c.nameEn.toLowerCase().contains(q) ||
                        c.countryAr.toLowerCase().contains(q) ||
                        c.province.toLowerCase().contains(q);
                  }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(
                            'المواقع المحفوظة في النظام',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_pin_rounded, size: 14, color: Color(0xFF0284C7)),
                                SizedBox(width: 4),
                                Text(
                                  'نظام GPS بدون إنترنت',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // GPS Quick Button
                      InkWell(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await prayer.detectLocationViaGps();
                          if (result == 'service_disabled') {
                            await Geolocator.openLocationSettings();
                          } else if (result == 'permission_denied_forever') {
                            await Geolocator.openAppSettings();
                          } else if (result == null) {
                            setModalState(() {});
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF166534),
                                behavior: SnackBarBehavior.floating,
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'تم تحديد موقعك وحفظه في النظام: ${prayer.selectedCity.displayName}',
                                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red.shade800,
                                content: Text(result, style: const TextStyle(fontFamily: 'Cairo')),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.my_location, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'تحديد الموقع الحالي تلقائياً عبر GPS وحفظه',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),

                      if (combinedList.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        // Search Field
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم المدينة أو المحافظة (مثال: الكوت، بغداد، النجف)...',
                            hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setModalState(() => searchQuery = ''),
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        // Header
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'المحافظات والمدن المتاحة (${filteredCities.length}):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Content: List or Empty State
                      Expanded(
                        child: combinedList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_searching_rounded,
                                          size: 44,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'لا توجد مواقع محفوظة بعد',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'تم إلغاء القوائم السابقة واعتماد نظام GPS الحصري.\nاضغط على الزر أعلاه لتحديد موقعك الحالي وحفظه في النظام ليعمل معك دائماً وبدون إنترنت.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : (filteredCities.isEmpty
                                ? Center(
                                    child: Text(
                                      'لا توجد مواقع تطابق بحثك',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white60 : Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: filteredCities.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                                    itemBuilder: (c, i) {
                                      final item = filteredCities[i];
                                      final isSelected = item.id == prayer.selectedCity.id ||
                                          (item.nameAr == prayer.selectedCity.nameAr &&
                                              (item.latitude - prayer.selectedCity.latitude).abs() < 0.05);

                                      return ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        leading: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                                                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                            size: 20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.displayName,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? const Color(0xFF0284C7)
                                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                                ),
                                              ),
                                            ),
                                            if (item.isHolyCity)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'مدينة مقدسة',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFB45309),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.countryAr} • خط العرض: ${item.latitude.toStringAsFixed(3)}° • خط الطول: ${item.longitude.toStringAsFixed(3)}°',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Row(
                                              children: [
                                                Icon(Icons.offline_pin, size: 12, color: Color(0xFF166534)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'محفوظ في النظام • متاح بدون إنترنت',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF166534),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSelected)
                                              const Icon(Icons.check_circle, color: Color(0xFF0284C7), size: 22),
                                            if (item.id.startsWith('gps_'))
                                              IconButton(
                                                icon: Icon(Icons.delete_outline_rounded,
                                                    size: 19, color: Colors.red.withValues(alpha: 0.7)),
                                                tooltip: 'حذف من السجل',
                                                onPressed: () async {
                                                  await StorageService().removeGpsCity(item.id);
                                                  setModalState(() {});
                                                },
                                              ),
                                          ],
                                        ),
                                        onTap: () {
                                          prayer.selectCity(item);
                                          Navigator.pop(ctx);
                                        },
                                      );
                                    },
                                  )),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  void _showCityPicker(BuildContext context) => PrayerTimesScreen.showCityPicker(context);
  Future<void> _handleGpsLocation(PrayerProvider prayer) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final result = await prayer.detectLocationViaGps();
    if (!mounted) return;

    if (result == 'service_disabled') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('خدمة الموقع (GPS) معطلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ],
          ),
          content: const Text(
            'خدمة تحديد الموقع الجغرافي (GPS) غير مفعلة على جهازك. يرجى تفعيلها لتحديد موقعك تلقائياً وبدقة.',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.gps_fixed, size: 18),
              label: const Text('تفعيل الـ GPS الآن', style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        ),
      );
    } else if (result == 'permission_denied_forever') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('إذن الموقع الجغرافي مطلوب', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ],
          ),
          content: const Text(
            'تم تعطيل إذن الوصول إلى الموقع الجغرافي سابقاً. يرجى منح إذن الموقع من إعدادات التطبيق لتحديد مدينتك تلقائياً.',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('فتح إعدادات التطبيق', style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openAppSettings();
              },
            ),
          ],
        ),
      );
    } else if (result == 'permission_denied') {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF991B1B),
          behavior: SnackBarBehavior.floating,
          content: Text('تم رفض إذن الموقع. يرجى منحه لتحديد مواقيت الصلاة لموقعك الحالي.', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
    } else if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF991B1B),
          behavior: SnackBarBehavior.floating,
          content: Text(result, style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF166534),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم تحديد موقعك بدقة وحفظه: ${prayer.selectedCity.displayName}',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleRefresh(PrayerProvider prayer) async {
    final messenger = ScaffoldMessenger.of(context);
    await prayer.fetchPrayerTimes();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('تم تحديث مواقيت الصلاة لـ ${prayer.selectedCity.displayName}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final times = prayer.prayerTimes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nextTime = times != null ? _getNextPrayerTime(prayer, times) : '11:57';
    final parsedNextTime = _split12HourTime(nextTime);

    final settings = context.watch<SettingsController>();
    final isEmerald = settings.themePalette == AppThemePalette.emeraldGreen;

    return Scaffold(
      backgroundColor: isEmerald
          ? const Color(0xFF07130A)
          : Theme.of(context).scaffoldBackgroundColor,
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
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          tooltip: 'رجوع',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مواقيت الصلاة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isEmerald
                        ? const Color(0xFF25D366)
                        : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                prayer.selectedCity.nameAr,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isEmerald
                      ? const Color(0xFF25D366)
                      : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, size: 20),
            tooltip: 'إعدادات تنبيهات الأذان والمواقيت',
            color: isEmerald
                ? const Color(0xFF25D366)
                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
            onPressed: () => PrayerTimesScreen.showPrayerSettingsModal(context),
          ),
        ],
      ),
      body: (prayer.isLoading && prayer.prayerTimes == null)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  children: [
                    // 1. City / GPS Location Card (Date Card removed as requested)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E28) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Location pin inside circular badge (on right in RTL)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFE0EDFB),
                            ),
                            child: const Icon(Icons.location_on, color: Color(0xFF1E40AF), size: 24),
                          ),
                          const SizedBox(width: 12),
                          // City info
                          Expanded(
                            child: InkWell(
                              onTap: () => _showCityPicker(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prayer.selectedCity.displayName,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'تحديد الموقع عبر GPS (اضغط للتحديث)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Refresh button (طھط­ط¯ظٹط« ظ…ظˆط§ظ‚ظٹطھ ط§ظ„طµظ„ط§ط©)
                          IconButton(
                            tooltip: 'تحديث المواقيت',
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.refresh, color: Color(0xFF0F766E), size: 20),
                            onPressed: () => _handleRefresh(prayer),
                          ),
                          const SizedBox(width: 4),
                          // GPS Location button (طھط­ط¯ظٹط¯ ط§ظ„ظ…ظˆظ‚ط¹ ط§ظ„ط¯ظ‚ظٹظ‚ ط¹ط¨ط± GPS ظ…ط¹ ط£ظٹظ‚ظˆظ†ط© ط§ظ„ظ…ط·ط§ط¨ظ‚ط© ظ„ظ„طµظˆط±ط© ظˆط­ط§ظ„ط© ط§ظ„طھط­ظ…ظٹظ„)
                          IconButton(
                            tooltip: 'تحديد الموقع الدقيق عبر GPS',
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: prayer.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0284C7),
                                    ),
                                  )
                                : const Icon(Icons.my_location, color: Color(0xFF0284C7), size: 20),
                            onPressed: prayer.isLoading ? null : () => _handleGpsLocation(prayer),
                          ),
                        ],
                      ),
                    ),

                const SizedBox(height: 12),

                // 3. Highlighted Next Prayer Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFDCEBF8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF38BDF8).withOpacity(0.4) : const Color(0xFF90CAF9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Row: â€¢ ط§ظ„طµظ„ط§ط© ط§ظ„ظ‚ط§ط¯ظ…ط©: طµظ„ط§ط© ط§ظ„ط¸ظ‡ط± â€¢ + Bell
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الصلاة القادمة: صلاة ${prayer.nextPrayerName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => PrayerTimesScreen.showPrayerSettingsModal(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1E40AF), size: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Time Display "11:57 ص"
                      Text.rich(
                        TextSpan(
                          text: parsedNextTime['time'],
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(
                              text: ' ${parsedNextTime['suffix']}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Countdown "يتبقى 01:57:07 لرفع الأذان"
                      Text(
                        'يتبقى ${prayer.timeUntilNextPrayer} لرفع الأذان',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 3.5,
                          color: isDark ? Colors.white12 : Colors.white.withOpacity(0.6),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: 0.38,
                              child: Container(
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Section Title
                Center(
                  child: Text(
                    'مواقيت الصلوات الخمسة حسب مدينة ${prayer.selectedCity.nameAr}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Prayer Tiles List (Matching Image 2)
                if (times != null) ...[
                  _prayerDetailCard(
                    title: 'صلاة الفجر',
                    time24: times.fajr,
                    icon: Icons.wb_twilight,
                    iconBg: const Color(0xFFFDE68A),
                    isCurrent: prayer.nextPrayerName == 'الفجر',
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'الشروق',
                    time24: times.sunrise,
                    icon: Icons.wb_sunny_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    isCurrent: prayer.nextPrayerName == 'الشروق',
                    isNoticeOnly: true,
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'صلاة الظهر',
                    time24: times.dhuhr,
                    icon: Icons.wb_sunny,
                    iconBg: const Color(0xFFFBBF24),
                    isCurrent: prayer.nextPrayerName == 'الظهر',
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'صلاة العصر',
                    time24: times.asr,
                    icon: Icons.wb_sunny_rounded,
                    iconBg: const Color(0xFFF59E0B),
                    isCurrent: prayer.nextPrayerName == 'العصر',
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'الغروب',
                    time24: times.sunset,
                    icon: Icons.nights_stay_outlined,
                    iconBg: const Color(0xFFE2E8F0),
                    isCurrent: false,
                    isNoticeOnly: true,
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'صلاة المغرب',
                    time24: times.maghrib,
                    icon: Icons.nights_stay,
                    iconBg: const Color(0xFF93C5FD),
                    isCurrent: prayer.nextPrayerName == 'المغرب',
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'صلاة العشاء',
                    time24: times.isha,
                    icon: Icons.bedtime,
                    iconBg: const Color(0xFF60A5FA),
                    isCurrent: prayer.nextPrayerName == 'العشاء',
                    isDark: isDark,
                  ),
                  _prayerDetailCard(
                    title: 'منتصف الليل',
                    time24: times.midnight,
                    icon: Icons.dark_mode_outlined,
                    iconBg: const Color(0xFFCBD5E1),
                    isCurrent: false,
                    isNoticeOnly: true,
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
            if (prayer.isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF0284C7),
                ),
              ),
          ],
        ),
    );
  }

  Widget _prayerDetailCard({
    required String title,
    required String time24,
    required IconData icon,
    required Color iconBg,
    required bool isCurrent,
    required bool isDark,
    bool isNoticeOnly = false,
  }) {
    final parsed = _split12HourTime(time24);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: isCurrent ? 10 : 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDCEBF8))
            : (isDark ? const Color(0xFF161E28) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF7DB3E0))
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top badge for current prayer (matching Image 2)
          if (isCurrent) ...[
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E40AF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'الصلاة القادمة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E40AF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          Row(
            children: [
              // 1. Right decorative icon (First child in RTL -> rendered on RIGHT)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.orange.shade800, size: 20),
              ),

              const SizedBox(width: 12),

              // 2. Title & optional bullet
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),

              const Spacer(),

              // 3. Time in 12h and 24h
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${parsed['time']} ${parsed['suffix']}',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: isCurrent
                          ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    '(24h) $time24',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // 4. Far left icon: Bell notification (Last child in RTL -> rendered on LEFT)
              InkWell(
                onTap: () => PrayerTimesScreen.showPrayerSettingsModal(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isNoticeOnly ? Icons.notifications_off_outlined : Icons.notifications_active_rounded,
                    size: 20,
                    color: isNoticeOnly
                        ? Colors.grey.shade400
                        : (isCurrent
                            ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E40AF))
                            : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getNextPrayerTime(PrayerProvider prayer, dynamic times) {
    switch (prayer.nextPrayerName) {
      case 'الفجر':
        return times.fajr;
      case 'الشروق':
        return times.sunrise;
      case 'الظهر':
        return times.dhuhr;
      case 'العصر':
        return times.asr;
      case 'المغرب':
        return times.maghrib;
      case 'العشاء':
        return times.isha;
      default:
        return times.dhuhr;
    }
  }

  Map<String, String> _split12HourTime(String time24) {
    final parts = time24.split(':');
    if (parts.length >= 2) {
      int h = int.tryParse(parts[0].trim()) ?? 12;
      final m = parts[1].trim().padLeft(2, '0');
      final suffix = h >= 12 ? 'م' : 'ص';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      final hStr = h.toString().padLeft(2, '0');
      return {
        'time': '$hStr:$m',
        'suffix': suffix,
      };
    }
    return {
      'time': time24,
      'suffix': '',
    };
  }
}
