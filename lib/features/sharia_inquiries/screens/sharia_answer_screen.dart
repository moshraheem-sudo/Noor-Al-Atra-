import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/sharia_answer.dart';

class ShariaAnswerScreen extends StatefulWidget {
  final ShariaAnswer item;

  const ShariaAnswerScreen({
    super.key,
    required this.item,
  });

  @override
  State<ShariaAnswerScreen> createState() => _ShariaAnswerScreenState();
}

class _ShariaAnswerScreenState extends State<ShariaAnswerScreen> {
  double _fontSize = 16.5;

  void _copyFullText() {
    final buf = StringBuffer()
      ..writeln('السؤال: ${widget.item.question}')
      ..writeln()
      ..writeln('الجواب: ${widget.item.answer}');
    if (widget.item.reference != null) {
      buf.writeln('\nالمرجع: ${widget.item.reference}');
    }
    if (widget.item.source != null) {
      buf.writeln('المصدر: ${widget.item.source}');
    }
    if (widget.item.url != null) {
      buf.writeln('الرابط: ${widget.item.url}');
    }

    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ السؤال والإجابة بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareFullText() {
    final buf = StringBuffer()
      ..writeln('📌 ${widget.item.title}')
      ..writeln()
      ..writeln('السؤال:\n${widget.item.question}')
      ..writeln()
      ..writeln('الإجابة:\n${widget.item.answer}');
    if (widget.item.reference != null) {
      buf.writeln('\nالمرجع: ${widget.item.reference}');
    }
    if (widget.item.url != null) {
      buf.writeln('\nالمصدر الأصلي: ${widget.item.url}');
    }
    buf.writeln('\nعبر تطبيق نور العترة');
    Share.share(buf.toString());
  }

  Future<void> _openExternalSource() async {
    final url = widget.item.url;
    if (url == null) return;
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF10B981) : const Color(0xFF1B3A57);
    const gold = Color(0xFFD97706);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: const Text(
            'المجيب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.text_decrease_rounded, size: 21),
              tooltip: 'تصغير الخط',
              onPressed: () => setState(() {
                if (_fontSize > 13.5) _fontSize -= 1.0;
              }),
            ),
            IconButton(
              icon: const Icon(Icons.text_increase_rounded, size: 21),
              tooltip: 'تكبير الخط',
              onPressed: () => setState(() {
                if (_fontSize < 24.0) _fontSize += 1.0;
              }),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              tooltip: 'نسخ',
              onPressed: _copyFullText,
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              tooltip: 'مشاركة',
              onPressed: _shareFullText,
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 36,
            ),
            children: [
            // Metadata chips
            if (widget.item.category != null ||
                widget.item.reference != null ||
                widget.item.source != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.item.category != null)
                    _DetailBadge(
                      icon: Icons.folder_outlined,
                      text: widget.item.category!,
                      color: accent,
                      isDark: isDark,
                    ),
                  if (widget.item.reference != null)
                    _DetailBadge(
                      icon: Icons.verified_outlined,
                      text: widget.item.reference!,
                      color: gold,
                      isDark: isDark,
                    ),
                  if (widget.item.source != null)
                    _DetailBadge(
                      icon: Icons.account_balance_outlined,
                      text: widget.item.source!,
                      color: isDark ? Colors.tealAccent.shade200 : const Color(0xFF0284C7),
                      isDark: isDark,
                    ),
                ],
              ),

            const SizedBox(height: 14),

            // Question Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFD0E6F7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded, size: 19, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'السؤال',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.item.title.isNotEmpty) ...[
                    Text(
                      widget.item.title,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: _fontSize + 0.5,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (widget.item.question != widget.item.title) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.item.question,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: _fontSize - 0.5,
                          height: 1.75,
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Answer Card (Verbatim published text)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.3,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 19, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'الإجابة المنشورة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      if (widget.item.createdAt != null)
                        Text(
                          widget.item.createdAt!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 22),
                  SelectableText(
                    widget.item.answer,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.85,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.item.url != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _openExternalSource,
                icon: const Icon(Icons.open_in_new_rounded, size: 19),
                label: const Text(
                  'عرض المصدر الأصلي',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _DetailBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Embedded in-app WebView fallback so the user never leaves Noor Al-Atra
/// if programmatic extraction is unavailable or when viewing the original page.
class ShariaWebViewFallbackScreen extends StatefulWidget {
  final String title;
  final String initialUrl;

  const ShariaWebViewFallbackScreen({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  State<ShariaWebViewFallbackScreen> createState() => _ShariaWebViewFallbackScreenState();
}

class _ShariaWebViewFallbackScreenState extends State<ShariaWebViewFallbackScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _progress = 0;

  static const String _hideAppBannerJs = '''
    (function() {
      function removeInstallBanner() {
        var all = document.querySelectorAll('div, section, aside, footer');
        for (var i = 0; i < all.length; i++) {
          var el = all[i];
          var txt = (el.innerText || '').trim();
          if (txt.indexOf('تثبيت تطبيق المجيب') !== -1 && el.offsetHeight < 180) {
            el.style.setProperty('display', 'none', 'important');
            el.remove();
          }
        }
        var links = document.querySelectorAll('a[href*="play.google.com"], a[href*="apps.apple.com"], a[href*="/app"]');
        for (var j = 0; j < links.length; j++) {
          var parent = links[j].closest('.fixed-bottom, [style*="position: fixed"], [class*="banner"], [class*="install"], [class*="download"]');
          if (parent && parent.offsetHeight < 180) {
            parent.style.setProperty('display', 'none', 'important');
            parent.remove();
          }
        }
      }
      removeInstallBanner();
      if (!window._noorBannerObserver) {
        window._noorBannerObserver = new MutationObserver(removeInstallBanner);
        window._noorBannerObserver.observe(document.body || document.documentElement, { childList: true, subtree: true });
      }
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            _controller.runJavaScript(_hideAppBannerJs).catchError((_) {});
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _controller.runJavaScript(_hideAppBannerJs).catchError((_) {});
              }
            });
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
              onPressed: () {
                setState(() => _hasError = false);
                _controller.reload();
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'فتح في المتصفح',
              onPressed: () => launchUrl(
                Uri.parse(widget.initialUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress > 0 && _progress <= 100 ? _progress / 100.0 : null,
                minHeight: 3,
              ),
            Expanded(
              child: _hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'تعذر تحميل صفحة المجيب حالياً',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _hasError = false);
                                _controller.reload();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
