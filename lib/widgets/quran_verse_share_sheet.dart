import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'ayah_number_symbol.dart';

/// نموذج ثيم بطاقة الآية
class VerseCardTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final List<Color>? backgroundGradient;
  final Color goldColor;
  final Color titleColor;
  final Color basmalaColor;
  final Color textColor;
  final Color ayahNumColor;
  final Color sadaqaColor;
  final Color footerColor;
  final Color dividerColor;
  final Color sideLineColor;
  final Color cardBorderColor;
  final bool isDark;

  const VerseCardTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    this.backgroundGradient,
    required this.goldColor,
    required this.titleColor,
    required this.basmalaColor,
    required this.textColor,
    required this.ayahNumColor,
    required this.sadaqaColor,
    required this.footerColor,
    required this.dividerColor,
    required this.sideLineColor,
    required this.cardBorderColor,
    this.isDark = true,
  });

  static const List<VerseCardTheme> allThemes = [
    VerseCardTheme(
      id: 'black_gold',
      name: 'أسود ملكي وذهبي',
      backgroundColor: Color(0xFF090D12),
      backgroundGradient: [Color(0xFF0B1017), Color(0xFF06080B)],
      goldColor: Color(0xFFD4AF37),
      titleColor: Color(0xFFD4AF37),
      basmalaColor: Color(0xFFE5C07B),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFD4AF37),
      sadaqaColor: Color(0xFFE5C07B),
      footerColor: Color(0xFF9E8B63),
      dividerColor: Color(0xFF5C4718),
      sideLineColor: Color(0x77D4AF37),
      cardBorderColor: Color(0xFF382E18),
      isDark: true,
    ),
    VerseCardTheme(
      id: 'navy_night',
      name: 'كحلي ليلي فاخر',
      backgroundColor: Color(0xFF081426),
      backgroundGradient: [Color(0xFF0D213D), Color(0xFF050E1B)],
      goldColor: Color(0xFFE2B855),
      titleColor: Color(0xFFE2B855),
      basmalaColor: Color(0xFFF3D27E),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFE2B855),
      sadaqaColor: Color(0xFFF3D27E),
      footerColor: Color(0xFF94A3B8),
      dividerColor: Color(0xFF334E68),
      sideLineColor: Color(0x66E2B855),
      cardBorderColor: Color(0xFF1E3A5F),
      isDark: true,
    ),
    VerseCardTheme(
      id: 'emerald_green',
      name: 'أخضر زمردي فاخر',
      backgroundColor: Color(0xFF052219),
      backgroundGradient: [Color(0xFF093326), Color(0xFF031610)],
      goldColor: Color(0xFFE5C07B),
      titleColor: Color(0xFFE5C07B),
      basmalaColor: Color(0xFFF7DCA4),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFE5C07B),
      sadaqaColor: Color(0xFFF7DCA4),
      footerColor: Color(0xFF86A795),
      dividerColor: Color(0xFF1E5240),
      sideLineColor: Color(0x66E5C07B),
      cardBorderColor: Color(0xFF1B4D3A),
      isDark: true,
    ),
    VerseCardTheme(
      id: 'ivory_classic',
      name: 'عاجي ورقي كلاسيكي',
      backgroundColor: Color(0xFFFFFDF8),
      backgroundGradient: [Color(0xFFFFFDF8), Color(0xFFF9F5EC)],
      goldColor: Color(0xFFC5A059),
      titleColor: Color(0xFF786028),
      basmalaColor: Color(0xFF2D2411),
      textColor: Color(0xFF1E1B18),
      ayahNumColor: Color(0xFFB88E4C),
      sadaqaColor: Color(0xFF2D2411),
      footerColor: Color(0xFF9E8B63),
      dividerColor: Color(0xFFE5D5AA),
      sideLineColor: Color(0x66C5A059),
      cardBorderColor: Color(0xFFDECBA0),
      isDark: false,
    ),
    VerseCardTheme(
      id: 'ice_blue',
      name: 'سمائي ثلجي هادئ',
      backgroundColor: Color(0xFFF0F7FD),
      backgroundGradient: [Color(0xFFF8FAFC), Color(0xFFE2F0FD)],
      goldColor: Color(0xFF0284C7),
      titleColor: Color(0xFF0369A1),
      basmalaColor: Color(0xFF0C4A6E),
      textColor: Color(0xFF0F172A),
      ayahNumColor: Color(0xFF0284C7),
      sadaqaColor: Color(0xFF0369A1),
      footerColor: Color(0xFF64748B),
      dividerColor: Color(0xFFBAE6FD),
      sideLineColor: Color(0x660284C7),
      cardBorderColor: Color(0xFF7DD3FC),
      isDark: false,
    ),
    VerseCardTheme(
      id: 'royal_burgundy',
      name: 'عنابي ملكي دافئ',
      backgroundColor: Color(0xFF240710),
      backgroundGradient: [Color(0xFF330B17), Color(0xFF19040A)],
      goldColor: Color(0xFFF5D061),
      titleColor: Color(0xFFF5D061),
      basmalaColor: Color(0xFFFBE296),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFF5D061),
      sadaqaColor: Color(0xFFFBE296),
      footerColor: Color(0xFFA88992),
      dividerColor: Color(0xFF5E1B2C),
      sideLineColor: Color(0x66F5D061),
      cardBorderColor: Color(0xFF4A1422),
      isDark: true,
    ),
    VerseCardTheme(
      id: 'royal_purple',
      name: 'بنفسجي ليلي فاخر',
      backgroundColor: Color(0xFF170928),
      backgroundGradient: [Color(0xFF220E3D), Color(0xFF10051C)],
      goldColor: Color(0xFFE0C068),
      titleColor: Color(0xFFE0C068),
      basmalaColor: Color(0xFFF5DE9C),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFE0C068),
      sadaqaColor: Color(0xFFF5DE9C),
      footerColor: Color(0xFFA193B5),
      dividerColor: Color(0xFF43226D),
      sideLineColor: Color(0x66E0C068),
      cardBorderColor: Color(0xFF361858),
      isDark: true,
    ),
    VerseCardTheme(
      id: 'andalusian_teal',
      name: 'تركواز أندلسي راقي',
      backgroundColor: Color(0xFF04262A),
      backgroundGradient: [Color(0xFF073A40), Color(0xFF021B1E)],
      goldColor: Color(0xFFE5C07B),
      titleColor: Color(0xFFE5C07B),
      basmalaColor: Color(0xFFF5E0B3),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFE5C07B),
      sadaqaColor: Color(0xFFF5E0B3),
      footerColor: Color(0xFF88A8AB),
      dividerColor: Color(0xFF14535B),
      sideLineColor: Color(0x66E5C07B),
      cardBorderColor: Color(0xFF0E4A52),
      isDark: true,
    ),
    VerseCardTheme(
      id: 'charcoal_gold',
      name: 'فحمي داكن مع ذهب',
      backgroundColor: Color(0xFF141416),
      backgroundGradient: [Color(0xFF1E1E22), Color(0xFF0E0E10)],
      goldColor: Color(0xFFFBBF24),
      titleColor: Color(0xFFFBBF24),
      basmalaColor: Color(0xFFFDE68A),
      textColor: Colors.white,
      ayahNumColor: Color(0xFFFBBF24),
      sadaqaColor: Color(0xFFFDE68A),
      footerColor: Color(0xFF9CA3AF),
      dividerColor: Color(0xFF3F3F46),
      sideLineColor: Color(0x66FBBF24),
      cardBorderColor: Color(0xFF27272A),
      isDark: true,
    ),
  ];
}

