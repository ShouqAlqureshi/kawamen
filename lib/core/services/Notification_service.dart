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

class NotificationRejected extends NotificationEvent {}

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

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging firebaseMessaging;
  final GlobalKey<NavigatorState> navigatorKey;

  final Map<String, String> _emotionTreatments = {
    'anger':
        'عن أَبي هريرة: أَنَّ رَجُلًا قَالَ للنَّبِيِّ ﷺ: أَوْصِني، قَالَ:(لا تَغْضَبْ)، فَرَدَّدَ مِرَارًا قَالَ:(لا تَغْضَبْ)رواه البخاري. جرب تمارين التنفس العميق للتهدئة',
    'sadness':
        ' سورةالقصص الآية:٧(وَلَا تَخَافِي وَلَا تَحْزَنِي) جرب تمارين العلاج السلوكي المعرفي لمساعدتك ',
  };

  // Add mapping of English emotion names to Arabic
  final Map<String, String> _emotionNamesArabic = {
    'anger': 'الغضب',
    'sadness': 'الحزن',
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

  Future<bool> _requestNotificationPermissions() async {
    final settings = await firebaseMessaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Create a treatment document and return the treatment ID
  Future<String> _createTreatmentDocument(String emotion, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Determine treatment type based on emotion
    final treatmentType =
        _emotionToTreatmentType[emotion.toLowerCase()] ?? 'CBTtherapy';

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

    // Update the document to include its own ID
    await treatmentRef.update({'userTreatmentId': userTreatmentId});

    return userTreatmentId;
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
          // We don't need treatmentStatus here anymore, as it will be in the treatment document
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
  void _navigateToTreatment(
      {required String emotion,
      required String emotionId,
      required String userTreatmentId}) {
    print('DirectNavigation attempting for $emotion, $userTreatmentId');

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

    // Navigate using the global navigator key
    navigatorKey.currentState!.pushNamed(
      route,
      arguments: {
        'userTreatmentId': userTreatmentId,
      },
    );
  }

  FutureOr<void> _onInitializeNotifications(
      InitializeNotifications event, Emitter<NotificationState> emit) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        const InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
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
                add(NotificationAccepted(emotion, emotionId));
              } else if (response.actionId == 'reject') {
                add(NotificationRejected());
              } else if (response.actionId == 'later') {
                add(NotificationPostponed(emotion, emotionId, intensity));
              } else {
                // Handle tap on notification body (no specific action)
                // Default to showing the notification
                add(ShowEmotionNotification(emotion, intensity, emotionId));
              }
            }
          }
        }
      },
    );

    // Request permissions
    await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
    print('Handling in-app notification response: $action for $emotion');

    if (action == 'accept') {
      add(NotificationAccepted(emotion, emotionId));
    } else if (action == 'reject') {
      add(NotificationRejected());
    } else if (action == 'later') {
      add(NotificationPostponed(emotion, emotionId, intensity));
    }
  }

  Future<void> checkNotificationPermissions() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  FutureOr<void> _onNotificationAccepted(
      NotificationAccepted event, Emitter<NotificationState> emit) {
    flutterLocalNotificationsPlugin.cancel(0);
    print('Notification accepted for ${event.emotion}, ${event.emotionId}');
    add(UpdateTreatmentStatus(event.emotionId, 'accepted'));
  }

  FutureOr<void> _onNotificationRejected(
      NotificationRejected event, Emitter<NotificationState> emit) async {
    // Cancel the notification first
    flutterLocalNotificationsPlugin.cancel(0);

    // If the current state is NotificationShowing, use that emotionId
    if (state is NotificationShowing) {
      final currentState = state as NotificationShowing;
      add(UpdateTreatmentStatus(currentState.emotionId, 'rejected'));
    }

    emit(NotificationReady());
  }

  FutureOr<void> _onNotificationPostponed(
      NotificationPostponed event, Emitter<NotificationState> emit) async {
    // Cancel the notification first
    flutterLocalNotificationsPlugin.cancel(0);

    // Create a treatment document with 'pending' status
    add(UpdateTreatmentStatus(event.emotionId, 'pending'));

    // After 30 minutes, show the notification again
    await Future.delayed(const Duration(minutes: 30));
    add(ShowEmotionNotification(
        event.emotion, event.intensity, event.emotionId));
  }

  Future<void> _showNotification(
      String emotion, String emotionId, double intensity) async {
    // Get Arabic emotion name
    String emotionArabic =
        _emotionNamesArabic[emotion.toLowerCase()] ?? 'مشاعر';

    // Get treatment text for this emotion
    String treatmentText = _emotionTreatments[emotion.toLowerCase()] ??
        'لدينا اقتراحات لمساعدتك مع مشاعرك الحالية.';

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'emotion_channel',
      'Emotion Notifications',
      channelDescription: 'Notifications for detected emotions',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept',
          'قبول',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject',
          'رفض',
        ),
        AndroidNotificationAction(
          'later',
          'لاحقاً',
        ),
      ],
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'تم اكتشاف مشاعر: $emotionArabic',
      'أنت تشعر بـ $emotionArabic... $treatmentText',
      platformChannelSpecifics,
      payload: 'EMOTION|$emotion|$emotionId|$intensity',
    );
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
      'anger': 'الغضب',
      'sadness': 'الحزن',
    };

    String emotionArabic =
        _emotionNamesArabic[emotion.toLowerCase()] ?? 'مشاعر';

    // Get treatment text
    final Map<String, String> _emotionTreatments = {
      'anger':
          'عن أَبي هريرة: أَنَّ رَجُلًا قَالَ للنَّبِيِّ ﷺ: أَوْصِني، قَالَ:(لا تَغْضَبْ)، فَرَدَّدَ مِرَارًا قَالَ:(لا تَغْضَبْ)رواه البخاري. جرب تمارين التنفس العميق للتهدئة',
      'sadness':
          ' سورةالقصص الآية:٧(وَلَا تَخَافِي وَلَا تَحْزَنِي) جرب تمارين العلاج السلوكي المعرفي لمساعدتك ',
    };

    String treatmentText = _emotionTreatments[emotion.toLowerCase()] ??
        'لدينا اقتراحات لمساعدتك مع مشاعرك الحالية.';

    return AlertDialog(
      title: Text('تم اكتشاف مشاعر: $emotionArabic'),
      content: Text('أنت تشعر بـ $emotionArabic... $treatmentText'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            bloc.handleInAppNotificationResponse(
                'accept', emotion, emotionId, intensity);
          },
          child: const Text('قبول'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            bloc.handleInAppNotificationResponse(
                'reject', emotion, emotionId, intensity);
          },
          child: const Text('رفض'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            bloc.handleInAppNotificationResponse(
                'later', emotion, emotionId, intensity);
          },
          child: const Text('لاحقاً'),
        ),
      ],
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
          current is NavigateToTreatment || current is NotificationShowing,
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
          showDialog(
            context: context,
            builder: (dialogContext) => InAppNotification(
              emotion: state.emotion,
              emotionId: state.emotionId,
              intensity:
                  0.0, // You might want to store intensity in NotificationShowing state
              bloc: NotificationService().bloc,
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
