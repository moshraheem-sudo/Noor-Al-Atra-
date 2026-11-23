import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallpaper_item.dart';
import '../services/wallpaper_service.dart';
import '../services/voice_search_service.dart';

class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  final WallpaperService _wallpaperService = WallpaperService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<WallpaperItem> _allWallpapers = [];
  List<WallpaperItem> _filteredWallpapers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  List<String> get _categories {
    final Set<String> cats = {'الكل'};
    for (final item in _allWallpapers) {
      if (item.category.trim().isNotEmpty) {
        cats.add(item.category.trim());
      }
    }
    if (cats.length == 1) {
      cats.addAll([
        'العتبة العلوية المقدسة',
        'العتبة العسكرية المقدسة',
        'العتبة الحسينية المقدسة',
        'العتبة العباسية المقدسة',
      ]);
    }
    return cats.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    final items = await _wallpaperService.loadWallpapers(forceRefresh: forceRefresh);

    if (mounted) {
      setState(() {
        _allWallpapers = items;
        _isLoading = false;
        _isRefreshing = false;
        _applyFilters();
      });
      if (forceRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث الخلفيات بنجاح (${items.length} خلفية)',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<WallpaperItem> result = _allWallpapers;

    if (_selectedCategory != 'الكل') {
      result = result.where((item) {
        final cat = item.category.trim();
        final sel = _selectedCategory.trim();
        return cat == sel || cat.contains(sel) || sel.contains(cat);
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            (item.shrine?.toLowerCase().contains(q) ?? false) ||
            item.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    setState(() {
      _filteredWallpapers = result;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'خلفيات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'تحديث من المستودع',
            onPressed: () => _loadData(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar with Voice Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن عتبة أو مرقد أو خلفية...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.mic, color: Color(0xFF0284C7), size: 20),
                        tooltip: 'البحث الصوتي',
                        onPressed: () async {
                          final spoken = await VoiceSearchService.startVoiceSearch(
                            context,
                            prompt: 'تحدث باسم العتبة أو المرقد...',
                          );
                          if (spoken != null && spoken.isNotEmpty) {
                            _searchCtrl.text = spoken;
                            _onSearchChanged(spoken);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),

          // 2. Category Filter Pills
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF059669),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    onSelected: (_) => _onCategorySelected(cat),
                  ),
                );
              },
            ),
          ),

          // 3. Grid of Wallpapers
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _filteredWallpapers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wallpaper_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد خلفيات مطابقة للبحث',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredWallpapers.length,
                        itemBuilder: (context, index) {
                          final item = _filteredWallpapers[index];
                          return _WallpaperCard(
                            item: item,
                            onTap: () => _openFullscreenViewer(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenViewer(WallpaperItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenWallpaperViewer(item: item),
      ),
    );
  }
}

class _WallpaperCard extends StatelessWidget {
  final WallpaperItem item;
  final VoidCallback onTap;

  const _WallpaperCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Real Shrine Image via CachedNetworkImage with dual fallback
            CachedNetworkImage(
              imageUrl: item.thumbnailUrl.isNotEmpty ? item.thumbnailUrl : item.imageUrl,
              httpHeaders: const {'User-Agent': 'NoorAlAtra/1.0'},
              fit: BoxFit.cover,
              memCacheWidth: 400,
              placeholder: (context, url) => Container(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                final full = item.imageUrl;
                final thumb = item.thumbnailUrl;
                if (full.isNotEmpty && full != thumb && full.startsWith('http')) {
                  return CachedNetworkImage(
                    imageUrl: full,
                    httpHeaders: const {'User-Agent': 'NoorAlAtra/1.0'},
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    placeholder: (_, __) => Container(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/Glossy Gallery Photo Badge.png',
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return Image.asset(
                  'assets/images/Glossy Gallery Photo Badge.png',
                  fit: BoxFit.cover,
                );
              },
            ),

            // Top gradient & HD badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hd_rounded, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      '4K HD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom gradient overlay with title & shrine
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
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
}

class _FullscreenWallpaperViewer extends StatefulWidget {
  final WallpaperItem item;

  const _FullscreenWallpaperViewer({required this.item});

  @override
  State<_FullscreenWallpaperViewer> createState() => _FullscreenWallpaperViewerState();
}

class _FullscreenWallpaperViewerState extends State<_FullscreenWallpaperViewer> {
  final WallpaperService _wallpaperService = WallpaperService();
  bool _isProcessing = false;
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _prepareLocalFile();
  }

  Future<void> _prepareLocalFile() async {
    final file = await _wallpaperService.downloadWallpaperFile(
      widget.item.imageUrl,
      widget.item.id,
    );
    if (mounted) {
      setState(() => _downloadedFile = file);
    }
  }

  Future<void> _setWallpaperDialog() async {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تعيين كخلفية للجهاز 📱',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اختر الشاشة التي ترغب بتطبيق الخلفية عليها:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.home_rounded, color: Color(0xFF059669)),
                  title: const Text('الشاشة الرئيسية فقط', style: TextStyle(color: Colors.white)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.white.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyWallpaper('home');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.lock_rounded, color: Color(0xFF0284C7)),
                  title: const Text('شاشة القفل فقط', style: TextStyle(color: Colors.white)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.white.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyWallpaper('lock');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.phone_android_rounded, color: Colors.amber),
                  title: const Text('كلا الشاشتين (الرئيسية والقفل)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.amber.withValues(alpha: 0.15),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyWallpaper('both');
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyWallpaper(String target) async {
    setState(() => _isProcessing = true);

    try {
      final file = _downloadedFile ??
          await _wallpaperService.downloadWallpaperFile(widget.item.imageUrl, widget.item.id);

      if (file != null && file.existsSync()) {
        final success = await _wallpaperService.applyDeviceWallpaper(file: file, target: target);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'تم تعيين الخلفية بنجاح على جهازك المبارك ✨' : 'تعذر تعيين الخلفية، يرجى المحاولة ثانية',
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
              ),
              backgroundColor: success ? const Color(0xFF059669) : Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تطبيق الخلفية: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadToGallery() async {
    setState(() => _isProcessing = true);
    try {
      final savedPath = await _wallpaperService.saveWallpaperToGallery(
        widget.item.imageUrl,
        widget.item.id,
      );

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'تم حفظ الصورة بنجاح في معرض الصور الخاص بك 📥✨',
                style: TextStyle(fontFamily: 'Amiri', fontSize: 14),
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تعذر حفظ الصورة في المعرض، يرجى التحقق من الأذونات'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تنزيل الصورة: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareWallpaper() async {
    try {
      final file = _downloadedFile ??
          await _wallpaperService.downloadWallpaperFile(widget.item.imageUrl, widget.item.id);
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '${widget.item.title}\nمن تطبيق نور العترة 🕊️\nالمصدر: ${widget.item.sourceName}',
        );
      }
    } catch (e) {
      debugPrint('Error sharing wallpaper: $e');
    }
  }

  Future<void> _openSourceUrl() async {
    if (widget.item.sourceUrl.isNotEmpty) {
      final uri = Uri.parse(widget.item.sourceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pinch-to-zoom interactive viewer
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: widget.item.imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: widget.item.imageUrl,
                      httpHeaders: const {'User-Agent': 'NoorAlAtra/1.0'},
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/Glossy Gallery Photo Badge.png',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      widget.item.imageUrl.startsWith('assets/')
                          ? widget.item.imageUrl
                          : 'assets/images/Glossy Gallery Photo Badge.png',
                      fit: BoxFit.contain,
                    ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.item.sourceUrl.isNotEmpty)
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.amber),
                      tooltip: 'زيارة موقع العتبة الرسمي',
                      onPressed: _openSourceUrl,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Action Panel
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  // Set as Wallpaper Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _setWallpaperDialog,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.wallpaper_rounded, size: 20),
                      label: Text(
                        _isProcessing ? 'جاري المعالجة...' : 'تعيين كخلفية',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Download to Gallery Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                    ),
                    icon: const Icon(Icons.download_rounded, color: Color(0xFF38BDF8)),
                    tooltip: 'تنزيل وحفظ في المعرض',
                    onPressed: _isProcessing ? null : _downloadToGallery,
                  ),
                  const SizedBox(width: 6),
                  // Share Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    tooltip: 'مشاركة',
                    onPressed: _shareWallpaper,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
