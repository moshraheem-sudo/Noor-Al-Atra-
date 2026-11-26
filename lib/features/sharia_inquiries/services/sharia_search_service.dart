import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/sharia_answer.dart';

class _CachedSearchEntry {
  final ShariaSearchResponse response;
  final DateTime cachedAt;

  const _CachedSearchEntry(this.response, this.cachedAt);
}

class ShariaSearchService {
  static final ShariaSearchService _instance = ShariaSearchService._internal();
  factory ShariaSearchService() => _instance;
  ShariaSearchService._internal() : _client = http.Client();

  ShariaSearchService.withClient(this._client);

  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const int _maxCacheEntries = 50;

  final http.Client _client;
  final Map<String, _CachedSearchEntry> _cache = {};

  static const List<Map<String, dynamic>> marjaOptions = [
    {'id': null, 'name': 'جميع المراجع'},
    {'id': 1, 'name': 'السيد السيستاني'},
    {'id': 3, 'name': 'السيد محمد سعيد الحكيم'},
    {'id': 2, 'name': 'السيد الخوئي'},
    {'id': 5, 'name': 'السيد الشهيد الصدر'},
    {'id': 6, 'name': 'الشيخ الفياض'},
    {'id': 7, 'name': 'الشيخ بشير النجفي'},
  ];

  static String buildWebSearchUrl(String query, {int? marjaId}) {
    final encoded = Uri.encodeQueryComponent(query.trim());
    final marjaParam = marjaId != null ? '&marja_id=$marjaId' : '';
    return 'https://almojib.com/ar/search?search=$encoded$marjaParam';
  }

  void clearCache() => _cache.clear();

  /// Searches published Sharia Q&As directly via Almojib.
  Future<ShariaSearchResponse> search(
    String rawQuery, {
    int page = 1,
    int? marjaId,
  }) async {
    final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) {
      return const ShariaSearchResponse(
        status: ShariaSearchStatus.invalidInput,
        query: '',
        errorMessage: 'يرجى كتابة سؤالك أو كلمات البحث أولاً.',
      );
    }
    if (query.length < 2) {
      return ShariaSearchResponse(
        status: ShariaSearchStatus.invalidInput,
        query: query,
        errorMessage: 'يرجى إدخال كلمتين أو حرفين على الأقل للبحث.',
      );
    }

    final cacheKey = '${query}_${page}_${marjaId ?? 'all'}';
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      return cached.response;
    }

    final fallbackUrl = buildWebSearchUrl(query, marjaId: marjaId);

    try {
      final directRes = await _searchViaAlmojibApi(query, page, fallbackUrl, marjaId: marjaId);
      if (directRes.status == ShariaSearchStatus.success ||
          directRes.status == ShariaSearchStatus.empty) {
        _storeCache(cacheKey, directRes);
      }
      return directRes;
    } on SocketException {
      return ShariaSearchResponse(
        status: ShariaSearchStatus.offline,
        query: query,
        errorMessage: 'يبدو أن الاتصال بالإنترنت مقطوع أو ضعيف. تحقق من الشبكة وحاول مجدداً.',
        fallbackWebUrl: fallbackUrl,
      );
    } on TimeoutException {
      return ShariaSearchResponse(
        status: ShariaSearchStatus.timeout,
        query: query,
        errorMessage: 'انتهت مهلة الاتصال بموقع المجيب. يمكنك إعادة المحاولة أو استخدام العرض المدمج.',
        fallbackWebUrl: fallbackUrl,
      );
    } on FormatException {
      return ShariaSearchResponse(
        status: ShariaSearchStatus.invalidResponse,
        query: query,
        errorMessage: 'وردت استجابة غير متوقعة من مصدر البحث.',
        fallbackWebUrl: fallbackUrl,
      );
    } catch (_) {
      return ShariaSearchResponse(
        status: ShariaSearchStatus.sourceUnavailable,
        query: query,
        errorMessage: 'تعذر الوصول إلى موقع المجيب حالياً. يمكنك فتح البحث المدمج داخل التطبيق.',
        fallbackWebUrl: fallbackUrl,
      );
    }
  }

  Future<ShariaSearchResponse> _searchViaAlmojibApi(
    String query,
    int page,
    String fallbackUrl, {
    int? marjaId,
  }) async {
    final encoded = Uri.encodeQueryComponent(query);
    final marjaParam = marjaId != null ? '&marja_id=$marjaId' : '';
    final url = 'https://api.almojib.com/ar/api/v1.1/faq/search?search=$encoded&page=$page$marjaParam';

    final res = await _client
        .get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json, text/plain, */*',
            'User-Agent': 'NoorAlAtra-App/1.0',
          },
        )
        .timeout(_requestTimeout);

    if (res.statusCode != 200) {
      return ShariaSearchResponse(
        status: ShariaSearchStatus.sourceUnavailable,
        query: query,
        errorMessage: 'تعذر الوصول إلى موقع المجيب حالياً (رمز ${res.statusCode}).',
        fallbackWebUrl: fallbackUrl,
      );
    }

    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected JSON root');
    }

    final outcome = decoded['outcome'];
    if (outcome is! Map<String, dynamic>) {
      throw const FormatException('Missing outcome object');
    }

    final rawData = outcome['data'] as List<dynamic>? ?? const [];
    final meta = outcome['meta'] as Map<String, dynamic>?;
    final total = meta?['total'] is num ? (meta!['total'] as num).toInt() : rawData.length;

    final results = rawData
        .whereType<Map<String, dynamic>>()
        .map(ShariaAnswer.fromAlmojibItem)
        .where((e) => e.question.isNotEmpty)
        .toList();

    return ShariaSearchResponse(
      status: results.isEmpty ? ShariaSearchStatus.empty : ShariaSearchStatus.success,
      query: query,
      results: results,
      total: total,
      page: page,
      fallbackWebUrl: fallbackUrl,
    );
  }

  void _storeCache(String key, ShariaSearchResponse response) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CachedSearchEntry(response, DateTime.now());
  }
}
