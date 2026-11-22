class WorshipReciterOption {
  final String reciterName;
  final String url;

  const WorshipReciterOption({
    required this.reciterName,
    required this.url,
  });

  factory WorshipReciterOption.fromJson(Map<String, dynamic> json) {
    return WorshipReciterOption(
      reciterName: json['reciterName'] as String? ?? 'القارئ',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'reciterName': reciterName,
        'url': url,
      };
}

class WorshipAudioItem {
  final int id;
  final String title;
  final String category; // DUA, ZIYARAH, MUNAJAT
  final String description;
  final List<WorshipReciterOption> reciters;

  WorshipAudioItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.reciters,
  });

  String get defaultReciterName => reciters.isNotEmpty ? reciters.first.reciterName : 'القارئ';
  String get defaultUrl => reciters.isNotEmpty ? reciters.first.url : '';
  bool get hasMultipleReciters => reciters.length > 1;

  // Compatibility getters for legacy code
  String get reciterName => defaultReciterName;
  String get url => defaultUrl;

  factory WorshipAudioItem.fromJson(Map<String, dynamic> json) {
    var recitersList = <WorshipReciterOption>[];
    if (json['reciters'] is List) {
      recitersList = (json['reciters'] as List)
          .map((r) => WorshipReciterOption.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json['url'] != null) {
      recitersList.add(
        WorshipReciterOption(
          reciterName: json['reciterName'] as String? ?? 'القارئ',
          url: json['url'] as String? ?? '',
        ),
      );
    }

    return WorshipAudioItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'DUA',
      description: json['description'] as String? ?? '',
      reciters: recitersList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'description': description,
        'reciters': reciters.map((r) => r.toJson()).toList(),
      };

  String get categoryArabic {
    switch (category) {
      case 'DUA':
        return 'دعاء';
      case 'ZIYARAH':
        return 'زيارة';
      case 'MUNAJAT':
        return 'مناجاة';
      default:
        return 'صوتيات';
    }
  }
}
