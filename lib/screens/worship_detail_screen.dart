import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/worship_item.dart';
import '../models/worship_audio.dart';
import '../providers/worship_provider.dart';
import '../services/data_service.dart';
import '../services/audio_player_service.dart';

class WorshipDetailScreen extends StatefulWidget {
  final WorshipItem item;
  final bool? showAudio;

  const WorshipDetailScreen({super.key, required this.item, this.showAudio});

  @override
  State<WorshipDetailScreen> createState() => _WorshipDetailScreenState();
}

class _WorshipDetailScreenState extends State<WorshipDetailScreen> {
  double _fontSize = 20.0;

  static String _stripDiacritics(String str) {
    return str.replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0640]'), '');
  }

  static String _removeLeadingBasmala(String text) {
    var trimmed = text.trim();
    final cleanWithoutDiacritics = _stripDiacritics(trimmed).replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanWithoutDiacritics.startsWith('بسم الله الرحمن الرحيم') ||
        cleanWithoutDiacritics.startsWith('باسم الله الرحمن الرحيم')) {
      final isLongForm = cleanWithoutDiacritics.startsWith('باسم الله الرحمن الرحيم');
      final targetLength = isLongForm ? 23 : 22; // length of stripped basmala string
      int nonDiacriticCount = 0;
      int cutIndex = 0;

      for (int i = 0; i < trimmed.length; i++) {
        final char = trimmed[i];
        if (!RegExp(r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0640]').hasMatch(char)) {
          nonDiacriticCount++;
        }
        if (nonDiacriticCount >= targetLength) {
          cutIndex = i + 1;
          break;
        }
      }

      if (cutIndex > 0 && cutIndex <= trimmed.length) {
        return trimmed.substring(cutIndex).trim();
      }
    } else if (cleanWithoutDiacritics.startsWith('﷽')) {
      return trimmed.replaceFirst('﷽', '').trim();
    }

    return trimmed;
  }

  static String _cleanArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0640]'), '')
        .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u0649\u064a]'), 'ي')
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
        .trim();
  }

  static bool _isAudioExcluded(String title, String categoryKey) {
    final lowerCat = categoryKey.toLowerCase();
    if (lowerCat == 'azkarlist' ||
        lowerCat.contains('azkar') ||
        lowerCat.contains('adhkar') ||
        lowerCat == 'salawatonhujaj' ||
        lowerCat.contains('salawat') ||
        lowerCat == 'sahifasajjadiya' ||
        lowerCat.contains('sahifa') ||
        lowerCat.contains('sajjadiya') ||
        lowerCat.contains('tasbeehat') ||
        lowerCat.contains('taqeebat') ||
        lowerCat.startsWith('aamal') ||
        lowerCat.contains('aamal') ||
        lowerCat.contains('rules') ||
        lowerCat.contains('fasting') ||
        lowerCat.contains('hajj')) {
      return true;
    }

    final clean = _cleanArabic(title);
    if (clean.startsWith('اذكار') ||
        clean.startsWith('ذكر') ||
        clean.startsWith('تسبيح') ||
        clean.contains('الاستغفار') ||
        clean.contains('الصلاه علي') ||
        clean.contains('صلوات') ||
        clean.startsWith('الدعاء ') ||
        clean.contains('لا حول ولا قوه') ||
        clean.contains('لا اله الا الله')) {
      return true;
    }
    return false;
  }

  List<WorshipAudioItem> _getMatchingAudios(String title, [String categoryKey = '']) {
    if (_isAudioExcluded(title, categoryKey)) {
      return [];
    }

    final cleanTitle = _cleanArabic(title);
    final allAudios = DataService().worshipAudios;

    // Direct matches: exact title or full-name mutual containment
    // e.g. "دعاء كميل" with "دعاء كميل بن زياد", "حديث الكساء" with "حديث الكساء اليماني"
    final directMatches = allAudios.where((a) {
      final cleanA = _cleanArabic(a.title);
      return cleanA == cleanTitle ||
          cleanA.contains(cleanTitle) ||
          cleanTitle.contains(cleanA);
    }).toList();

    return directMatches;
  }

  void _showRecitersSheet(
    BuildContext context,
    List<WorshipAudioItem> audios,
    AudioPlayerService audioService,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: audioService,
          builder: (context, _) {
            final currentUrl = audioService.currentTrack?.url;
            final isServicePlaying = audioService.isPlaying;

            return Container(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Sheet Title & Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.headset_mic_rounded,
                              color: Color(0xFF059669),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اختر القارئ المبارك',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF1B3A57),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.item.title} • (${audios.length} قراء متاحين)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24, thickness: 1),

                    // Reciters List
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: audios.length,
                        itemBuilder: (context, idx) {
                          final audio = audios[idx];
                          final isThisTrackCurrent = audio.url == currentUrl;
                          final isThisTrackPlaying = isThisTrackCurrent && isServicePlaying;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isThisTrackCurrent
                                  ? const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08)
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isThisTrackCurrent
                                    ? const Color(0xFF059669).withValues(alpha: 0.6)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: isThisTrackCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isThisTrackCurrent
                                        ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                        : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    isThisTrackPlaying
                                        ? Icons.graphic_eq_rounded
                                        : Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                audio.reciterName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isThisTrackCurrent ? FontWeight.w900 : FontWeight.bold,
                                  color: isThisTrackCurrent
                                      ? const Color(0xFF059669)
                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                              ),
                              subtitle: Text(
                                isThisTrackPlaying
                                    ? 'جارٍ الاستماع الآن 🔊'
                                    : (audio.description.isNotEmpty
                                        ? audio.description
                                        : 'تسجيل صوتي خاشع'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isThisTrackPlaying
                                      ? const Color(0xFF059669)
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                              ),
                              trailing: InkWell(
                                onTap: () {
                                  if (isThisTrackPlaying) {
                                    audioService.pause();
                                  } else if (isThisTrackCurrent) {
                                    audioService.resume();
                                  } else {
                                    audioService.playTrack(AudioTrackInfo(
                                      title: widget.item.title,
                                      subtitle: audio.reciterName,
                                      url: audio.url,
                                      category: audio.categoryArabic,
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('جارٍ تشغيل ${widget.item.title} بصوت ${audio.reciterName}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isThisTrackPlaying
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isThisTrackPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isThisTrackPlaying ? 'إيقاف' : 'تشغيل',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Quick Active Mini Player in sheet if track active
                    if (currentUrl != null && audios.any((a) => a.url == currentUrl)) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(audioService.position),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatDuration(audioService.duration),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: const Color(0xFF059669),
                                  inactiveTrackColor: Colors.grey.shade300,
                                  thumbColor: const Color(0xFF059669),
                                ),
                                child: Slider(
                                  min: 0.0,
                                  max: audioService.duration.inMilliseconds > 0
                                      ? audioService.duration.inMilliseconds.toDouble()
                                      : 1.0,
                                  value: audioService.position.inMilliseconds
                                      .clamp(0, audioService.duration.inMilliseconds > 0 ? audioService.duration.inMilliseconds : 1)
                                      .toDouble(),
                                  onChanged: (val) {
                                    audioService.seek(Duration(milliseconds: val.toInt()));
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.stop_rounded),
                                    color: Colors.red.shade400,
                                    onPressed: () => audioService.stop(),
                                    tooltip: 'إيقاف تام',
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    iconSize: 42,
                                    icon: Icon(
                                      isServicePlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                    ),
                                    color: const Color(0xFF059669),
                                    onPressed: () => audioService.togglePlayPause(),
                                    tooltip: isServicePlaying ? 'إيقاف مؤقت' : 'تشغيل',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorshipProvider>();
    final isFav = provider.isFavorite(widget.item.title);
    final audioService = AudioPlayerService();

    final isAudioDisabled = (widget.showAudio == false) ||
        _isAudioExcluded(widget.item.title, widget.item.categoryKey);

    final matchingAudios = isAudioDisabled
        ? <WorshipAudioItem>[]
        : _getMatchingAudios(widget.item.title, widget.item.categoryKey);
    final hasAudio = matchingAudios.isNotEmpty && !isAudioDisabled;

    // Clean text and extract body without duplicate Basmala
    final cleanText = widget.item.text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    final String bodyContent = _removeLeadingBasmala(cleanText);
    final List<String> paragraphs = bodyContent
        .split(RegExp(r'\n\s*\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: audioService,
        builder: (context, _) {
          final currentUrl = audioService.currentTrack?.url;
          final isThisItemActive = currentUrl != null && matchingAudios.any((a) => a.url == currentUrl);
          final isPlaying = isThisItemActive && audioService.isPlaying;
          final currentReciterName = isThisItemActive ? audioService.currentTrack?.subtitle : null;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0.5,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleSpacing: 2,
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
                tooltip: 'رجوع',
                color: isDark ? Colors.white : const Color(0xFF1B3A57),
              ),
              title: Text(
                widget.item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                children: [
                // Unified Full-Width Luxury Control Toolbar Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFD6E8F3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Font Size Control (Right side in RTL)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.format_size_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                            ),
                            const SizedBox(width: 4),
                            // Decrease Font Button (-)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _fontSize = (_fontSize - 1).clamp(14.0, 36.0);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Font Size Number Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_fontSize.toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Increase Font Button (+)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _fontSize = (_fontSize + 1).clamp(14.0, 36.0);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Vertical subtle divider
                        Container(
                          height: 22,
                          width: 1.2,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFD0E0EC),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),

                        // 2. Action Tools Group (Left side in RTL: Favorite + Copy + Share + Audio)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Favorite Tool
                            InkWell(
                              onTap: () {
                                final wasFav = isFav;
                                provider.toggleFavorite(widget.item.title);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      wasFav
                                          ? 'تمت الإزالة من المفضلة 💔'
                                          : 'تمت الإضافة إلى المفضلة بنجاح ❤️',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: isFav
                                      ? Colors.red.withValues(alpha: 0.12)
                                      : (isDark ? const Color(0xFF334155) : Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFav
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 15,
                                  color: isFav ? Colors.red : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),

                            // Copy Tool
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: '${widget.item.title}\n\n$cleanText'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ النص المبارك إلى الحافظة 📋'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),

                            // Share Tool
                            InkWell(
                              onTap: () {
                                Share.share('${widget.item.title}\n\n$cleanText');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.share_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                                ),
                              ),
                            ),

                            // Interactive Audio Control Button
                            if (hasAudio) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  if (matchingAudios.length > 1) {
                                    _showRecitersSheet(context, matchingAudios, audioService, isDark);
                                  } else {
                                    final singleAudio = matchingAudios.first;
                                    if (isPlaying) {
                                      audioService.pause();
                                    } else if (isThisItemActive) {
                                      audioService.resume();
                                    } else {
                                      audioService.playTrack(AudioTrackInfo(
                                        title: widget.item.title,
                                        subtitle: singleAudio.reciterName,
                                        url: singleAudio.url,
                                        category: singleAudio.categoryArabic,
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('جارٍ تشغيل: ${singleAudio.reciterName}'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isPlaying ? Colors.red : const Color(0xFF059669))
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        isPlaying
                                            ? 'إيقاف'
                                            : (matchingAudios.length > 1
                                                ? 'صوت (${matchingAudios.length})'
                                                : 'صوت'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (matchingAudios.length > 1) ...[
                                        const SizedBox(width: 1),
                                        const Icon(
                                          Icons.arrow_drop_down_rounded,
                                          color: Colors.white70,
                                          size: 15,
                                        ),
                                      ],
                                    ],
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

                // Worship Text Content inside clean paper card
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(14, 6, 14, MediaQuery.of(context).padding.bottom + 50),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Elegant Section Title Header
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                widget.item.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Always Prominent Centered Basmala
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF132238)
                                    : const Color(0xFFF0F7FB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.3)
                                      : const Color(0xFFB88E4C).withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: (_fontSize * 1.1).clamp(18.0, 32.0),
                                  height: 1.4,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFE5C882) : const Color(0xFF8C621E),
                                ),
                              ),
                            ),
                          ),

                          // Worship Text with clean natural Kashida, close line spacing & clear paragraph boundaries
                          SelectionArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (int i = 0; i < paragraphs.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  Text(
                                    paragraphs[i],
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: _fontSize,
                                      height: 1.78,
                                      letterSpacing: 0.1,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Active Audio Bottom Floating Bar (if audio is currently playing/active)
                if (isThisItemActive)
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: isDark ? 0.25 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF059669),
                              ),
                              child: Icon(
                                isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentReciterName ?? widget.item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_formatDuration(audioService.position)} / ${_formatDuration(audioService.duration)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                color: const Color(0xFF059669),
                                size: 32,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  audioService.togglePlayPause();
                                } else {
                                  if (matchingAudios.length > 1) {
                                    _showRecitersSheet(context, matchingAudios, audioService, isDark);
                                  } else {
                                    audioService.togglePlayPause();
                                  }
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              onPressed: () => audioService.stop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}
