import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the notification plugin
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize time zones
    tz.initializeTimeZones();
  }

  //TODO test
  void scheduleTestNotification() {
    DateTime scheduledTime = DateTime.now().add(Duration(seconds: 10));
    scheduleNotification(0, 'Test Notification', 'Testing', scheduledTime);
  }

  Future<void> scheduleNotification(
      int id, String title, String tag, DateTime scheduledTime) async {
    print("notification @ $scheduledTime for $title");
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      tag,
      _convertTimeToTZDateTime(scheduledTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      //androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _convertTimeToTZDateTime(DateTime dateTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      //dateTime.second,
    );
  }
}
