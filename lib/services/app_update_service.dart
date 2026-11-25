import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_notification_service.dart';

class AppUpdateService {
  static const String currentVersion = '5.65.0';

  // 1️⃣ مستودع التحديثات الرئيسي لتطبيق نور العترة
  static const String primaryRepoUrl = 'https://github.com/moshraheem-sudo/Noor-Al-Atra-';
  static const String primaryApiUrl = 'https://api.github.com/repos/moshraheem-sudo/Noor-Al-Atra-/releases/latest';

  // 2️⃣ المستودع العام الدائم لنور العترة (Fallback Mirror)
  static const String fallbackRepoUrl = 'https://github.com/moshraheem-sudo/myapp-updates';
  static const String fallbackApiUrl = 'https://api.github.com/repos/moshraheem-sudo/myapp-updates/releases/latest';

  // 3️⃣ مستودع صوتيات القرآن الكريم
  static const String quranAudioRepoUrl = 'https://github.com/moshraheem-sudo/Sawt-Al-Quran-';
  static const String quranAudioApiUrl = 'https://api.github.com/repos/moshraheem-sudo/Sawt-Al-Quran-/releases/latest';

  // 4️⃣ مستودع مواقيت الصلاة والأذان
  static const String prayerTimesRepoUrl = 'https://github.com/moshraheem-sudo/Prayer-Times';
  static const String prayerTimesApiUrl = 'https://api.github.com/repos/moshraheem-sudo/Prayer-Times/releases/latest';
  static const String prayerTimesRawGradleUrl = 'https://raw.githubusercontent.com/moshraheem-sudo/Prayer-Times/main/app/build.gradle.kts';

  // 5️⃣ الإصدارات المتوفرة للتطبيقات الشقيقة (محدثة تلقائياً من GitHub)
  static String quranAudioVersion = 'v3.40.0';
  static String prayerTimesVersion = 'v1.70.0';

  /// جلب أحدث أرقام الإصدارات لتطبيقي صوت القرآن وصلاتي في الخلفية
  static Future<void> fetchSisterAppsVersions() async {
    try {
      final res1 = await http.get(Uri.parse(quranAudioApiUrl), headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 5));
      if (res1.statusCode == 200) {
        final d = json.decode(res1.body);
        final tag = (d['tag_name'] ?? '').toString().trim();
        if (tag.isNotEmpty) {
          quranAudioVersion = tag.startsWith('v') ? tag : 'v$tag';
        }
      }
    } catch (_) {}

