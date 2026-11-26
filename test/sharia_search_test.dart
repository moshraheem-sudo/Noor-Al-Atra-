import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_noor_alatra/features/sharia_inquiries/models/sharia_answer.dart';
import 'package:flutter_noor_alatra/features/sharia_inquiries/screens/sharia_answer_screen.dart';
import 'package:flutter_noor_alatra/features/sharia_inquiries/screens/sharia_search_screen.dart';
import 'package:flutter_noor_alatra/features/sharia_inquiries/services/sharia_search_service.dart';

void main() {
  group('ShariaSearchService unit tests', () {
    test('rejects empty and 1-char input as invalidInput', () async {
      final service = ShariaSearchService.withClient(
        MockClient((_) async => http.Response('{}', 200)),
      );

      final emptyRes = await service.search('   ');
      expect(emptyRes.status, ShariaSearchStatus.invalidInput);

      final shortRes = await service.search('أ');
      expect(shortRes.status, ShariaSearchStatus.invalidInput);
    });

    test('parses valid Almojib API response into ShariaAnswer list', () async {
      final mockPayload = {
        'outcome': {
          'meta': {'total': 1},
          'data': [
            {
              'question': {
                'id': 2138261,
                'subject': 'الصلاة بعباية الصلاة',
                'question': 'هل يجوز الصلاة بعباية الصلاة فقط؟',
                'category': {'id': 1, 'name': 'مسائل فقهية'},
                'share_link': 'https://almojib.com/ar/question/2138261',
              },
              'first_reply': {
                'reply': 'اذا تحقق الستر المعتبر في الصلاة جاز.',
                'created_at': '19/07/25 09:05:21',
                'marjas': [
                  {'id': 1, 'name': 'السيد السيستاني'}
                ],
                'institute': {'id': 1, 'name': 'مؤسسة المصطفى للإرشاد'},
              },
            }
          ],
        },
      };

      final service = ShariaSearchService.withClient(
        MockClient((req) async {
          expect(req.url.toString(), contains('search='));
          return http.Response.bytes(
            utf8.encode(json.encode(mockPayload)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final res = await service.search('الصلاة');
      expect(res.status, ShariaSearchStatus.success);
      expect(res.total, 1);
      expect(res.results.length, 1);
      expect(res.results.first.title, 'الصلاة بعباية الصلاة');
      expect(res.results.first.answer, 'اذا تحقق الستر المعتبر في الصلاة جاز.');
      expect(res.results.first.source, 'مؤسسة المصطفى للإرشاد');
      expect(res.results.first.category, 'مسائل فقهية');
      expect(res.results.first.reference, 'السيد السيستاني');
      expect(res.results.first.url, 'https://almojib.com/ar/question/2138261');
    });

    test('returns empty status when API returns zero results', () async {
      final service = ShariaSearchService.withClient(
        MockClient((_) async => http.Response(
              json.encode({'outcome': {'meta': {'total': 0}, 'data': []}}),
              200,
            )),
      );

      final res = await service.search('كلمةغيرموجودةابدا');
      expect(res.status, ShariaSearchStatus.empty);
      expect(res.results, isEmpty);
    });

    test('handles SocketException as offline', () async {
      final service = ShariaSearchService.withClient(
        MockClient((_) async => throw const SocketException('No Internet')),
      );

      final res = await service.search('الصلاة');
      expect(res.status, ShariaSearchStatus.offline);
    });

    test('handles TimeoutException as timeout with fallbackWebUrl', () async {
      final service = ShariaSearchService.withClient(
        MockClient((_) async => throw TimeoutException('Timeout')),
      );

      final res = await service.search('الصلاة');
      expect(res.status, ShariaSearchStatus.timeout);
      expect(res.fallbackWebUrl, contains('almojib.com/ar/search'));
    });

    test('handles invalid JSON as invalidResponse with fallbackWebUrl', () async {
      final service = ShariaSearchService.withClient(
        MockClient((_) async => http.Response('<html>error</html>', 200)),
      );

      final res = await service.search('الصلاة');
      expect(res.status, ShariaSearchStatus.invalidResponse);
      expect(res.fallbackWebUrl, contains('almojib.com/ar/search'));
    });
  });

  group('ShariaSearchService live Almojib integration test', () {
    test('fetches real published Q&As for الصلاة and handles nonexistent query', () async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final liveService = ShariaSearchService.withClient(http.Client());

        final liveRes = await liveService.search('الصلاة');
        expect(liveRes.status, ShariaSearchStatus.success);
        expect(liveRes.results, isNotEmpty);
        expect(liveRes.results.first.question, isNotEmpty);
        expect(liveRes.results.first.answer, isNotEmpty);
        expect(liveRes.results.first.url, startsWith('https://almojib.com'));

        final emptyRes = await liveService.search('شسيشسيشسيشسي999999');
        expect(emptyRes.status, ShariaSearchStatus.empty);
        expect(emptyRes.results, isEmpty);
      } finally {
        HttpOverrides.global = previousOverrides;
      }
    });
  });

  group('ShariaSearchScreen widget tests', () {
    testWidgets('displays Arabic RTL UI, validates empty input, and navigates to answer screen',
        (tester) async {
      final mockPayload = {
        'outcome': {
          'meta': {'total': 1},
          'data': [
            {
              'question': {
                'id': 100,
                'subject': 'حكم الشك في الركعات',
                'question': 'ما حكم من شك بين الثالثة والرابعة؟',
                'category': {'id': 1, 'name': 'أحكام الصلاة'},
                'share_link': 'https://almojib.com/ar/question/100',
              },
              'first_reply': {
                'reply': 'يبني على الرابعة ويأتي بركعة احتياط.',
                'marjas': [
                  {'id': 1, 'name': 'السيد السيستاني'}
                ],
                'institute': {'id': 1, 'name': 'مؤسسة المصطفى للإرشاد'},
              },
            }
          ],
        },
      };

      final service = ShariaSearchService.withClient(
        MockClient((_) async => http.Response.bytes(
              utf8.encode(json.encode(mockPayload)),
              200,
            )),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShariaSearchScreen(searchService: service),
        ),
      );

      expect(find.text('المجيب'), findsOneWidget);
      expect(
        find.text('ابحث عن المسائل والأجوبة الشرعية وفق مدرسة أهل البيت (عليهم السلام)'),
        findsOneWidget,
      );

      // Submit empty query
      await tester.tap(find.text('بحث'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل نص السؤال للبحث'), findsOneWidget);

      // Enter query and search
      await tester.enterText(find.byType(TextField), 'الشك في الركعات');
      await tester.pump();
      await tester.tap(find.text('بحث'));
      await tester.pumpAndSettle();

      expect(find.text('حكم الشك في الركعات'), findsOneWidget);
      expect(find.text('قراءة الإجابة كاملة'), findsOneWidget);

      // Tap to open full answer screen
      await tester.tap(find.text('قراءة الإجابة كاملة'));
      await tester.pumpAndSettle();

      expect(find.byType(ShariaAnswerScreen), findsOneWidget);
      expect(find.text('المجيب'), findsOneWidget);
      expect(find.text('عرض المصدر الأصلي'), findsOneWidget);
      expect(find.text('يبني على الرابعة ويأتي بركعة احتياط.'), findsOneWidget);
    });
  });
}
