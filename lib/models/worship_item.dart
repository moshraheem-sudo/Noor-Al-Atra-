class WorshipItem {
  final String title;
  final String text;
  final String categoryKey;
  final String? audioUrl;

  WorshipItem({
    required this.title,
    required this.text,
    required this.categoryKey,
    this.audioUrl,
  });

  factory WorshipItem.fromJson(Map<String, dynamic> json, {String categoryKey = ''}) {
    return WorshipItem(
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      categoryKey: categoryKey,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'text': text,
        'categoryKey': categoryKey,
        'audioUrl': audioUrl,
      };
}

class WorshipCategory {
  final String key;
  final String title;
  final String iconAsset;
  final String description;

  const WorshipCategory({
    required this.key,
    required this.title,
    required this.iconAsset,
    required this.description,
  });

  static const List<WorshipCategory> categories = [
    WorshipCategory(
      key: 'dailyPrayers',
      title: 'أدعية الأيام',
      iconAsset: 'assets/images/ic_worship_dua_3d.png',
      description: 'أدعية أيام الأسبوع المأثورة عن الإمام السجاد عليه السلام',
    ),
    WorshipCategory(
      key: 'taqeebat',
      title: 'تعقيبات الصلاة',
      iconAsset: 'assets/images/ic_worship_taqibat_3d.png',
      description: 'التعقيبات العامة والخاصة للصلوات اليومية الخمس',
    ),
    WorshipCategory(
      key: 'munajat',
      title: 'المناجاة الخمس عشرة',
      iconAsset: 'assets/images/ic_worship_munajat_3d.png',
      description: 'مناجاة الإمام علي بن الحسين السجاد عليه السلام',
    ),
    WorshipCategory(
      key: 'sahifaSajjadiya',
      title: 'الصحيفة السجادية',
      iconAsset: 'assets/images/ic_worship_sahifa_3d.png',
      description: 'زبور آل محمد وإنجيل أهل البيت عليهم السلام',
    ),
    WorshipCategory(
      key: 'generalPrayers',
      title: 'الأدعية المشهورة',
      iconAsset: 'assets/images/ic_worship_selected_dua_3d.png',
      description: 'دعاء كميل، التوسل، الندبة، الافتتاح، الجوشن، السمات',
    ),
    WorshipCategory(
      key: 'ziyarats',
      title: 'الزيارات',
      iconAsset: 'assets/images/ic_worship_ziyarat_3d.png',
      description: 'زيارة عاشوراء، وارث، الجامعة الكبيرة، الأئمة الأطهار',
    ),
    WorshipCategory(
      key: 'ziyaratsOfDays',
      title: 'زيارات أيام الأسبوع',
      iconAsset: 'assets/images/ic_worship_ziyarat_3d.png',
      description: 'زيارة المعصومين المخصوصة بكل يوم من أيام الأسبوع',
    ),
    WorshipCategory(
      key: 'azkarList',
      title: 'الأذكار والتعويذات',
      iconAsset: 'assets/images/ic_worship_azkar_3d.png',
      description: 'أذكار الصباح والمساء، أذكار النوم واليقظة',
    ),
    WorshipCategory(
      key: 'salawatsOnHujaj',
      title: 'الصلوات على الحجج',
      iconAsset: 'assets/images/ic_worship_salawat_ahlalbayt_3d.png',
      description: 'الصلوات الخاصة على النبي وآله المعصومين واحداً بعد واحد',
    ),
    WorshipCategory(
      key: 'ahlAlBaytPrayers',
      title: 'صلوات وأدعية الأئمة',
      iconAsset: 'assets/images/ic_worship_salat_3d.png',
      description: 'الصلوات المروية عن الأئمة الأطهار لكل حاجة ومهمة',
    ),
    WorshipCategory(
      key: 'concisePrayers',
      title: 'أدعية موجزة وقضاء الحوائج',
      iconAsset: 'assets/images/ic_worship_dua_3d.png',
      description: 'أدعية مختصرة للرزق، الشفاء، كشف الهم، وتيسير الأمور',
    ),
    WorshipCategory(
      key: 'obligatoryAndRecommendedPrayers',
      title: 'الصلوات المستحبة وأحكامها',
      iconAsset: 'assets/images/ic_worship_salat_3d.png',
      description: 'صلاة الليل، صلاة الغفيلة، صلاة الآيات، صلاة جعفر الطيار',
    ),
    WorshipCategory(
      key: 'fastingRules',
      title: 'أحكام الصوم',
      iconAsset: 'assets/images/ic_worship_ahkam_sawm_3d.png',
      description: 'المفطرات، الكفارات، وأحكام الصوم الفقهية المباركة',
    ),
    WorshipCategory(
      key: 'tasbeehat',
      title: 'التسبيحات المأثورة',
      iconAsset: 'assets/images/ic_worship_misbaha_3d.png',
      description: 'تسبيحات الأيام، تسبيح جبرائيل، تسبيحات قضاء الحوائج',
    ),
  ];
}
