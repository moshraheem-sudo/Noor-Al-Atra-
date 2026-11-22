import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quran_chapter.dart';
import '../models/reciter.dart';
import '../services/audio_player_manager.dart';
import '../services/quran_api_service.dart';
import '../services/quran_audio_download_service.dart';
import '../widgets/mini_audio_player.dart';

class ReciterDetailScreen extends StatefulWidget {
  final ReciterItem reciter;

  const ReciterDetailScreen({super.key, required this.reciter});

  @override
  State<ReciterDetailScreen> createState() => _ReciterDetailScreenState();
}

class _ReciterDetailScreenState extends State<ReciterDetailScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedStyleIndex = 0;
  final Set<int> _bookmarkedSurahIds = {};

  List<ReciterStyle> _styles = [];
  bool _isLoadingStyles = true;

  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    setState(() => _isLoadingStyles = true);
    final fetched = await QuranApiService.getReciterStyles(widget.reciter.id);
    if (mounted) {
      setState(() {
        if (fetched.isNotEmpty) {
          _styles = fetched;
        } else {
          // Fallback style with reciter's actual audio server
          _styles = [
            ReciterStyle(
              id: 1,
              name: 'حفص عن عاصم - مرتل',
              server: widget.reciter.defaultServer,
              surahList: List.generate(114, (i) => '${i + 1}').join(','),
            ),
          ];
        }
        _isLoadingStyles = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final player = AudioPlayerManager();
    final downloadService = context.watch<QuranAudioDownloadService>();

    final currentStyle = _styles.isNotEmpty && _selectedStyleIndex < _styles.length
        ? _styles[_selectedStyleIndex]
        : null;

    final availableSurahs = currentStyle?.availableSurahs ?? List.generate(114, (i) => i + 1);

    final filteredSurahIds = availableSurahs.where((id) {
      final chapter = QuranChapter.allChapters.firstWhere(
        (c) => c.id == id,
        orElse: () => QuranChapter(id: id, nameArabic: '$id', nameSimple: '', revelationPlace: '', versesCount: 0),
      );
      if (_searchQuery.trim().isEmpty) return true;
      return chapter.nameArabic.contains(_searchQuery.trim()) ||
          chapter.id.toString() == _searchQuery.trim() ||
          chapter.nameSimple.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    final downloadedCount = downloadService.getCachedDownloadedCount(widget.reciter.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar with Back Button & Reciter Name
            _buildHeader(context, isDark),

            // 2. Narration / Style Tabs (حفص عن عاصم • المصحف المجود)
            if (_styles.isNotEmpty) _buildStyleTabs(isDark),

            // 3. Quick Search Box
            _buildSearchBox(isDark),

            // 4. Download Full Quran Card (0 / 114 سورة)
            _buildDownloadCard(context, downloadedCount, downloadService, isDark),

            // 5. Surah Items List
            Expanded(
              child: _isLoadingStyles
                  ? const Center(child: CircularProgressIndicator())
                  : ListenableBuilder(
                      listenable: player,
                      builder: (context, _) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filteredSurahIds.length,
                          itemBuilder: (context, index) {
                            final surahId = filteredSurahIds[index];
                            final chapter = QuranChapter.allChapters.firstWhere(
                              (c) => c.id == surahId,
                              orElse: () => QuranChapter(id: surahId, nameArabic: '$surahId', nameSimple: '', revelationPlace: '', versesCount: 0),
                            );

                            final isPlayingThis = player.isPlaying &&
                                player.currentSurahId == surahId &&
                                player.currentReciter?.id == widget.reciter.id;

                            final isDownloaded = downloadService.isSurahDownloaded(widget.reciter.id, surahId);
                            final isBookmarked = _bookmarkedSurahIds.contains(surahId);

                            return _buildSurahCard(
                              chapter: chapter,
                              surahId: surahId,
                              isPlaying: isPlayingThis,
                              isDownloaded: isDownloaded,
                              isBookmarked: isBookmarked,
                              isDark: isDark,
                              currentStyle: currentStyle,
                              player: player,
                              downloadService: downloadService,
                            );
                          },
                        );
                      },
                    ),
            ),

            // 6. Floating Mini Audio Player above bottom
            const MiniAudioPlayer(autoBottomInset: true),
          ],
        ),
      ),
    );
  }

  // --- 1. Header with Back button and Name ---
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 24),
            color: isDark ? Colors.white : const Color(0xFF1B3A57),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.reciter.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1B3A57),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Narration / Style Tabs (حفص عن عاصم • ورش عن نافع • المصحف المجود) ---
  Widget _buildStyleTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_styles.length, (idx) {
            final s = _styles[idx];
            final isSelected = (_selectedStyleIndex == idx);

            return InkWell(
              onTap: () => setState(() => _selectedStyleIndex = idx),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57))
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      s.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                            : (isDark ? Colors.white60 : const Color(0xFF7A8B99)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- 3. Search Box matching Image 1 ---
  Widget _buildSearchBox(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE1EFF7),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 13.5,
          color: isDark ? Colors.white : const Color(0xFF1B3A57),
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة بالاسم أو الرقم..',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white60 : const Color(0xFF1B3A57),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // --- 4. Download Full Quran Card with Live Progress & Controls ---
  Widget _buildDownloadCard(
    BuildContext context,
    int downloadedCount,
    QuranAudioDownloadService downloadService,
    bool isDark,
  ) {
    final isThisReciterActive = downloadService.currentReciter?.id == widget.reciter.id &&
        (downloadService.isDownloading || downloadService.isPaused);

    if (isThisReciterActive) {
      final percent = (downloadService.progress * 100).toInt();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132338) : const Color(0xFFF0F7FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Icon(
                  downloadService.isPaused
                      ? Icons.pause_circle_filled_rounded
                      : Icons.cloud_download_rounded,
                  color: const Color(0xFF0284C7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    downloadService.statusMessage ?? 'جاري تنزيل المصحف...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: downloadService.progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFDDEBF7),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
              ),
            ),
            const SizedBox(height: 10),

            // Controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${downloadService.currentSurahIndex} من ١١٤ سورة',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                Row(
                  children: [
                    // Pause / Resume Button
                    InkWell(
                      onTap: () {
                        if (downloadService.isPaused) {
                          downloadService.resumeDownload();
                        } else {
                          downloadService.pauseDownload();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDDEBF7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              downloadService.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 16,
                              color: const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              downloadService.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cancel Button
                    InkWell(
                      onTap: () => downloadService.cancelDownload(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3B1E28) : const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    final isAllDownloaded = downloadedCount >= 114;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAllDownloaded
              ? (isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE1EFF7)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showDownloadAllDialog(context, downloadService, isDark),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isAllDownloaded ? Icons.cloud_done_rounded : Icons.cloud_download_outlined,
                  color: isAllDownloaded
                      ? const Color(0xFF16A34A)
                      : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57)),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAllDownloaded
                        ? 'المصحف محمل بالكامل (١١٤ سورة) جاهز للاستماع دون إنترنت'
                        : 'تنزيل وحجم ملفات القرآن الكريم ($downloadedCount / 114 سورة)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isAllDownloaded
                          ? const Color(0xFF16A34A)
                          : (isDark ? Colors.white : const Color(0xFF1B3A57)),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.white60 : const Color(0xFF1B3A57),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final Set<int> _sharingSurahIds = {};

  // --- 5. Surah Item Card matching Image 1 ---
  Widget _buildSurahCard({
    required QuranChapter chapter,
    required int surahId,
    required bool isPlaying,
    required bool isDownloaded,
    required bool isBookmarked,
    required bool isDark,
    required ReciterStyle? currentStyle,
    required AudioPlayerManager player,
    required QuranAudioDownloadService downloadService,
  }) {
    final isDownloading = downloadService.isSurahDownloading(widget.reciter.id, surahId);
    final downloadProgress = downloadService.getSurahDownloadProgress(widget.reciter.id, surahId);
    final isSharing = _sharingSurahIds.contains(surahId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFF1B3A57)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE8F4F8)),
          width: isPlaying ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Right Title: Name of Surah
            Expanded(
              child: Text(
                'سورة ${chapter.nameArabic}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                ),
              ),
            ),

            // 4 Actions on the left
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Play Button
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD9EEF9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3A57),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (isPlaying) {
                        player.togglePlayPause();
                      } else {
                        final localPath = downloadService.getLocalSurahPath(widget.reciter.id, surahId);
                        player.playSurah(
                          surahId: surahId,
                          reciter: widget.reciter,
                          style: currentStyle,
                          localPath: localPath,
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(width: 4),

                // 2. Share Audio File Button
                isSharing
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: isDark ? Colors.white70 : const Color(0xFF1B3A57),
                          size: 20,
                        ),
                        tooltip: 'مشاركة التلاوة كملف صوتي',
                        onPressed: () => _shareSurahAsAudio(
                          chapter: chapter,
                          surahId: surahId,
                          currentStyle: currentStyle,
                          downloadService: downloadService,
                        ),
                      ),

                // 3. Download Button with live circular progress
                if (isDownloading)
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      value: (downloadProgress != null && downloadProgress > 0)
                          ? downloadProgress
                          : null,
                      strokeWidth: 2.4,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3A57),
                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      isDownloaded ? Icons.download_done_rounded : Icons.download_outlined,
                      color: isDownloaded
                          ? const Color(0xFF059669)
                          : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
                      size: 20,
                    ),
                    tooltip: isDownloaded ? 'محملة في الجهاز' : 'تنزيل السورة',
                    onPressed: isDownloaded
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('سورة ${chapter.nameArabic} محملة بالفعل وجاهزة للاستماع دون إنترنت'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        : () async {
                            await downloadService.downloadSurahDirect(
                              reciter: widget.reciter,
                              surahId: surahId,
                              serverUrl: currentStyle?.server ?? widget.reciter.defaultServer,
                            );
                          },
                  ),

                // 4. Bookmark Button
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_outlined,
                    color: isBookmarked
                        ? const Color(0xFF1B3A57)
                        : (isDark ? Colors.white70 : const Color(0xFF1B3A57)),
                    size: 20,
                  ),
                  tooltip: isBookmarked ? 'إزالة من المحفوظات' : 'حفظ في المفضلة',
                  onPressed: () {
                    setState(() {
                      if (isBookmarked) {
                        _bookmarkedSurahIds.remove(surahId);
                      } else {
                        _bookmarkedSurahIds.add(surahId);
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Share Surah directly as an audio file (.mp3)
  Future<void> _shareSurahAsAudio({
    required QuranChapter chapter,
    required int surahId,
    required ReciterStyle? currentStyle,
    required QuranAudioDownloadService downloadService,
  }) async {
    try {
      setState(() => _sharingSurahIds.add(surahId));

      String? localPath = downloadService.getLocalSurahPath(widget.reciter.id, surahId);
      if (localPath == null || !await File(localPath).exists()) {
        // Download audio first in background
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('جاري تحميل سورة ${chapter.nameArabic} لإرسالها كملف صوتي...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        final success = await downloadService.downloadSurahDirect(
          reciter: widget.reciter,
          surahId: surahId,
          serverUrl: currentStyle?.server ?? widget.reciter.defaultServer,
        );

        if (success) {
          localPath = downloadService.getLocalSurahPath(widget.reciter.id, surahId);
        }
      }

      if (localPath != null && await File(localPath).exists()) {
        final xfile = XFile(
          localPath,
          mimeType: 'audio/mpeg',
          name: '${chapter.nameArabic}_${widget.reciter.name}.mp3',
        );
        await Share.shareXFiles(
          [xfile],
          text: 'سورة ${chapter.nameArabic} بصوت القارئ ${widget.reciter.name} - تطبيق نور العترة',
        );
      } else {
        // Fallback to URL sharing if offline download was unable to complete
        final server = currentStyle?.server ?? widget.reciter.defaultServer;
        final url = QuranApiService.getSurahAudioUrl(server, surahId);
        await Share.share(
          'استمع إلى سورة ${chapter.nameArabic} بصوت القارئ ${widget.reciter.name}:\n$url',
        );
      }
    } catch (e) {
      debugPrint('Error sharing audio file: $e');
    } finally {
      if (mounted) {
        setState(() => _sharingSurahIds.remove(surahId));
      }
    }
  }

  void _showDownloadAllDialog(
    BuildContext context,
    QuranAudioDownloadService downloadService,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<QuranAudioDownloadService>(
          builder: (context, dService, _) {
            final isActive = dService.currentReciter?.id == widget.reciter.id &&
                (dService.isDownloading || dService.isPaused);
            final downloadedCount = dService.getCachedDownloadedCount(widget.reciter.id);
            final selectedStyle = _styles.isNotEmpty && _selectedStyleIndex < _styles.length
                ? _styles[_selectedStyleIndex]
                : null;
            final styleLabel = selectedStyle != null ? ' - ${selectedStyle.displayName}' : '';

            if (isActive) {
              final percent = (dService.progress * 100).toInt();
              return AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(
                      dService.isPaused
                          ? Icons.pause_circle_filled_rounded
                          : Icons.cloud_download_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'جاري تنزيل المصحف',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: isDark ? Colors.white : const Color(0xFF1B3A57),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${widget.reciter.name}$styleLabel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dService.statusMessage ?? 'جاري التنزيل...',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: dService.progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${dService.currentSurahIndex} من ١١٤ سورة',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton.icon(
                    icon: Icon(
                      dService.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 18,
                    ),
                    label: Text(dService.isPaused ? 'استئناف' : 'إيقاف مؤقت'),
                    onPressed: () {
                      if (dService.isPaused) {
                        dService.resumeDownload();
                      } else {
                        dService.pauseDownload();
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('إلغاء التحميل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      dService.cancelDownload();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              );
            }

            final isAllDownloaded = downloadedCount >= 114;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isAllDownloaded ? 'المصحف محمل بالكامل' : 'تنزيل المصحف بالكامل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF1B3A57),
                ),
              ),
              content: Text(
                isAllDownloaded
                    ? 'جميع سور القرآن الكريم (١١٤ سورة) بصوت ${widget.reciter.name}$styleLabel محملة مسبقاً وتعمل دون الحاجة لإنترنت.'
                    : 'هل ترغب في تنزيل جميع سور القرآن الكريم (١١٤ سورة) بصوت ${widget.reciter.name}$styleLabel لتشغيلها دون إنترنت؟',
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
                if (!isAllDownloaded)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_download_rounded, size: 18),
                    label: const Text('بدء التنزيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      dService.startBatchDownload(
                        widget.reciter,
                        serverUrl: selectedStyle?.server ?? widget.reciter.defaultServer,
                      );
                    },
                  ),
                if (isAllDownloaded)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    label: const Text('حذف الملفات المحملة', style: TextStyle(color: Colors.redAccent)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      dService.deleteReciterAudio(widget.reciter.id);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