    try {
      final res2 = await http.get(Uri.parse(prayerTimesApiUrl), headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 5));
      if (res2.statusCode == 200) {
        final d = json.decode(res2.body);
        final tag = (d['tag_name'] ?? '').toString().trim();
        if (tag.isNotEmpty) {
          prayerTimesVersion = tag.startsWith('v') ? tag : 'v$tag';
        }
      }
    } catch (_) {}
  }

  /// فحص صامت للتحديثات في خلفية التطبيق عند الإقلاع بدون إزعاج المستخدم
  /// في حال توفر إصدار جديد يتم إظهار نافذة التحديث المباشر للمستخدم تلقائياً
  static Future<void> checkUpdateSilently(BuildContext context) async {
    Map<String, dynamic>? releaseData;
    String targetRepoUrl = primaryRepoUrl;

    try {
      final primaryRes = await http.get(Uri.parse(primaryApiUrl), headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 6));

      if (primaryRes.statusCode == 200) {
        releaseData = json.decode(primaryRes.body);
        targetRepoUrl = primaryRepoUrl;
      } else {
        final fallbackRes = await http.get(Uri.parse(fallbackApiUrl), headers: {
          'Accept': 'application/vnd.github.v3+json',
        }).timeout(const Duration(seconds: 6));

        if (fallbackRes.statusCode == 200) {
          releaseData = json.decode(fallbackRes.body);
          targetRepoUrl = fallbackRepoUrl;
        }
      }
    } catch (_) {
      try {
        final fallbackRes = await http.get(Uri.parse(fallbackApiUrl), headers: {
          'Accept': 'application/vnd.github.v3+json',
        }).timeout(const Duration(seconds: 6));

        if (fallbackRes.statusCode == 200) {
          releaseData = json.decode(fallbackRes.body);
          targetRepoUrl = fallbackRepoUrl;
        }
      } catch (_) {}
    }

    if (releaseData != null && context.mounted) {
      final String tagName = (releaseData['tag_name'] ?? '').toString().replaceAll('v', '').trim();
      final String body = (releaseData['body'] ?? 'تحديث جديد يتضمن تحسينات عامة وميزات إضافية.').toString();
      final String htmlUrl = (releaseData['html_url'] ?? targetRepoUrl).toString();

      String? apkDownloadUrl;
      if (releaseData['assets'] is List) {
        for (var asset in releaseData['assets']) {
          final name = (asset['name'] ?? '').toString().toLowerCase();
          if (name.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }
      }

      if (_isNewerVersion(tagName, currentVersion) && context.mounted) {
        // إرسال إشعار فوري إلى شريط الإشعارات بالنظام
        AppNotificationService().showAppUpdateNotification(newVersion: tagName, changelog: body);

        // بدء نافذة التنزيل التلقائي المباشر داخلياً بدون فتح متصفح خارجي
        _showLiveApkDownloadModal(
          context,
          apkDownloadUrl ?? htmlUrl,
          'تطبيق نور العترة v$tagName',
          htmlUrl,
          autoInstall: true,
        );
      }
    }
  }

  /// فحص توفر تحديثات جديدة لتطبيق نور العترة
  static Future<void> checkForUpdates(BuildContext context, {bool showToastIfLatest = true}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1B3A57)),
                SizedBox(width: 16),
                Text(
                  'جاري التحقق من توفر تحديثات جديدة...',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Map<String, dynamic>? releaseData;
    String targetRepoUrl = primaryRepoUrl;

    try {
      final primaryRes = await http.get(Uri.parse(primaryApiUrl), headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 7));

      if (primaryRes.statusCode == 200) {
        releaseData = json.decode(primaryRes.body);
        targetRepoUrl = primaryRepoUrl;
      } else {
        final fallbackRes = await http.get(Uri.parse(fallbackApiUrl), headers: {
          'Accept': 'application/vnd.github.v3+json',
        }).timeout(const Duration(seconds: 7));

        if (fallbackRes.statusCode == 200) {
          releaseData = json.decode(fallbackRes.body);
          targetRepoUrl = fallbackRepoUrl;
        }
      }
    } catch (_) {
      try {
        final fallbackRes = await http.get(Uri.parse(fallbackApiUrl), headers: {
          'Accept': 'application/vnd.github.v3+json',
        }).timeout(const Duration(seconds: 7));

        if (fallbackRes.statusCode == 200) {
          releaseData = json.decode(fallbackRes.body);
          targetRepoUrl = fallbackRepoUrl;
        }
      } catch (_) {}
    }

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (releaseData != null) {
      final String tagName = (releaseData['tag_name'] ?? '').toString().replaceAll('v', '').trim();
      final String body = (releaseData['body'] ?? 'تحسينات عامة وإصلاحات في الأداء والتلاوات.').toString();
      final String htmlUrl = (releaseData['html_url'] ?? targetRepoUrl).toString();

      String? apkDownloadUrl;
      if (releaseData['assets'] is List) {
        for (var asset in releaseData['assets']) {
          final name = (asset['name'] ?? '').toString().toLowerCase();
          if (name.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }
      }

      if (_isNewerVersion(tagName, currentVersion)) {
        // إرسال إشعار فوري في النظام
        AppNotificationService().showAppUpdateNotification(newVersion: tagName, changelog: body);
        if (context.mounted) {
          _showUpdateDialog(context, tagName, body, apkDownloadUrl ?? htmlUrl, htmlUrl);
        }
      } else {
        if (context.mounted && showToastIfLatest) {
          _showLatestVersionSnackBar(context);
        }
      }
    } else {
      if (context.mounted && showToastIfLatest) {
        _showLatestVersionSnackBar(context);
      }
    }
  }

  /// Download and Install Quran Audio APK with Live Progress Bar & MB counter
  static Future<void> checkQuranAudioRelease(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0F766E)),
                SizedBox(width: 16),
                Text(
                  'جاري البحث عن أحدث حزمة صوتية...',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    String? directApkUrl;
    String releasePageUrl = quranAudioRepoUrl;

    try {
      final res = await http.get(Uri.parse(quranAudioApiUrl), headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 7));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        releasePageUrl = data['html_url'] ?? quranAudioRepoUrl;
        final tag = (data['tag_name'] ?? '').toString().trim();
        if (tag.isNotEmpty) {
          quranAudioVersion = tag.startsWith('v') ? tag : 'v$tag';
        }
        if (data['assets'] is List) {
          for (var a in data['assets']) {
            if ((a['name'] ?? '').toString().toLowerCase().endsWith('.apk')) {
              directApkUrl = a['browser_download_url'];
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Dismiss loading search
    }

    if (!context.mounted) return;

    // If direct APK is found, launch animated live download modal with MB progress
    if (directApkUrl != null && directApkUrl.isNotEmpty) {
      _showLiveApkDownloadModal(context, directApkUrl, 'تطبيق صوت القرآن الكريم', releasePageUrl);
    } else {
      // Fallback: Open GitHub Release page directly
      final uri = Uri.parse(releasePageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// تنزيل وتثبيت تطبيق صلاتي (مواقيت الصلاة والأذان)
  static Future<void> checkPrayerTimesRelease(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1B3A57)),
                SizedBox(width: 16),
                Text(
                  'جاري البحث عن أحدث إصدار لتطبيق صلاتي...',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    String? directApkUrl;
    String releasePageUrl = prayerTimesRepoUrl;

    try {
      final res = await http.get(Uri.parse(prayerTimesApiUrl), headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 7));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        releasePageUrl = data['html_url'] ?? prayerTimesRepoUrl;
        final tag = (data['tag_name'] ?? '').toString().trim();
        if (tag.isNotEmpty) {
          prayerTimesVersion = tag.startsWith('v') ? tag : 'v$tag';
        }
        if (data['assets'] is List) {
          for (var a in data['assets']) {
            if ((a['name'] ?? '').toString().toLowerCase().endsWith('.apk')) {
              directApkUrl = a['browser_download_url'];
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Dismiss loading search
    }

    if (!context.mounted) return;

    if (directApkUrl != null && directApkUrl.isNotEmpty) {
      _showLiveApkDownloadModal(context, directApkUrl, 'تطبيق صلاتي (مواقيت الصلاة والأذان)', releasePageUrl);
    } else {
      final uri = Uri.parse(releasePageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static const MethodChannel _platformChannel = MethodChannel('com.example.flutter_noor_alatra/wakelock');

  /// تثبيت ملف الـ APK المحمل مباشرة داخل نظام أندرويد بدون متصفح خارجي
  static Future<bool> installDownloadedApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final res = await _platformChannel.invokeMethod('installApk', {'filePath': filePath});
        return res == true;
      }
    } catch (e) {
      debugPrint('Error triggering native APK install: $e');
    }
    return false;
  }

  /// نافذة التحميل الداخلي المباشر للـ APK مع نسبة التقدم وعداد الميغابايت وإمكانية الإلغاء والتثبيت التلقائي
  static void _showLiveApkDownloadModal(
    BuildContext context,
    String downloadUrl,
    String appName,
    String fallbackUrl, {
    bool autoInstall = false,
  }) {
    if (Platform.isIOS) {
      // iOS cannot install APKs; launch the web release page instead
      final target = Uri.parse(fallbackUrl.isNotEmpty ? fallbackUrl : primaryRepoUrl);
      launchUrl(target, mode: LaunchMode.externalApplication);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        double progress = 0.0;
        double downloadedMb = 0.0;
        double totalMb = 0.0;
        bool isDownloading = true;
        bool isCompleted = false;
        String? localApkPath;
        String? errorMessage;
        http.Client? client;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Start download on first build
            if (isDownloading && progress == 0.0 && client == null) {
              client = http.Client();
              Future.microtask(() async {
                try {
                  final tempDir = await getTemporaryDirectory();
                  final rawName = downloadUrl.split('/').last.split('?').first;
                  final fileName = rawName.endsWith('.apk') ? rawName : 'downloaded_app.apk';
                  final file = File('${tempDir.path}/$fileName');
                  if (await file.exists()) {
                    await file.delete();
                  }

                  final req = http.Request('GET', Uri.parse(downloadUrl));
                  final streamedRes = await client!.send(req).timeout(const Duration(minutes: 5));

                  if (streamedRes.statusCode == 200) {
                    final total = streamedRes.contentLength ?? 0;
                    totalMb = total > 0 ? (total / (1024 * 1024)) : 35.0; // estimate if unknown
                    int received = 0;

                    final sink = file.openWrite();
                    await for (final chunk in streamedRes.stream) {
                      sink.add(chunk);
                      received += chunk.length;
                      downloadedMb = (received / (1024 * 1024));
                      if (total > 0) {
                        progress = (received / total).clamp(0.0, 1.0);
                      } else {
                        progress = (downloadedMb / totalMb).clamp(0.0, 0.95);
                      }
                      setDialogState(() {});
                    }

                    await sink.flush();
                    await sink.close();

                    if (await file.exists() && await file.length() > 50000) {
                      setDialogState(() {
                        progress = 1.0;
                        isDownloading = false;
                        isCompleted = true;
                        localApkPath = file.path;
                      });
                      if (autoInstall) {
                        // بدء التثبيت التلقائي الفوري دون الحاجة لتحويل المستخدم للخارج
                        Future.delayed(const Duration(milliseconds: 300), () {
                          installDownloadedApk(file.path);
                        });
                      }
                    } else {
                      throw Exception('حجم الملف المحمل غير مكتمل');
                    }
                  } else {
                    throw Exception('تعذر التحميل (رمز الخطأ: ${streamedRes.statusCode})');
                  }
                } catch (e) {
                  setDialogState(() {
                    isDownloading = false;
                    errorMessage = e.toString();
                  });
                } finally {
                  client?.close();
                }
              });
            }

            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                            : const Color(0xFF0F766E).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
                        color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF0F766E),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompleted ? 'اكتمل التحميل بنجاح!' : 'تحميل $appName',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF1B3A57),
                            ),
                          ),
                          Text(
                            isCompleted ? 'حزمة التثبيت جاهزة الآن' : 'جارٍ تنزيل ملف الـ APK المباشر...',
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
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDownloading) ...[
                      // Percentage and MBs indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          Text(
                            '${downloadedMb.toStringAsFixed(1)} ميغابايت / ${totalMb.toStringAsFixed(1)} ميغابايت',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'يرجى الانتظار حتى اكتمال تحميل حزمة التطبيق...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ] else if (isCompleted) ...[
                      // Success & Android Install Permissions Guide
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF132238) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.security_rounded, color: Color(0xFF22C55E), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'صلاحيات وتثبيت التطبيق:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• اضغط على «تثبيت التطبيق الآن» لفتح ملف التثبيت المباشر.\n• إذا ظهرت لك رسالة أمان من نظام أندرويد، يُرجى تفعيل خيار «السماح بتثبيت التطبيقات من هذا المصدر» لإتمام التثبيت بنجاح.',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                height: 1.6,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Error view
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'تعذر إكمال التحميل التلقائي: ${errorMessage ?? ""}\nيمكنك التحميل مباشرة من صفحة الإصدارات في المتصفح.',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (isDownloading)
                    TextButton(
                      onPressed: () {
                        client?.close();
                        Navigator.pop(dialogCtx);
                      },
                      child: const Text('إلغاء التحميل', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    )
                  else if (isCompleted) ...[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: () async {
                        if (localApkPath != null) {
                          final success = await installDownloadedApk(localApkPath!);
                          if (!success) {
                            final uri = Uri.parse(downloadUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.install_mobile_rounded, size: 18),
                      label: const Text(
                        'تثبيت التطبيق الآن',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3A57),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        final uri = Uri.parse(fallbackUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                      label: const Text('التحميل من المتصفح', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static bool _isNewerVersion(String latest, String current) {
    if (latest.isEmpty) return false;
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return false;
    }
  }

  static void _showLatestVersionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B3A57),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF2DD4BF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'أنت تستخدم أحدث إصدار بالفعل (v$currentVersion) ✓',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String changelog,
    String downloadUrl,
    String releasePageUrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update_rounded, color: Color(0xFF1B5E20), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحديث جديد متاح!',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A57)),
                  ),
                  Text(
                    'الإصدار $newVersion (الإصدار الحالي: $currentVersion)',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سجل التغييرات والتحسينات:',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3A57)),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  changelog,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, height: 1.6, color: Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3A57),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // تنزيل وتثبيت داخلي فوري داخل التطبيق دون فتح المتصفح الخارجي
              _showLiveApkDownloadModal(
                context,
                downloadUrl,
                'تطبيق نور العترة v$newVersion',
                releasePageUrl,
                autoInstall: true,
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('تحميل وتحديث الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Launch official GitHub repository URL
  static Future<void> openGitHubRepository() async {
    final uri = Uri.parse(primaryRepoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launch Fallback Mirror repository URL
  static Future<void> openFallbackRepository() async {
    final uri = Uri.parse(fallbackRepoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launch Prayer Times repository URL
  static Future<void> openPrayerTimesRepository() async {
    final uri = Uri.parse(prayerTimesRepoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
