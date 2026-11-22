import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/city_location.dart';
import '../screens/ramadan_imsakiya_screen.dart';
import '../services/hijri_date_service.dart';

/// أنماط التصميم المتاحة لبوستر الإمساكية المطبوعة
enum ImsakiyaPosterTheme {
  classicPrint, // عاجي ورقي للطباعة
  royalNavy, // كحلي ملكي وذهبي
  emeraldGreen, // أخضر زمردي إسلامي
}

class RamadanPosterShareSheet extends StatefulWidget {
  final List<RamadanDayData> days;
  final CityLocation city;
  final int hijriYear;

  const RamadanPosterShareSheet({
    super.key,
    required this.days,
    required this.city,
    required this.hijriYear,
  });

  static void show(
    BuildContext context, {
    required List<RamadanDayData> days,
    required CityLocation city,
    required int hijriYear,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RamadanPosterShareSheet(
          days: days,
          city: city,
          hijriYear: hijriYear,
        ),
      ),
    );
  }

  @override
  State<RamadanPosterShareSheet> createState() => _RamadanPosterShareSheetState();
}

class _RamadanPosterShareSheetState extends State<RamadanPosterShareSheet> {
  final GlobalKey _posterKey = GlobalKey();
  ImsakiyaPosterTheme _currentTheme = ImsakiyaPosterTheme.classicPrint;
  bool _isExporting = false;
  String? _lastSavedPath;

