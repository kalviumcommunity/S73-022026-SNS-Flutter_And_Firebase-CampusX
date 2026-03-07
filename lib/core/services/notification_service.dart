import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

/// Notification types for Campus Connect
enum NotificationType {
  announcement,
  eventRegistration,
  teamMembership,
  interviewSchedule,
  eventReminder,
  general,
}

/// Service for handling push notifications with FCM
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('FCM Token: $_fcmToken');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        // Update token in Firestore when user is logged in
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification when app is opened from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const announcementChannel = AndroidNotificationChannel(
      'announcements',
      'Announcements',
      description: 'Notifications for new club announcements',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const eventChannel = AndroidNotificationChannel(
      'events',
      'Events',
      description: 'Notifications for event registrations and reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const teamChannel = AndroidNotificationChannel(
      'teams',
      'Teams',
      description: 'Notifications for team membership updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const interviewChannel = AndroidNotificationChannel(
      'interviews',
      'Interviews',
      description: 'Notifications for interview schedules',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const generalChannel = AndroidNotificationChannel(
      'general',
      'General',
      description: 'General notifications',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(announcementChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eventChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(teamChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(interviewChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Handle foreground messages (show local notification)
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Campus Connect',
        body: notification.body ?? '',
        payload: jsonEncode(data),
        channelId: _getChannelId(data['type']),
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap (from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.notification?.title}');
    print('Notification data: ${message.data}');

    // TODO: Navigate to appropriate screen based on notification type
    final type = message.data['type'];
    final entityId = message.data['entityId'];

    // This will be handled by the app's navigation system
    // You can use a NavigatorKey or notification callback
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      print('Notification data: $data');
      // TODO: Navigate based on data
    }
  }

  /// Get channel ID based on notification type
  String _getChannelId(String? type) {
    switch (type) {
      case 'announcement':
        return 'announcements';
      case 'event_registration':
      case 'event_reminder':
        return 'events';
      case 'team_membership':
        return 'teams';
      case 'interview':
        return 'interviews';
      default:
        return 'general';
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Save FCM token to user document
  Future<void> saveFcmTokenToUser(String userId) async {
    if (_fcmToken == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('FCM token saved for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Subscribe to topic (e.g., club announcements)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Send notification to specific user (requires backend/Cloud Functions)
  /// This is a placeholder - actual implementation needs Cloud Functions
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done via Cloud Functions
    // For now, we'll store a notification document that Cloud Functions can process
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
      print('Notification queued for user: $userId');
    } catch (e) {
      print('Error queuing notification: $e');
    }
  }

  /// Send notification to topic (requires backend/Cloud Functions)
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done via Cloud Functions
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'topic': topic,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
      print('Notification queued for topic: $topic');
    } catch (e) {
      print('Error queuing notification: $e');
    }
  }

  /// Schedule local notification (for event reminders)
  Future<void> scheduleNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    // This requires timezone plugin configuration
    // For now, using immediate notification as placeholder
    print('Notification scheduled for: $scheduledTime');
    print('Title: $title, Body: $body');
    // TODO: Implement actual scheduling with timezone support
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_isInitialized) {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return false;
  }

  /// Request notification permissions (can be called from UI)
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }
}
