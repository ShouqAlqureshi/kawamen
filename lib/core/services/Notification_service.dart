import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class UpdateTreatmentStatus extends NotificationEvent {
  final String emotionId;
  final String status; // 'accepted', 'rejected', 'pending'

  const UpdateTreatmentStatus(this.emotionId, this.status);

  @override
  List<Object?> get props => [emotionId, status];
}

class InitializeNotifications extends NotificationEvent {}

class ShowEmotionNotification extends NotificationEvent {
  final String emotion;
  final double intensity;
  final String emotionId;

  const ShowEmotionNotification(this.emotion, this.intensity, this.emotionId);

  @override
  List<Object?> get props => [emotion, intensity, emotionId];
}

class NotificationAccepted extends NotificationEvent {
  final String emotion;
  final String emotionId;

  const NotificationAccepted(this.emotion, this.emotionId);

  @override
  List<Object?> get props => [emotion, emotionId];
}

class NotificationRejected extends NotificationEvent {
  final String emotionId; // Added to track which notification was rejected
  final String
      emotion; // Added emotion to ensure we have it for document creation

  const NotificationRejected(this.emotionId, this.emotion);

  @override
  List<Object?> get props => [emotionId, emotion];
}

class NotificationPostponed extends NotificationEvent {
  final String emotion;
  final String emotionId;
  final double intensity;

  const NotificationPostponed(this.emotion, this.emotionId, this.intensity);

  @override
  List<Object?> get props => [emotion, emotionId, intensity];
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object> get props => [];
}

class TreatmentStatusUpdated extends NotificationState {
  final String emotionId;
  final String status;
  final String? userTreatmentId;

  const TreatmentStatusUpdated(this.emotionId, this.status,
      {this.userTreatmentId});

  @override
  List<Object> get props => [emotionId, status, userTreatmentId ?? ''];
}

class NotificationInitial extends NotificationState {}

class NotificationReady extends NotificationState {}

class NotificationShowing extends NotificationState {
  final String emotion;
  final String emotionId;

  const NotificationShowing(this.emotion, this.emotionId);

  @override
  List<Object> get props => [emotion, emotionId];
}

class NavigateToTreatment extends NotificationState {
  final String emotion;
  final String emotionId;
  final String userTreatmentId;

  const NavigateToTreatment(this.emotion, this.emotionId, this.userTreatmentId);

  @override
  List<Object> get props => [emotion, emotionId, userTreatmentId];
}

class NotificationCancelled extends NotificationState {
  final String action; // 'rejected' or 'postponed'

  const NotificationCancelled(this.action);

  @override
  List<Object> get props => [action];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging firebaseMessaging;
  final GlobalKey<NavigatorState> navigatorKey;

  // Track current notification ID
  int _currentNotificationId = 0;

  final Map<String, String> _emotionTreatments = {
    'angry':
        'لا تَغْضَبْ لا تَغْضَبْ لا تَغْضَبْ - جرب تمارين التنفس العميق للتهدئة',
    'sad':
        'وَلَا تَخَافِي وَلَا تَحْزَنِي - جرب تمارين العلاج السلوكي المعرفي لمساعدتك',
  };

  // Add mapping of English emotion names to Arabic
  final Map<String, String> _emotionNamesArabic = {
    'angry': 'الغضب',
    'sad': 'الحزن',
  };

  // Map emotions to treatment types
  final Map<String, String> _emotionToTreatmentType = {
    'anger': 'DeepBreathing',
    'angry': 'DeepBreathing',
    'sadness': 'CBTtherapy',
    'sad': 'CBTtherapy',
    'fear': 'deep-breathing',
    'anxiety': 'deep-breathing',
    'anxious': 'deep-breathing',
  };

