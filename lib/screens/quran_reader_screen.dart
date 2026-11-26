import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/khatma_model.dart';
import '../models/quran_chapter.dart';
import '../models/quran_sajdah.dart';
import '../models/reciter.dart';
import '../providers/quran_provider.dart';
import '../repositories/khatma_repository.dart';
import '../services/audio_player_service.dart';
import '../services/hijri_date_service.dart';
import '../services/quran_api_service.dart';
import '../widgets/ayah_number_symbol.dart';
import '../widgets/ayah_options_sheet.dart';
import '../widgets/quran_bookmarks_sheet.dart';
import '../widgets/quran_settings_sheet.dart';

class QuranReaderScreen extends StatefulWidget {
  final QuranChapter? chapter;
  final int? surahId;
  final int? initialAyah;
  final int? initialPage;
  final bool highlightKhatmaAyah;
  final bool isKhatmaMode;
  final bool isKhatmah;
  final bool autoPlayAyah;

  const QuranReaderScreen({
    super.key,
    this.chapter,
    this.surahId,
    this.initialAyah,
    this.initialPage,
    this.highlightKhatmaAyah = false,
    this.isKhatmaMode = false,
    this.isKhatmah = false,
    this.autoPlayAyah = false,
  });

  bool get isKhatmaActive => isKhatmaMode || isKhatmah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late QuranChapter _currentChapter;
  final ScrollController _scrollCtrl = ScrollController();
  int? _selectedAyahNum;
  int? _resumedKhatmaAyah;
  int? _activeRecitingAyah;
  bool _isContinuousReciting = false;
  double _readingProgress = 0.0;

  bool _showBookmarkPill = false;
  String _bookmarkPillText = 'تمت إضافة الآية للعلامات المرجعية';
  Timer? _bookmarkPillTimer;
  Timer? _scrollDebounceTimer;
  bool _isPlayerCollapsed = false;

  final Map<int, GlobalKey> _ayahKeys = {};
  final Map<int, TapGestureRecognizer> _recognizers = {};
  int _lastTapTime = 0;
  int _lastTappedAyah = -1;

