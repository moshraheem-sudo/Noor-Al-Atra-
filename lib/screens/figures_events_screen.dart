import 'package:flutter/material.dart';
import '../models/person.dart';
import '../services/data_service.dart';
import 'person_detail_screen.dart';

enum FiguresListType {
  infallibles,
  prominent,
}

/// الشاشة الرئيسية لـ "شخصيات أهل البيت (عليهم السلام)"
/// تحتوي في الأعلى على نافذتين/زرين بشكل صف عمودي مطابق للصورة المرفقة
class FiguresEventsScreen extends StatefulWidget {
  const FiguresEventsScreen({super.key});

  @override
  State<FiguresEventsScreen> createState() => _FiguresEventsScreenState();
}

class _FiguresEventsScreenState extends State<FiguresEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFiguresList(BuildContext context, FiguresListType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FiguresListScreen(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPeople = DataService().people;

    final filteredPeople = _searchQuery.isEmpty
        ? <Person>[]
        : allPeople.where((p) {
            final q = _searchQuery.trim().toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.title.toLowerCase().contains(q) ||
                p.father.toLowerCase().contains(q) ||
                p.bio.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'شخصيات أهل البيت (عليهم السلام)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Search Bar for instant figure lookup
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ابحث عن معصوم أو شخصية جليلة...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF0284C7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // If searching, show search results
          if (_searchQuery.isNotEmpty) ...[
            Text(
              'نتائج البحث (${filteredPeople.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 8),
            if (filteredPeople.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'لم يتم العثور على شخصية مطابقة',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              ...filteredPeople.map((person) {
                return _buildFigureCard(context, person, isDark);
              }),
          ] else ...[
            // 2. The Two Vertical Windows/Buttons matching Image 1:
            // "الأئمة المعصومين (عليهم السلام)"
            _buildCategoryPillButton(
              context: context,
              title: 'الأئمة المعصومين (عليهم السلام)',
              isDark: isDark,
              onTap: () => _openFiguresList(context, FiguresListType.infallibles),
            ),

            const SizedBox(height: 12),

            // "الشخصيات البارزة"
            _buildCategoryPillButton(
              context: context,
              title: 'الشخصيات البارزة',
              isDark: isDark,
              onTap: () => _openFiguresList(context, FiguresListType.prominent),
            ),

            const SizedBox(height: 24),

            // 3. Informational Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16202C) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'دليل السيرة العطرة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'يتضمن هذا الدليل المبارك السيرة المختصرة والمعلومات الدقيقة عن النبي الأعظم (ص) وأئمة أهل البيت المعصومين الأربعة عشر (عليهم السلام)، بالإضافة إلى الشخصيات الجليلة وأعلام أصحاب الأئمة الكرام، مع بيان ألقابهم، وتواريخ ولاداتهم وشهاداتهم، ومراقد هم الشريفة.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// زر الفئة البيضاوي الأنيق المطابق للصورة 1 بالضبط
  Widget _buildCategoryPillButton({
    required BuildContext context,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFE6F1FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFC7DEFA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF90CAF9)).withValues(alpha: isDark ? 0.25 : 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0F4C5C),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFigureCard(BuildContext context, Person person, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202C) : const Color(0xFFEDF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFD0E5FA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PersonDetailScreen(person: person)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar circle with person silhouette on the right (in RTL)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFDCEBF8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF0284C7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Figure name and title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        person.title,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شاشة استعراض الشخصيات المطابقة تماماً للصورة 2 والصورة 3
class FiguresListScreen extends StatelessWidget {
  final FiguresListType type;

  const FiguresListScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPeople = DataService().people;

    final isInf = type == FiguresListType.infallibles;
    final people = isInf
        ? allPeople.where((p) => p.id <= 14).toList()
        : allPeople.where((p) => p.id > 14).toList();

    final screenTitle = isInf
        ? 'الأئمة المعصومين (عليهم السلام)'
        : 'الشخصيات البارزة';
    final titleEmoji = isInf ? '🕌' : '⭐';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background subtle arched decorative header pattern
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: CustomPaint(
              painter: _SubtleIslamicPatternPainter(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.08)
                    : const Color(0xFF93C5FD).withValues(alpha: 0.2),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom AppBar matching screenshot:
                // Close 'X' on left, title + emoji in center, back arrow '->' on right
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      // Close button (X on left) - returns to calendar/home
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        tooltip: 'إغلاق',
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),

                      // Center Title + Emoji (الأئمة المعصومين عليهم السلام 🕌 / الشخصيات البارزة ⭐)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                screenTitle,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              titleEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                      // Back button (-> on right) - returns to categories selection
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 24),
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        tooltip: 'رجوع',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.8, color: Colors.black12),

                // Figures List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return _buildFigureCard(context, person, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الشخصية المطابقة للصور 2 و 3
  Widget _buildFigureCard(BuildContext context, Person person, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202C) : const Color(0xFFEDF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFD0E5FA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PersonDetailScreen(person: person)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar circle with blue person silhouette icon on the right (in RTL)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E2E40) : const Color(0xFFDCEBF8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF0284C7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        person.title,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// رسام زخرفي رقيق خلف شريط التطبيق لمحاكاة التصميم المرفق في الصور
class _SubtleIslamicPatternPainter extends CustomPainter {
  final Color color;

  _SubtleIslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    // ارسم دوائر وأقواس هندسية رقيقة
    for (double r = 40; r <= 160; r += 28) {
      canvas.drawCircle(Offset(centerX, 0), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SubtleIslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