  NotificationBloc({
    required this.flutterLocalNotificationsPlugin,
    required this.firebaseMessaging,
    required this.navigatorKey,
  }) : super(NotificationInitial()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<ShowEmotionNotification>(_onShowEmotionNotification);
    on<NotificationAccepted>(_onNotificationAccepted);
    on<NotificationRejected>(_onNotificationRejected);
    on<NotificationPostponed>(_onNotificationPostponed);
    on<UpdateTreatmentStatus>(_onUpdateTreatmentStatus);
  }
  Future<void> _showNotification(
      String emotion, String emotionId, double intensity) async {
    // Get Arabic emotion name
    String emotionArabic =
        _emotionNamesArabic[emotion.toLowerCase()] ?? 'مشاعر';

    // Get treatment text for this emotion
    String treatmentText = _emotionTreatments[emotion.toLowerCase()] ??
        'لدينا اقتراحات لمساعدتك مع مشاعرك الحالية.';

    // Create non-const instance to allow setting all properties
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'emotion_channel',
      'Emotion Notifications',
      channelDescription: 'Notifications for detected emotions',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Make notification persistent
      autoCancel: false, // Prevent auto-cancellation
      fullScreenIntent: true, // Make sure user sees it
      category: AndroidNotificationCategory
          .reminder, // Use enum type instead of string
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept',
          'قبول',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject',
          'رفض',
          showsUserInterface: true, // Ensure UI interaction for reject action
        ),
        AndroidNotificationAction(
          'later',
          'لاحقاً',
          showsUserInterface: true, // Ensure UI interaction for later action
        ),
      ],
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Use current notification ID for tracking
    _currentNotificationId =
        DateTime.now().millisecondsSinceEpoch.hashCode % 100000;
    int notificationId = _currentNotificationId;

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'تم اكتشاف مشاعر: $emotionArabic',
      'أنت تشعر بـ $emotionArabic... $treatmentText',
      platformChannelSpecifics,
      payload: 'EMOTION|$emotion|$emotionId|$intensity',
    );
  }

  FutureOr<void> _onInitializeNotifications(
      InitializeNotifications event, Emitter<NotificationState> emit) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final InitializationSettings initializationSettings =
        const InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null) {
          final parts = payload.split('|');
          if (parts.length >= 3) {
            final action = parts[0];
            final emotion = parts[1];
            final emotionId = parts[2];
            final intensity =
                parts.length >= 4 ? double.tryParse(parts[3]) ?? 0.0 : 0.0;

            if (action == 'EMOTION') {
              // Process notification response based on action ID
              if (response.actionId == 'accept') {
                print('Action: accept for emotion $emotion, $emotionId');
                add(NotificationAccepted(emotion, emotionId));
              } else if (response.actionId == 'reject') {
                print('Action: reject for emotion $emotion, $emotionId');
                // Make sure the event is being created correctly with both emotionId and emotion
                add(NotificationRejected(emotionId, emotion));
              } else if (response.actionId == 'later') {
                print('Action: later for emotion $emotion, $emotionId');
                add(NotificationPostponed(emotion, emotionId, intensity));
              } else {
                // Handle tap on notification body (default to accept)
                print('Notification tapped (default action)');
                add(NotificationAccepted(emotion, emotionId));
              }
            }
          }
        }
      },
    );

    // Configure notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emotion_channel',
      'Emotion Notifications',
      description: 'Notifications for detected emotions',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create the notification channel for Android 8.0+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions
    await _requestNotificationPermissions();

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      if (data.containsKey('emotion') && data.containsKey('emotionId')) {
        final emotion = data['emotion'] as String;
        final emotionId = data['emotionId'] as String;
        final intensity = double.tryParse(data['intensity'] ?? '0.0') ?? 0.0;

        add(ShowEmotionNotification(emotion, intensity, emotionId));
      }
    });

    emit(NotificationReady());
  }

  Future<bool> _requestNotificationPermissions() async {
    // Request notification permissions
    final settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true, // Request critical alert permission
      announcement: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  FutureOr<void> _onNotificationRejected(
      NotificationRejected event, Emitter<NotificationState> emit) async {
    try {
      print(
          '[DEBUG] _onNotificationRejected handler START with emotionId: ${event.emotionId}, emotion: ${event.emotion}');

      // First, cancel the notification to ensure it goes away
      await flutterLocalNotificationsPlugin.cancel(_currentNotificationId);
      print('[DEBUG] Notification cancelled');

      // Then update the database
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[DEBUG] User authenticated: ${user.uid}');

        // IMPORTANT FIX: Make sure we have a valid emotion string
        if (event.emotion.isEmpty) {
          print('[DEBUG] ERROR: Empty emotion string!');
          throw Exception('Empty emotion string in NotificationRejected event');
        }

        print(
            '[DEBUG] Creating treatment document with rejected status for emotion: ${event.emotion}');

        // Create treatment document with 'rejected' status using the emotion from the event
        final userTreatmentId =
            await _createTreatmentDocument(event.emotion, 'rejected');
        print(
            '[DEBUG] Created rejected treatment document with ID: $userTreatmentId');

        // Get the emotion document reference to update it
        final emotionDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emotionalData')
            .doc(event.emotionId);

        // IMPORTANT: Verify the document exists before updating
        final docSnapshot = await emotionDocRef.get();
        if (!docSnapshot.exists) {
          print(
              '[DEBUG] ERROR: Emotion document ${event.emotionId} does not exist!');
          throw Exception('Emotion document not found');
        }

        // Update the emotion document with a reference to the treatment
        print('[DEBUG] Updating emotion document with treatment reference');
        await emotionDocRef.update({
          'userTreatmentId': userTreatmentId,
          'treatmentStatus': 'rejected',
        });
        print('[DEBUG] Emotion document updated successfully');

        // Emit states
        emit(TreatmentStatusUpdated(event.emotionId, 'rejected',
            userTreatmentId: userTreatmentId));
        emit(NotificationCancelled('rejected'));
        emit(NotificationReady());
        print('[DEBUG] States emitted successfully');
      } else {
        print('[DEBUG] Error: User not authenticated');
        // Still emit states
        emit(NotificationCancelled('rejected'));
        emit(NotificationReady());
      }
    } catch (e) {
      print('[DEBUG] Error rejecting notification: $e');
      // Still emit states to ensure UI is updated
      emit(NotificationCancelled('rejected'));
      emit(NotificationReady());
    }

    print('[DEBUG] _onNotificationRejected handler END');
  }

  // Fixed postpone handler with proper document creation
  FutureOr<void> _onNotificationPostponed(
      NotificationPostponed event, Emitter<NotificationState> emit) async {
    try {
      print('Notification postponed for ${event.emotion}, ${event.emotionId}');

      // First, update the database
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the emotion document
        final emotionDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emotionalData')
            .doc(event.emotionId);

        // Create treatment document with 'pending' status
        final userTreatmentId =
            await _createTreatmentDocument(event.emotion, 'pending');
        print('Created pending treatment document: $userTreatmentId');

        // Update the emotion document with a reference to the treatment
        await emotionDocRef.update({
          'userTreatmentId': userTreatmentId,
          'treatmentStatus': 'pending',
        });

        // Now cancel the notification
        await flutterLocalNotificationsPlugin.cancel(_currentNotificationId);

        // Emit states
        emit(TreatmentStatusUpdated(event.emotionId, 'pending',
            userTreatmentId: userTreatmentId));
        emit(NotificationCancelled('postponed'));
        emit(NotificationReady());

        // After 30 minutes, show the notification again
        await Future.delayed(const Duration(minutes: 30));
        print('30 minutes passed, showing notification again');
        add(ShowEmotionNotification(
            event.emotion, event.intensity, event.emotionId));
      } else {
        print('Error: User not authenticated');
        // Still cancel notification even if there's an auth issue
        await flutterLocalNotificationsPlugin.cancel(_currentNotificationId);
        emit(NotificationCancelled('postponed'));
        emit(NotificationReady());
      }
    } catch (e) {
      print('Error postponing notification: $e');
      // Still cancel notification even if there's an error
      await flutterLocalNotificationsPlugin.cancel(_currentNotificationId);
      emit(NotificationCancelled('postponed'));
      emit(NotificationReady());
    }
  }

  // Create a treatment document and return the treatment ID
  Future<String> _createTreatmentDocument(String emotion, String status) async {
    try {
      print(
          '[DEBUG] _createTreatmentDocument START - emotion: $emotion, status: $status');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[DEBUG] User not authenticated in _createTreatmentDocument');
        throw Exception('User not authenticated');
      }

      print(
          '[DEBUG] Creating $status treatment document for emotion: $emotion');

      // Determine treatment type based on emotion
      final treatmentType =
          _emotionToTreatmentType[emotion.toLowerCase()] ?? 'CBTtherapy';
      print('[DEBUG] Selected treatment type: $treatmentType');

      // Create a treatment document in a treatments collection
      final treatmentRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userTreatments')
          .add({
        'treatmentId': treatmentType,
        'status': status,
        'emotion': emotion,
        'progress': status == 'accepted' ? 0.0 : null,
        'date': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the generated document ID
      final userTreatmentId = treatmentRef.id;
      print('[DEBUG] Created treatment document with ID: $userTreatmentId');

      // Update the document to include its own ID
      await treatmentRef.update({'userTreatmentId': userTreatmentId});
      print('[DEBUG] Updated treatment document with its own ID');

      print(
          '[DEBUG] _createTreatmentDocument END - returning ID: $userTreatmentId');
      return userTreatmentId;
    } catch (e) {
      print('[DEBUG] Error in _createTreatmentDocument: $e');
      throw e; // Re-throw to handle in calling method
    }
  }

  FutureOr<void> _onUpdateTreatmentStatus(
      UpdateTreatmentStatus event, Emitter<NotificationState> emit) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the emotion document to access the emotion type
        final emotionDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emotionalData')
            .doc(event.emotionId);

        final emotionDoc = await emotionDocRef.get();
        if (!emotionDoc.exists) {
          print('Error: Emotion document not found');
          return;
        }

        final emotion = emotionDoc.data()?['emotion'] as String? ?? 'unknown';

        // Create a treatment document with the specified status
        final userTreatmentId =
            await _createTreatmentDocument(emotion, event.status);

        // Update the emotion document with a reference to the treatment
        await emotionDocRef.update({
          'userTreatmentId': userTreatmentId,
          'treatmentStatus':
              event.status, // Keep this for backward compatibility
        });

        emit(TreatmentStatusUpdated(event.emotionId, event.status,
            userTreatmentId: userTreatmentId));

        // If accepted, we'll want to navigate to the treatment
        if (event.status == 'accepted') {
          emit(NavigateToTreatment(emotion, event.emotionId, userTreatmentId));
          // Direct navigation using navigatorKey
          _navigateToTreatment(
              emotion: emotion,
              emotionId: event.emotionId,
              userTreatmentId: userTreatmentId);
        }
      }
    } catch (e) {
      print('Error updating treatment status: $e');
    }
  }

  // Handle navigation directly within the bloc
