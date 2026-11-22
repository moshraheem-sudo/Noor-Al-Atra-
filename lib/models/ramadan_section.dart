import 'worship_item.dart';

class RamadanSection {
  final String id;
  final String title;
  final String subtitle;
  final List<WorshipItem> items;

  const RamadanSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  bool get hasSubItems => items.length > 1;
}
