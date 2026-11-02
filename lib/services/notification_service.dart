import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'tidenote_channel';
  static const _channelName = 'TideNote Smart Reminders';
  static const _channelDescription = 'Pengingat Notifikasi Pintar TideNote';

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _unavailable = false;

  Future<void> initialize() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        _initialized ||
        _unavailable) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      await plugin.initialize(
        settings: const InitializationSettings(android: androidSettings),
      );
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel());
      _initialized = true;
    } on MissingPluginException catch (error) {
      _unavailable = true;
      debugPrint('[TideNote] notification plugin unavailable: $error');
    } on Error catch (error) {
      _unavailable = true;
      debugPrint('[TideNote] notification platform not registered: $error');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await initialize();
    if (_unavailable) return;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsGranted = await android
        ?.requestNotificationsPermission();
    final exactAlarmGranted = await android?.requestExactAlarmsPermission();
    debugPrint(
      '[TideNote] notification permission=$notificationsGranted exactAlarm=$exactAlarmGranted',
    );
  }

  AndroidNotificationChannel _channel() => const AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  AndroidNotificationDetails _androidDetails() =>
      const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF8DBEE1),
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
      );

  Future<void> showTestNotification() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await initialize();
    if (_unavailable) return;
    await plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: '\u{1F9EA} TideNote Test',
      body: 'Ini adalah notifikasi tes sistem dari TideNote.',
      notificationDetails: NotificationDetails(android: _androidDetails()),
    );
  }

  Future<void> scheduleTaskNotification(
    String id,
    String title,
    DateTime deadline, {
    String? instruction,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await initialize();
    if (_unavailable) return;
    await cancelTaskNotification(id);

    final now = tz.TZDateTime.now(tz.local);
    final deadlineInWib = tz.TZDateTime.from(deadline, tz.local);
    if (!deadlineInWib.isAfter(now)) {
      debugPrint(
        '[TideNote] notification skipped because deadline is in the past: $deadline',
      );
      return;
    }

    final baseId = id.hashCode & 0x7fffffff;
    final remaining = deadlineInWib.difference(now);
    final details = NotificationDetails(android: _androidDetails());
    final hasInstruction = instruction != null && instruction.trim().isNotEmpty;
    debugPrint(
      '[TideNote] scheduleTaskNotification id=$id deadline=$deadlineInWib now=$now remaining=$remaining',
    );

    Future<void> schedule({
      required int notificationId,
      required String notificationTitle,
      required String fallback,
      required tz.TZDateTime date,
    }) async {
      if (!date.isAfter(now) || !date.isBefore(deadlineInWib)) return;
      await _schedule(
        id: notificationId,
        title: notificationTitle,
        body: _buildBody(
          fallback: fallback,
          title: title,
          instruction: hasInstruction ? instruction : null,
        ),
        scheduledDate: date,
        details: details,
      );
    }

    if (remaining > const Duration(hours: 48)) {
      for (var day = 0; ; day++) {
        final date = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          19,
        );
        if (!date.isBefore(deadlineInWib)) break;
        await schedule(
          notificationId: baseId + day,
          notificationTitle: '\u{1F7E2} TideNote: Status Aman',
          fallback: 'Tugas "$title" masih memiliki waktu lebih dari 2 hari.',
          date: date,
        );
      }
    } else if (remaining >= const Duration(hours: 24)) {
      for (var day = 0; ; day++) {
        final base = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
        );
        final morning = tz.TZDateTime(
          tz.local,
          base.year,
          base.month,
          base.day,
          8,
        );
        final evening = tz.TZDateTime(
          tz.local,
          base.year,
          base.month,
          base.day,
          19,
        );
        await schedule(
          notificationId: baseId + day * 10 + 1,
          notificationTitle: '\u{1F7E1} TideNote Pengingat Pagi',
          fallback:
              'Tugas "$title" dikumpulkan besok! Tetap semangat menyelesaikannya.',
          date: morning,
        );
        await schedule(
          notificationId: baseId + day * 10 + 2,
          notificationTitle: '\u{1F7E1} TideNote Pengingat Malam',
          fallback: 'Jangan lupa cicil tugas "$title" sebelum besok.',
          date: evening,
        );
        if (!morning.isBefore(deadlineInWib) &&
            !evening.isBefore(deadlineInWib)) {
          break;
        }
      }
    } else {
      for (var day = 0; ; day++) {
        final base = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
        );
        final morning = tz.TZDateTime(
          tz.local,
          base.year,
          base.month,
          base.day,
          8,
        );
        final noon = tz.TZDateTime(
          tz.local,
          base.year,
          base.month,
          base.day,
          13,
        );
        final evening = tz.TZDateTime(
          tz.local,
          base.year,
          base.month,
          base.day,
          19,
        );
        await schedule(
          notificationId: baseId + day * 10 + 3,
          notificationTitle: '\u{1F534} TideNote: Pagi Ini',
          fallback:
              'Deadline tugas "$title" sudah sangat dekat. Mulai dikerjakan sekarang.',
          date: morning,
        );
        await schedule(
          notificationId: baseId + day * 10 + 4,
          notificationTitle: '\u{1F534} TideNote: Siang Ini',
          fallback:
              'Sisa waktu untuk tugas "$title" tinggal sedikit. Tetap lanjutkan pengerjaan.',
          date: noon,
        );
        await schedule(
          notificationId: baseId + day * 10 + 5,
          notificationTitle: '\u{1F534} TideNote: Malam Ini',
          fallback:
              'Jangan tunda lagi, tugas "$title" harus segera diselesaikan.',
          date: evening,
        );
        if (!morning.isBefore(deadlineInWib) &&
            !noon.isBefore(deadlineInWib) &&
            !evening.isBefore(deadlineInWib)) {
          break;
        }
      }
      final emergency = deadlineInWib.subtract(const Duration(hours: 3));
      if (emergency.isAfter(now)) {
        await schedule(
          notificationId: baseId + 6,
          notificationTitle: '\u{1F534} PERINGATAN DARURAT!',
          fallback: 'Waktu tersisa kurang dari 3 jam untuk tugas "$title"!',
          date: emergency,
        );
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
  }) async {
    try {
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (error) {
      debugPrint(
        '[TideNote] exact schedule failed id=$id error=$error; retrying inexact',
      );
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelTaskNotification(String id) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await initialize();
    if (_unavailable) return;
    final baseId = id.hashCode & 0x7fffffff;
    for (var offset = 0; offset < 240; offset++) {
      await plugin.cancel(id: baseId + offset);
    }
  }

  String _buildBody({
    required String fallback,
    required String title,
    String? instruction,
  }) {
    final cleaned = instruction?.trim();
    return cleaned == null || cleaned.isEmpty
        ? '$fallback\nDetail tugas: $title'
        : '$fallback\nInstruksi: $cleaned';
  }
}
