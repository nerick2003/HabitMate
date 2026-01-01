import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    // Set to device's local timezone (defaults to local if not set)
    try {
      final location = tz.getLocation('America/New_York'); // Fallback
      tz.setLocalLocation(location);
    } catch (e) {
      // If timezone initialization fails, continue without setting
      // The notifications will still work with UTC
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleHabitReminders(Habit habit) async {
    // Cancel existing notifications for this habit
    await cancelHabitReminders(habit.id!);

    if (habit.reminderTimes.isEmpty) return;

    for (int i = 0; i < habit.reminderTimes.length; i++) {
      final timeParts = habit.reminderTimes[i].split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        habit.id! * 1000 + i, // Unique ID for each reminder
        habit.name,
        'Time to ${habit.name.toLowerCase()}!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders for your daily habits',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_${habit.id}',
      );
    }
  }

  Future<void> cancelHabitReminders(int? habitId) async {
    if (habitId == null) return;
    
    // Cancel all reminders for this habit (assuming max 10 reminders per habit)
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(habitId * 1000 + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

