import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Zahra Tasbeeh State: 34 Allahu Akbar, 33 Alhamdulillah, 33 SubhanAllah
  int _currentStep = 0; // 0: Allahu Akbar, 1: Alhamdulillah, 2: SubhanAllah
  int _stepCount = 0;

  final List<String> _stepNames = ['اللهُ أَكْبَرُ', 'الْحَمْدُ لِلَّهِ', 'سُبْحَانَ اللَّهِ'];
  final List<int> _stepMax = [34, 33, 33];

  // Free Tasbeeh State
  int _freeCount = 0;
  int _targetCount = 100; // 0 means open/infinite
  bool _vibrationEnabled = true;

  final List<String> _popularAdhkar = [
    'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ وَعَجِّلْ فَرَجَهُمْ',
    'أَسْتَغْفِرُ اللَّهَ رَبِّي وَأَتُوبُ إِلَيْهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
    'لَا إِلَهَ إِلَّا اللَّهُ الْمَلِكُ الْحَقُّ الْمُبِينُ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    'يَا صَاحِبَ الزَّمَانِ أَدْرِكْنَا',
  ];
  String _selectedDhikr = 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _freeCount = StorageService().getFreeTasbeehCount();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _tapZahra() {
    if (_vibrationEnabled) HapticFeedback.lightImpact();
    setState(() {
      _stepCount++;
      if (_stepCount >= _stepMax[_currentStep]) {
        if (_currentStep < 2) {
          _currentStep++;
          _stepCount = 0;
          if (_vibrationEnabled) HapticFeedback.mediumImpact();
        } else {
          // Completed all 100
          _currentStep = 0;
          _stepCount = 0;
          if (_vibrationEnabled) HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تقبل الله طاعتكم! أتممت تسبيحة الزهراء (ع) كاملة 🌸', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFF1B5E20),
            ),
          );
        }
      }
    });
  }

  void _resetZahra() {
    setState(() {
      _currentStep = 0;
      _stepCount = 0;
    });
  }

  void _tapFree() {
    if (_vibrationEnabled) HapticFeedback.lightImpact();
    setState(() {
      _freeCount++;
      if (_targetCount > 0 && _freeCount == _targetCount) {
        if (_vibrationEnabled) HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ما شاء الله! أتممت الهدف المحدد ($_targetCount تسبيحة) 🎉',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
    StorageService().setFreeTasbeehCount(_freeCount);
  }

  void _resetFree() {
    setState(() {
      _freeCount = 0;
    });
    StorageService().setFreeTasbeehCount(0);
  }

  void _showCustomTargetDialog() {
    final textController = TextEditingController(
      text: _targetCount > 0 ? _targetCount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('تحديد عدد التسبيحات', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اكتب العدد الذي ترغب بالوصول إليه في هذا الورد المبارك (مثلاً: 100 أو 500 أو 1000):',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'مثلاً: 100',
                labelText: 'العدد المطلوب',
                prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF1B5E20)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _targetCount = 0; // Open/infinite
              });
              Navigator.pop(ctx);
            },
            child: const Text('تسبيح مفتوح (بلا حد)', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = int.tryParse(textController.text.trim());
              if (val != null && val > 0) {
                setState(() {
                  _targetCount = val;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ الهدف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDhikrPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'اختر صيغة الذكر أو التسبيح:',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _popularAdhkar.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final dhikr = _popularAdhkar[i];
                    final isSelected = dhikr == _selectedDhikr;
                    return ListTile(
                      title: Text(
                        dhikr,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1B5E20) : null,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF1B5E20)) : null,
                      onTap: () {
                        setState(() {
                          _selectedDhikr = dhikr;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'المسبحة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _vibrationEnabled ? Icons.vibration : Icons.mobile_off,
                color: _vibrationEnabled ? const Color(0xFF1B5E20) : Colors.grey,
              ),
              tooltip: _vibrationEnabled ? 'الاهتزاز مفعل' : 'الاهتزاز معطل',
              onPressed: () {
                setState(() {
                  _vibrationEnabled = !_vibrationEnabled;
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: const Color(0xFF1B5E20),
            labelColor: const Color(0xFF1B5E20),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'تسبيحة الزهراء (ع)', icon: Icon(Icons.circle_outlined)),
              Tab(text: 'السبحة الحرة', icon: Icon(Icons.touch_app)),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildZahraTab(),
              _buildFreeTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZahraTab() {
    final progress = (_stepCount / _stepMax[_currentStep]).clamp(0.0, 1.0);
    final totalCompleted = (_currentStep == 0
            ? 0
            : _currentStep == 1
                ? 34
                : 34 + 33) +
        _stepCount;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current Phrase
            Text(
              _stepNames[_currentStep],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'المرحلة ${_currentStep + 1} من 3 • الإجمالي: $totalCompleted / 100',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Big Tap Button with Circular Progress
            GestureDetector(
              onTap: _tapZahra,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                    ),
                  ),
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_stepCount',
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'من ${_stepMax[_currentStep]}',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Reset Button
            OutlinedButton.icon(
              onPressed: _resetZahra,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة البدء'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTab() {
    final double? progressValue = _targetCount > 0 ? (_freeCount / _targetCount).clamp(0.0, 1.0) : null;
    final isTargetReached = _targetCount > 0 && _freeCount >= _targetCount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // 1. Selected Dhikr Box (Tappable to change)
          InkWell(
            onTap: _showDhikrPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF1B5E20), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDhikr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1B5E20), size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Large Tap Circle with Target Progress Ring
          GestureDetector(
            onTap: _tapFree,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_targetCount > 0)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTargetReached ? Colors.amber : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                Container(
                  width: 195,
                  height: 195,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isTargetReached
                          ? [const Color(0xFF047857), const Color(0xFF059669)]
                          : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isTargetReached ? const Color(0xFF059669) : const Color(0xFF1B5E20))
                            .withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_freeCount',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_targetCount > 0)
                          Text(
                            'الهدف: $_targetCount',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          )
                        else
                          Text(
                            'تسبيح مفتوح',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Target Configuration Card Under the Circle (As requested by user!)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.track_changes_rounded, color: Color(0xFF1B5E20), size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _targetCount > 0 ? 'الهدف: $_targetCount' : 'الهدف: مفتوح ∞',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showCustomTargetDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 13, color: Color(0xFF1B5E20)),
                            SizedBox(width: 4),
                            Text(
                              'عدد مخصص',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Target Selection Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTargetChip(label: '33', target: 33),
                      const SizedBox(width: 8),
                      _buildTargetChip(label: '70 (استغفار)', target: 70),
                      const SizedBox(width: 8),
                      _buildTargetChip(label: '100', target: 100),
                      const SizedBox(width: 8),
                      _buildTargetChip(label: '500', target: 500),
                      const SizedBox(width: 8),
                      _buildTargetChip(label: '1000', target: 1000),
                      const SizedBox(width: 8),
                      _buildTargetChip(label: 'مفتوح ∞', target: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Action Buttons (Reset)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _resetFree,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('تصفير العداد', style: TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip({required String label, required int target}) {
    final isSelected = _targetCount == target;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1B5E20),
      onSelected: (_) {
        setState(() {
          _targetCount = target;
        });
      },
    );
  }
}