  @override
  void initState() {
    super.initState();
    if (widget.chapter != null) {
      _currentChapter = widget.chapter!;
    } else if (widget.surahId != null) {
      _currentChapter = QuranChapter.allChapters.firstWhere(
        (c) => c.id == widget.surahId,
        orElse: () => QuranChapter.allChapters.first,
      );
    } else {
      _currentChapter = QuranChapter.allChapters.first;
    }

    // Resolve initial ayah from widget or saved Khatma progress
    int? resolvedAyah = widget.initialAyah;
    if (resolvedAyah == null && widget.isKhatmaActive) {
      final currentJuz = _getJuzNumber(_currentChapter.id);
      final savedProgress = KhatmaRepository().getJuzProgress(currentJuz);
      if (savedProgress.lastReadSurahId == _currentChapter.id && savedProgress.lastReadAyah != null) {
        resolvedAyah = savedProgress.lastReadAyah;
      }
    }
    _resumedKhatmaAyah = resolvedAyah;
    _selectedAyahNum = resolvedAyah;

    // Track initial Khatma progress if in Khatma mode
    if (widget.isKhatmaActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final initPage = widget.initialPage ?? JuzInfo.getPageForSurahAndAyah(_currentChapter.id, resolvedAyah ?? 1);
        KhatmaRepository().updateReadingProgress(
          page: initPage,
          surahId: _currentChapter.id,
          surahName: _currentChapter.nameArabic,
          ayahNumber: resolvedAyah ?? 1,
        );
      });
    }

    _scrollCtrl.addListener(_onScrollProgressChanged);

    final audio = AudioPlayerService();
    audio.addListener(_onAudioPlayerStateChanged);
    audio.onAyahChanged = _onAyahRecitationChanged;
    audio.onSurahCompleted = _onSurahRecitationCompleted;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadVerses(_currentChapter.id).then((_) {
        final targetScrollAyah = _resumedKhatmaAyah ?? _selectedAyahNum ?? widget.initialAyah;
        if (targetScrollAyah != null && targetScrollAyah > 0) {
          setState(() {
            _resumedKhatmaAyah = targetScrollAyah;
            _selectedAyahNum = targetScrollAyah;
          });
          // Perform scrolling once layout is stable
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _scrollToAyah(targetScrollAyah, animate: false);
          });
          Future.delayed(const Duration(milliseconds: 450), () {
            if (mounted) _scrollToAyah(targetScrollAyah, animate: true);
          });
          if (widget.initialAyah != null) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _triggerBookmarkToast('سورة ${_currentChapter.nameArabic} • الآية ${_toArabicDigits(targetScrollAyah)}');
              }
            });
          }
          if (widget.autoPlayAyah) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _playAyahDirect(targetScrollAyah, continuous: true);
              }
            });
          }
        }
        if (mounted) {
          _onScrollProgressChanged();
        }
      });
    });
  }

  void _onScrollProgressChanged() {
    if (!_scrollCtrl.hasClients) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_readingProgress != 1.0) {
        setState(() => _readingProgress = 1.0);
      }
      return;
    }
    final current = _scrollCtrl.offset;
    final progress = (current / maxScroll).clamp(0.0, 1.0);
    if ((progress - _readingProgress).abs() > 0.003) {
      setState(() => _readingProgress = progress);
    }

    // Debounce progress saving (350ms): saves steadily as user reads/scrolls calmly
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _saveCurrentReadingPosition();
      }
    });
  }

  void _saveCurrentReadingPosition() {
    final currentAyah = _findCurrentVisibleAyah();
    if (currentAyah != null && currentAyah > 0) {
      final computedPage = JuzInfo.getPageForSurahAndAyah(_currentChapter.id, currentAyah);
      if (widget.isKhatmaActive) {
        KhatmaRepository().updateReadingProgressByAyah(
          surahId: _currentChapter.id,
          surahName: _currentChapter.nameArabic,
          ayahNumber: currentAyah,
          pageNumber: computedPage,
        );
      }
    }
  }

  int? _findCurrentVisibleAyah() {
    // 1. Try finding by GlobalKey in the viewport
    final visibleAyahs = <MapEntry<int, double>>[];
    for (final entry in _ayahKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dy >= 70 && pos.dy <= 400) {
            visibleAyahs.add(MapEntry(entry.key, pos.dy));
          }
        }
      }
    }

    if (visibleAyahs.isNotEmpty) {
      visibleAyahs.sort((a, b) => a.value.compareTo(b.value));
      return visibleAyahs.first.key;
    }

    // 2. Fallback using scroll proportion
    if (_scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent > 0) {
      final progress = (_scrollCtrl.offset / _scrollCtrl.position.maxScrollExtent).clamp(0.0, 1.0);
      final verses = context.read<QuranProvider>().currentVerses;
      if (verses.isNotEmpty) {
        final index = (progress * (verses.length - 1)).round().clamp(0, verses.length - 1);
        return int.tryParse(verses[index].verseKey.split(':').last) ?? (index + 1);
      }
    }
    return _selectedAyahNum ?? _resumedKhatmaAyah ?? 1;
  }

  void _triggerBookmarkToast(String text) {
    _bookmarkPillTimer?.cancel();
    setState(() {
      _bookmarkPillText = text;
      _showBookmarkPill = true;
    });
    _bookmarkPillTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() => _showBookmarkPill = false);
      }
    });
  }

  void _onAudioPlayerStateChanged() {
    if (!mounted) return;
    final audio = AudioPlayerService();
    if (audio.currentSurahId == _currentChapter.id) {
      _activeRecitingAyah = audio.currentAyahNum;
      _isContinuousReciting = audio.isContinuousQuranPlayback;
    } else if (!audio.isContinuousQuranPlayback && !audio.isPlaying) {
      _isContinuousReciting = false;
      _activeRecitingAyah = null;
    }
    setState(() {});
  }

  void _onAyahRecitationChanged(int surahId, int ayahNum) {
    if (!mounted) return;
    if (surahId == _currentChapter.id) {
      setState(() {
        _activeRecitingAyah = ayahNum;
        _selectedAyahNum = ayahNum;
        _isContinuousReciting = AudioPlayerService().isContinuousQuranPlayback;
      });
      _scrollToAyah(ayahNum);
      KhatmaRepository().updateReadingProgressByAyah(
        surahId: _currentChapter.id,
        surahName: _currentChapter.nameArabic,
        ayahNumber: ayahNum,
        pageNumber: widget.initialPage,
      );
    } else {
      // Automatic transition to next surah/page
      final newChapter = QuranChapter.allChapters.firstWhere(
        (c) => c.id == surahId,
        orElse: () => _currentChapter,
      );
      if (newChapter.id != _currentChapter.id) {
        _goToChapter(newChapter);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _activeRecitingAyah = ayahNum;
              _selectedAyahNum = ayahNum;
              _isContinuousReciting = AudioPlayerService().isContinuousQuranPlayback;
            });
            _scrollToAyah(ayahNum);
            KhatmaRepository().updateReadingProgressByAyah(
              surahId: newChapter.id,
              surahName: newChapter.nameArabic,
              ayahNumber: ayahNum,
            );
          }
        });
      }
    }
  }

  void _onSurahRecitationCompleted(int nextSurahId) {
    if (!mounted) return;
    if (nextSurahId <= 114) {
      final next = QuranChapter.allChapters.firstWhere((c) => c.id == nextSurahId);
      _goToChapter(next);
      final quran = context.read<QuranProvider>();
      AudioPlayerService().playQuranAyah(
        surahId: nextSurahId,
        ayahNum: 1,
        totalAyahs: next.versesCount,
        reciterPath: quran.selectedReciter.everyAyahFolder,
        reciterName: quran.selectedReciter.name,
        continuous: true,
      );
    } else {
      AudioPlayerService().stopQuranRecitation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD4AF37),
          content: Text('تمت ختمة القرآن الكريم بحمد الله تعالى 🤲✨'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bookmarkPillTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _saveCurrentReadingPosition();
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();

    final audio = AudioPlayerService();
    audio.removeListener(_onAudioPlayerStateChanged);
    audio.onAyahChanged = null;
    audio.onSurahCompleted = null;
    if (_isContinuousReciting) {
      audio.stopQuranRecitation();
    }
    _scrollCtrl.removeListener(_onScrollProgressChanged);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _goToChapter(QuranChapter newChapter, {bool scrollToBottom = false, int? initialAyah}) {
    // 1. First commit & preserve the current surah/juz reading position
    _saveCurrentReadingPosition();
    _stopContinuousRecitation();
    _ayahKeys.clear();
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();

    // 2. Determine target starting verse and page for new chapter
    final targetAyah = initialAyah ?? (scrollToBottom ? newChapter.versesCount : 1);
    final targetPage = JuzInfo.getPageForSurahAndAyah(newChapter.id, targetAyah);

    setState(() {
      _currentChapter = newChapter;
      _resumedKhatmaAyah = targetAyah;
      _selectedAyahNum = null;
      _activeRecitingAyah = null;
      _readingProgress = scrollToBottom ? 1.0 : 0.0;
    });

    // 3. Immediately record progress for the new chapter/juz
    if (widget.isKhatmaActive) {
      KhatmaRepository().updateReadingProgressByAyah(
        surahId: newChapter.id,
        surahName: newChapter.nameArabic,
        ayahNumber: targetAyah,
        pageNumber: targetPage,
      );
    }

    context.read<QuranProvider>().loadVerses(newChapter.id).then((_) {
      if (mounted) {
        _onScrollProgressChanged();
        if (scrollToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted && _scrollCtrl.hasClients) {
                _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                if (newChapter.versesCount > 0) {
                  _scrollToAyah(newChapter.versesCount);
                }
              }
            });
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                _scrollToAyah(targetAyah);
              }
            });
          });
        }
      }
    });
    if (_scrollCtrl.hasClients) {
      if (scrollToBottom) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  void _nextChapter() {
    if (_currentChapter.id < 114) {
      final next = QuranChapter.allChapters.firstWhere((c) => c.id == _currentChapter.id + 1);
      _goToChapter(next, scrollToBottom: false);
    }
  }

  void _previousChapter() {
    if (_currentChapter.id > 1) {
      final prev = QuranChapter.allChapters.firstWhere((c) => c.id == _currentChapter.id - 1);
      _goToChapter(prev, scrollToBottom: true);
    }
  }

  int _getJuzNumber(int surahId, [int ayah = 1]) {
    if (surahId == 1) return 1;
    if (surahId == 2) {
      if (ayah < 142) return 1;
      if (ayah < 253) return 2;
      return 3;
    }
    if (surahId == 3) {
      if (ayah < 93) return 3;
      return 4;
    }
    if (surahId == 4) {
      if (ayah < 24) return 4;
      if (ayah < 148) return 5;
      return 6;
    }
    if (surahId == 5) {
      if (ayah < 82) return 6;
      return 7;
    }
    if (surahId == 6) {
      if (ayah < 111) return 7;
      return 8;
    }
    if (surahId == 7) {
      if (ayah < 88) return 8;
      return 9;
    }
    if (surahId == 8) {
      if (ayah < 41) return 9;
      return 10;
    }
    if (surahId == 9) {
      if (ayah < 93) return 10;
      return 11;
    }
    if (surahId == 10) return 11;
    if (surahId == 11) {
      if (ayah < 6) return 11;
      return 12;
    }
    if (surahId == 12) {
      if (ayah < 53) return 12;
      return 13;
    }
    if (surahId == 13 || surahId == 14) return 13;
    if (surahId == 15 || surahId == 16) return 14;
    if (surahId == 17) return 15;
    if (surahId == 18) {
      if (ayah < 75) return 15;
      return 16;
    }
    if (surahId == 19 || surahId == 20) return 16;
    if (surahId == 21 || surahId == 22) return 17;
    if (surahId == 23 || surahId == 24) return 18;
    if (surahId == 25) {
      if (ayah < 21) return 18;
      return 19;
    }
    if (surahId == 26 || surahId == 27) return 19;
    if (surahId == 28 || surahId == 29) return 20;
    if (surahId == 30 || surahId == 31 || surahId == 32) return 21;
    if (surahId == 33 || surahId == 34 || surahId == 35) return 22;
    if (surahId == 36 || surahId == 37 || surahId == 38) return 23;
    if (surahId == 39 || surahId == 40 || surahId == 41) return 24;
    if (surahId >= 42 && surahId <= 45) return 25;
    if (surahId >= 46 && surahId <= 50) return 26;
    if (surahId >= 51 && surahId <= 57) return 27;
    if (surahId >= 58 && surahId <= 66) return 28;
    if (surahId >= 67 && surahId <= 77) return 29;
    return 30;
  }

  void _showSurahListBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر السورة الكريمة',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: QuranChapter.allChapters.length,
                itemBuilder: (c, idx) {
                  final ch = QuranChapter.allChapters[idx];
                  final isCurrent = ch.id == _currentChapter.id;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFE0EDFB),
                      child: Text(
                        HijriDateService.toArabicDigits(ch.id),
                        style: TextStyle(
                          color: isCurrent ? Colors.white : const Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      'سورة ${ch.nameArabic}',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF0284C7) : null,
                      ),
                    ),
                    subtitle: Text('${ch.isMakki ? "مكية" : "مدنية"} • ${HijriDateService.toArabicDigits(ch.versesCount)} آية'),
                    onTap: () {
                      Navigator.pop(ctx);
                      final targetJuz = JuzInfo.getJuzNumberForAyah(ch.id, 1);
                      final savedProgress = KhatmaRepository().getJuzProgress(targetJuz);
                      int? resumeAyah;
                      if (savedProgress.lastReadSurahId == ch.id && savedProgress.lastReadAyah != null) {
                        resumeAyah = savedProgress.lastReadAyah;
                      }
                      _goToChapter(ch, initialAyah: resumeAyah);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  void _showJuzListBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentJuz = _getJuzNumber(_currentChapter.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أجزاء القرآن الكريم (٣٠ جزء)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: JuzInfo.allAjza.length,
                itemBuilder: (c, idx) {
                  final jInfo = JuzInfo.allAjza[idx];
                  final isCurrent = jInfo.juzNumber == currentJuz;
                  final progress = KhatmaRepository().getJuzProgress(jInfo.juzNumber);
                  final targetSurahId = progress.lastReadSurahId ?? jInfo.startSurahId;
                  final targetAyah = progress.lastReadAyah ?? jInfo.startAyah;
                  final chapter = QuranChapter.allChapters.firstWhere(
                    (ch) => ch.id == targetSurahId,
                    orElse: () => QuranChapter.allChapters.first,
                  );

                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFE0EDFB),
                      child: Text(
                        HijriDateService.toArabicDigits(jInfo.juzNumber),
                        style: TextStyle(
                          color: isCurrent ? Colors.white : const Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      jInfo.arabicName,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF0284C7) : null,
                      ),
                    ),
                    subtitle: Text(
                      progress.status == JuzStatus.inProgress
                          ? '${progress.lastReadSurahName ?? ""}: آية ${progress.lastReadAyah ?? 1} (${progress.progressPercentInt}%)'
                          : (progress.status == JuzStatus.completed ? 'مكتمل' : 'يبدأ من سورة ${jInfo.startSurahName}'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    trailing: progress.status == JuzStatus.completed
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18)
                        : (progress.status == JuzStatus.inProgress
                            ? Text('${progress.progressPercentInt}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 12))
                            : null),
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToChapter(chapter, initialAyah: targetAyah);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _startContinuousRecitation({int startAyah = 1}) {
    _playAyahDirect(startAyah, continuous: true);
  }

  void _stopContinuousRecitation() {
    AudioPlayerService().stopQuranRecitation();
    if (mounted) {
      setState(() {
        _isContinuousReciting = false;
        _activeRecitingAyah = null;
      });
    }
  }

  void _showSettingsBottomSheet(BuildContext context, QuranProvider quran) {
    QuranSettingsSheet.show(
      context,
      currentChapter: _currentChapter,
      currentJuz: _getJuzNumber(_currentChapter.id),
      isKhatmaActive: widget.isKhatmaActive,
      onOpenReciters: () => _showReciterSelectionSheet(context, quran),
      onDownloadSurah: () => _showDownloadSurahDialog(context, quran),
      onOpenNavigation: () {
        if (widget.isKhatmaActive) {
          _showJuzListBottomSheet(context);
        } else {
          _showSurahListBottomSheet(context);
        }
      },
      onOpenBookmarks: () {
        QuranBookmarksSheet.show(
          context,
          onSelectBookmark: (b) {
            if (b.surahId == _currentChapter.id) {
              setState(() => _selectedAyahNum = b.ayahNumber);
              _scrollToAyah(b.ayahNumber);
            } else {
              final ch = QuranChapter.allChapters.firstWhere(
                (c) => c.id == b.surahId,
                orElse: () => QuranChapter.allChapters.first,
              );
              _goToChapter(ch);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() => _selectedAyahNum = b.ayahNumber);
                    _scrollToAyah(b.ayahNumber);
                  }
                });
              });
            }
          },
        );
      },
    );
  }


  void _scrollToAyah(int ayahNum, {bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;

      double? targetOffset;

      // 1. Precise renderObject coordinate lookup via RenderAbstractViewport
      final key = _ayahKeys[ayahNum];
      final ctx = key?.currentContext;
      if (ctx != null) {
        try {
          final renderObject = ctx.findRenderObject();
          if (renderObject != null && renderObject.attached) {
            final viewport = RenderAbstractViewport.maybeOf(renderObject);
            if (viewport != null) {
              final revealed = viewport.getOffsetToReveal(renderObject, 0.14);
              if (revealed.offset > 20 || ayahNum <= 2) {
                targetOffset = revealed.offset;
              }
            }
          }
        } catch (_) {}
      }

      // 2. Character-proportional fallback if geometry wasn't ready or gave stuck 0 offset for mid/late verses
      if (targetOffset == null || (targetOffset <= 20 && ayahNum > 3)) {
        final verses = context.read<QuranProvider>().currentVerses;
        if (verses.isNotEmpty && _scrollCtrl.position.maxScrollExtent > 0) {
          final maxScroll = _scrollCtrl.position.maxScrollExtent;
          int totalChars = 0;
          for (final v in verses) {
            totalChars += v.textUthmani.length;
          }
          if (totalChars > 0) {
            int charsBefore = 0;
            for (int i = 0; i < verses.length && i < ayahNum - 1; i++) {
              charsBefore += verses[i].textUthmani.length;
            }
            final double proportion = charsBefore / totalChars;
            targetOffset = (proportion * maxScroll - 40).clamp(0.0, maxScroll);
          }
        }
      }

      if (targetOffset != null) {
        final clampedOffset = targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
        if (animate) {
          _scrollCtrl.animateTo(
            clampedOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        } else {
          _scrollCtrl.jumpTo(clampedOffset);
        }
      }
    });
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? arabicDigits[d] : c;
    }).join();
  }

  /// Split verse text into segments to apply Sajdah overline decoration while keeping 100% of the Uthmani script untouched
  List<_VerseSegment> _splitVerseForSajdah(String uthmaniText, QuranSajdahInfo sajdah) {
    if (uthmaniText.isEmpty) return [_VerseSegment(uthmaniText)];

    // 1. Build a normalized index mapping
    final normChars = <String>[];
    final origIndices = <int>[];

    for (int i = 0; i < uthmaniText.length; i++) {
      final char = uthmaniText[i];
      final code = char.codeUnitAt(0);
      final isTashkeel = (code >= 0x064B && code <= 0x065F) ||
          code == 0x0670 ||
          (code >= 0x06D6 && code <= 0x06ED) ||
          char == '\u0640'; // tatweel
      if (isTashkeel) continue;

      String n = char;
      if (n == 'أ' || n == 'إ' || n == 'آ' || n == 'ٱ') {
        n = 'ا';
      } else if (n == 'ى') {
        n = 'ي';
      } else if (n == 'ة') {
        n = 'ه';
      } else if (n == 'ؤ') {
        n = 'و';
      } else if (n == 'ئ') {
        n = 'ي';
      } else if (n == 'ء') {
        n = '';
      }
      if (n.isNotEmpty) {
        normChars.add(n);
        origIndices.add(i);
      }
    }

    // 2. Try each keyword from the Sajdah info
    for (final kw in sajdah.keywords) {
      final normKw = QuranApiService.normalizeArabic(kw).replaceAll(' ', '');
      if (normKw.isEmpty) continue;

      final spacelessNorm = <String>[];
      final spacelessToOrig = <int>[];

      for (int k = 0; k < normChars.length; k++) {
        if (normChars[k] != ' ') {
          spacelessNorm.add(normChars[k]);
          spacelessToOrig.add(origIndices[k]);
        }
      }

      final spacelessStr = spacelessNorm.join('');
      final matchIdx = spacelessStr.indexOf(normKw);

      if (matchIdx != -1) {
        final startOrig = spacelessToOrig[matchIdx];
        final endOrigChar = spacelessToOrig[matchIdx + normKw.length - 1];

        // Include all attached following diacritics
        int endOrig = endOrigChar;
        while (endOrig + 1 < uthmaniText.length) {
          final nextCode = uthmaniText.codeUnitAt(endOrig + 1);
          final isNextTashkeel = (nextCode >= 0x064B && nextCode <= 0x065F) ||
              nextCode == 0x0670 ||
              (nextCode >= 0x06D6 && nextCode <= 0x06ED);
          if (isNextTashkeel) {
            endOrig++;
          } else {
            break;
          }
        }

        final segments = <_VerseSegment>[];
        if (startOrig > 0) {
          segments.add(_VerseSegment(uthmaniText.substring(0, startOrig), isSajdah: false));
        }
        segments.add(_VerseSegment(uthmaniText.substring(startOrig, endOrig + 1), isSajdah: true));
        if (endOrig + 1 < uthmaniText.length) {
          segments.add(_VerseSegment(uthmaniText.substring(endOrig + 1), isSajdah: false));
        }
        return segments;
      }
    }

    // Fallback if no specific keyword matched: mark whole verse
    return [_VerseSegment(uthmaniText, isSajdah: true)];
  }

  void _handleAyahTap(VerseItem verse, int ayahNum) {
    setState(() {
      _resumedKhatmaAyah = ayahNum;
      _selectedAyahNum = ayahNum;
    });

    if (widget.isKhatmaActive) {
      KhatmaRepository().updateReadingProgressByAyah(
        surahId: _currentChapter.id,
        surahName: _currentChapter.nameArabic,
        ayahNumber: ayahNum,
        pageNumber: widget.initialPage ?? JuzInfo.getPageForSurahAndAyah(_currentChapter.id, ayahNum),
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastTappedAyah == ayahNum && (now - _lastTapTime) < 350) {
      // Double tap detected: start recitation directly!
      _lastTappedAyah = -1;
      _lastTapTime = 0;
      _playAyahDirect(ayahNum, continuous: true);
    } else {
      _lastTappedAyah = ayahNum;
      _lastTapTime = now;
      Future.delayed(const Duration(milliseconds: 360), () {
        if (_lastTappedAyah == ayahNum && (DateTime.now().millisecondsSinceEpoch - _lastTapTime) >= 350) {
          if (mounted) {
            _openAyahOptions(verse, ayahNum);
          }
        }
      });
    }
  }

  void _openAyahOptions(VerseItem verse, int ayahNum) {
    final quran = context.read<QuranProvider>();
    final isBookmarked = quran.isAyahBookmarked(_currentChapter.id, ayahNum);
    setState(() {
      _resumedKhatmaAyah = ayahNum;
      _selectedAyahNum = ayahNum;
    });
    if (widget.isKhatmaActive) {
      KhatmaRepository().updateReadingProgressByAyah(
        surahId: _currentChapter.id,
        surahName: _currentChapter.nameArabic,
        ayahNumber: ayahNum,
        pageNumber: widget.initialPage ?? JuzInfo.getPageForSurahAndAyah(_currentChapter.id, ayahNum),
      );
    }
    AyahOptionsSheet.show(
      context,
      chapter: _currentChapter,
      ayahNum: ayahNum,
      verseText: verse.textUthmani,
      reciterName: quran.selectedReciter.name,
      reciterPath: quran.selectedReciter.everyAyahFolder,
      juzNum: _getJuzNumber(_currentChapter.id, ayahNum),
      onPlaySingle: () => _playAyahDirect(ayahNum, continuous: false),
      onPlayContinuous: () => _playAyahDirect(ayahNum, continuous: true),
      isBookmarked: isBookmarked,
      onBookmark: () async {
        final wasAdded = await quran.toggleBookmark(
          surahId: _currentChapter.id,
          surahName: _currentChapter.nameArabic,
          ayahNum: ayahNum,
          verseText: verse.textUthmani,
        );
        _triggerBookmarkToast(
          wasAdded
              ? 'تمت إضافة الآية للعلامات المرجعية'
              : 'تمت إزالة الآية من العلامات المرجعية',
        );
      },
    );
  }

  void _playAyahDirect(int ayahNum, {bool continuous = true}) {
    final quran = context.read<QuranProvider>();
    setState(() {
      _activeRecitingAyah = ayahNum;
      _selectedAyahNum = ayahNum;
      _isContinuousReciting = continuous;
    });

    KhatmaRepository().updateReadingProgressByAyah(
      surahId: _currentChapter.id,
      surahName: _currentChapter.nameArabic,
      ayahNumber: ayahNum,
      pageNumber: widget.initialPage,
    );

    AudioPlayerService().playQuranAyah(
      surahId: _currentChapter.id,
      ayahNum: ayahNum,
      totalAyahs: _currentChapter.versesCount,
      reciterPath: quran.selectedReciter.everyAyahFolder,
      reciterName: quran.selectedReciter.name,
      continuous: continuous,
    );
    _scrollToAyah(ayahNum);
  }

  Future<File> _getLocalSurahAudioFile(int surahId, int reciterId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${docDir.path}/quran_audio/$reciterId');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final s = surahId.toString().padLeft(3, '0');
    final file = File('${audioDir.path}/$s.mp3');
    if (await file.exists() && await file.length() > 2048) {
      return file;
    }
    final legacyFile = File('${docDir.path}/quran_audio/surah_${surahId}_reciter_$reciterId.mp3');
    if (await legacyFile.exists() && await legacyFile.length() > 2048) {
      return legacyFile;
    }
    return file;
  }

  void _showReciterSelectionSheet(BuildContext context, QuranProvider quran) {
    _showAudioRecitationSheet(context, quran);
  }

  void _showAudioRecitationSheet(BuildContext context, QuranProvider quran) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const reciters = ReciterItem.popularReciters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetCtx, setSheetState) {
            final playerService = AudioPlayerService();
            final isPlaying = playerService.isPlaying;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.headphones_rounded,
                                color: Color(0xFFD4AF37),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تلاوة السورة واختيار القارئ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'سورة ${_currentChapter.nameArabic} • ${_toArabicDigits(_currentChapter.versesCount)} آية',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Active Player Quick Action Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? (_isContinuousReciting
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [const Color(0xFF16202C), const Color(0xFF1E2E40)])
                              : (_isContinuousReciting
                                  ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                                  : [const Color(0xFFFDFBF7), const Color(0xFFF8F4E8)]),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isContinuousReciting
                              ? const Color(0xFFD4AF37)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: _isContinuousReciting ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isContinuousReciting
                                ? const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.2 : 0.15)
                                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isContinuousReciting ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
                                  color: const Color(0xFFD4AF37),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isContinuousReciting
                                          ? 'قيد التلاوة: ${quran.selectedReciter.name}'
                                          : 'القارئ المعتمد: ${quran.selectedReciter.name}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      _isContinuousReciting
                                          ? 'الآية ${_toArabicDigits(_activeRecitingAyah ?? 1)} من ${_toArabicDigits(_currentChapter.versesCount)} (تلاوة مستمرة مع التمرير)'
                                          : 'اختر أي قارئ من القائمة بالأسفل واضغط تشغيل',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (_isContinuousReciting) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
                                      backgroundColor: isDark ? Colors.transparent : Colors.red.shade50.withValues(alpha: 0.6),
                                      side: BorderSide(color: isDark ? Colors.red.shade400 : Colors.red.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                    icon: const Icon(Icons.stop_rounded, size: 18),
                                    label: const Text('إيقاف التلاوة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    onPressed: () {
                                      _stopContinuousRecitation();
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: const Color(0xFF1B3A57),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                                    label: Text(isPlaying ? 'إيقاف مؤقت' : 'استئناف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    onPressed: () {
                                      playerService.togglePlayPause();
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                    label: Text(
                                      'تشغيل التلاوة بصوت ${quran.selectedReciter.name}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      final targetAyah = _activeRecitingAyah ?? _selectedAyahNum ?? 1;
                                      _startContinuousRecitation(startAyah: targetAyah);
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Section title
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'قائمة القراء المتاحين للتلاوة:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Reciters List
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reciters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (c, idx) {
                          final r = reciters[idx];
                          final isSelected = r.id == quran.selectedReciter.id;
                          final isThisPlaying = isSelected && _isContinuousReciting;

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.2 : 0.12)
                                  : (isDark ? const Color(0xFF16202C) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                child: Icon(
                                  isThisPlaying ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
                                  color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                r.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? const Color(0xFFD4AF37) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                              subtitle: Text(
                                isThisPlaying ? 'قيد التلاوة الآن 🔊' : r.tags.join(' • '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isThisPlaying
                                      ? const Color(0xFF059669)
                                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  fontWeight: isThisPlaying ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? const Color(0xFFD4AF37) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  foregroundColor: isSelected ? Colors.black87 : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(
                                  isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  isThisPlaying ? 'إيقاف' : 'تشغيل',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  if (isThisPlaying) {
                                    playerService.togglePlayPause();
                                    setSheetState(() {});
                                  } else {
                                    Navigator.pop(ctx);
                                    final targetAyah = _activeRecitingAyah ?? _selectedAyahNum ?? 1;
                                    await quran.selectReciter(r);
                                    _playAyahDirect(targetAyah, continuous: true);
                                  }
                                },
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final targetAyah = _activeRecitingAyah ?? _selectedAyahNum ?? 1;
                                await quran.selectReciter(r);
                                _playAyahDirect(targetAyah, continuous: true);
                              },
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

  void _showDownloadSurahDialog(BuildContext context, QuranProvider quran) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reciterFolder = quran.selectedReciter.everyAyahFolder;
    final ayahDir = await AudioPlayerService.getAyahAudioDir(reciterFolder, _currentChapter.id);
    final legacyFile = await _getLocalSurahAudioFile(_currentChapter.id, quran.selectedReciter.id);

    Future<({int count, int bytes})> scanAyahFiles() async {
      int count = 0;
      int bytes = 0;
      if (await ayahDir.exists()) {
        for (int i = 1; i <= _currentChapter.versesCount; i++) {
          final a = i.toString().padLeft(3, '0');
          final f = File('${ayahDir.path}/$a.mp3');
          if (await f.exists()) {
            final len = await f.length();
            if (len > 1024) {
              count++;
              bytes += len;
            }
          }
        }
      }
      return (count: count, bytes: bytes);
    }

    final initialScan = await scanAyahFiles();
    int downloadedAyahs = initialScan.count;
    int totalBytesOnDisk = initialScan.bytes;
    bool hasLegacyFullSurah = await legacyFile.exists() && await legacyFile.length() > 2048;
    if (hasLegacyFullSurah && totalBytesOnDisk == 0) {
      totalBytesOnDisk = await legacyFile.length();
    }
    bool isAllAyahsDownloaded = downloadedAyahs >= _currentChapter.versesCount;
    double downloadProgress = _currentChapter.versesCount > 0
        ? (downloadedAyahs / _currentChapter.versesCount).clamp(0.0, 1.0)
        : 0.0;
    bool isDownloading = false;
    bool isCancelled = false;
    String statusMessage = '';

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isDownloading,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDlgState) {
            String formatBytes(int bytes) {
              if (bytes <= 0) return '0 B';
              final kb = bytes / 1024;
              if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
              return '${(kb / 1024).toStringAsFixed(1)} MB';
            }

            Future<void> startDownload() async {
              isCancelled = false;
              if (dialogCtx.mounted) {
                setDlgState(() {
                  isDownloading = true;
                  downloadProgress = 0.02;
                  statusMessage = 'جارٍ تجهيز نص السورة وتحميل الآيات الصوتية...';
                });
              }

              final client = http.Client();
              try {
                // 1. Ensure Surah verses text is cached offline
                await QuranApiService.getVerses(_currentChapter.id);

                // 2. Ensure ayah audio directory exists
                if (!await ayahDir.exists()) {
                  await ayahDir.create(recursive: true);
                }

                final totalAyahs = _currentChapter.versesCount;
                final s = _currentChapter.id.toString().padLeft(3, '0');
                final List<int> missingAyahs = [];
                int completed = 0;
                int bytesSum = 0;

                for (int i = 1; i <= totalAyahs; i++) {
                  final a = i.toString().padLeft(3, '0');
                  final f = File('${ayahDir.path}/$a.mp3');
                  if (await f.exists() && await f.length() > 1024) {
                    completed++;
                    bytesSum += await f.length();
                  } else {
                    missingAyahs.add(i);
                  }
                }

                int nextIdx = 0;
                int failedCount = 0;

                Future<void> worker() async {
                  while (!isCancelled) {
                    if (nextIdx >= missingAyahs.length) break;
                    final ayahNum = missingAyahs[nextIdx++];
                    final a = ayahNum.toString().padLeft(3, '0');
                    final url = 'https://everyayah.com/data/$reciterFolder/$s$a.mp3';
                    final targetFile = File('${ayahDir.path}/$a.mp3');
                    final tempFile = File('${targetFile.path}.part');

                    bool ok = false;
                    for (int attempt = 0; attempt < 2 && !ok && !isCancelled; attempt++) {
                      try {
                        final res = await client
                            .get(Uri.parse(url))
                            .timeout(const Duration(seconds: 25));
                        if (res.statusCode >= 200 &&
                            res.statusCode < 300 &&
                            res.bodyBytes.length > 1024) {
                          await tempFile.writeAsBytes(res.bodyBytes, flush: true);
                          if (await targetFile.exists()) {
                            await targetFile.delete();
                          }
                          await tempFile.rename(targetFile.path);
                          bytesSum += res.bodyBytes.length;
                          completed++;
                          ok = true;
                        }
                      } catch (_) {
                        if (await tempFile.exists()) {
                          try {
                            await tempFile.delete();
                          } catch (_) {}
                        }
                      }
                    }
                    if (!ok && !isCancelled) {
                      failedCount++;
                    }

                    if (dialogCtx.mounted && !isCancelled) {
                      setDlgState(() {
                        downloadedAyahs = completed;
                        totalBytesOnDisk = bytesSum;
                        downloadProgress = totalAyahs > 0
                            ? (completed / totalAyahs).clamp(0.0, 1.0)
                            : 1.0;
                        statusMessage =
                            '${(downloadProgress * 100).toInt()}% • تم تحميل $completed من $totalAyahs آية';
                      });
                    }
                  }
                }

                const int concurrency = 6;
                final workers = List.generate(
                  missingAyahs.length < concurrency
                      ? (missingAyahs.isEmpty ? 1 : missingAyahs.length)
                      : concurrency,
                  (_) => worker(),
                );
                await Future.wait(workers);

                if (!isCancelled && dialogCtx.mounted) {
                  final allDone = completed >= totalAyahs && failedCount == 0;
                  setDlgState(() {
                    isDownloading = false;
                    downloadedAyahs = completed;
                    totalBytesOnDisk = bytesSum;
                    isAllAyahsDownloaded = allDone;
                    statusMessage = allDone
                        ? 'اكتمل تحميل السورة والصوت بنجاح!'
                        : 'تم تحميل $completed من $totalAyahs آية. تحقق من الإنترنت للاستكمال.';
                  });

                  if (allDone && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text(
                          'تم تحميل سورة ${_currentChapter.nameArabic} والنص والصوت معاً بنجاح 📥🎧',
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  setDlgState(() {
                    isDownloading = false;
                    statusMessage = 'تعذر التحميل، يرجى التأكد من اتصال الإنترنت.';
                  });
                }
              } finally {
                client.close();
              }
            }

            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) isCancelled = true;
              },
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_download_outlined, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تحميل سورة ${_currentChapter.nameArabic} والصوت',
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16202C) : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD0E5FA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.record_voice_over_rounded, size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'القارئ: ${quran.selectedReciter.name}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'النص والتلاوة الكاملة آية بآية مع التمرير التلقائي (${_currentChapter.versesCount} آية)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          if (totalBytesOnDisk > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'الحجم في الجهاز: ${formatBytes(totalBytesOnDisk)} ($downloadedAyahs/${_currentChapter.versesCount} آية)',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isDownloading) ...[
                      LinearProgressIndicator(
                        value: downloadProgress > 0 ? downloadProgress : null,
                        backgroundColor: Colors.grey.shade300,
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                      ),
                    ] else if (isAllAyahsDownloaded) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'السورة والصوت محملة وجاهزة للتشغيل والتمرير بدون إنترنت',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        statusMessage.isNotEmpty
                            ? statusMessage
                            : 'اضغط لتحميل السورة والصوت معاً لتعمل التلاوة مع التمرير التلقائي دون الحاجة للإنترنت.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (isDownloading) ...[
                    TextButton(
                      onPressed: () {
                        isCancelled = true;
                        Navigator.pop(ctx);
                      },
                      child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
                    ),
                  ] else if (isAllAyahsDownloaded) ...[
                    TextButton(
                      onPressed: () async {
                        if (await ayahDir.exists()) {
                          await ayahDir.delete(recursive: true);
                        }
                        if (await legacyFile.exists()) {
                          await legacyFile.delete();
                        }
                        setDlgState(() {
                          isAllAyahsDownloaded = false;
                          hasLegacyFullSurah = false;
                          downloadedAyahs = 0;
                          totalBytesOnDisk = 0;
                          statusMessage = 'تم حذف الملفات من الجهاز';
                        });
                      },
                      child: const Text('حذف', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      label: const Text('تشغيل بدون إنترنت', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _playAyahDirect(_selectedAyahNum ?? 1, continuous: true);
                      },
                    ),
                  ] else ...[
                    if (hasLegacyFullSurah)
                      TextButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Color(0xFF059669)),
                        label: const Text('تشغيل الصوت فقط', style: TextStyle(color: Color(0xFF059669))),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _playFullSurah(quran);
                        },
                      )
                    else
                      TextButton.icon(
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('استماع مباشر'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _playAyahDirect(_selectedAyahNum ?? 1, continuous: true);
                        },
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: Text(
                        downloadedAyahs > 0
                            ? 'استكمال التحميل ($downloadedAyahs/${_currentChapter.versesCount})'
                            : 'تحميل السورة والصوت معاً',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: startDownload,
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

  void _playFullSurah(QuranProvider quran) async {
    final file = await _getLocalSurahAudioFile(_currentChapter.id, quran.selectedReciter.id);
    if (await file.exists()) {
      AudioPlayerService().playTrack(AudioTrackInfo(
        title: 'سورة ${_currentChapter.nameArabic}',
        subtitle: '${quran.selectedReciter.name} (أوفلاين)',
        url: file.path,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('تشغيل سورة ${_currentChapter.nameArabic} بصوت ${quran.selectedReciter.name} (محلياً بدون إنترنت) 🎧'),
          ),
        );
      }
      return;
    }

    final style = quran.currentStyle;
    if (style != null) {
      final url = QuranApiService.getSurahAudioUrl(style.server, _currentChapter.id);
      AudioPlayerService().playTrack(AudioTrackInfo(
        title: 'سورة ${_currentChapter.nameArabic}',
        subtitle: quran.selectedReciter.name,
        url: url,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0284C7),
            content: Text('جارٍ تشغيل سورة ${_currentChapter.nameArabic} بصوت ${quran.selectedReciter.name} 🎧'),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quran = context.watch<QuranProvider>();
    final verses = quran.currentVerses;
    final activeAyah = _resumedKhatmaAyah ?? _selectedAyahNum ?? 1;
    final juzNum = _getJuzNumber(_currentChapter.id, activeAyah);
    final juzArabicName = JuzInfo.allAjza[(juzNum - 1).clamp(0, 29)].arabicName;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _saveCurrentReadingPosition();
      },
      child: Scaffold(
      backgroundColor: quran.isUthmanicMode
          ? (isDark ? Colors.black : const Color(0xFFF7F4E9))
          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F9FD)),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
            // 1. Top Controls Bar matching user request & screenshot
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // 1. Back Button (->) inside soft circle on the right (in RTL, child 0 is right)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'رجوع',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const Spacer(),

                  // 3. زر فهرس السور أو قائمة الأجزاء (بحسب وضع الختمة)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        widget.isKhatmaActive ? Icons.auto_stories_rounded : Icons.menu_book_rounded,
                        size: 19,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: widget.isKhatmaActive ? 'أجزاء الختمة (٣٠ جزء)' : 'فهرس السور',
                      onPressed: () => widget.isKhatmaActive
                          ? _showJuzListBottomSheet(context)
                          : _showSurahListBottomSheet(context),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 4. Unified Settings Button (⚙)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 19,
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'إعدادات السورة',
                      onPressed: () => _showSettingsBottomSheet(context, quran),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 5. زر تشغيل الصوت والتلاوة واختيار القارئ
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isContinuousReciting
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isContinuousReciting ? const Color(0xFFD4AF37) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isContinuousReciting ? Icons.volume_up_rounded : Icons.headphones_rounded,
                        size: 19,
                        color: _isContinuousReciting ? const Color(0xFFD4AF37) : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'تشغيل الصوت واختيار القارئ',
                      onPressed: () => _showAudioRecitationSheet(context, quran),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // زر إيقاف الصوت الدائم أثناء القراءة والتمرير عند تشغيل أي صوت
                  if (AudioPlayerService().isPlaying || _isContinuousReciting || _activeRecitingAyah != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.75),
                          width: 1.4,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.stop_rounded, size: 20),
                        color: Colors.redAccent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'إيقاف الصوت',
                        onPressed: () {
                          _stopContinuousRecitation();
                          AudioPlayerService().stop();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // 6. Chevron (<) on far left - الانتقال للسورة التالية
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 23),
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'السورة التالية',
                      onPressed: _currentChapter.id < 114 ? _nextChapter : null,
                    ),
                  ),
                ],
              ),
            ),

            // 2. The Main Framed Mushaf Page matching Image 2 & Image 3
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -200) {
                      _nextChapter();
                    } else if (details.primaryVelocity! > 200) {
                      _previousChapter();
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: quran.isUthmanicMode
                        ? (isDark ? Colors.black : const Color(0xFFFAF7EE))
                        : (isDark ? const Color(0xFF161E28) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: quran.isUthmanicMode
                          ? (isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : const Color(0xFFD4AF37))
                          : (isDark ? const Color(0xFF334155) : const Color(0xFF7EAAD8)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.5),
                    child: Column(
                      children: [
                        // Reading Progress Bar at the top of the Mushaf Frame
                        SizedBox(
                          height: 3.0,
                          width: double.infinity,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: LinearProgressIndicator(
                              value: _readingProgress,
                              backgroundColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                            ),
                          ),
                        ),

                        // A. Page Header inside Frame: "الجزء ١" on right, Surah name on left
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left: Surah name (tap goes to previous surah)
                              InkWell(
                                onTap: _currentChapter.id > 1 ? _previousChapter : null,
                                child: Text(
                                  _currentChapter.nameArabic,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),

                              // Right: Juz name in Arabic
                              Text(
                                juzArabicName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),

                    // Thin Divider below Header
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
                    ),

                    // B. Scrollable Quran Page Content
                    Expanded(
                      child: quran.isLoadingVerses
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              children: [
                                // Previous Surah Card at top (if surah > 1)
                                if (_currentChapter.id > 1) ...[
                                  Builder(builder: (context) {
                                    final prevChapter = QuranChapter.allChapters.firstWhere((c) => c.id == _currentChapter.id - 1);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _previousChapter,
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isDark
                                                    ? [const Color(0xFF1E2E40), const Color(0xFF1E293B)]
                                                    : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.25),
                                                width: 1.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.06),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Color(0xFF0284C7),
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'السورة السابقة',
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${prevChapter.isMakki ? "مكية" : "مدنية"} • ${HijriDateService.toArabicDigits(prevChapter.versesCount)} آية',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0284C7),
                                                    borderRadius: BorderRadius.circular(10),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    'سورة ${prevChapter.nameArabic}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],

                                // Ornate framed header for Surah title containing Hizb symbol ۞ (\u06DE)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: quran.isUthmanicMode
                                        ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFFBF8EE))
                                        : (isDark ? const Color(0xFF1E2E40) : const Color(0xFFFBF8EE)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37),
                                      width: 1.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          '\u06DE', // ۞ رمز الحزب
                                          style: TextStyle(
                                            color: Color(0xFFD4AF37),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'سُورَةُ ${_currentChapter.nameArabic}',
                                          style: TextStyle(
                                            fontFamily: quran.isUthmanicMode ? 'AmiriQuran' : 'Cairo',
                                            fontFamilyFallback: const [
                                              'UthmanicHafs',
                                              'UthmanicHafs',
                                              'Amiri',
                                              'Traditional Arabic',
                                              'sans-serif',
                                            ],
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          '\u06DE', // ۞ رمز الحزب
                                          style: TextStyle(
                                            color: Color(0xFFD4AF37),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Basmalah (for all surahs except Surah At-Tawbah 9)
                                if (_currentChapter.id != 9)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Center(
                                      child: Text(
                                        quran.isUthmanicMode
                                            ? 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'
                                            : 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: (quran.fontSize + 2).clamp(18.0, 32.0),
                                          fontFamily: quran.isUthmanicMode ? 'AmiriQuran' : null,
                                          fontFamilyFallback: const [
                                            'UthmanicHafs',
                                            'Amiri',
                                            'Traditional Arabic',
                                            'sans-serif',
                                          ],
                                          fontWeight: quran.isUthmanicMode ? FontWeight.normal : FontWeight.bold,
                                          height: quran.isUthmanicMode ? 2.2 : 1.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),

                                // C. Continuous Mushaf Text with Quranic script, \u06DD, and gestures
                                if (verses.isNotEmpty)
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text.rich(
                                      TextSpan(
                                         children: verses.map((v) {
                                           final ayahNum = int.tryParse(v.verseKey.split(':').last) ?? 1;
                                           final audio = AudioPlayerService();
                                           final isHighlighted = (audio.isPlaying || _isContinuousReciting) &&
                                               audio.currentSurahId == _currentChapter.id &&
                                               audio.currentAyahNum == ayahNum;
                                           final isLastReadHighlight = (_resumedKhatmaAyah == ayahNum || _selectedAyahNum == ayahNum);
                                           final isTargetAyah = isLastReadHighlight;
                                           final isBookmarked = quran.isAyahBookmarked(_currentChapter.id, ayahNum);
                                           final sajdah = QuranSajdahInfo.getSajdah(_currentChapter.id, ayahNum);

                                           const uthmanicFallbacks = [
                                              'UthmanicHafs',
                                              'Amiri',
                                              'Traditional Arabic',
                                              'Cairo',
                                              'sans-serif',
                                            ];

                                           // Shaded translucent highlight for the active/last read Ayah
                                           final Color? ayahBgColor = isHighlighted
                                                ? (isDark ? const Color(0x66D4AF37) : const Color(0x44D4AF37))
                                                : (isTargetAyah
                                                    ? (isDark
                                                        ? const Color(0xFF0284C7).withValues(alpha: 0.35)
                                                        : const Color(0xFFBAE6FD).withValues(alpha: 0.70))
                                                    : (isBookmarked
                                                        ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.20) : const Color(0xFFE0F2FE))
                                                        : null));

                                            final Color ayahTextColor = isHighlighted
                                                ? (isDark ? const Color(0xFFFFE082) : const Color(0xFF78350F))
                                                : (isTargetAyah ? (isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0369A1)) : (isDark ? Colors.white : const Color(0xFF0F172A)));

                                           // Register or retrieve tap gesture recognizer for this ayah
                                           final recognizer = _recognizers.putIfAbsent(ayahNum, () {
                                             final r = TapGestureRecognizer();
                                             r.onTap = () => _handleAyahTap(v, ayahNum);
                                             return r;
                                           });
                                           recognizer.onTap = () => _handleAyahTap(v, ayahNum);

                                           // Clean potential leading basmalah from first ayah if already in banner
                                           String cleanText = v.textUthmani.trim();
                                           if (ayahNum == 1 && _currentChapter.id != 1 && _currentChapter.id != 9) {
                                             cleanText = cleanText.replaceFirst('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', '').trim();
                                             cleanText = cleanText.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '').trim();
                                           }
                                           cleanText = VerseItem.sanitizeUthmaniText(cleanText.trim());

                                           final List<InlineSpan> ayahSpans = [];

                                           // Anchor widget for precise Scrollable.ensureVisible (width & height > 0 for valid geometry)
                                           ayahSpans.add(
                                             WidgetSpan(
                                               alignment: PlaceholderAlignment.middle,
                                               child: SizedBox(
                                                 key: _ayahKeys.putIfAbsent(ayahNum, () => GlobalKey()),
                                                 width: 1,
                                                 height: 1,
                                               ),
                                             ),
                                           );

                                           // Text segments: if Sajdah verse, apply line overline decoration on Sajdah phrase
                                           if (sajdah != null) {
                                             final segments = _splitVerseForSajdah(cleanText, sajdah);
                                             for (int i = 0; i < segments.length; i++) {
                                               final seg = segments[i];
                                               final segTrailing = (i == segments.length - 1) ? '' : ' ';
                                               if (seg.isSajdah) {
                                                 ayahSpans.add(
                                                   TextSpan(
                                                     text: '${seg.text}$segTrailing',
                                                     style: TextStyle(
                                                       fontFamily: quran.isUthmanicMode ? 'AmiriQuran' : null,
                                                       fontFamilyFallback: quran.isUthmanicMode ? uthmanicFallbacks : null,
                                                       fontSize: quran.fontSize,
                                                       height: quran.isUthmanicMode ? 2.45 : 2.2,
                                                       letterSpacing: 0.0,
                                                       wordSpacing: quran.isUthmanicMode ? 1.5 : null,
                                                       fontWeight: quran.isUthmanicMode ? FontWeight.normal : FontWeight.bold,
                                                       color: ayahTextColor,
                                                       backgroundColor: ayahBgColor,
                                                       decoration: TextDecoration.overline,
                                                       decorationColor: sajdah.isObligatory
                                                           ? const Color(0xFFEF4444)
                                                           : const Color(0xFFD4AF37),
                                                       decorationThickness: 2.5,
                                                     ),
                                                     recognizer: recognizer,
                                                   ),
                                                 );
                                               } else {
                                                 ayahSpans.add(
                                                   TextSpan(
                                                     text: '${seg.text}$segTrailing',
                                                     style: TextStyle(
                                                       fontFamily: quran.isUthmanicMode ? 'AmiriQuran' : null,
                                                       fontFamilyFallback: quran.isUthmanicMode ? uthmanicFallbacks : null,
                                                       fontSize: quran.fontSize,
                                                       height: quran.isUthmanicMode ? 2.45 : 2.2,
                                                       letterSpacing: 0.0,
                                                       wordSpacing: quran.isUthmanicMode ? 1.5 : null,
                                                       fontWeight: quran.isUthmanicMode
                                                           ? FontWeight.normal
                                                           : (isHighlighted ? FontWeight.bold : FontWeight.w600),
                                                       color: ayahTextColor,
                                                       backgroundColor: ayahBgColor,
                                                     ),
                                                     recognizer: recognizer,
                                                   ),
                                                 );
                                               }
                                             }

                                             // Insert the Sajdah mihrab symbol ۩ (\u06E9)
                                             ayahSpans.add(
                                               TextSpan(
                                                 text: ' ۩ ',
                                                 style: TextStyle(
                                                   fontSize: (quran.fontSize * 1.05).clamp(18.0, 32.0),
                                                   fontWeight: FontWeight.bold,
                                                   color: sajdah.isObligatory ? const Color(0xFFEF4444) : const Color(0xFFD4AF37),
                                                   backgroundColor: ayahBgColor,
                                                 ),
                                                 recognizer: recognizer,
                                               ),
                                             );

                                             // Insert small elegant Sajdah badge [سجدة واجبة] or [سجدة مستحبة]
                                             ayahSpans.add(
                                               WidgetSpan(
                                                 alignment: PlaceholderAlignment.middle,
                                                 child: GestureDetector(
                                                   onTap: () => _handleAyahTap(v, ayahNum),
                                                   child: Container(
                                                     margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                     decoration: BoxDecoration(
                                                       color: sajdah.isObligatory
                                                           ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.12)
                                                           : const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.25 : 0.15),
                                                       borderRadius: BorderRadius.circular(6),
                                                       border: Border.all(
                                                         color: sajdah.isObligatory ? const Color(0xFFEF4444) : const Color(0xFFD4AF37),
                                                         width: 0.9,
                                                       ),
                                                     ),
                                                     child: Text(
                                                       sajdah.shortBadge,
                                                       style: TextStyle(
                                                         fontSize: 10.5,
                                                         fontWeight: FontWeight.bold,
                                                         color: sajdah.isObligatory ? const Color(0xFFEF4444) : const Color(0xFFD4AF37),
                                                       ),
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                             );
                                           } else {
                                             // Normal verse
                                             ayahSpans.add(
                                               TextSpan(
                                                 text: cleanText,
                                                 style: TextStyle(
                                                   fontFamily: quran.isUthmanicMode ? 'AmiriQuran' : null,
                                                   fontFamilyFallback: quran.isUthmanicMode ? uthmanicFallbacks : null,
                                                   fontSize: quran.fontSize,
                                                   height: quran.isUthmanicMode ? 2.45 : 2.2,
                                                   letterSpacing: 0.0,
                                                   wordSpacing: quran.isUthmanicMode ? 1.5 : null,
                                                   fontWeight: quran.isUthmanicMode
                                                       ? FontWeight.normal
                                                       : (isHighlighted ? FontWeight.bold : FontWeight.w600),
                                                   color: ayahTextColor,
                                                   backgroundColor: ayahBgColor,
                                                 ),
                                                 recognizer: recognizer,
                                               ),
                                             );
                                           }

                                            // End of Ayah Quranic decorative symbol with Arabic numerals
                                            final ayahSymbolSize = (quran.fontSize * 1.25).clamp(22.0, 52.0);

                                            ayahSpans.add(
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.middle,
                                                child: AyahNumberSymbol(
                                                   ayahNumber: ayahNum,
                                                   size: ayahSymbolSize,
                                                   isHighlighted: isHighlighted,
                                                   backgroundColor: ayahBgColor,
                                                   symbolColor: ayahTextColor,
                                                   numberColor: ayahTextColor,
                                                   onTap: () => _handleAyahTap(v, ayahNum),
                                                 ),
                                              ),
                                            );
                                            ayahSpans.add(const TextSpan(text: ' '));

                                           return TextSpan(children: ayahSpans);
                                         }).toList(),
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  )
                                else
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                // Next Surah Button or Completion message at bottom
                                if (_currentChapter.id < 114) ...[
                                  Builder(builder: (context) {
                                    final nextChapter = QuranChapter.allChapters.firstWhere((c) => c.id == _currentChapter.id + 1);
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _nextChapter,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isDark
                                                  ? [const Color(0xFF1E2E40), const Color(0xFF1E293B)]
                                                  : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.25),
                                              width: 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.06),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_back_rounded,
                                                  color: Color(0xFF0284C7),
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'السورة التالية',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${nextChapter.isMakki ? "مكية" : "مدنية"} • ${HijriDateService.toArabicDigits(nextChapter.versesCount)} آية',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7),
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  'سورة ${nextChapter.nameArabic}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '✨ تمت ختمة القرآن الكريم بحمد الله تعالى ✨',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD4AF37),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Space so floating mini player never hides bottom card or verses
                                const SizedBox(height: 125),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

            // 3. Floating Recitation Mini-Player Bar at bottom with Collapsible side-dock
            if (_activeRecitingAyah != null || AudioPlayerService().isPlaying)
              Positioned(
                bottom: 12,
                left: (_activeRecitingAyah != null && _isPlayerCollapsed) ? null : 14,
                right: 14,
                child: _activeRecitingAyah == null
                    ? _buildFullSurahStopBar(isDark, quran)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.horizontal,
                              alignment: Alignment.centerRight,
                              child: child,
                            ),
                          );
                        },
                        child: _isPlayerCollapsed
                            ? _buildCollapsedPlayerDock(isDark, quran)
                            : _buildMiniPlayerBar(isDark, quran),
                      ),
              ),

            // 4. Floating Bookmark Pill Toast
            _buildBookmarkToast(isDark),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCollapsedPlayerDock(bool isDark, QuranProvider quran) {
    final playerService = AudioPlayerService();
    final isPlaying = playerService.isPlaying;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('collapsed_dock'),
        onTap: () => setState(() => _isPlayerCollapsed = false),
        onLongPress: () => _showAudioRecitationSheet(context, quran),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand Chevron
              const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFD4AF37),
                size: 20,
              ),
              const SizedBox(width: 4),

              // Reciter & Ayah Info
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الآية ${_toArabicDigits(_activeRecitingAyah ?? 1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    quran.selectedReciter.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Mini Play/Pause button
              GestureDetector(
                onTap: () {
                  playerService.togglePlayPause();
                  setState(() {});
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Dedicated Stop Audio button even when collapsed
              GestureDetector(
                onTap: () {
                  _stopContinuousRecitation();
                  playerService.stop();
                  setState(() {});
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullSurahStopBar(bool isDark, QuranProvider quran) {
    final playerService = AudioPlayerService();
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Color(0xFFD4AF37), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerService.currentTrack?.title ?? 'سورة ${_currentChapter.nameArabic}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    playerService.currentTrack?.subtitle ?? quran.selectedReciter.name,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('إيقاف الصوت', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                _stopContinuousRecitation();
                playerService.stop();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerBar(bool isDark, QuranProvider quran) {
    final playerService = AudioPlayerService();
    final isPlaying = playerService.isPlaying;

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('expanded_bar'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. Top Section: Reciter Info & Ayah Number (فوق في نفس البطاقة) ---
            InkWell(
              onTap: () => _showAudioRecitationSheet(context, quran),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    // Reciter Voice Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: Color(0xFFD4AF37),
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Reciter Name (given maximum available space)
                    Expanded(
                      child: Text(
                        quran.selectedReciter.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Ayah & Chapter Badge (compact)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                          width: 0.9,
                        ),
                      ),
                      child: Text(
                        '${_toArabicDigits(_activeRecitingAyah ?? 1)} / ${_toArabicDigits(_currentChapter.versesCount)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Subtle divider line
            Divider(
              height: 1,
              thickness: 0.7,
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),

            const SizedBox(height: 6),

            // --- 2. Bottom Section: Controls (إيقاف الصوت، تبديل الآية، حذف المشغل، طي المشغل) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Collapse to side button (طي المشغل)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  color: isDark ? Colors.white60 : Colors.black54,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'طي إلى الجانب',
                  onPressed: () => setState(() => _isPlayerCollapsed = true),
                ),

                // 2. Playback Controls in the middle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous Ayah (الآية السابقة)
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 24),
                      color: (_activeRecitingAyah ?? 1) > 1
                          ? const Color(0xFFD4AF37)
                          : (isDark ? Colors.white24 : Colors.black26),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: 'الآية السابقة',
                      onPressed: (_activeRecitingAyah ?? 1) > 1
                          ? () => playerService.previousAyah()
                          : null,
                    ),

                    const SizedBox(width: 8),

                    // Play / Pause (إيقاف الصوت / استئناف)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: isPlaying ? 'إيقاف مؤقت' : 'استئناف التلاوة',
                        onPressed: () => playerService.togglePlayPause(),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Next Ayah (تبديل للآية التي بعدها)
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 24),
                      color: (_activeRecitingAyah ?? 1) < _currentChapter.versesCount
                          ? const Color(0xFFD4AF37)
                          : (isDark ? Colors.white24 : Colors.black26),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: 'الآية التالية',
                      onPressed: (_activeRecitingAyah ?? 1) < _currentChapter.versesCount
                          ? () => playerService.nextAyah()
                          : null,
                    ),
                  ],
                ),

                // 3. Stop / Close button (حذف المشغل / إيقاف التلاوة)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.redAccent.shade200,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'إغلاق المشغل وإيقاف التلاوة',
                  onPressed: _stopContinuousRecitation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkToast(bool isDark) {
    return Positioned(
      bottom: _activeRecitingAyah != null ? (_isPlayerCollapsed ? 68 : 82) : 20,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showBookmarkPill ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: IgnorePointer(
          ignoring: !_showBookmarkPill,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF064E3B), // Dark green / mosque badge from screenshot
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mosque_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _bookmarkPillText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
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
}

class _VerseSegment {
  final String text;
  final bool isSajdah;
  const _VerseSegment(this.text, {this.isSajdah = false});
}
