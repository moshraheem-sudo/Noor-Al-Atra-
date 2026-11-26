import 'dart:async';
import 'package:flutter/material.dart';

import '../models/sharia_answer.dart';
import '../services/sharia_search_service.dart';
import '../widgets/sharia_loading_view.dart';
import '../widgets/sharia_result_card.dart';
import '../widgets/sharia_search_field.dart';
import 'sharia_answer_screen.dart';

class ShariaSearchScreen extends StatefulWidget {
  final ShariaSearchService? searchService;

  const ShariaSearchScreen({
    super.key,
    this.searchService,
  });

  @override
  State<ShariaSearchScreen> createState() => _ShariaSearchScreenState();
}

class _ShariaSearchScreenState extends State<ShariaSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final ShariaSearchService _service;

  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isLoadingMore = false;

  ShariaSearchStatus _status = ShariaSearchStatus.initial;
  String _activeQuery = '';
  int _currentPage = 1;
  int _totalResults = 0;
  List<ShariaAnswer> _results = [];
  String? _errorMessage;
  String? _fallbackWebUrl;

  static const List<String> _suggestedTopics = [
    'أحكام الصلاة',
    'الوضوء',
    'الصوم',
    'الخمس',
    'الحج',
    'المعاملات',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.searchService ?? ShariaSearchService();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch({String? overrideQuery, bool resetPage = true}) async {
    if (_isSearching) return;

    final query = (overrideQuery ?? _searchController.text).trim();
    if (overrideQuery != null) {
      _searchController.text = overrideQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: overrideQuery.length),
      );
    }

    _focusNode.unfocus();

    if (query.isEmpty) {
      setState(() {
        _status = ShariaSearchStatus.invalidInput;
        _errorMessage = 'يرجى كتابة سؤالك الشرعي أو كلمات البحث أولاً.';
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _status = ShariaSearchStatus.loading;
      _activeQuery = query;
      if (resetPage) {
        _currentPage = 1;
        _results = [];
      }
      _errorMessage = null;
    });

    final response = await _service.search(query, page: 1);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _status = response.status;
      _results = response.results;
      _totalResults = response.total;
      _currentPage = response.page;
      _errorMessage = response.errorMessage;
      _fallbackWebUrl = response.fallbackWebUrl;
    });
  }

  Future<void> _loadMore() async {
    if (_isSearching || _isLoadingMore || _activeQuery.isEmpty) return;

    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final response = await _service.search(_activeQuery, page: nextPage);

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (response.status == ShariaSearchStatus.success && response.results.isNotEmpty) {
        _currentPage = nextPage;
        _results = [..._results, ...response.results];
      }
    });
  }

  void _openEmbeddedWebFallback() {
    final url = _fallbackWebUrl ?? ShariaSearchService.buildWebSearchUrl(_activeQuery);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShariaWebViewFallbackScreen(
          title: 'نتائج المجيب: $_activeQuery',
          initialUrl: url,
        ),
      ),
    );
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _status = ShariaSearchStatus.initial;
      _activeQuery = '';
      _results = [];
      _totalResults = 0;
      _errorMessage = null;
      _fallbackWebUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF10B981) : const Color(0xFF1B3A57);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'المجيب',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header & Search Box
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ابحث عن المسائل والأجوبة الشرعية وفق مدرسة أهل البيت (عليهم السلام)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShariaSearchField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      isLoading: _isSearching,
                      onSearch: () => _performSearch(),
                      onClear: _clearSearch,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              // Body area
              Expanded(
                child: _buildBody(context, isDark, accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, Color accent) {
    switch (_status) {
      case ShariaSearchStatus.loading:
        return ShariaLoadingView(query: _activeQuery);

      case ShariaSearchStatus.success:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: _results.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      'النتائج المنشورة ($_totalResults)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'المصدر: المجيب',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (index == _results.length + 1) {
              if (_results.length >= _totalResults) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton.icon(
                  onPressed: _isLoadingMore ? null : _loadMore,
                  icon: _isLoadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(_isLoadingMore ? 'جاري تحميل المزيد...' : 'عرض المزيد من النتائج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }

            final item = _results[index - 1];
            return ShariaResultCard(
              item: item,
              onReadFull: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShariaAnswerScreen(item: item),
                  ),
                );
              },
              onOpenSource: item.url != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShariaWebViewFallbackScreen(
                            title: item.title,
                            initialUrl: item.url!,
                          ),
                        ),
                      );
                    }
                  : null,
            );
          },
        );

      case ShariaSearchStatus.empty:
        return _StateMessageView(
          icon: Icons.search_off_rounded,
          title: 'لم يتم العثور على نتائج مطابقة',
          subtitle: 'جرّب البحث بكلمات مفتاحية أقصر أو مختلفة عن «$_activeQuery».',
          accent: accent,
          isDark: isDark,
          onRetry: () => _performSearch(),
          onOpenWebFallback: _openEmbeddedWebFallback,
        );

      case ShariaSearchStatus.invalidInput:
        return _StateMessageView(
          icon: Icons.edit_note_rounded,
          title: 'أدخل نص السؤال للبحث',
          subtitle: _errorMessage ?? 'يرجى كتابة كلمات البحث أولاً.',
          accent: accent,
          isDark: isDark,
        );

      case ShariaSearchStatus.offline:
        return _StateMessageView(
          icon: Icons.wifi_off_rounded,
          title: 'لا يوجد اتصال بالإنترنت',
          subtitle: _errorMessage ?? 'يرجى التحقق من اتصال الشبكة والمحاولة مجدداً.',
          accent: accent,
          isDark: isDark,
          onRetry: () => _performSearch(),
        );

      case ShariaSearchStatus.timeout:
        return _StateMessageView(
          icon: Icons.hourglass_disabled_rounded,
          title: 'انتهت مهلة الطلب',
          subtitle: _errorMessage ?? 'استغرق الاتصال وقتاً أطول من المعتاد.',
          accent: accent,
          isDark: isDark,
          onRetry: () => _performSearch(),
          onOpenWebFallback: _openEmbeddedWebFallback,
        );

      case ShariaSearchStatus.sourceUnavailable:
      case ShariaSearchStatus.invalidResponse:
        return _StateMessageView(
          icon: Icons.cloud_off_rounded,
          title: 'تعذر جلب النتائج مباشرة',
          subtitle: _errorMessage ?? 'يمكنك عرض صفحة نتائج المجيب مباشرة داخل التطبيق.',
          accent: accent,
          isDark: isDark,
          onRetry: () => _performSearch(),
          onOpenWebFallback: _openEmbeddedWebFallback,
        );

      case ShariaSearchStatus.initial:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFD0E6F7),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.question_answer_rounded,
                        size: 30,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'البحث الفوري في المسائل الشرعية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اكتب سؤالك في المربع أعلاه لاستعراض الفتاوى والأجوبة المنشورة مسبقاً من مستودع موقع المجيب مباشرة داخل التطبيق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.2,
                        height: 1.6,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مواضيع مقترحة للبحث:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTopics.map((topic) {
                  return ActionChip(
                    label: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    backgroundColor: accent.withValues(alpha: isDark ? 0.15 : 0.08),
                    side: BorderSide(color: accent.withValues(alpha: 0.25)),
                    onPressed: () => _performSearch(overrideQuery: topic),
                  );
                }).toList(),
              ),
            ],
          ),
        );
    }
  }
}

class _StateMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenWebFallback;

  const _StateMessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    this.onRetry,
    this.onOpenWebFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            if (onRetry != null || onOpenWebFallback != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (onRetry != null)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (onOpenWebFallback != null)
                    OutlinedButton.icon(
                      onPressed: onOpenWebFallback,
                      icon: const Icon(Icons.web_rounded, size: 18),
                      label: const Text('عرض نتائج المجيب داخل التطبيق'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
