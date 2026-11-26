class ShariaAnswer {
  final int? id;
  final String title;
  final String question;
  final String answer;
  final String? source;
  final String? category;
  final String? reference;
  final String? url;
  final String? createdAt;

  const ShariaAnswer({
    this.id,
    required this.title,
    required this.question,
    required this.answer,
    this.source,
    this.category,
    this.reference,
    this.url,
    this.createdAt,
  });

  /// Parses an item from the Almojib search API.
  factory ShariaAnswer.fromAlmojibItem(Map<String, dynamic> item) {
    final qObj = item['question'] as Map<String, dynamic>? ?? const {};
    final replyObj = item['first_reply'] as Map<String, dynamic>?;

    final rawTitle = (qObj['subject'] as String?)?.trim() ?? '';
    final rawQuestion = (qObj['question'] as String?)?.trim() ?? '';
    final rawAnswer = (replyObj?['reply'] as String?)?.trim() ?? '';

    final marjasList = replyObj?['marjas'] as List<dynamic>? ?? const [];
    final marjaNames = marjasList
        .map((m) => (m is Map<String, dynamic> ? m['name'] as String? : null)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final institute = (replyObj?['institute'] as Map<String, dynamic>?)?['name'] as String?;
    final category = (qObj['category'] as Map<String, dynamic>?)?['name'] as String?;
    final id = qObj['id'] is num ? (qObj['id'] as num).toInt() : null;
    final shareLink = _nullIfEmpty(qObj['share_link'] as String?) ??
        (id != null ? 'https://almojib.com/ar/question/$id' : null);

    return ShariaAnswer(
      id: id,
      title: rawTitle.isNotEmpty ? rawTitle : rawQuestion,
      question: rawQuestion.isNotEmpty ? rawQuestion : rawTitle,
      answer: rawAnswer.isNotEmpty ? rawAnswer : 'الإجابة منشورة في المصدر الأصلي.',
      source: _nullIfEmpty(institute) ?? 'موقع المجيب',
      category: _nullIfEmpty(category),
      reference: marjaNames.isNotEmpty ? marjaNames.join('، ') : null,
      url: shareLink,
      createdAt: _nullIfEmpty(replyObj?['created_at'] as String?) ??
          _nullIfEmpty(qObj['created_at'] as String?),
    );
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

enum ShariaSearchStatus {
  initial,
  loading,
  success,
  empty,
  offline,
  timeout,
  sourceUnavailable,
  invalidResponse,
  invalidInput,
}

class ShariaSearchResponse {
  final ShariaSearchStatus status;
  final String query;
  final List<ShariaAnswer> results;
  final int total;
  final int page;
  final String? errorMessage;
  final String? fallbackWebUrl;

  const ShariaSearchResponse({
    required this.status,
    required this.query,
    this.results = const [],
    this.total = 0,
    this.page = 1,
    this.errorMessage,
    this.fallbackWebUrl,
  });

  bool get hasResults => results.isNotEmpty;
}