// Fix for the _navigateToTreatment method in NotificationBloc
  void _navigateToTreatment({
    required String emotion,
    required String emotionId,
    required String userTreatmentId,
  }) {
    print(
        'DirectNavigation attempting for $emotion, userTreatmentId: $userTreatmentId');

    if (navigatorKey.currentState == null) {
      print('Error: Navigator state is null');
      return;
    }

    // Map emotions to routes
    String route;
    switch (emotion.toLowerCase()) {
      case 'sadness':
      case 'sad':
        route = '/cbt-therapy';
        break;
      case 'anger':
      case 'angry':
        route = '/deep-breathing';
        break;
      default:
        route = '/cbt-therapy';
    }

    // DEBUG: Print the arguments being passed
    print('Navigating to $route with userTreatmentId: $userTreatmentId');

    // Navigate using the global navigator key
    navigatorKey.currentState!.pushNamed(
      route,
      arguments: {
        'userTreatmentId': userTreatmentId,
        'treatmentId':
            _emotionToTreatmentType[emotion.toLowerCase()] ?? 'CBTtherapy',
      },
    );
  }

// Fix for _onNotificationAccepted method in NotificationBloc
  FutureOr<void> _onNotificationAccepted(
      NotificationAccepted event, Emitter<NotificationState> emit) async {
    try {
      // Cancel notification first
      await flutterLocalNotificationsPlugin.cancel(_currentNotificationId);
      print('Notification accepted for ${event.emotion}, ${event.emotionId}');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: User not authenticated');
        return;
      }

      // First create the treatment document
      final userTreatmentId =
          await _createTreatmentDocument(event.emotion, 'accepted');
      print('Created accepted treatment document with ID: $userTreatmentId');

      // Update the emotion document with the treatment reference
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData')
          .doc(event.emotionId)
          .update({
        'userTreatmentId': userTreatmentId,
        'treatmentStatus': 'accepted',
      });

      // Emit the status update
      emit(TreatmentStatusUpdated(event.emotionId, 'accepted',
          userTreatmentId: userTreatmentId));

      // Then emit the navigation state which will trigger navigation to the treatment
      emit(
          NavigateToTreatment(event.emotion, event.emotionId, userTreatmentId));

      // Direct navigation using navigatorKey
      _navigateToTreatment(
        emotion: event.emotion,
        emotionId: event.emotionId,
        userTreatmentId: userTreatmentId,
      );
    } catch (e) {
      print('Error in _onNotificationAccepted: $e');
    }
  }

  FutureOr<void> _onShowEmotionNotification(
      ShowEmotionNotification event, Emitter<NotificationState> emit) async {
    await _showNotification(event.emotion, event.emotionId, event.intensity);
    emit(NotificationShowing(event.emotion, event.emotionId));

    // This will help with in-app notifications - check if the app is in foreground
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get the current app state to see if we're in foreground
      final isInForeground =
          true; // This is always true when this code runs in _onShowEmotionNotification

      // If we're in foreground, we need to handle the navigation directly
      if (isInForeground) {
        // First, show the notification UI
        // Then, setup a listener for user actions within the app
        // This is where the in-app handling could be improved
        print('App is in foreground, notification shown for ${event.emotion}');
      }
    }
  }

  void handleInAppNotificationResponse(
      String action, String emotion, String emotionId, double intensity) {
    print(
        '[DEBUG] handleInAppNotificationResponse called with action: $action for $emotion with ID: $emotionId');

    if (action == 'accept') {
      add(NotificationAccepted(emotion, emotionId));
    } else if (action == 'reject') {
      print('[DEBUG] About to add NotificationRejected event for $emotionId');
      // Make sure the event is being created correctly
      final event = NotificationRejected(emotionId, emotion);
      print(
          '[DEBUG] Created event with emotionId: ${event.emotionId}, emotion: ${event.emotion}');
      add(event);
      print('[DEBUG] Added NotificationRejected event to stream');
    } else if (action == 'later') {
      add(NotificationPostponed(emotion, emotionId, intensity));
    }
  }

  Future<void> checkNotificationPermissions() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    print('Notification permission status: ${settings.authorizationStatus}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late NotificationBloc _notificationBloc;
  bool _isInitialized = false;
  // Global navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Firebase.initializeApp();

    _notificationBloc = NotificationBloc(
      flutterLocalNotificationsPlugin: FlutterLocalNotificationsPlugin(),
      firebaseMessaging: FirebaseMessaging.instance,
      navigatorKey: navigatorKey,
    );

    _notificationBloc.add(InitializeNotifications());
    _isInitialized = true;

    // Add debug print to verify initialization
    print('NotificationService initialized successfully');
  }

  NotificationBloc get bloc {
    if (!_isInitialized) {
      print('Warning: Accessing NotificationBloc before initialization');
    }
    return _notificationBloc;
  }

  GlobalKey<NavigatorState> get getNavigatorKey => navigatorKey;
}

