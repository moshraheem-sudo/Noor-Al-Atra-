class Person {
  final int id;
  final String name;
  final String title;
  final String father;
  final String mother;
  final String birthDateStr;
  final String deathDateStr;
  final String? imamateDuration;
  final String? causeOfDeath;
  final String? killer;
  final int childrenCount;
  final List<String> famousChildren;
  final List<String> wives;
  final String bio;

  Person({
    required this.id,
    required this.name,
    required this.title,
    required this.father,
    required this.mother,
    required this.birthDateStr,
    required this.deathDateStr,
    this.imamateDuration,
    this.causeOfDeath,
    this.killer,
    required this.childrenCount,
    required this.famousChildren,
    required this.wives,
    required this.bio,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      father: json['father'] as String? ?? '',
      mother: json['mother'] as String? ?? '',
      birthDateStr: json['birthDateStr'] as String? ?? '',
      deathDateStr: json['deathDateStr'] as String? ?? '',
      imamateDuration: json['imamateDuration'] as String?,
      causeOfDeath: json['causeOfDeath'] as String?,
      killer: json['killer'] as String?,
      childrenCount: json['childrenCount'] as int? ?? 0,
      famousChildren: (json['famousChildren'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      wives: (json['wives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bio: json['bio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'father': father,
        'mother': mother,
        'birthDateStr': birthDateStr,
        'deathDateStr': deathDateStr,
        'imamateDuration': imamateDuration,
        'causeOfDeath': causeOfDeath,
        'killer': killer,
        'childrenCount': childrenCount,
        'famousChildren': famousChildren,
        'wives': wives,
        'bio': bio,
      };
}
