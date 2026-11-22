import 'dart:math';
import 'package:flutter/material.dart';

/// ويدجت علامة الترقيم القرآني المزخرفة لنهاية الآيات (Quranic Ayah Number Symbol)
/// ترسم رمز نهاية الآية القرآني المزخرف بدقة متناهية عبر الرسم الشعاعي (Vector Canvas)
/// لتفادي مشكلة الرموز غير المعرفة (Tofu / Box ⊠) في المحاكيات والأجهزة التي لا تدعم رمز \u06DD.
///
/// الميزات:
/// 1) طبقة خلفية ترسم دائرة الترقيم القرآنية والزخارف الإسلامية المحيطة بلون ذهبي إسلامي Color(0xFFD4AF37).
/// 2) طبقة أمامية متمركزة في المنتصف تماماً تضع رقم الآية بالأرقام العربية المشرقية (١، ٢، ٣...).
/// 3) تحجيم ديناميكي سلس ومضبوط تماماً دون أي انزياح أو خروج عن الإطار.
class AyahNumberSymbol extends StatelessWidget {
  final int ayahNumber;
  final double size;
  final Color? symbolColor;
  final Color? numberColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final EdgeInsetsGeometry? margin;

  const AyahNumberSymbol({
    super.key,
    required this.ayahNumber,
    this.size = 28.0,
    this.symbolColor,
    this.numberColor,
    this.backgroundColor,
    this.onTap,
    this.isHighlighted = false,
    this.margin,
  });

  /// تحويل الأرقام الإنجليزية إلى الأرقام العربية المشرقية (١، ٢، ٣...)
  static String toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? arabicDigits[digit] : char;
    }).join('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);

    final effectiveSymbolColor = symbolColor ??
        (isHighlighted ? const Color(0xFFD4AF37) : defaultColor);
    final effectiveNumberColor = numberColor ??
        (isHighlighted ? const Color(0xFFD4AF37) : defaultColor);

    final digits = toArabicDigits(ayahNumber);

    // نسبة الخط للأرقام داخل الدائرة:
    // لأرقام من 1 إلى 9: 0.44 * size
    // لأرقام من 10 إلى 99: 0.38 * size
    // للأرقام المكونة من 3 خانات (مثل آية 102، 286): 0.31 * size
    final double numFontSize = (digits.length >= 3 ? 0.31 : (digits.length == 2 ? 0.38 : 0.44)) * size;

    Widget content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. الرسم الشعاعي للعلامة القرآنية المزخرفة (مطابقة تماماً لرسم المصحف الشريف)
          Positioned.fill(
            child: CustomPaint(
              painter: _QuranicAyahSymbolPainter(
                color: effectiveSymbolColor,
                isHighlighted: isHighlighted,
              ),
            ),
          ),

          // 2. الطبقة الأمامية: متمركزة في المنتصف تماماً برقم الآية بالأرقام العربية
          Center(
            child: SizedBox(
              width: size * 0.60,
              height: size * 0.60,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    digits,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    strutStyle: const StrutStyle(
                      forceStrutHeight: true,
                      height: 1.0,
                      leading: 0,
                    ),
                    style: TextStyle(
                      fontSize: numFontSize,
                      fontWeight: FontWeight.bold,
                      color: effectiveNumberColor,
                      fontFamily: 'AmiriQuran',
                      fontFamilyFallback: const ['Amiri', 'UthmanicHafs', 'Cairo', 'sans-serif'],
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (backgroundColor != null) {
      content = Container(
        color: backgroundColor,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: content,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// رسام شعاعي لعلامة الترقيم القرآنية المزخرفة الأصيلة (رمز الوردة ونهاية الآيات)
class _QuranicAyahSymbolPainter extends CustomPainter {
  final Color color;
  final bool isHighlighted;

  const _QuranicAyahSymbolPainter({
    required this.color,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = (size.width / 2) - 1.5;
    if (maxR <= 0) return;

    // 1. وهج ناعم إذا كانت الآية قيد التلاوة المباشرة
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawCircle(center, maxR, glowPaint);
    }

    final ringR = maxR * 0.86;
    final innerR = ringR * 0.80;

    // 2. الإطار الدائري الخارجي الأساسي
    final outerRingPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;
    canvas.drawCircle(center, ringR, outerRingPaint);

    // 3. الحلقة الدائرية الداخلية الرقيقة
    final innerRingPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerR, innerRingPaint);

    // 4. الزخارف الخارجية الثمانية (أعلى، أسفل، يمين، يسار، والزوايا الأربع) بنمط المصحف الشريف
    final finialPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final finialStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // تيجان الجهات الأربع الرئيسية (0°, 90°, 180°, 270°)
    final cardinalFinialLength = maxR - ringR;
    _drawCardinalFinial(canvas, center, ringR, cardinalFinialLength, -pi / 2, finialPaint); // أعلى
    _drawCardinalFinial(canvas, center, ringR, cardinalFinialLength, pi / 2, finialPaint);  // أسفل
    _drawCardinalFinial(canvas, center, ringR, cardinalFinialLength, 0, finialPaint);       // يمين
    _drawCardinalFinial(canvas, center, ringR, cardinalFinialLength, pi, finialPaint);      // يسار

    // وريقات الزوايا الأربع (45°, 135°, 225°, 315°)
    for (int i = 0; i < 4; i++) {
      final angle = (pi / 4) + (i * pi / 2);
      final lobeCenter = Offset(center.dx + ringR * cos(angle), center.dy + ringR * sin(angle));
      canvas.drawCircle(lobeCenter, maxR * 0.08, finialStrokePaint);
      canvas.drawCircle(lobeCenter, maxR * 0.04, finialPaint);
    }
  }

  void _drawCardinalFinial(Canvas canvas, Offset center, double baseR, double len, double angle, Paint paint) {
    final tip = Offset(center.dx + (baseR + len) * cos(angle), center.dy + (baseR + len) * sin(angle));
    final perpAngle = angle + pi / 2;
    final halfWidth = len * 0.75;
    final leftBase = Offset(center.dx + baseR * cos(angle) + halfWidth * cos(perpAngle),
        center.dy + baseR * sin(angle) + halfWidth * sin(perpAngle));
    final rightBase = Offset(center.dx + baseR * cos(angle) - halfWidth * cos(perpAngle),
        center.dy + baseR * sin(angle) - halfWidth * sin(perpAngle));

    final path = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuranicAyahSymbolPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isHighlighted != isHighlighted;
}
