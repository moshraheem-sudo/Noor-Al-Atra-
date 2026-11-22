import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/widgets/ayah_number_symbol.dart';

void main() {
  test('AyahNumberSymbol.toArabicDigits converts integers correctly', () {
    expect(AyahNumberSymbol.toArabicDigits(1), '١');
    expect(AyahNumberSymbol.toArabicDigits(12), '١٢');
    expect(AyahNumberSymbol.toArabicDigits(255), '٢٥٥');
    expect(AyahNumberSymbol.toArabicDigits(286), '٢٨٦');
  });

  testWidgets('AyahNumberSymbol renders vector rosette canvas and Eastern Arabic numerals', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AyahNumberSymbol(
              ayahNumber: 255,
              size: 30.0,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    // Verify CustomPaint vector rosette exists
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify foreground Arabic numerals exist
    expect(find.text('٢٥٥'), findsOneWidget);

    // Tap and verify callback
    await tester.tap(find.byType(AyahNumberSymbol));
    expect(tapped, true);
  });

  testWidgets('AyahNumberSymbol integrates seamlessly into Text.rich with WidgetSpan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ',
                  style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 24, color: Colors.white),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AyahNumberSymbol(
                    ayahNumber: 255,
                    size: 24.0 * 1.25, // 30.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'), findsOneWidget);
    expect(find.text('٢٥٥'), findsOneWidget);
  });
}