  Future<File?> _capturePosterImage() async {
    try {
      await Future.delayed(const Duration(milliseconds: 120));
      final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Capture at high resolution (pixelRatio: 2.2) for crisp printed text
      final ui.Image image = await boundary.toImage(pixelRatio: 2.2);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'imsakiya_ramadan_${widget.city.id}_${widget.hijriYear}_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error generating imsakiya poster: $e');
      return null;
    }
  }

  Future<void> _sharePoster() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final file = await _capturePosterImage();
      if (file == null) {
        throw Exception('تعذر التقاط صورة الإمساكية');
      }

      final shareSubject =
          'إمساكية شهر رمضان المبارك لعام ${HijriDateService.toArabicDigits(widget.hijriYear)} هـ - ${widget.city.displayName}';
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: shareSubject,
        text: '🌙 $shareSubject\nوفق توقيت مركز الكفيل / العتبة العباسية المقدسة\nتطبيق نور العترة ✨',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تصدير الصورة: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _downloadPoster() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final file = await _capturePosterImage();
      if (file == null) {
        throw Exception('تعذر التقاط صورة الإمساكية');
      }

      Directory? targetDir;
      if (Platform.isAndroid) {
        // First try the public Download folder
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          targetDir = publicDownload;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
      targetDir ??= await getApplicationDocumentsDirectory();

      final String fileName =
          'imsakiya_ramadan_${widget.city.id}_${widget.hijriYear}.png';
      final File targetFile = File('${targetDir.path}/$fileName');
      await file.copy(targetFile.path);
      _lastSavedPath = targetFile.path;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ تم تنزيل وحفظ الإمساكية في مجلد التنزيلات (Download)',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'مشاركة',
              textColor: Colors.white,
              onPressed: _sharePoster,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الإمساكية: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0F18) : const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F1B2B) : Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 26),
            tooltip: 'إغلاق',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تنزيل الإمساكية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            // Circular color theme swatches without any text or labels
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildColorCircle(
                  theme: ImsakiyaPosterTheme.classicPrint,
                  primaryColor: Colors.white,
                  secondaryColor: const Color(0xFFFDE68A),
                  borderColor: const Color(0xFFD97706),
                ),
                _buildColorCircle(
                  theme: ImsakiyaPosterTheme.royalNavy,
                  primaryColor: const Color(0xFF0B192C),
                  secondaryColor: const Color(0xFF1E3E62),
                  borderColor: const Color(0xFFFBBF24),
                ),
                _buildColorCircle(
                  theme: ImsakiyaPosterTheme.emeraldGreen,
                  primaryColor: const Color(0xFF062A1F),
                  secondaryColor: const Color(0xFF064E3B),
                  borderColor: const Color(0xFF34D399),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Subtle zoom & pan hint banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              child: Text(
                '💡 اسحب أو كبّر بإصبعين للمعاينة الدقيقة قبل التنزيل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),

            // Poster Preview Area filling full screen with InteractiveViewer
            Expanded(
              child: InteractiveViewer(
                minScale: 0.2,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(40),
                constrained: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: _buildPrintablePosterWidget(),
                  ),
                ),
              ),
            ),

            // Action Buttons Bar with SafeArea(bottom: true)
            SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132238) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Download Button
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _downloadPoster,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 2,
                        ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 21),
                        label: Text(
                          _isExporting ? 'جارٍ المعالجة...' : 'تنزيل الإمساكية',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Share Button
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: _isExporting ? null : _sharePoster,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF059669), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text(
                          'مشاركة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle({
    required ImsakiyaPosterTheme theme,
    required Color primaryColor,
    required Color secondaryColor,
    required Color borderColor,
  }) {
    final isSelected = (_currentTheme == theme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _currentTheme = theme),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? borderColor : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: (primaryColor.computeLuminance() > 0.5)
                          ? const Color(0xFF1B3A57)
                          : Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPrintablePosterWidget() {
    Color bgColor;
    Color textColor;
    Color subTextColor;
    Color goldColor;
    Color headerGradient1;
    Color headerGradient2;
    Color cardBg;
    Color borderColor;
    Color tableHeaderBg;
    Color evenRowBg;
    Color oddRowBg;
    Color iftarBg;

    switch (_currentTheme) {
      case ImsakiyaPosterTheme.classicPrint:
        bgColor = const Color(0xFFFCFDF9);
        textColor = const Color(0xFF1E293B);
        subTextColor = const Color(0xFF64748B);
        goldColor = const Color(0xFFB45309);
        headerGradient1 = const Color(0xFF1E3A5F);
        headerGradient2 = const Color(0xFF0F172A);
        cardBg = Colors.white;
        borderColor = const Color(0xFFCBD5E1);
        tableHeaderBg = const Color(0xFFF1F5F9);
        evenRowBg = Colors.white;
        oddRowBg = const Color(0xFFF8FAFC);
        iftarBg = const Color(0xFFDCFCE7);
        break;

      case ImsakiyaPosterTheme.royalNavy:
        bgColor = const Color(0xFF070F1E);
        textColor = Colors.white;
        subTextColor = const Color(0xFF94A3B8);
        goldColor = const Color(0xFFFBBF24);
        headerGradient1 = const Color(0xFF1E293B);
        headerGradient2 = const Color(0xFF0F172A);
        cardBg = const Color(0xFF0C192E);
        borderColor = const Color(0xFF1E3A5F);
        tableHeaderBg = const Color(0xFF142745);
        evenRowBg = const Color(0xFF0E1E38);
        oddRowBg = const Color(0xFF091426);
        iftarBg = const Color(0xFF13382C);
        break;

      case ImsakiyaPosterTheme.emeraldGreen:
        bgColor = const Color(0xFF041913);
        textColor = Colors.white;
        subTextColor = const Color(0xFF6EE7B7);
        goldColor = const Color(0xFFFCD34D);
        headerGradient1 = const Color(0xFF064E3B);
        headerGradient2 = const Color(0xFF022C22);
        cardBg = const Color(0xFF07271E);
        borderColor = const Color(0xFF065F46);
        tableHeaderBg = const Color(0xFF124736);
        evenRowBg = const Color(0xFF0C2F23);
        oddRowBg = const Color(0xFF072118);
        iftarBg = const Color(0xFF15533D);
        break;
    }

    return Container(
      width: 920, // Expanded width so all 12 columns fit comfortably with zero vertical text breaking
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Decorative Header Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerGradient1, headerGradient2],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: goldColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Column(
              children: [
                // Basmala
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: goldColor,
                  ),
                ),
                const SizedBox(height: 6),

                // Main Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.nights_stay_rounded, color: goldColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'إمساكية شهر رمضان المبارك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: goldColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.nights_stay_rounded, color: goldColor, size: 28),
                  ],
                ),
                const SizedBox(height: 4),

                // Year & City Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'لعام ${HijriDateService.toArabicDigits(widget.hijriYear)} هجرية  |  ${widget.city.displayName}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Quran Verse
                Text(
                  '﴿ شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ هُدًى لِّلنَّاسِ وَبَيِّنَاتٍ مِّنَ الْهُدَىٰ وَالْفُرْقَانِ ﴾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Jurisprudential / Astronomical notes
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚠️ وقت الإمساك محتسب احترازاً قبل أذان الفجر بـ ١٠ دقائق  •  المغرب عند ذهاب الحمرة المشرقية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Complete 30 Days Professional Table
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(1.2),  // اليوم
                1: FlexColumnWidth(0.95), // رمضان (Generous width to avoid 'رمضا' / 'ن' split)
                2: FlexColumnWidth(1.2),  // التاريخ الميلادي
                3: FlexColumnWidth(0.9),  // الإمساك
                4: FlexColumnWidth(0.85), // الفجر
                5: FlexColumnWidth(0.85), // الشروق
                6: FlexColumnWidth(0.85), // الظهر
                7: FlexColumnWidth(0.85), // العصر
                8: FlexColumnWidth(0.85), // الغروب
                9: FlexColumnWidth(0.95), // المغرب (الإفطار)
                10: FlexColumnWidth(0.85),// العشاء
                11: FlexColumnWidth(1.05),// منتصف الليل
              },
              children: [
                // Table Header Row
                TableRow(
                  decoration: BoxDecoration(color: tableHeaderBg),
                  children: [
                    _buildPosterHeaderCell('اليوم', textColor),
                    _buildPosterHeaderCell('رمضان', textColor),
                    _buildPosterHeaderCell('الميلادي', textColor),
                    _buildPosterHeaderCell('الإمساك', goldColor, isGold: true),
                    _buildPosterHeaderCell('الفجر', textColor),
                    _buildPosterHeaderCell('الشروق', textColor),
                    _buildPosterHeaderCell('الظهر', textColor),
                    _buildPosterHeaderCell('العصر', textColor),
                    _buildPosterHeaderCell('الغروب', textColor),
                    _buildPosterHeaderCell('المغرب', const Color(0xFF10B981), isGold: true),
                    _buildPosterHeaderCell('العشاء', textColor),
                    _buildPosterHeaderCell('منتصف الليل', textColor),
                  ],
                ),

                // Table 30 Days Rows
                ...widget.days.map((d) {
                  final isEven = (d.dayNumber % 2 == 0);
                  final isQadrNight = (d.dayNumber == 19 || d.dayNumber == 21 || d.dayNumber == 23);
                  final rowColor = isEven ? evenRowBg : oddRowBg;

                  return TableRow(
                    decoration: BoxDecoration(
                      color: isQadrNight
                          ? goldColor.withValues(alpha: 0.12)
                          : rowColor,
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor.withValues(alpha: 0.35),
                          width: 0.7,
                        ),
                      ),
                    ),
                    children: [
                      // اليوم
                      _buildPosterDataCell(
                        d.dayName,
                        textColor,
                        isBold: true,
                        fontSize: 10.5,
                        suffixBadge: isQadrNight ? '⭐' : null,
                      ),
                      // رقم رمضان
                      _buildPosterDataCell(
                        HijriDateService.toArabicDigits(d.dayNumber),
                        textColor,
                        isBold: true,
                        fontSize: 11,
                      ),
                      // الميلادي
                      _buildPosterDataCell(d.gregorianFormatted, subTextColor, fontSize: 9.5),
                      // الإمساك
                      _buildPosterDataCell(
                        d.imsak,
                        goldColor,
                        isBold: true,
                        fontSize: 11,
                      ),
                      // الفجر
                      _buildPosterDataCell(d.fajr, textColor, fontSize: 10.5),
                      // الشروق
                      _buildPosterDataCell(d.sunrise, subTextColor, fontSize: 10),
                      // الظهر
                      _buildPosterDataCell(d.dhuhr, textColor, fontSize: 10.5),
                      // العصر
                      _buildPosterDataCell(d.asr, textColor, fontSize: 10.5),
                      // الغروب
                      _buildPosterDataCell(d.sunset, subTextColor, fontSize: 10),
                      // المغرب (الإفطار)
                      _buildPosterDataCell(
                        d.maghrib,
                        const Color(0xFF10B981),
                        isBold: true,
                        fontSize: 11,
                        highlightBg: iftarBg,
                      ),
                      // العشاء
                      _buildPosterDataCell(d.isha, textColor, fontSize: 10.5),
                      // منتصف الليل
                      _buildPosterDataCell(d.midnight, subTextColor, fontSize: 10),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Footer with Authentic Duas and Credits
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دعاء الإفطار: « اللَّهُمَّ لَكَ صُمْتُ، وَعَلَىٰ رِزْقِكَ أَفْطَرْتُ، وَعَلَيْكَ تَوَكَّلْتُ »',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'وفق الحساب الفلكي الشرعي الدقيق لمركز الكفيل للثقافة والإعلام / العتبة العباسية المقدسة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9.5,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goldColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'تطبيق نور العترة ✨',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
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

  Widget _buildPosterHeaderCell(String text, Color color, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPosterDataCell(
    String text,
    Color color, {
    bool isBold = false,
    double fontSize = 10.5,
    Color? highlightBg,
    String? suffixBadge,
  }) {
    return Container(
      color: highlightBg,
      padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            softWrap: false,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          if (suffixBadge != null) ...[
            const SizedBox(width: 2),
            Text(suffixBadge, style: const TextStyle(fontSize: 8)),
          ],
        ],
      ),
    );
  }
}
