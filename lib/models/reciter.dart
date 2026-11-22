class ReciterItem {
  final int id;
  final String name;
  final List<String> tags;
  final String everyAyahFolder;

  const ReciterItem(this.id, this.name, this.tags, [this.everyAyahFolder = 'Alafasy_128kbps']);

  String get subtitle => tags.join(' • ');

  String get defaultServer {
    switch (id) {
      case 51:
        return 'https://server7.mp3quran.net/basit/';
      case 112:
        return 'https://server10.mp3quran.net/minsh/';
      case 118:
        return 'https://server13.mp3quran.net/husr/';
      case 86:
        return 'https://server8.mp3quran.net/mustafa/';
      case 70:
        return 'https://server8.mp3quran.net/frs_a/';
      case 44:
        return 'https://server7.mp3quran.net/s_gmd/';
      case 108:
        return 'https://server8.mp3quran.net/afs/';
      case 104:
        return 'https://server12.mp3quran.net/maher/';
      case 13:
        return 'https://server11.mp3quran.net/shatri/';
      case 7:
        return 'https://server10.mp3quran.net/ajm/';
      case 126:
        return 'https://server11.mp3quran.net/yasser/';
      case 54:
        return 'https://server11.mp3quran.net/sds/';
      case 46:
        return 'https://server7.mp3quran.net/shur/';
      case 63:
        return 'https://server11.mp3quran.net/jbr/';
      default:
        return 'https://server8.mp3quran.net/afs/';
    }
  }

  static const List<ReciterItem> popularReciters = [
    ReciterItem(51, 'عبد الباسط عبد الصمد', ['مصر', 'مجود'], 'Abdul_Basit_Murattal_192kbps'),
    ReciterItem(112, 'محمد صديق المنشاوي', ['مصر', 'مجود'], 'Minshawy_Murattal_128kbps'),
    ReciterItem(118, 'محمود خليل الحصري', ['مصر', 'معلم'], 'Husary_128kbps'),
    ReciterItem(86, 'مصطفى إسماعيل', ['مصر'], 'Mostafa_Ismail_128kbps'),
    ReciterItem(70, 'فارس عباد', ['اليمن'], 'Fares_Abbad_64kbps'),
    ReciterItem(44, 'سعد الغامدي', ['السعودية'], 'Ghamadi_40kbps'),
    ReciterItem(108, 'مشاري العفاسي', ['الكويت', 'مرتل'], 'Alafasy_128kbps'),
    ReciterItem(104, 'ماهر المعيقلي', ['السعودية', 'حرم'], 'MaherAlMuaiqly128kbps'),
    ReciterItem(13, 'أبو بكر الشاطري', ['السعودية', 'مرتل'], 'Abu_Bakr_Ash-Shaatree_128kbps'),
    ReciterItem(7, 'أحمد بن علي العجمي', ['السعودية'], 'Ahmed_ibn_Ali_al-Ajamy_128kbps'),
    ReciterItem(126, 'ياسر الدوسري', ['السعودية'], 'Yasser_Ad-Dussary_128kbps'),
    ReciterItem(54, 'عبدالرحمن السديس', ['السعودية'], 'Abdurrahmaan_As-Sudais_192kbps'),
    ReciterItem(46, 'سعود الشريم', ['السعودية'], 'Saood_ash-Shuraym_128kbps'),
    ReciterItem(63, 'علي جابر', ['السعودية'], 'Ali_Jaber_64kbps'),
  ];
}

class ReciterStyle {
  final int id;
  final String name;
  final String server;
  final String surahList;

  ReciterStyle({
    required this.id,
    required this.name,
    required this.server,
    required this.surahList,
  });

  factory ReciterStyle.fromJson(Map<String, dynamic> json) {
    return ReciterStyle(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'رواية حفص عن عاصم',
      server: json['server'] as String? ?? '',
      surahList: json['surah_list'] as String? ?? '1,2,3',
    );
  }

  String get displayName {
    final clean = name.trim();

    // Determine Riwayah / Qira'ah (رواية القراءة)
    String? riwayah;
    if (clean.contains('حفص')) {
      riwayah = 'حفص عن عاصم';
    } else if (clean.contains('ورش')) {
      riwayah = 'ورش عن نافع';
    } else if (clean.contains('قالون')) {
      riwayah = 'قالون عن نافع';
    } else if (clean.contains('الدوري')) {
      riwayah = 'الدوري عن أبي عمرو';
    } else if (clean.contains('السوسي')) {
      riwayah = 'السوسي عن أبي عمرو';
    } else if (clean.contains('شعبة')) {
      riwayah = 'شعبة عن عاصم';
    } else if (clean.contains('البزي')) {
      riwayah = 'البزي عن ابن كثير';
    } else if (clean.contains('قنبل')) {
      riwayah = 'قنبل عن ابن كثير';
    } else if (clean.contains('ابن ذكوان') || clean.contains('هشام')) {
      riwayah = 'ابن عامر الشامي';
    }

    // Determine Style / Mode (النمط: مجود / مرتل / معلم)
    String? type;
    if (clean.contains('المجود') || clean.contains('مجود') || clean.contains('تجويد')) {
      type = 'مجود';
    } else if (clean.contains('معلم') || clean.contains('المعلم')) {
      type = 'معلم';
    } else if (clean.contains('مرتل') || clean.contains('المرتل') || clean.contains('ترتيل')) {
      type = 'مرتل';
    }

    if (riwayah != null && type != null) {
      return '$riwayah ($type)';
    } else if (riwayah != null) {
      return riwayah;
    } else if (type != null) {
      if (type == 'مجود') return 'المصحف المجود';
      if (type == 'مرتل') return 'المصحف المرتل';
      if (type == 'معلم') return 'المصحف المعلم';
      return type;
    }

    // Deduplicate repeated hyphenated parts
    final parts = clean.split(RegExp(r'[-–•]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (parts.length == 1) return parts.first;
    return parts.join(' • ');
  }

  List<int> get availableSurahs {
    return surahList
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }
}
