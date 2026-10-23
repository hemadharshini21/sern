import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

/// Rapido-style notification + sound service.
/// Handles:
///  • Ambulance assigned notification
///  • Ambulance en-route notification
///  • Ambulance arrived notification (with siren sound)
///  • Trip completed notification
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audio = AudioPlayer();
  bool _initialized = false;

  static const _channelId = 'sern_emergency';
  static const _channelName = 'SERN Emergency Alerts';
  static const _channelDesc = 'Real-time ambulance tracking alerts';

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );

    // Request permissions on Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

  NotificationDetails get _details =>
      NotificationDetails(android: _androidDetails);

  /// Show notification that ambulance has been assigned
  Future<void> showAssigned({required String unitNumber}) async {
    if (kIsWeb) return;
    await _plugin.show(
      id: 1,
      title: '🚑 Ambulance Assigned',
      body: 'Unit $unitNumber is heading to your location',
      notificationDetails: _details,
    );
  }

  /// Show notification that ambulance is en route
  Future<void> showEnRoute({required String eta, required String distanceKm}) async {
    if (kIsWeb) return;
    await _plugin.show(
      id: 2,
      title: '🚨 Ambulance En Route',
      body: '$distanceKm away • ETA: $eta',
      notificationDetails: _details,
    );
  }

  /// Show arrival notification + play siren sound
  Future<void> showArrived({required String unitNumber}) async {
    if (kIsWeb) return;

    // Play siren / alert sound
    try {
      await _audio.play(AssetSource('sounds/arrival_alert.mp3'));
    } catch (e) {
      debugPrint('[Notification] Sound play error: $e (non-fatal)');
    }

    await _plugin.show(
      id: 3,
      title: '✅ Ambulance Arrived!',
      body: 'Unit $unitNumber has reached your location. Paramedic is assisting you.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          playSound: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1D9E75),
        ),
      ),
    );
  }

  /// Show trip completed notification
  Future<void> showCompleted() async {
    if (kIsWeb) return;
    await _plugin.show(
      id: 4,
      title: '🏥 Emergency Trip Completed',
      body: 'Thank you for using SERN. Stay safe.',
      notificationDetails: _details,
    );
  }

  void dispose() {
    _audio.dispose();
  }
}
