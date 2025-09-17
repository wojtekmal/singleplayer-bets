import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'bet_model.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleBetNotifications(Bet bet) async {
    // Ensure bet.id is not null
    if (bet.id == null) return;

    // Use a unique integer for notification ID
    final int notificationId = bet.id!;
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    // Schedule initial notification
    if (scheduledDate.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Bet needs resolving!',
        'Did "${bet.content}" happen?',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bet_resolution_channel',
            'Bet Resolution',
            channelDescription: 'Notifications for resolving bets',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    
    // Schedule weekly repeating notification, starting one week after the resolve date
    // Use a different ID to not overwrite the initial one
    final int weeklyNotificationId = notificationId + 100000;
    final tz.TZDateTime weeklyStartDate = scheduledDate.add(const Duration(days: 7));
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      weeklyNotificationId,
      'Unresolved Bet Reminder',
      'Your bet "${bet.content}" is still unresolved.',
      weeklyStartDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bet_reminder_channel',
          'Bet Reminders',
          channelDescription: 'Weekly reminders for unresolved bets',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelBetNotifications(int betId) async {
    // Cancel both the initial and the weekly notification
    await flutterLocalNotificationsPlugin.cancel(betId);
    await flutterLocalNotificationsPlugin.cancel(betId + 100000);
  }
}