class InAppNotification extends StatelessWidget {
  final String emotion;
  final String emotionId;
  final double intensity;
  final NotificationBloc bloc;

  const InAppNotification({
    Key? key,
    required this.emotion,
    required this.emotionId,
    required this.intensity,
    required this.bloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get Arabic emotion name using the bloc's mapping
    final Map<String, String> _emotionNamesArabic = {
      'angry': 'الغضب',
      'sad': 'الحزن',
    };

    String emotionArabic =
        _emotionNamesArabic[emotion.toLowerCase()] ?? 'مشاعر';

    // Get treatment text
    final Map<String, String> _emotionTreatments = {
      'angry':
          'عن أَبي هريرة: أَنَّ رَجُلًا قَالَ للنَّبِيِّ ﷺ: أَوْصِني، قَالَ:(لا تَغْضَبْ)، فَرَدَّدَ مِرَارًا قَالَ:(لا تَغْضَبْ)رواه البخاري. جرب تمارين التنفس العميق للتهدئة',
      'sad':
          ' سورةالقصص الآية:٧(وَلَا تَخَافِي وَلَا تَحْزَنِي) جرب تمارين العلاج السلوكي المعرفي لمساعدتك ',
    };

    String treatmentText = _emotionTreatments[emotion.toLowerCase()] ??
        'لدينا اقتراحات لمساعدتك مع مشاعرك الحالية.';

    return WillPopScope(
      // Prevent dialog from being dismissed by back button
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text('تم اكتشاف مشاعر: $emotionArabic'),
        content: Text('أنت تشعر بـ $emotionArabic... $treatmentText'),
        // Disable the close button
        actions: [
          TextButton(
            onPressed: () {
              print('[DEBUG] ACCEPT button pressed for emotion $emotionId');
              Navigator.of(context).pop(); // Close the dialog
              bloc.handleInAppNotificationResponse(
                  'accept', emotion, emotionId, intensity);
            },
            child: const Text('قبول'),
          ),
          // FIXED REJECT BUTTON
          TextButton(
            onPressed: () {
              print('[DEBUG] REJECT button pressed for emotion $emotionId');

              // Store the bloc reference before dismissing dialog
              final NotificationBloc localBloc = bloc;
              final String localEmotionId = emotionId;
              final String localEmotion = emotion;

              // Close the dialog first
              Navigator.of(context).pop();

              // Use a microtask to ensure this runs after dialog dismissal but before the next frame
              Future.microtask(() {
                print('[DEBUG] Creating NotificationRejected event');
                final event =
                    NotificationRejected(localEmotionId, localEmotion);
                print(
                    '[DEBUG] Created event with emotionId: ${event.emotionId}, emotion: ${event.emotion}');

                localBloc.add(event);
                print('[DEBUG] Added NotificationRejected event to bloc');
              });
            },
            child: const Text('رفض'),
          ),
          TextButton(
            onPressed: () {
              print('[DEBUG] LATER button pressed for emotion $emotionId');
              Navigator.of(context).pop(); // Close the dialog
              bloc.handleInAppNotificationResponse(
                  'later', emotion, emotionId, intensity);
            },
            child: const Text('لاحقاً'),
          ),
        ],
      ),
    );
  }
}

