import 'package:flutter/material.dart';
import 'proximity_wakelock_service.dart';

class VoiceSearchService {
  /// Launches native Arabic speech recognition.
  /// If speech is recognized, returns the recognized text string.
  static Future<String?> startVoiceSearch(
    BuildContext context, {
    String prompt = 'تحدث الآن للبحث...',
  }) async {
    try {
      final text = await ProximityWakeLockService().startVoiceRecognition(prompt: prompt);
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تفعيل البحث الصوتي: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return null;
    }
  }
}
