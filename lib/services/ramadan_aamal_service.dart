import '../models/ramadan_section.dart';
import '../models/worship_item.dart';
import 'data_service.dart';
import 'ramadan_texts.dart';

class RamadanAamalService {
  static final RamadanAamalService _instance = RamadanAamalService._internal();
  factory RamadanAamalService() => _instance;
  RamadanAamalService._internal();

  List<RamadanSection>? _cachedSections;

  List<RamadanSection> getSections() {
    if (_cachedSections != null) return _cachedSections!;

    final rawList = DataService().getItemsByCategory('aamal_ramadan');
    final Map<String, String> raw = {};
    for (var item in rawList) {
      raw[item.title.trim()] = item.text;
    }

    final sections = <RamadanSection>[];

    // Helper to find raw item safely
    String getRaw(String key) {
      for (final entry in raw.entries) {
        if (entry.key.contains(key) || key.contains(entry.key)) {
          return entry.value;
        }
      }
      return '';
    }

    String getSahifa(String query) {
      final sahifa = DataService().getItemsByCategory('sahifaSajjadiya');
      for (var x in sahifa) {
        if (x.title.contains(query)) {
          return x.text;
        }
      }
      return '';
    }

    String getGen(String query) {
      final gen = DataService().getItemsByCategory('generalPrayers');
      for (var x in gen) {
        if (x.title.contains(query)) {
          return x.text;
        }
      }
      return '';
    }

    WorshipItem createItem(String title, String text) {
      return WorshipItem(
        title: title,
        text: text,
        categoryKey: 'aamal_ramadan',
      );
    }

    // 1. أعمال أسحار شهر رمضان المبارك (8 أعمال وأدعية)
    final saharText = getRaw('أسحار');
    if (saharText.isNotEmpty) {
      final saharItems = <WorshipItem>[];
      final idxBahaa = saharText.indexOf('دعاء البهاء');
      final idxAbuHamza = saharText.indexOf('دعاء أبي حمزة الثمالي');
      final idxDuaFiSahar = saharText.indexOf('دعاء في السحر');
      final idxIdris = saharText.indexOf('دعاء إدريس');
      final idxYaMafzai = saharText.indexOf('دعاء يا مفزعي');
      final idxTasbeeh = saharText.indexOf('تسبيح السحر');
      final idxNiyya = saharText.indexOf('نية الصوم');

      if (idxBahaa != -1 && idxAbuHamza != -1 && idxDuaFiSahar != -1) {
        saharItems.add(createItem('فضل السحور وقراءة سورة القدر', saharText.substring(0, idxBahaa).trim()));
        saharItems.add(createItem('دعاء البهاء (المروي عن الإمام الباقر عليه السلام)', saharText.substring(idxBahaa, idxAbuHamza).trim()));
        saharItems.add(createItem('دعاء أبي حمزة الثمالي (المروي عن الإمام زين العابدين عليه السلام)', saharText.substring(idxAbuHamza, idxDuaFiSahar).trim()));
        saharItems.add(createItem('دعاء في السحر: يا عُدّتي في كُربَتي', saharText.substring(idxDuaFiSahar, idxIdris != -1 ? idxIdris : saharText.length).trim()));
        if (idxIdris != -1 && idxYaMafzai != -1) {
          saharItems.add(createItem(
            'دعاء إدريس عليه السلام في السحر',
            'السادس: تدعو بدعاء إدريس الذي رواه الشيخ في (المصباح) والسيّد في (الإقبال):\n\n${RamadanTexts.duaIdris}',
          ));
        }
        if (idxYaMafzai != -1 && idxTasbeeh != -1) {
          saharItems.add(createItem('دعاء يا مَفزَعي عِندَ كُربَتي (أقصر أدعية السحر)', saharText.substring(idxYaMafzai, idxTasbeeh).trim()));
        }
        if (idxTasbeeh != -1 && idxNiyya != -1) {
          saharItems.add(createItem('تسبيحات السحر المروية في الإقبال', saharText.substring(idxTasbeeh, idxNiyya).trim()));
        }
        if (idxNiyya != -1) {
          saharItems.add(createItem('نية الصوم المبارك وآدابه', saharText.substring(idxNiyya).trim()));
        }
      } else {
        saharItems.add(createItem('أعمال أسحار شهر رمضان المبارك', saharText));
      }

      sections.add(RamadanSection(
        id: 'sahar',
        title: 'أعمال أسحار شهر رمضان المبارك',
        subtitle: '${saharItems.length} أدعية وأعمال مباركة (دعاء البهاء، أبو حمزة، السحر...)',
        items: saharItems,
      ));
    }

    // 2. أعمال ليالي شهر رمضان المبارك
    final nightComm1 = getRaw('ما يُستحب إتيانه في ليالي شهر رمضان');
    final nightComm2 = getRaw('أن يدعو في كل ليلة من شهر رمضان');
    final nightCommItems = <WorshipItem>[];

    if (nightComm1.isNotEmpty) {
      final nIftar = nightComm1.indexOf('الأول: الإفطار');
      final nLokma = nightComm1.indexOf('الرابع: أن يقول عند أوّل لقمة');
      final nRabRamadan = nightComm1.indexOf('التاسع: روى السيّد');
      final nDuaHajj = nightComm1.indexOf('العاشر: أن يدعو بعد المغرب بدعاء الحج');

      if (nIftar != -1 && nLokma != -1 && nRabRamadan != -1 && nDuaHajj != -1) {
        nightCommItems.add(createItem('آداب الإفطار ودعواته المأثورة', nightComm1.substring(nIftar, nLokma).trim()));
        nightCommItems.add(createItem('دعاء أول لقمة من الإفطار وسورة القدر والصدقة', nightComm1.substring(nLokma, nRabRamadan).trim()));
        nightCommItems.add(createItem('دعاء غفران ذنوب أربعين سنة: اللهم رب شهر رمضان', nightComm1.substring(nRabRamadan, nDuaHajj).trim()));
        nightCommItems.add(createItem(
          'دعاء الحج المأثور بعد المغرب',
          'العاشر: أن يدعو بعد المغرب بدعاء الحج المأثور:\n\n${RamadanTexts.duaHajj}',
        ));
      } else {
        nightCommItems.add(createItem('ما يستحب إتيانه في ليالي شهر رمضان', nightComm1));
      }
    }

    if (nightComm2.isNotEmpty) {
      final n11 = nightComm2.indexOf('الحادي عشر:');
      final n12 = nightComm2.indexOf('الثاني عشر:');
      final n13 = nightComm2.indexOf('الثالث عشر:');
      final n14 = nightComm2.indexOf('الرابع عشر:');
      final n15 = nightComm2.indexOf('الخامس عشر:');
      final n16 = nightComm2.indexOf('السادس عَشر:');

      if (n11 != -1 && n12 != -1 && n13 != -1 && n14 != -1 && n15 != -1 && n16 != -1) {
        nightCommItems.add(createItem('الدعاء الحادي عشر في كل ليلة من شهر رمضان', nightComm2.substring(n11, n12).trim()));
        nightCommItems.add(createItem('دعاء الافتتاح المأثور في كل ليلة من شهر رمضان', nightComm2.substring(n12, n13).trim()));
        nightCommItems.add(createItem('الدعاء الثالث عشر المأثور عن الصادق عليه السلام', nightComm2.substring(n13, n14).trim()));
        nightCommItems.add(createItem('دعاء أنيس الصالحين في كل ليلة', nightComm2.substring(n14, n15).trim()));
        nightCommItems.add(createItem('صلاة ركعتين في كل ليلة وفضلها وتسبيحها', nightComm2.substring(n15, n16).trim()));
        nightCommItems.add(createItem('قراءة سورة إنا فتحنا في صلاة مسنونة', nightComm2.substring(n16).trim()));
      } else {
        nightCommItems.add(createItem('أن يدعو في كل ليلة من شهر رمضان', nightComm2));
      }
    }

    if (nightCommItems.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'night_common',
        title: 'أعمال ليالي شهر رمضان المبارك',
        subtitle: '${nightCommItems.length} أعمال وأدعية (الإفطار، دعاء الافتتاح، صلاة كل ليلة...)',
        items: nightCommItems,
      ));
    }

    // 3. أعمال اليوم الأوّل من شهر رمضان (7 أعمال)
    final day1Text = getRaw('أعمال اليوم الأوّل من شهر رمضان');
    if (day1Text.isNotEmpty) {
      final day1Items = <WorshipItem>[];
      final d1 = day1Text.indexOf('الأول:');
      final d2 = day1Text.indexOf('الثاني:');
      final d3 = day1Text.indexOf('الثالث:');
      final d4 = day1Text.indexOf('الرابع:');
      final d5 = day1Text.indexOf('الخامس:');
      final d6 = day1Text.indexOf('السادس:');
      final d7 = day1Text.indexOf('السابع:');

      if (d1 != -1 && d2 != -1 && d3 != -1 && d4 != -1 && d5 != -1 && d6 != -1 && d7 != -1) {
        day1Items.add(createItem('العمل الأول: الغسل بماء جارٍ وفضله العظيم', day1Text.substring(d1, d2).trim()));
        day1Items.add(createItem('العمل الثاني: غسل الوجه بماء الورد لدفع الفقر والمذلة', day1Text.substring(d2, d3).trim()));
        day1Items.add(createItem('العمل الثالث: صلاة ركعتي أول الشهر والصدقة', day1Text.substring(d3, d4).trim()));
        day1Items.add(createItem('العمل الرابع: صلاة ركعتين بسورة الفتح للحفظ طوال العام', day1Text.substring(d4, d5).trim()));
        day1Items.add(createItem('العمل الخامس: دعاء طلوع الفجر في اليوم الأول', day1Text.substring(d5, d6).trim()));
        final dua44 = getSahifa('٤٤');
        day1Items.add(createItem(
          'العمل السادس: الدعاء الرابع والأربعون من الصحيفة السجادية',
          'السادس: دعاء الإمام علي بن الحسين زين العابدين (عليهما السلام) عند دخول شهر رمضان (الدعاء الرابع والأربعون من أدعية الصحيفة الكاملة):\n\n${dua44.isNotEmpty ? dua44 : day1Text.substring(d6, d7).trim()}',
        ));
        day1Items.add(createItem('العمل السابع: دعاء الإمام الكاظم عليه السلام في أول السنة (دعاء عظيم الشأن)', day1Text.substring(d7).trim()));
      } else {
        day1Items.add(createItem('أعمال اليوم الأوّل من شهر رمضان', day1Text));
      }

      sections.add(RamadanSection(
        id: 'day1',
        title: 'أعمال اليوم الأوّل من شهر رمضان',
        subtitle: '${day1Items.length} أعمال مباركة (الغسل، الصلوات، دعاء الكاظم ع)',
        items: day1Items,
      ));
    }

    // 4. أعمال اللّيلة الأولى من شهر رمضان (12 عملاً)
    final night1Text = getRaw('أعمال اللّيلة الأولى من شهر رمضان');
    if (night1Text.isNotEmpty) {
      final night1Items = <WorshipItem>[];
      final n1_1 = night1Text.indexOf('الأول: الاستهلال');
      final n1_5 = night1Text.indexOf('الخامس: الغسل');
      final n1_8 = night1Text.indexOf('الثامن: أن يبدأ');
      final n1_9 = night1Text.indexOf('التاسع: أن يصلّي');
      final n1_10 = night1Text.indexOf('العاشر: أن يدعو');
      final n1_11 = night1Text.indexOf('الحادي عَشر:');
      final n1_12 = night1Text.indexOf('الثاني عَشر:');
      final n1_13 = night1Text.indexOf('الثالث عَشر:');
      final n1_14 = night1Text.indexOf('الرابع عَشر:');
      final n1_15 = night1Text.indexOf('الخامس عَشر:');
      final n1_17 = night1Text.indexOf('السّابع عَشر:');
      final n1_18 = night1Text.indexOf('الثامن عَشر:');

      if (n1_1 != -1 && n1_5 != -1 && n1_8 != -1 && n1_11 != -1 && n1_17 != -1) {
        night1Items.add(createItem('الاستهلال وأدعية رؤية الهلال (الأول إلى الرابع)', night1Text.substring(n1_1, n1_5).trim()));
        night1Items.add(createItem('العمل الخامس إلى السابع: الغسل وزيارة الحسين (ع)', night1Text.substring(n1_5, n1_8).trim()));
        if (n1_9 != -1) night1Items.add(createItem('العمل الثامن: الصلاة ألف ركعة في شهر رمضان', night1Text.substring(n1_8, n1_9).trim()));
        if (n1_9 != -1 && n1_10 != -1) night1Items.add(createItem('العمل التاسع: صلاة ركعتين بسورة الأنعام للحفظ', night1Text.substring(n1_9, n1_10).trim()));
        if (n1_10 != -1 && n1_11 != -1) night1Items.add(createItem('العمل العاشر: دعاء آخر ليلة من شعبان المأثور', night1Text.substring(n1_10, n1_11).trim()));
        if (n1_12 != -1) night1Items.add(createItem('العمل الحادي عشر: دعاء الإمام الجواد (ع) بعد المغرب', night1Text.substring(n1_11, n1_12).trim()));
        if (n1_12 != -1 && n1_13 != -1) night1Items.add(createItem('العمل الثاني عشر: دعاء الإمام الصادق (ع) المروي في الإقبال', night1Text.substring(n1_12, n1_13).trim()));
        if (n1_13 != -1 && n1_14 != -1) {
          final dua44 = getSahifa('٤٤');
          night1Items.add(createItem(
            'العمل الثالث عشر: دعاء الصحيفة السجادية لدخول شهر رمضان',
            'الثالث عَشر: أن يدعو بالدعاء الرابع والأربعين من أدعية الصحيفة الكاملة لدخول شهر رمضان المبارك للإمام زين العابدين (عليه السلام):\n\n${dua44.isNotEmpty ? dua44 : night1Text.substring(n1_13, n1_14).trim()}',
          ));
        }
        if (n1_14 != -1 && n1_15 != -1) night1Items.add(createItem('العمل الرابع عشر: دعاء الإقبال الطويل (اللهم إن هذا شهر رمضان)', night1Text.substring(n1_14, n1_15).trim()));
        if (n1_15 != -1 && n1_17 != -1) night1Items.add(createItem('العمل الخامس عشر والسادس عشر: دعاء النبي (ص) لدخول شهر رمضان', night1Text.substring(n1_15, n1_17).trim()));
        if (n1_17 != -1 && n1_18 != -1) {
          final joshan = getGen('الجوشن الكبير');
          night1Items.add(createItem(
            'العمل السابع عشر: دعاء الجوشن الكبير المبارك',
            'السّابع عَشر: استحباب قراءة دعاء الجوشن الكبير في أول ليلة من شهر رمضان المبارك:\n\n${joshan.isNotEmpty ? joshan : night1Text.substring(n1_17, n1_18).trim()}',
          ));
        }
        if (n1_18 != -1) {
          final remaining = night1Text.substring(n1_18).replaceFirst(RegExp(r'الثامن عَشر:[^\n]*\n*'), '').trim();
          night1Items.add(createItem(
            'العمل الثامن عشر والتاسع عشر: دعاء الحج وتلاوة القرآن الكريم',
            'الثامن عَشر: أن يدعو بعد المغرب بدعاء الحج المأثور:\n\n${RamadanTexts.duaHajj}\n\n◆ $remaining',
          ));
        }
      } else {
        night1Items.add(createItem('أعمال اللّيلة الأولى من شهر رمضان', night1Text));
      }

      sections.add(RamadanSection(
        id: 'night1',
        title: 'أعمال اللّيلة الأولى من شهر رمضان',
        subtitle: '${night1Items.length} أعمال ودعوات (الاستهلال، الجوشن، الغسل، الزيارة...)',
        items: night1Items,
      ));
    }

    // 5. صلوات ليالي شهر رمضان (مفصلة ليلة بليلة)
    final salawatRaw = getRaw('صلوات ليالي شهر رمضان');
    if (salawatRaw.isNotEmpty) {
      final salawatItems = <WorshipItem>[];
      final idxFirst = salawatRaw.indexOf('صلاة اللّيلة الاُولى:');
      if (idxFirst != -1) {
        salawatItems.add(createItem('فضل صلوات ليالي شهر رمضان (مقدمة العلامة المجلسي)', salawatRaw.substring(0, idxFirst).trim()));
      }

      final lines = salawatRaw.split('\n');
      String curTitle = '';
      StringBuffer curText = StringBuffer();

      for (final line in lines) {
        final t = line.trim();
        final isNightHeading = t.startsWith('صلاة اللّيلة الاُولى:') ||
            t.startsWith('اللّيلة الثّانية:') ||
            t.startsWith('الثّالثة:') ||
            t.startsWith('الرّابعة:') ||
            t.startsWith('الخامسة:') ||
            t.startsWith('◆ السادسة:') ||
            t.startsWith('السابعة:') ||
            t.startsWith('الثّامنة:') ||
            t.startsWith('التاسعة:') ||
            t.startsWith('◆ العاشرة:') ||
            t.startsWith('الحادية عشرة:') ||
            t.startsWith('الثّانية عشرة:') ||
            t.startsWith('الثّالثة عشرة:') ||
            t.startsWith('الرّابعة عشرة:') ||
            t.startsWith('الخامسة عشرة:') ||
            t.startsWith('السّادسة عشرة:') ||
            t.startsWith('السّابعة عشرة:') ||
            t.startsWith('◆ الثّامنة عشرة:') ||
            t.startsWith('التّاسعة عشرة:') ||
            t.startsWith('صلوات اللّيلة العشرين') ||
            t.startsWith('الخامسة والعشرين:') ||
            t.startsWith('السّادسة والعشرين:') ||
            t.startsWith('السّابعة والعشرين:') ||
            t.startsWith('الثّامنة والعشرين:') ||
            t.startsWith('أقول: صلاة اللّيلة الثّامنة') ||
            t.startsWith('التّاسعة والعشرين:') ||
            t.startsWith('الثلاثين:');

        if (isNightHeading) {
          if (curTitle.isNotEmpty && curText.isNotEmpty) {
            salawatItems.add(createItem(curTitle, curText.toString().trim()));
            curText.clear();
          }
          curTitle = t.replaceAll('◆', '').split(':').first.trim();
          if (!curTitle.contains('صلاة')) curTitle = 'صلاة $curTitle';
          curText.writeln(t);
        } else if (curTitle.isNotEmpty) {
          curText.writeln(line);
        }
      }

      if (curTitle.isNotEmpty && curText.isNotEmpty) {
        salawatItems.add(createItem(curTitle, curText.toString().trim()));
      }

      sections.add(RamadanSection(
        id: 'salawat',
        title: 'صلوات ليالي شهر رمضان المبارك',
        subtitle: '${salawatItems.length} صلاة مأثورة (مقسمة ليلة بليلة من الليلة 1 إلى 30)',
        items: salawatItems.isNotEmpty ? salawatItems : [createItem('صلوات ليالي شهر رمضان', salawatRaw)],
      ));
    }

    // 6. دعوات الأيام المشهورة لشهر رمضان (مفصلة يوماً بيوم)
    final dailyDuasRaw = getRaw('دعوات الأيام المشهورة لشهر رمضان');
    if (dailyDuasRaw.isNotEmpty) {
      final dailyItems = <WorshipItem>[];
      final lines = dailyDuasRaw.split('\n');
      String curTitle = 'فضل دعوات الأيام المأثورة عن النبي (ص)';
      StringBuffer curText = StringBuffer();

      for (var line in lines) {
        final trimmed = line.trim();
        final isDayHeading = trimmed.startsWith('دعاء اليوم الأول:') ||
            (trimmed.contains('اليوم') && (trimmed.startsWith('◆ اليوم') || trimmed.startsWith('اليوم')) && trimmed.endsWith(':'));

        if (isDayHeading) {
          if (curText.isNotEmpty) {
            dailyItems.add(createItem(curTitle, curText.toString().trim()));
            curText.clear();
          }
          curTitle = trimmed.replaceAll('◆', '').replaceAll(':', '').trim();
          if (!curTitle.startsWith('دعاء')) curTitle = 'دعاء $curTitle';
        } else if (trimmed.startsWith('◆ أقول: اختلفت كتب الدعوات')) {
          if (curText.isNotEmpty) {
            dailyItems.add(createItem(curTitle, curText.toString().trim()));
            curText.clear();
          }
          curTitle = 'تنبيه حول ترتيب بعض دعوات الأيام';
          curText.writeln(line);
        } else {
          curText.writeln(line);
        }
      }

      if (curText.isNotEmpty) {
        dailyItems.add(createItem(curTitle, curText.toString().trim()));
      }

      sections.add(RamadanSection(
        id: 'daily_duas',
        title: 'دعوات الأيام المشهورة لشهر رمضان',
        subtitle: '${dailyItems.length} دعاءً مأثوراً (دعاء كل يوم من أيام شهر رمضان 1 - 30)',
        items: dailyItems,
      ));
    }

    // 7. أعمال ليالي القدر المباركة (الأعمال المشتركة)
    final qadrFull = getRaw('أعمال الليلة التاسعة عشرة من شهر رمضان');
    final qadrSummary = getRaw('ملخص كل ليلة من ليالي القدر');
    final qadrItems = <WorshipItem>[];

    if (qadrFull.isNotEmpty) {
      final qIntro = qadrFull.indexOf('القسم الأوّل عدّة أعمال:');
      final q1 = qadrFull.indexOf('الأول: الغسل');
      final q2 = qadrFull.indexOf('الثاني: الصلاة ركعتان');
      final q3 = qadrFull.indexOf('الثالث: تأخذ المصحف');
      final q4 = qadrFull.indexOf('الرّابع: خذ المصحف');
      final q5 = qadrFull.indexOf('الخامس: زيارة الحسين');
      final q6 = qadrFull.indexOf('السادس: إحياء هذه الليالي');
      final q7 = qadrFull.indexOf('وقد روى الكفعمي هذا الدّعاء');

      if (q1 != -1 && q2 != -1 && q3 != -1 && q4 != -1 && q5 != -1 && q6 != -1) {
        if (qIntro != -1) {
          qadrItems.add(createItem('فضل ليالي القدر المباركة وعظمتها', qadrFull.substring(0, qIntro).trim()));
        }
        qadrItems.add(createItem('العمل الأول: الغسل عند غروب الشمس', qadrFull.substring(q1, q2).trim()));
        qadrItems.add(createItem('العمل الثاني: صلاة ركعتين بالتوحيد سبعاً والاستغفار سبعين مرّة', qadrFull.substring(q2, q3).trim()));
        qadrItems.add(createItem('العمل الثالث: نشر المصحف الشريف بين يديك والدعاء به', qadrFull.substring(q3, q4).trim()));
        qadrItems.add(createItem('العمل الرابع: رفع المصحف على الرأس والتوسل بالمعصومين (عليهم السلام)', qadrFull.substring(q4, q5).trim()));
        qadrItems.add(createItem('العمل الخامس: زيارة الإمام الحسين عليه السلام في ليالي القدر', qadrFull.substring(q5, q6).trim()));
        qadrItems.add(createItem('العمل السادس: إحياء ليلة القدر بالعبادة والمناجاة', qadrFull.substring(q6, q7 != -1 ? q7 : qadrFull.length).trim()));
        if (q7 != -1) {
          qadrItems.add(createItem('دعاء الإمام زين العابدين (عليه السلام) في ليالي القدر', qadrFull.substring(q7).trim()));
        }
      } else {
        qadrItems.add(createItem('الأعمال المشتركة لليالي القدر', qadrFull));
      }

      sections.add(RamadanSection(
        id: 'qadr_shared',
        title: 'أعمال ليالي القدر المباركة (الأعمال المشتركة)',
        subtitle: '${qadrItems.length} أعمال مباركة (الغسل، رفع المصاحف، الزيارة، الإحياء...)',
        items: qadrItems,
      ));
    }

    // 8. أعمال الليلة التاسعة عشرة من شهر رمضان
    final night19Items = <WorshipItem>[];
    night19Items.add(createItem('فضل الليلة التاسعة عشرة ومصاب أمير المؤمنين (ع)', 'الليلة التاسعة عشرة: وهي أولى ليالي القدر، وفي صبيحتها ضُرب أمير المؤمنين عليه السلام في محرابه بالسيف المسموم ففاز بالشهادة والرضوان، ويستحب فيها الغسل والزيارة والإحياء.'));
    if (qadrSummary.isNotEmpty) {
      final idxLaan = qadrSummary.indexOf('الثاني: مائة مرّة:');
      final idxDua1 = qadrSummary.indexOf('الثالث: دعاء:');
      final idxDua2 = qadrSummary.indexOf('الرابع: يقول:');

      if (idxLaan != -1 && idxDua1 != -1 && idxDua2 != -1) {
        night19Items.add(createItem('الاستغفار مائة مرّة: أستَغفِرُ الله رَبّي وأتوبُ إلَيهِ', qadrSummary.substring(0, idxLaan).trim()));
        night19Items.add(createItem('مائة مرّة: اللَّهُمَّ العَن قَتَلَةَ أميرِ المُؤمِنينَ', qadrSummary.substring(idxLaan, idxDua1).trim()));
        night19Items.add(createItem('دعاء: يا ذا الَّذي كانَ قَبلَ كُلِّ شَيءٍ', qadrSummary.substring(idxDua1, idxDua2).trim()));
        night19Items.add(createItem('دعاء: اللَّهُمَّ اجعَل فيما تَقضي وَتُقَدِّرُ مِنَ الأمرِ المَحتومِ', qadrSummary.substring(idxDua2).trim()));
      } else {
        night19Items.add(createItem('أعمال الليلة التاسعة عشرة المأثورة', qadrSummary));
      }
    }
    sections.add(RamadanSection(
      id: 'night19',
      title: 'أعمال الليلة التاسعة عشرة من شهر رمضان',
      subtitle: '${night19Items.length} أعمال خاصة (الاستغفار 100، لعن القتلة 100، الأدعية المأثورة)',
      items: night19Items,
    ));

    // 9. أعمال الليلة الواحدة والعشرين من شهر رمضان
    final night21Text = getRaw('أعمال الليلة الواحدة والعشرين من شهر رمضان');
    if (night21Text.isNotEmpty) {
      final night21Items = <WorshipItem>[];
      final idx21Dua = night21Text.indexOf('دعاء الليلة الحادية والعشرين');
      final idx21Ashar = night21Text.indexOf('العشر الأواخر');

      if (idx21Ashar != -1 && idx21Dua != -1 && idx21Ashar < idx21Dua) {
        night21Items.add(createItem('فضل الليلة الحادية والعشرين وشهادة أمير المؤمنين (ع) وزيارته', night21Text.substring(0, idx21Ashar).trim()));
        night21Items.add(createItem('أدعية العشر الأواخر من شهر رمضان المبارك (المروية في الكافي والإقبال)', night21Text.substring(idx21Ashar, idx21Dua).trim()));
        night21Items.add(createItem('دعاء الليلة الحادية والعشرين المروي في البلد الأمين', night21Text.substring(idx21Dua).trim()));
      } else if (idx21Ashar != -1) {
        night21Items.add(createItem('فضل الليلة الحادية والعشرين وشهادة أمير المؤمنين (ع) وأعمالها', night21Text.substring(0, idx21Ashar).trim()));
        night21Items.add(createItem('أدعية العشر الأواخر من شهر رمضان المبارك', night21Text.substring(idx21Ashar).trim()));
      } else {
        night21Items.add(createItem('أعمال الليلة الواحدة والعشرين من شهر رمضان', night21Text));
      }
      sections.add(RamadanSection(
        id: 'night21',
        title: 'أعمال الليلة الواحدة والعشرين من شهر رمضان',
        subtitle: '${night21Items.length} أعمال وأدعية (شهادة أمير المؤمنين ع، أدعية العشر الأواخر)',
        items: night21Items,
      ));
    }

    // 10. أعمال الليلة الثالثة والعشرين من شهر رمضان (ليلة القدر الكبرى)
    final night23Text = getRaw('أعمال الليلة الثالثة والعشرين من شهر رمضان');
    if (night23Text.isNotEmpty) {
      final night23Items = <WorshipItem>[];
      final n23Sowar = night23Text.indexOf('الأول: قراءة سورتي العنكبوت والروم');
      final n23Ghusl = night23Text.indexOf('◆ الثامِن: أن ياتي غسلاً آخر');

      if (n23Sowar != -1 && n23Ghusl != -1) {
        night23Items.add(createItem('دعاء الفرج للإمام المهدي (عج) وأدعية الليلة الثالثة والعشرين', night23Text.substring(0, n23Sowar).trim()));
        night23Items.add(createItem('قراءة سورتي العنكبوت والروم وسورة الدخان وسورة القدر ألف مرة', night23Text.substring(n23Sowar, n23Ghusl).trim()));
        night23Items.add(createItem('الغسل الثاني في آخر الليل وأدعية ختام الليلة الثالثة والعشرين', night23Text.substring(n23Ghusl).trim()));
        final makarem = getSahifa('مَكارِمِ');
        final tawba = getSahifa('التَّوْبَة');
        if (makarem.isNotEmpty) {
          night23Items.add(createItem(
            'دعاء مكارم الأخلاق للإمام السجاد (ع) (المندوب في ليلة القدر)',
            'دعاء مكارم الأخلاق ومرضي الأفعال للإمام زين العابدين علي بن الحسين عليهما السلام (الدعاء العشرون من الصحيفة السجادية):\n\n$makarem',
          ));
        }
        if (tawba.isNotEmpty) {
          night23Items.add(createItem(
            'دعاء التوبة للإمام السجاد (ع) (المندوب في ليلة القدر)',
            'دعاء الإمام زين العابدين علي بن الحسين عليهما السلام في ذكر التوبة وطلبها (الدعاء الحادي والثلاثون من الصحيفة السجادية):\n\n$tawba',
          ));
        }
      } else {
        night23Items.add(createItem('أعمال الليلة الثالثة والعشرين من شهر رمضان', night23Text));
      }
      sections.add(RamadanSection(
        id: 'night23',
        title: 'أعمال الليلة الثالثة والعشرين من شهر رمضان',
        subtitle: 'ليلة القدر الكبرى وعظيمة الشأن والبركات',
        items: night23Items,
      ));
    }

    // 11. أعمال الليالي البيض (13 و 14 و 15)
    final w13 = getRaw('أعمال الليلة الثالثة عشرة');
    final w14 = getRaw('أعمال الليلة الرابعة عشرة');
    final w15 = getRaw('أعمال الليلة الخامسة عشرة');
    final whiteItems = <WorshipItem>[];
    if (w13.isNotEmpty) whiteItems.add(createItem('أعمال الليلة الثالثة عشرة من شهر رمضان (أولى الليالي البيض)', w13));
    if (w14.isNotEmpty) whiteItems.add(createItem('أعمال الليلة الرابعة عشرة من شهر رمضان', w14));
    if (w15.isNotEmpty) whiteItems.add(createItem('أعمال الليلة الخامسة عشرة (ولادة الإمام الحسن المجتبى عليه السلام)', w15));
    final mujeer = getGen('المجير');
    if (mujeer.isNotEmpty) {
      whiteItems.add(createItem(
        'دعاء المجير المبارك (يستحب قراءته في الأيام والليالي البيض)',
        'دعاء المجير المبارك:\nوهو دعاء رفيع الشأن مروي عن النبي (ص) نزل به جبرائيل (ع) وهو يصلي في مقام إبراهيم (ع)، ويستحب قراءته في الأيام البيض من شهر رمضان (13 و 14 و 15) لمغفرة الذنوب:\n\n$mujeer',
      ));
    }

    if (whiteItems.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'white_nights',
        title: 'أعمال الليالي البيض (13 و 14 و 15 من شهر رمضان)',
        subtitle: '${whiteItems.length} ليالٍ مباركة (دعاء المجير، ولادة كريم أهل البيت ع)',
        items: whiteItems,
      ));
    }

    // 12. أعمال الليلة السابعة عشرة من شهر رمضان (غزوة بدر)
    final night17Text = getRaw('أعمال الليلة السابعة عشرة من شهر رمضان');
    if (night17Text.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'night17',
        title: 'أعمال الليلة السابعة عشرة من شهر رمضان',
        subtitle: 'ليلة غزوة بدر الكبرى وفضائل ومناقب أمير المؤمنين (ع)',
        items: [createItem('أعمال الليلة السابعة عشرة من شهر رمضان', night17Text)],
      ));
    }

    // 13. أعمال ختام ووداع شهر رمضان المبارك
    final night30Text = getRaw('أعمال الليلة الثلاثين من شهر رمضان');
    final day30Text = getRaw('أعمال اليوم الثلاثين من شهر رمضان');
    final farewellText = getRaw('أدعية وداع شهر رمضان المبارك');
    final farewellItems = <WorshipItem>[];

    final dua45 = getSahifa('٤٥');
    final dua42 = getSahifa('٤٢');
    if (night30Text.isNotEmpty) {
      farewellItems.add(createItem(
        'أعمال الليلة الثلاثين من شهر رمضان (ليلة ختام الشهر المبارك)',
        dua45.isNotEmpty
            ? night30Text.replaceFirst(
                'ولعلّ أحسنها هو الدّعاء الخامس والأربعون من الصحيفة الكاملة.',
                'ولعلّ أحسنها هو الدّعاء الخامس والأربعون من الصحيفة الكاملة للإمام زين العابدين عليه السلام في وداع شهر رمضان المبارك:\n\n$dua45',
              )
            : night30Text,
      ));
    }
    if (day30Text.isNotEmpty) {
      farewellItems.add(createItem(
        'أعمال اليوم الثلاثين من شهر رمضان (دعاء ختم القرآن)',
        dua42.isNotEmpty
            ? day30Text.replaceFirst(
                'فينبغي أن يُدعى عند الختم بالدعاء الثاني والأربعين من الصحيفة الكاملة،',
                'فينبغي أن يُدعى عند الختم بالدعاء الثاني والأربعين من الصحيفة الكاملة للإمام زين العابدين عليه السلام عند ختم القرآن الكريم:\n\n$dua42\n\n',
              )
            : day30Text,
      ));
    }
    if (farewellText.isNotEmpty) {
      farewellItems.add(createItem(
        'أدعية وداع شهر رمضان المبارك (دعاء الصحيفة السجادية ودعاء الكافي)',
        farewellText.contains('الحَمْدُ للهِ الَّذِي نَدَبَنَا')
            ? farewellText
            : '$farewellText\n\n◆ دعاء الإمام السجاد عليه السلام في وداع شهر رمضان (الدعاء الخامس والأربعون من الصحيفة السجادية):\n\n$dua45',
      ));
    }

    if (farewellItems.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'farewell',
        title: 'أعمال ختام ووداع شهر رمضان المبارك',
        subtitle: '${farewellItems.length} أعمال ختامية (الليلة 30، اليوم 30، أدعية الوداع)',
        items: farewellItems,
      ));
    }

    // 14. خطبة النبي (ص) في استقبال شهر رمضان المبارك
    final khutbahText = getRaw('خطبة النبي (ص) في استقبال شهر رمضان');
    if (khutbahText.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'khutbah',
        title: 'خطبة النبي (ص) في استقبال شهر رمضان',
        subtitle: 'الخطبة الشريفة في بيان فضل وضيافة الشهر الكريم',
        items: [createItem('خطبة النبي (ص) في استقبال شهر رمضان', khutbahText)],
      ));
    }

    // 15. ما يعمّ ليالي وأيام شهر رمضان المبارك
    final generalRamadan = getRaw('ما يعمّ ليالي وأيام شهر رمضان');
    if (generalRamadan.isNotEmpty) {
      final generalItems = <WorshipItem>[];
      final gYaAli = generalRamadan.indexOf('الأول: أن يدعو عقيب كل فريضة بهذا الدّعاء: يا عَلِيُّ يا عَظيمُ');
      final gSurur = generalRamadan.indexOf('الثاني: أن يدعو عقيب كلّ فريضة فيقول: اللَّهُمَّ أدخِل عَلى أهلِ القُبورِ السُّرورَ');
      final gHajj = generalRamadan.indexOf('الثالث: روى الكليني');
      final gTasbeeh = generalRamadan.indexOf('الرابع: أن يسبّح في كلّ يوم من رمضان بهذا التسبيح');

      if (gYaAli != -1 && gSurur != -1 && gHajj != -1 && gTasbeeh != -1) {
        generalItems.add(createItem('دعاء يا عَلِيُّ يا عَظيمُ يا غَفورُ يا رَحيمُ (عقيب الفرائض)', generalRamadan.substring(gYaAli, gSurur).trim()));
        generalItems.add(createItem('دعاء اللَّهُمَّ أدخِل عَلى أهلِ القُبورِ السُّرورَ (عقيب الفرائض)', generalRamadan.substring(gSurur, gHajj).trim()));
        generalItems.add(createItem('دعاء الحج المأثور في كل يوم من شهر رمضان', generalRamadan.substring(gHajj, gTasbeeh).trim()));
        generalItems.add(createItem('تسبيحات كل يوم من شهر رمضان المبارك', generalRamadan.substring(gTasbeeh).trim()));
      } else {
        generalItems.add(createItem('ما يعمّ ليالي وأيام شهر رمضان', generalRamadan));
      }

      sections.add(RamadanSection(
        id: 'general_daily',
        title: 'ما يعمّ ليالي وأيام شهر رمضان المبارك',
        subtitle: '${generalItems.length} أدعية مشتركة (يا علي يا عظيم، أدخل على أهل القبور...)',
        items: generalItems,
      ));
    }

    // 16. تسبيحات شهر رمضان العشرة المأثورة
    final tasbeehatText = getRaw('تسبيحات شهر رمضان العشرة');
    if (tasbeehatText.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'tasbeehat10',
        title: 'تسبيحات شهر رمضان العشرة المأثورة',
        subtitle: 'التسبيحات العشر المروية في الإقبال والكافي',
        items: [createItem('تسبيحات شهر رمضان العشرة', tasbeehatText)],
      ));
    }

    // 17. الصلاة في كل يوم من شهر رمضان على النبي (ص)
    final salawatProphet = getRaw('الصلاة في كل يوم من شهر رمضان على النبي (ص)');
    if (salawatProphet.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'salawat_prophet',
        title: 'الصلاة في كل يوم من شهر رمضان على النبي وآله (ص)',
        subtitle: 'الصلوات الشريفة المروية عن الإمام الصادق عليه السلام',
        items: [
          createItem(
            'الصلاة في كل يوم من شهر رمضان على النبي (ص)',
            salawatProphet.replaceFirst(
              '◆ وقد تركناه لطوله فليطلب من كتاب (الاقبال) أو من (زاد المعاد).',
              'وهذه هي الصلاة الشريفة المروية في (الإقبال) و(زاد المعاد) كاملة:\n\n${RamadanTexts.salawatIqbal}',
            ),
          )
        ],
      ));
    }

    // 18. أعمال باقي ليالي العشر الأواخر
    final remainingNights = <WorshipItem>[];
    for (final num in ['الثانية والعشرين', 'الرابعة والعشرين', 'الخامسة والعشرين', 'السادسة والعشرين', 'السابعة والعشرين', 'الثامنة والعشرين', 'التاسعة والعشرين']) {
      final t = getRaw('أعمال الليلة $num من شهر رمضان');
      if (t.isNotEmpty) {
        remainingNights.add(createItem('أعمال الليلة $num من شهر رمضان', t));
      }
    }
    if (remainingNights.isNotEmpty) {
      sections.add(RamadanSection(
        id: 'late_nights',
        title: 'أعمال باقي ليالي العشر الأواخر المباركة',
        subtitle: '${remainingNights.length} ليالٍ مباركة (ليالي 22، 24، 25، 26، 27، 28، 29)',
        items: remainingNights,
      ));
    }

    _cachedSections = sections;
    return sections;
  }
}
