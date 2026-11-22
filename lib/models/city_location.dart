class CityLocation {
  final String id;
  final String nameAr;
  final String nameEn;
  final String countryAr;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool isHolyCity;
  final String province;

  CityLocation({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.countryAr,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.isHolyCity = false,
    this.province = '',
  });

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      countryAr: json['countryAr'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? '+3',
      isHolyCity: json['isHolyCity'] as bool? ?? false,
      province: json['province'] as String? ?? '',
    );
  }

  String get displayName {
    if (province.isNotEmpty && province != nameAr && !nameAr.contains(province)) {
      return '$nameAr ($province)';
    }
    return nameAr;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'countryAr': countryAr,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'isHolyCity': isHolyCity,
        'province': province,
      };

  static CityLocation defaultCity = CityLocation(
    id: 'karbala',
    nameAr: 'كربلاء المقدسة',
    nameEn: 'Karbala',
    countryAr: 'العراق',
    latitude: 32.6143,
    longitude: 44.0228,
    timezone: '+3',
    isHolyCity: true,
    province: 'كربلاء',
  );
}
