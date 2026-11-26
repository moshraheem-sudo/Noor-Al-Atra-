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

  static const String supabaseUrl = 'https://grqszdqdcpnmpawexagw.supabase.co';
  static const String edgeFunctionUrl = '$supabaseUrl/functions/v1/sharia-search';
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const int _maxCacheEntries = 50;

  final http.Client _client;
  final Map<String, _CachedSearchEntry> _cache = {};

  static String buildWebSearchUrl(String query) {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return 'https://almojib.com/ar/search?search=$encoded';
  }

  void clearCache() => _cache.clear();

  /// Searches published Sharia Q&As via Supabase `sharia-search` Edge Function,
  /// with automatic fallback to the public Almojib API if the Edge Function
  /// key is not configured or not yet deployed.
  Future<ShariaSearchResponse> search(String rawQuery, {int page = 1}) async {
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

    final cacheKey = '${query}_$page';
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      return cached.response;
    }

    final fallbackUrl = buildWebSearchUrl(query);

    // 1. Try Supabase Edge Function if publishable key is configured
    if (supabasePublishableKey.isNotEmpty) {
      try {
        final edgeRes = await _searchViaSupabaseEdge(query, page);
        if (edgeRes != null) {
          _storeCache(cacheKey, edgeRes);
          return edgeRes;
        }
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
          errorMessage: 'انتهت مهلة الاتصال بالخادم. يمكنك إعادة المحاولة أو فتح صفحة البحث المدمجة.',
          fallbackWebUrl: fallbackUrl,
        );
      } catch (_) {
        // Fall through to direct public API fallback
      }
    }

    // 2. Direct Almojib public search API fallback
    try {
      final directRes = await _searchViaAlmojibApi(query, page, fallbackUrl);
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

  Future<ShariaSearchResponse?> _searchViaSupabaseEdge(String query, int page) async {
    final res = await _client
        .post(
          Uri.parse(edgeFunctionUrl),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'apikey': supabasePublishableKey,
            'Authorization': 'Bearer $supabasePublishableKey',
          },
          body: json.encode({'query': query, 'page': page}),
        )
        .timeout(_requestTimeout);

    if (res.statusCode == 401 || res.statusCode == 404) {
      // Edge function not deployed yet or publishable key mismatch -> allow fallback
      return null;
    }

    if (res.statusCode != 200) {
      return null;
    }

    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      return null;
    }

    final rawList = decoded['results'] as List<dynamic>? ?? const [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(ShariaAnswer.fromJson)
        .where((e) => e.question.isNotEmpty)
        .toList();

    final total = decoded['total'] is num ? (decoded['total'] as num).toInt() : items.length;
    return ShariaSearchResponse(
      status: items.isEmpty ? ShariaSearchStatus.empty : ShariaSearchStatus.success,
      query: query,
      results: items,
      total: total,
      page: page,
      fallbackWebUrl: buildWebSearchUrl(query),
    );
  }

  Future<ShariaSearchResponse> _searchViaAlmojibApi(
    String query,
    int page,
    String fallbackUrl,
  ) async {
    final encoded = Uri.encodeQueryComponent(query);
    final url = 'https://api.almojib.com/ar/api/v1.1/faq/search?search=$encoded&page=$page';

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