/// نموذج خيار نسبة الأبعاد
class CardAspectRatioOption {
  final String id;
  final String label;
  final String subLabel;
  final double? ratio; // null means auto height

  const CardAspectRatioOption({
    required this.id,
    required this.label,
    required this.subLabel,
    this.ratio,
  });

  static const List<CardAspectRatioOption> allOptions = [
    CardAspectRatioOption(
      id: 'auto',
      label: 'تلقائي',
      subLabel: 'حسب النص',
      ratio: null,
    ),
    CardAspectRatioOption(
      id: 'story',
      label: '9:16',
      subLabel: 'ستوري / حالة',
      ratio: 9.0 / 16.0,
    ),
    CardAspectRatioOption(
      id: 'post_portrait',
      label: '4:5',
      subLabel: 'منشور طولي',
      ratio: 4.0 / 5.0,
    ),
    CardAspectRatioOption(
      id: 'square',
      label: '1:1',
      subLabel: 'مربع',
      ratio: 1.0,
    ),
    CardAspectRatioOption(
      id: 'portrait_3_4',
      label: '3:4',
      subLabel: 'عمودي',
      ratio: 3.0 / 4.0,
    ),
    CardAspectRatioOption(
      id: 'wide',
      label: '16:9',
      subLabel: 'عريض',
      ratio: 16.0 / 9.0,
    ),
  ];
}

