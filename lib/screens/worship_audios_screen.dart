import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/worship_audio.dart';
import '../services/data_service.dart';
import '../services/audio_player_service.dart';
import '../services/audio_player_manager.dart';
import '../services/settings_controller.dart';
import '../services/voice_search_service.dart';
import '../widgets/mini_audio_player.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../main.dart';
import 'qibla_compass_screen.dart';
import 'worship_category_detail_screen.dart';

class WorshipAudiosScreen extends StatefulWidget {
  const WorshipAudiosScreen({super.key});

  @override
  State<WorshipAudiosScreen> createState() => _WorshipAudiosScreenState();
}

class _WorshipAudiosScreenState extends State<WorshipAudiosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearching = false;
  final Map<int, WorshipReciterOption> _selectedReciters = {};

  final Set<String> _downloadingAudioKeys = {};
  final Set<String> _downloadedAudioKeys = {};

  String _getAudioFileKey(WorshipAudioItem item, WorshipReciterOption reciter) =>
      '${item.id}_${reciter.reciterName.hashCode}';

  Future<File> _getLocalAudioFile(WorshipAudioItem item, WorshipReciterOption reciter) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/worship_audios');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final safeReciter = reciter.reciterName.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
    return File('${audioDir.path}/${item.id}_$safeReciter.mp3');
  }

  int _playRequest = 0;

  Future<void> _playAudio(WorshipAudioItem selected, WorshipReciterOption reciter) async {
    final request = ++_playRequest;
    final items = DataService().worshipAudios.where((item) => item.reciters.isNotEmpty).toList();
    final tracks = await Future.wait(items.map((item) async {
      final voice = item.id == selected.id ? reciter : (_getSelectedReciter(item) ?? item.reciters.first);
      var source = voice.url;
      try {
        final file = await _getLocalAudioFile(item, voice);
        if (await file.exists() && await file.length() > 1024) source = file.path;
      } catch (_) {}
      return AudioTrackInfo(title: item.title, subtitle: voice.reciterName,
        url: source, category: item.categoryArabic);
    }));
    if (!mounted || request != _playRequest) return;
    final index = items.indexWhere((item) => item.id == selected.id);
    await AudioPlayerManager().playPlaylist(tracks, index);
  }

  Future<void> _scanDownloadedAudios() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/worship_audios');
      if (await audioDir.exists()) {
        final files = audioDir.listSync();
        for (final f in files) {
          if (f is File && f.path.endsWith('.mp3') && (await f.length()) > 1024) {
            final fileName = f.uri.pathSegments.last;
            for (final item in DataService().worshipAudios) {
              if (fileName.startsWith('${item.id}_')) {
                for (final r in item.reciters) {
                  final safeReciter = r.reciterName.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
                  if (fileName.contains(safeReciter)) {
                    _downloadedAudioKeys.add(_getAudioFileKey(item, r));
                  }
                }
              }
            }
          }
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _downloadAudio(WorshipAudioItem item, WorshipReciterOption reciter) async {
    final key = _getAudioFileKey(item, reciter);
    if (_downloadingAudioKeys.contains(key)) return;

    setState(() => _downloadingAudioKeys.add(key));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ تحميل ${item.title} بصوت ${reciter.reciterName}...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final response = await http.get(Uri.parse(reciter.url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final file = await _getLocalAudioFile(item, reciter);
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _downloadedAudioKeys.add(key);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF059669),
              content: Text('تم تحميل ${item.title} بنجاح! يمكنك الآن الاستماع دون إنترنت ومشاركته كملف صوتي.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        throw Exception('رمز الاستجابة: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('تعذر تحميل الملف الصوتي: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingAudioKeys.remove(key));
      }
    }
  }

  Future<void> _shareAudioFile(WorshipAudioItem item, WorshipReciterOption reciter) async {
    final file = await _getLocalAudioFile(item, reciter);
    final isDownloaded = await file.exists() && await file.length() > 1024;

    if (isDownloaded) {
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'audio/mpeg',
            name: '${item.title}_${reciter.reciterName}.mp3',
          ),
        ],
        text: '${item.title} بصوت ${reciter.reciterName} - تطبيق نور العترة',
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'حمل الملف أولاً لمشاركته كصوت',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC09040),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'تحميل الآن',
            textColor: Colors.white,
            onPressed: () => _downloadAudio(item, reciter),
          ),
        ),
      );
    }
  }

  WorshipReciterOption? _getSelectedReciter(WorshipAudioItem item) {
    return _selectedReciters[item.id] ?? (item.reciters.isNotEmpty ? item.reciters.first : null);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _scanDownloadedAudios();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAudios = DataService().worshipAudios;
    final filtered = _searchQuery.trim().isEmpty
        ? allAudios
        : allAudios
            .where((a) =>
                a.title.contains(_searchQuery) ||
                a.description.contains(_searchQuery) ||
                a.reciters.any((r) => r.reciterName.contains(_searchQuery)))
            .toList();

    final duasList = filtered.where((a) => a.category == 'DUA').toList();
    final ziyaratsList = filtered.where((a) => a.category == 'ZIYARAH').toList();
    final munajatList = filtered.where((a) => a.category == 'MUNAJAT').toList();

    final isEmerald = context.watch<SettingsController>().themePalette == AppThemePalette.emeraldGreen;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !_isSearching,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchCtrl.clear();
              _searchQuery = '';
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isEmerald
                  ? [const Color(0xFF04140D), const Color(0xFF082216), const Color(0xFF030E09)]
                  : (isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF090D16)]
                      : [const Color(0xFFEBF7FD), const Color(0xFFE2F3F9), const Color(0xFFDCF0F9)]),
            ),
          ),
          child: Stack(
            children: [
              // Background subtle watermark
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 350,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _IslamicGeometricWatermarkPainter(
                      lineColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFF0284C7).withValues(alpha: 0.08),
                      goldColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFD4AF37).withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),

              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: _isSearching
                    ? AppBar(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        elevation: 1,
                        titleSpacing: 0,
                        automaticallyImplyLeading: false,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                          tooltip: 'إغلاق البحث',
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchCtrl.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                        title: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن دعاء، زيارة، أو مناجاة...',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white38 : const Color(0xFF64748B),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        actions: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.mic, size: 20, color: Color(0xFF0284C7)),
                            tooltip: 'البحث الصوتي',
                            onPressed: () async {
                              final spoken = await VoiceSearchService.startVoiceSearch(
                                context,
                                prompt: 'تحدث باسم المقطع أو القارئ...',
                              );
                              if (spoken != null && spoken.isNotEmpty) {
                                _searchCtrl.text = spoken;
                                setState(() => _searchQuery = spoken);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : AppBar(
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
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: Text(
                          'صوتيات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        actions: [
                          // Qibla button
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QiblaCompassScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD),
                                  width: 1.2,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.explore_outlined, size: 16, color: Color(0xFF0284C7)),
                                  SizedBox(width: 4),
                                  Text(
                                    'القبلة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search_rounded, size: 20),
                            color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                            tooltip: 'بحث في الصوتيات',
                            onPressed: () {
                              setState(() {
                                _isSearching = true;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _searchFocusNode.requestFocus();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_rounded, size: 20),
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(),
                            tooltip: 'المفضلة',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WorshipCategoryDetailScreen(
                                    title: 'المفضلة',
                                    categoryKey: 'favorites',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                body: Column(
                  children: [

                    // Tabs with count badges (Moved up directly under sub-header)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        indicatorWeight: 3.0,
                        isScrollable: true,
                        labelColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF334155),
                        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: 'الكل (${allAudios.length})'),
                          Tab(text: 'الأدعية (${duasList.length})'),
                          Tab(text: 'الزيارات (${ziyaratsList.length})'),
                          Tab(text: 'المناجاة (${munajatList.length})'),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAudioTabContent(filtered, isDark),
                          _buildAudioTabContent(duasList, isDark),
                          _buildAudioTabContent(ziyaratsList, isDark),
                          _buildAudioTabContent(munajatList, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MiniAudioPlayer(
                      bottomPadding: 6,
                      autoBottomInset: false,
                    ),
                    AppBottomNavBar(
                      currentIndex: 2,
                      onTap: (index) {
                        if (index == 2) {
                          Navigator.pop(context);
                        } else {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          MainNavigationScreen.switchTab(context, index);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioTabContent(List<WorshipAudioItem> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headset_off_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'لا توجد تسجيلات صوتية مطابقة',
                style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total audio count badge row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.volume_up_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                '${items.length} عمل صوتي مبارك',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        // List of audio cards
        Expanded(
          child: AnimatedBuilder(
            animation: AudioPlayerService(),
            builder: (context, _) {
              final player = AudioPlayerService();
              final isPlaying = player.isPlaying;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selectedReciter = _getSelectedReciter(item);
                  final isItemActive = selectedReciter != null && player.currentTrack?.title == item.title && player.currentTrack?.subtitle == selectedReciter.reciterName;
                  final isItemPlaying = isItemActive && isPlaying;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (selectedReciter == null) return;
                          if (isItemActive && isPlaying) {
                            player.pause();
                          } else {
                            _playAudio(item, selectedReciter);
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isItemActive
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              width: isItemActive ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isItemActive
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Top Section: Avatar, Full-Width Title & Category Tag
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Microphone avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isItemActive
                                          ? const Color(0xFF0284C7)
                                          : (isDark ? const Color(0xFF0B2942) : const Color(0xFFD9EEF9)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isItemPlaying ? Icons.volume_up_rounded : Icons.mic_none_rounded,
                                      color: isItemActive ? Colors.white : const Color(0xFF0284C7),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title and Reciter (Full Width Space)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_rounded,
                                              size: 15,
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                selectedReciter?.reciterName ?? item.defaultReciterName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.categoryArabic,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Description (if available) - High Contrast Dark Text in Daytime
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 0.7,
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                              const SizedBox(height: 8),

                              // 2. Bottom Action Bar: Actions aligned neatly
                              Row(
                                children: [
                                  const Spacer(),

                                  // Share button
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, size: 20),
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    tooltip: 'مشاركة كصوت',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    onPressed: () {
                                      final reciter = selectedReciter ?? (item.reciters.isNotEmpty ? item.reciters.first : null);
                                      if (reciter != null) {
                                        _shareAudioFile(item, reciter);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),

                                  // Download button with dynamic state
                                  Builder(builder: (context) {
                                    final reciter = selectedReciter ?? (item.reciters.isNotEmpty ? item.reciters.first : null);
                                    final key = reciter != null ? _getAudioFileKey(item, reciter) : '';
                                    final isDownloading = _downloadingAudioKeys.contains(key);
                                    final isDownloaded = _downloadedAudioKeys.contains(key);

                                    return IconButton(
                                      icon: isDownloading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                            )
                                          : Icon(
                                              isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                                              size: 20,
                                            ),
                                      color: isDownloaded
                                          ? const Color(0xFF059669)
                                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                      tooltip: isDownloaded ? 'تم التحميل' : 'تحميل',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      onPressed: () {
                                        if (reciter == null) return;
                                        if (isDownloaded) {
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('الملف (${item.title}) محمل مسبقاً وجاهز للمشاركة والاستماع دون إنترنت.'),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          );
                                        } else {
                                          _downloadAudio(item, reciter);
                                        }
                                      },
                                    );
                                  }),
                                  const SizedBox(width: 6),

                                  // Main Play / Pause Button: Prompts reciter selection if multiple reciters
                                  Material(
                                    color: isItemPlaying ? const Color(0xFF0284C7) : (isDark ? const Color(0xFF0B2942) : const Color(0xFFD9EEF9)),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () async {
                                        if (isItemPlaying) {
                                          player.pause();
                                        } else {
                                          if (item.hasMultipleReciters) {
                                            _showReciterSelectionSheet(context, item, isDark);
                                          } else {
                                            if (selectedReciter == null) return;
                                            _playAudio(item, selectedReciter);
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isItemPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              color: isItemPlaying ? Colors.white : const Color(0xFF0284C7),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isItemPlaying ? 'إيقاف' : 'تشغيل',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isItemPlaying ? Colors.white : const Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// نافذة منبثقة لاختيار القارئ عند توفر أكثر من صوت للدعاء أو الزيارة
  void _showReciterSelectionSheet(BuildContext context, WorshipAudioItem item, bool isDark) {
    final player = AudioPlayerService();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: player,
          builder: (context, _) {
                    final isPlaying = player.isPlaying;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header title & count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اختر القارئ • ${item.title}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.reciters.length} أصوات متوفرة للاستماع',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),

                    // List of reciters
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: item.reciters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final reciter = item.reciters[idx];
                          final isSelectedReciter = (_selectedReciters[item.id]?.url ?? item.reciters.first.url) == reciter.url;
                          final isThisCurrent = player.currentTrack?.title == item.title && player.currentTrack?.subtitle == reciter.reciterName;
                          final isThisPlaying = isThisCurrent && isPlaying;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedReciters[item.id] = reciter;
                                });
                                if (isThisPlaying) {
                                  player.pause();
                                } else {
                                  _playAudio(item, reciter);
                                }
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelectedReciter || isThisCurrent
                                      ? (isDark
                                          ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                                          : const Color(0xFFE0F2FE))
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelectedReciter || isThisCurrent
                                        ? const Color(0xFF0284C7)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    width: isSelectedReciter || isThisCurrent ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isThisPlaying
                                            ? const Color(0xFF0284C7)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFD9EEF9)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: isThisPlaying
                                            ? Colors.white
                                            : const Color(0xFF0284C7),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  reciter.reciterName,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelectedReciter)
                                                Container(
                                                  margin: const EdgeInsets.only(right: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0284C7),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'تم الاختيار',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isThisPlaying ? 'قيد الاستماع الآن 🔊' : 'اضغط لاختيار القارئ والتشغيل فوراً',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isThisPlaying
                                                  ? const Color(0xFF0284C7)
                                                  : (isDark ? Colors.white60 : const Color(0xFF475569)),
                                              fontWeight: isThisPlaying ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined, size: 18),
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      tooltip: 'مشاركة كصوت',
                                      onPressed: () {
                                        _shareAudioFile(item, reciter);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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

class _IslamicGeometricWatermarkPainter extends CustomPainter {
  final Color lineColor;
  final Color goldColor;

  _IslamicGeometricWatermarkPainter({required this.lineColor, required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final goldPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, 80);
    final radii = [50.0, 90.0, 135.0, 180.0];

    for (final r in radii) {
      canvas.drawCircle(center, r, linePaint);
    }

    for (int i = 0; i < 16; i++) {
      final angle = i * pi / 8;
      final p1 = Offset(center.dx + 35 * cos(angle), center.dy + 35 * sin(angle));
      final p2 = Offset(center.dx + 220 * cos(angle), center.dy + 220 * sin(angle));
      canvas.drawLine(p1, p2, (i % 2 == 0) ? goldPaint : linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicGeometricWatermarkPainter oldDelegate) => false;
}
