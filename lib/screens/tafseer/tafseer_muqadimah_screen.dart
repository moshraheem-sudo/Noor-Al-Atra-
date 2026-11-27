import 'package:flutter/material.dart';
import '../../models/tafseer_model.dart';
import '../../repositories/tafseer_repository.dart';

class TafseerMuqadimahScreen extends StatefulWidget {
  final TafseerType type;
  const TafseerMuqadimahScreen({super.key, required this.type});

  @override
  State<TafseerMuqadimahScreen> createState() => _TafseerMuqadimahScreenState();
}

class _TafseerMuqadimahScreenState extends State<TafseerMuqadimahScreen> {
  String? _content;
  bool _isLoading = true;
  double _fontSize = 17.5;

  @override
  void initState() {
    super.initState();
    _loadMuqadimah();
  }

  Future<void> _loadMuqadimah() async {
    final text = await TafseerRepository().getMuqadimah(widget.type);
    final size = TafseerRepository().getFontSize();
    if (mounted) {
      setState(() {
        _content = text;
        _fontSize = size;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'مقدمة ${widget.type.shortName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'حجم الخط',
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 24 ? 15 : _fontSize + 2;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : (_content == null || _content!.isEmpty)
              ? const Center(child: Text('لا توجد مقدمة متوفرة لهذا التفسير'))
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 16, 18, 24 + MediaQuery.of(context).padding.bottom),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  widget.type.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.type.author,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SelectableText(
                            _cleanContent(_content!),
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.85,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  String _cleanContent(String raw) {
    return raw
        .replaceAll(RegExp(r'^#+ ', multiLine: true), '')
        .replaceAll('****', '\n───── ✦ ─────\n')
        .replaceAll('```arabic', '')
        .replaceAll('```', '');
  }
}