/// نافذة "شارك الآية كصورة" التفاعلية الفاخرة
/// تدعم ثيمات متعددة، نسب أبعاد مختلفة (ستوري 9:16، منشور 4:5، مربع 1:1، وغيرها)، وأدوات تحكم مرنة وتصدير عالي الدقة
class QuranVerseShareSheet extends StatefulWidget {
  final String surahName;
  final int ayahNum;
  final String ayahText;
  final int? juz;

  const QuranVerseShareSheet({
    super.key,
    required this.surahName,
    required this.ayahNum,
    required this.ayahText,
    this.juz,
  });

  /// فتح النافذة المنبثقة السفلية
  static void show(
    BuildContext context, {
    required String surahName,
    required int ayahNum,
    required String ayahText,
    int? juz,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuranVerseShareSheet(
        surahName: surahName,
        ayahNum: ayahNum,
        ayahText: ayahText,
        juz: juz,
      ),
    );
  }

  @override
  State<QuranVerseShareSheet> createState() => _QuranVerseShareSheetState();
}

class _QuranVerseShareSheetState extends State<QuranVerseShareSheet> {
  final GlobalKey _cardKey = GlobalKey();

  // خيارات التحكم التفاعلية
  VerseCardTheme _selectedTheme = VerseCardTheme.allThemes[0];
  CardAspectRatioOption _selectedRatio = CardAspectRatioOption.allOptions[0];
  bool _showBasmala = true;
  bool _showSadaqallah = true;
  int _scaleValue = 78;
  double _fontSize = 20.0;
  bool _isJustified = true;
  bool _isExporting = false;

  /// تحويل الأرقام إلى أرقام عربية مشرقية
  String _toArabicDigits(dynamic number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((char) {
      final d = int.tryParse(char);
      return d != null ? arabicDigits[d] : char;
    }).join('');
  }