class CombinedNotificationListener extends StatelessWidget {
  final Widget child;

  const CombinedNotificationListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      bloc: NotificationService().bloc,
      listenWhen: (previous, current) =>
          current is NavigateToTreatment ||
          current is NotificationShowing ||
          current is NotificationCancelled,
      listener: (context, state) {
        if (state is NavigateToTreatment) {
          print(
              'CombinedListener: NavigateToTreatment received: ${state.emotion}, ${state.userTreatmentId}');
          _navigateToTreatment(
              context, state.emotion, state.emotionId, state.userTreatmentId);
        } else if (state is NotificationShowing) {
          // This is where we handle in-app notifications
          print(
              'CombinedListener: NotificationShowing received: ${state.emotion}');

          // Show an in-app dialog instead of a system notification
          // with barrierDismissible set to false to prevent tapping outside to dismiss
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => InAppNotification(
              emotion: state.emotion,
              emotionId: state.emotionId,
              intensity: 0.0,
              bloc: NotificationService().bloc,
            ),
          );
        } else if (state is NotificationCancelled) {
          print(
              'CombinedListener: Notification cancelled with action: ${state.action}');
          // You could show a brief confirmation message here if desired
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'تم ${state.action == 'rejected' ? 'رفض' : 'تأجيل'} التنبيه'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: child,
    );
  }

  void _navigateToTreatment(BuildContext context, String emotion,
      String emotionId, String userTreatmentId) {
    print(
        'CombinedListener: Navigating to treatment for emotion: $emotion, userTreatmentId: $userTreatmentId');

    // Map emotions to treatment types
    final Map<String, String> _emotionToTreatmentType = {
      'anger': 'DeepBreathing',
      'angry': 'DeepBreathing',
      'sadness': 'CBTtherapy',
      'sad': 'CBTtherapy',
      'fear': 'deep-breathing',
      'anxiety': 'deep-breathing',
      'anxious': 'deep-breathing',
    };

    final String treatmentType =
        _emotionToTreatmentType[emotion.toLowerCase()] ?? 'CBTtherapy';

    // Map emotions to specific treatment pages
    switch (emotion.toLowerCase()) {
      case 'sadness':
      case 'sad':
        Navigator.pushNamed(
          context,
          '/cbt-therapy',
          arguments: {
            'userTreatmentId': userTreatmentId,
            'treatmentId': treatmentType,
          },
        );
        break;

      case 'anger':
      case 'angry':
        Navigator.pushNamed(
          context,
          '/deep-breathing',
          arguments: {
            'userTreatmentId': userTreatmentId,
            'treatmentId': treatmentType,
          },
        );
        break;

      default:
        Navigator.pushNamed(
          context,
          '/cbt-therapy',
          arguments: {
            'userTreatmentId': userTreatmentId,
            'treatmentId': treatmentType,
          },
        );
        break;
    }
  }
}

