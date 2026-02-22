import 'dart:async';
import 'dart:io';

import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

class BackgroundLocationService {
  static Future<void> configure() async {
    if (!Platform.isAndroid) return;

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: 'courier_location',
        initialNotificationTitle: 'Foodly Courier',
        initialNotificationContent: 'Sharing live location',
        foregroundServiceNotificationId: 1337,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: _onBackground,
      ),
    );
  }

  static Future<void> start(String orderId) async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeOrderId', orderId);
    final service = FlutterBackgroundService();
    service.invoke('setOrderId', {'orderId': orderId});
    await service.startService();
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  final repo = FirebaseDataRepository();
  final prefs = await SharedPreferences.getInstance();
  var activeOrderId = prefs.getString('activeOrderId') ?? '1012';

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Foodly Courier',
      content: 'Sharing live location',
    );
  }

  service.on('setOrderId').listen((event) {
    final orderId = event?['orderId'] as String?;
    if (orderId == null) return;
    activeOrderId = orderId;
  });

  Timer? timer;
  timer = Timer.periodic(const Duration(seconds: 15), (_) async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await repo.updateCourierLocation(
      activeOrderId,
      position.latitude,
      position.longitude,
    );
  });

  service.on('stopService').listen((_) {
    timer?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> _onBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