  /// التقاط بطاقة الآية الكريمة بدقة عالية pixelRatio: 3.0
  Future<File?> _capturePngFile() async {
    try {
      await Future.delayed(const Duration(milliseconds: 120));

      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'noor_alatra_ayah_${widget.surahName}_${widget.ayahNum}_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error capturing ayah image: $e');
      return null;
    }
  }

  /// مشاركة الصورة مباشرة مع التطبيقات
  Future<void> _shareImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final file = await _capturePngFile();
      if (file == null) {
        throw Exception('فشل في معالجة وتصدير صورة الآية');
      }

      final shareText = 'سورة ${widget.surahName} - آية ${widget.ayahNum}\nتطبيق نور العترة';
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: shareText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر مشاركة الصورة: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// تحميل وحفظ الصورة في ذاكرة الجهاز
  Future<void> _downloadImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final file = await _capturePngFile();
      if (file == null) {
        throw Exception('فشل في التقاط الصورة');
      }

      Directory? targetDir;
      try {
        if (Platform.isAndroid) {
          final pictures = Directory('/storage/emulated/0/Pictures/NoorAlAtra');
          if (!pictures.existsSync()) {
            pictures.createSync(recursive: true);
          }
          targetDir = pictures;
        }
      } catch (_) {}

      targetDir ??= await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFile = File('${targetDir.path}/ayah_${widget.surahName}_${widget.ayahNum}_$timestamp.png');
      await file.copy(savedFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4ADE80)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم تحميل وحفظ الصورة بنجاح في جهازك 🖼️',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F3D24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الصورة: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F9FD);
    final cardRowBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF4FA);
    final cardRowBorder = isDark ? const Color(0xFF334155) : const Color(0xFFD3E7F8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. شريط السحب والعنوان
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الإغلاق (X)
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white70 : const Color(0xFF64748B), size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // عنوان النافذة
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'شارك الآية كصورة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF0284C7),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. محتوى النافذة القابل للتمرير
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. شريط اختيار الثيمات
                  _buildSectionHeader('اختر نمط ولون البطاقة (الثيم):', isDark),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      itemCount: VerseCardTheme.allThemes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final theme = VerseCardTheme.allThemes[idx];
                        final isSelected = theme.id == _selectedTheme.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedTheme = theme),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0284C7)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: theme.backgroundColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.goldColor,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  theme.name,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // B. شريط اختيار نسب الأبعاد (Aspect Ratio Selector)
                  _buildSectionHeader('نسبة أبعاد الصورة (حجم المنشور / الستوري):', isDark),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      itemCount: CardAspectRatioOption.allOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final option = CardAspectRatioOption.allOptions[idx];
                        final isSelected = option.id == _selectedRatio.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedRatio = option),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  option.ratio == (9.0 / 16.0)
                                      ? Icons.smartphone_rounded
                                      : (option.ratio == 1.0 ? Icons.crop_square_rounded : Icons.aspect_ratio_rounded),
                                  size: 14,
                                  color: isSelected ? Colors.black87 : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${option.label} (${option.subLabel})',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.black87
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // C. أدوات التحكم التفاعلية
                  // خيار 1: إظهار البسملة أعلى الصورة
                  _buildControlCard(
                    isDark: isDark,
                    bg: cardRowBg,
                    border: cardRowBorder,
                    title: 'إظهار البسملة أعلى الصورة',
                    textColor: textPrimary,
                    control: _AppSwitch(
                      value: _showBasmala,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (v) => setState(() => _showBasmala = v),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // خيار 2: إضافة صدق الله العلي العظيم
                  _buildControlCard(
                    isDark: isDark,
                    bg: cardRowBg,
                    border: cardRowBorder,
                    title: 'إضافة صدق الله العلي العظيم',
                    textColor: textPrimary,
                    control: _AppSwitch(
                      value: _showSadaqallah,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (v) => setState(() => _showSadaqallah = v),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // خيار 3: حجم نص الآية (+ 78 -)
                  _buildControlCard(
                    isDark: isDark,
                    bg: cardRowBg,
                    border: cardRowBorder,
                    title: 'حجم نص الآية:',
                    textColor: textPrimary,
                    control: _buildStepper(isDark),
                  ),

                  const SizedBox(height: 8),

                  // خيار 4: كشيدة ومحاذاة النص
                  _buildControlCard(
                    isDark: isDark,
                    bg: cardRowBg,
                    border: cardRowBorder,
                    title: 'كشيدة ومحاذاة النص:',
                    textColor: textPrimary,
                    control: _AppSwitch(
                      value: _isJustified,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (v) => setState(() => _isJustified = v),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // D. معاينة بطاقة المصحف الشريف المذهبة بالثيم والنسب المحددة
                  Center(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _buildVerseCardContent(),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          // 3. أزرار الإجراءات السفلية (مشاركة الصورة / تحميل الصورة)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    // زر مشاركة الصورة
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1EBFB),
                            foregroundColor: const Color(0xFF7C3AED),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: _isExporting ? null : _shareImage,
                          icon: _isExporting
                              ? const SizedBox.shrink()
                              : const Icon(Icons.share_rounded, size: 18, color: Color(0xFF7C3AED)),
                          label: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                                  ),
                                )
                              : const Text(
                                  'مشاركة الصورة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // زر تحميل الصورة
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: _isExporting ? null : _downloadImage,
                          icon: _isExporting
                              ? const SizedBox.shrink()
                              : const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                          label: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'تحميل الصورة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
      ),
    );
  }

  /// بناء بطاقة الآية مع دعم نسب الأبعاد المختلفة والثيم المختار
  Widget _buildVerseCardContent() {
    final theme = _selectedTheme;
    final ratio = _selectedRatio.ratio;

    final contentColumn = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. ترويسة البطاقة
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '۞  نور العترة  ۞',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: theme.titleColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'سورة ${widget.surahName} • الآية ${_toArabicDigits(widget.ayahNum)}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: theme.goldColor.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 0.8,
              color: theme.dividerColor,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 2. البسملة والنص القرآني والتذييل
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // البسملة المباركة
            if (_showBasmala) ...[
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: _fontSize,
                  fontWeight: FontWeight.normal,
                  height: 2.0,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // النص القرآني المبارك محاط بخطي تأطير جانبيين
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // خط جانبي أيمن
                  Positioned(
                    right: 2,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 1,
                      color: theme.sideLineColor,
                    ),
                  ),
                  // خط جانبي أيسر
                  Positioned(
                    left: 2,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 1,
                      color: theme.sideLineColor,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text.rich(
                        TextSpan(
                          text: widget.ayahText,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: _fontSize,
                            fontWeight: FontWeight.normal,
                            height: 2.25,
                            color: theme.textColor,
                            letterSpacing: _isJustified ? 0.3 : 0.0,
                          ),
                          children: [
                            const TextSpan(text: ' '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: AyahNumberSymbol(
                                ayahNumber: widget.ayahNum,
                                size: (_fontSize * 1.25).clamp(24.0, 48.0),
                                symbolColor: theme.ayahNumColor,
                                numberColor: theme.ayahNumColor,
                              ),
                            ),
                          ],
                        ),
                        textAlign: _isJustified ? TextAlign.center : TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // إضافة صدق الله العلي العظيم
            if (_showSadaqallah) ...[
              const SizedBox(height: 10),
              Text(
                'صَدَقَ اللَّهُ العَلِيُّ العَظِيمُ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: _fontSize * 0.92,
                  fontWeight: FontWeight.normal,
                  height: 2.0,
                  color: theme.textColor,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // 3. فاصل وتذييل البطاقة
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 0.8,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 6),
            Text(
              'تطبيق نور العترة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.footerColor,
              ),
            ),
          ],
        ),
      ],
    );

    final cardInner = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        gradient: theme.backgroundGradient != null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.backgroundGradient!,
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.cardBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _IslamicGildedBorderPainter(
          goldColor: theme.goldColor,
          cornerRadius: 14.0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: ratio != null
              ? Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 380,
                      child: contentColumn,
                    ),
                  ),
                )
              : contentColumn,
        ),
      ),
    );

    if (ratio != null) {
      return AspectRatio(
        aspectRatio: ratio,
        child: cardInner,
      );
    }

    return cardInner;
  }

  /// صف بطاقة التحكم الموحدة
  Widget _buildControlCard({
    required bool isDark,
    required Color bg,
    required Color border,
    required String title,
    required Color textColor,
    required Widget control,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            control,
          ],
        ),
      ),
    );
  }

  /// أداة التحكم بحجم نص الآية (+ 78 -)
  Widget _buildStepper(bool isDark) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر التكبير (+)
            InkWell(
              onTap: () {
                setState(() {
                  _scaleValue = (_scaleValue + 4).clamp(50, 120);
                  _fontSize = (_fontSize + 1.0).clamp(14.0, 32.0);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Icon(Icons.add, size: 16, color: Color(0xFF0284C7)),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$_scaleValue',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : const Color(0xFF0284C7),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            // زر التصغير (-)
            InkWell(
              onTap: () {
                setState(() {
                  _scaleValue = (_scaleValue - 4).clamp(50, 120);
                  _fontSize = (_fontSize - 1.0).clamp(14.0, 32.0);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Icon(Icons.remove, size: 16, color: Color(0xFF0284C7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مفتاح التبديل الأنيق المخصص
class _AppSwitch extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _AppSwitch({
    required this.value,
    this.activeColor = const Color(0xFF0284C7),
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: value ? activeColor : const Color(0xFF94A3B8).withValues(alpha: 0.3),
            border: Border.all(
              color: value ? activeColor : const Color(0xFF94A3B8).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// رسام الإطار المذهب الإسلامي مع زوايا تزيينية دقيقة
class _IslamicGildedBorderPainter extends CustomPainter {
  final Color goldColor;
  final double cornerRadius;

  _IslamicGildedBorderPainter({
    required this.goldColor,
    this.cornerRadius = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintLineOuter = Paint()
      ..color = goldColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const outerInset = 6.0;
    const innerInset = 10.0;

    // الإطار الخارجي الناعم
    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(outerInset, outerInset, size.width - outerInset * 2, size.height - outerInset * 2),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(outerRRect, paintLineOuter);

    // الإطار الداخلي المذهب الأساسي
    final innerRect = Rect.fromLTWH(
      innerInset,
      innerInset,
      size.width - innerInset * 2,
      size.height - innerInset * 2,
    );
    canvas.drawRect(innerRect, paintLine);

    // نقاط الزوايا التزيينية الأربع
    final cornerPoints = [
      const Offset(innerInset, innerInset),
      Offset(size.width - innerInset, innerInset),
      Offset(innerInset, size.height - innerInset),
      Offset(size.width - innerInset, size.height - innerInset),
    ];

    final paintFill = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    for (final point in cornerPoints) {
      canvas.drawCircle(point, 3.5, paintLine);
      canvas.drawCircle(point, 1.2, paintFill);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicGildedBorderPainter oldDelegate) =>
      goldColor != oldDelegate.goldColor || cornerRadius != oldDelegate.cornerRadius;
}