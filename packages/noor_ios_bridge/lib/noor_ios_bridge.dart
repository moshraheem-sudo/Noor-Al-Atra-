import 'package:flutter/services.dart';

class NoorIosBridge {
  static const MethodChannel methodChannel = MethodChannel('com.example.flutter_noor_alatra/wakelock');
  static const EventChannel proximityChannel = EventChannel('com.example.flutter_noor_alatra/proximity');
}
