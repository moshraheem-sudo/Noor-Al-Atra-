class HijriEvent {
  final int day;
  final int month;
  final String name;
  final bool isMartyrdom;
  final int? year;

  HijriEvent({
    required this.day,
    required this.month,
    required this.name,
    required this.isMartyrdom,
    this.year,
  });

  factory HijriEvent.fromJson(Map<String, dynamic> json) {
    return HijriEvent(
      day: json['day'] as int,
      month: json['month'] as int,
      name: json['name'] as String? ?? '',
      isMartyrdom: json['isMartyrdom'] as bool? ?? false,
      year: json['year'] as int?,
    );
  }

  static String getMonthName(int month) {
    const months = [
      'محرم الحرام',
      'صفر الخير',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب الأصب',
      'شعبان المعظم',
      'شهر رمضان المبارك',
      'شوال المكرم',
      'ذو القعدة الحرام',
      'ذو الحجة الحرام'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