class TreatmentNavigator extends StatelessWidget {
  const TreatmentNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      bloc: NotificationService().bloc,
      listenWhen: (previous, current) => current is NavigateToTreatment,
      listener: (context, state) {
        if (state is NavigateToTreatment) {
          print(
              'TreatmentNavigator: NavigateToTreatment received: ${state.emotion}, ${state.userTreatmentId}');
          _navigateToTreatment(
              context, state.emotion, state.emotionId, state.userTreatmentId);
        }
      },
      child: Container(), // Invisible widget
    );
  }

  void _navigateToTreatment(BuildContext context, String emotion,
      String emotionId, String userTreatmentId) {
    // Add debug print to verify this method is called
    print(
        'TreatmentNavigator: Navigating to treatment for emotion: $emotion, userTreatmentId: $userTreatmentId');

    // Map emotions to specific treatment pages
    switch (emotion.toLowerCase()) {
      case 'sadness':
      case 'sad':
        Navigator.pushNamed(
          context,
          '/cbt-therapy',
          arguments: {
            'userTreatmentId': userTreatmentId,
          },
        );
        break;

      case 'anger':
      case 'angry':
        Navigator.pushNamed(
          context,
          '/deep-breathing',
          arguments: {
            'userTreatmentId': userTreatmentId,
          },
        );
        break;

      default:
        Navigator.pushNamed(
          context,
          '/cbt-therapy',
          arguments: {
            'userTreatmentId': userTreatmentId,
          },
        );
        break;
    }
  }
}
