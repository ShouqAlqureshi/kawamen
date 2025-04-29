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
  final String emotion; // Add emotion to event

  const UpdateTreatmentStatus(this.emotionId, this.status, this.emotion);

  @override
  List<Object?> get props => [emotionId, status, emotion];
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
  final String emotionId;
  final String emotion;

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

  const TreatmentStatusUpdated(this.emotionId, this.status, {this.userTreatmentId});

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

// Track active notifications
class ActiveNotification {
  final String emotion;
  final String emotionId;
  final double intensity;

  ActiveNotification(this.emotion, this.emotionId, this.intensity);
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging firebaseMessaging;
  
  // Store active notification (use a map if you need to track multiple)
  ActiveNotification? _activeNotification;

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
    'anger': 'deepBreathing',
    'angry': 'deepBreathing',
    'sadness': 'CBTtherapy',
    'sad': 'CBTtherapy',
    'fear': 'deep-breathing',
    'anxiety': 'deep-breathing',
    'anxious': 'deep-breathing',
  };

  NotificationBloc({
    required this.flutterLocalNotificationsPlugin,
    required this.firebaseMessaging,
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

    print('Creating treatment document for emotion: $emotion with status: $status');

    // Determine treatment type based on emotion
    final treatmentType = _emotionToTreatmentType[emotion.toLowerCase()] ?? 'CBTtherapy';
    
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
    await treatmentRef.update({
      'userTreatmentId': userTreatmentId
    });
    
    print('Created treatment document with ID: $userTreatmentId');
    return userTreatmentId;
  }

  // This method returns whether an emotion document exists
  Future<bool> _doesEmotionDocumentExist(String emotionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final emotionDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData')
          .doc(emotionId);
      
      final emotionDoc = await emotionDocRef.get();
      return emotionDoc.exists;
    } catch (e) {
      print('Error checking emotion document: $e');
      return false;
    }
  }

  // Create emotion document if it doesn't exist (for handling notifications before doc exists)
  Future<void> _createEmotionDocumentIfNeeded(String emotionId, String emotion) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final exists = await _doesEmotionDocumentExist(emotionId);
      if (!exists) {
        print('Creating new emotion document for ID: $emotionId');
        final emotionDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emotionalData')
            .doc(emotionId);
        
        await emotionDocRef.set({
          'emotion': emotion,
          'emotionId': emotionId,
          'timestamp': FieldValue.serverTimestamp(),
          'intensity': 0.5, // Default intensity
        });
      }
    } catch (e) {
      print('Error creating emotion document: $e');
    }
  }

  FutureOr<void> _onUpdateTreatmentStatus(
      UpdateTreatmentStatus event, Emitter<NotificationState> emit) async {
    try {
      print('Updating treatment status: ${event.emotionId} to ${event.status}');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated');
        return;
      }
      
      // Create emotion document if it doesn't exist (handling edge cases)
      await _createEmotionDocumentIfNeeded(event.emotionId, event.emotion);
      
      // Create a treatment document with the specified status
      final userTreatmentId = await _createTreatmentDocument(event.emotion, event.status);
      
      // Update the emotion document with a reference to the treatment
      final emotionDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emotionalData')
          .doc(event.emotionId);
      
      await emotionDocRef.update({
        'userTreatmentId': userTreatmentId,
        'treatmentStatus': event.status,
      });
      
      emit(TreatmentStatusUpdated(event.emotionId, event.status, userTreatmentId: userTreatmentId));
      
      // If accepted, we'll want to navigate to the treatment
      if (event.status == 'accepted') {
        print('Treatment accepted, navigating to treatment screen');
        emit(NavigateToTreatment(event.emotion, event.emotionId, userTreatmentId));
      }
    } catch (e) {
      print('Error updating treatment status: $e');
    }
  }

  // Setup notification channels separately to ensure they're properly registered
  Future<void> _setupNotificationChannels() async {
    // Create the notification channel group
    const AndroidNotificationChannelGroup channelGroup =
        AndroidNotificationChannelGroup(
      'emotion_channel_group',
      'Emotion Notifications',
      description: 'Notification channels for emotion detection',
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(channelGroup);

    // Create the high importance channel for emotion notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emotion_channel',
      'Emotion Notifications',
      description: 'Notifications for detected emotions',
      importance: Importance.max,
      enableLights: true,
      enableVibration: true,
      showBadge: true,
      groupId: 'emotion_channel_group',
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    print('Notification channels set up successfully');
  }

  FutureOr<void> _onInitializeNotifications(
      InitializeNotifications event, Emitter<NotificationState> emit) async {
    try {
      print('Initializing notifications');
      
      // Setup notification channels
      await _setupNotificationChannels();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          const InitializationSettings(
        android: initializationSettingsAndroid,
      );

      // Define notification response handler
      void notificationResponseHandler(NotificationResponse response) {
        print('Received notification response: actionId=${response.actionId}, payload=${response.payload}');
        
        final payload = response.payload;
        if (payload == null) {
          print('Error: notification payload is null');
          return;
        }
        
        final parts = payload.split('|');
        if (parts.length < 3) {
          print('Error: notification payload format invalid: $payload');
          return;
        }
        
        final action = parts[0];
        final emotion = parts[1];
        final emotionId = parts[2];
        final intensity = parts.length >= 4 ? double.tryParse(parts[3]) ?? 0.0 : 0.0;

        if (action != 'EMOTION') {
          print('Error: unknown action type: $action');
          return;
        }

        print('Processing notification action: ${response.actionId} for emotion $emotion');
        
        switch (response.actionId) {
          case 'accept':
            add(NotificationAccepted(emotion, emotionId));
            break;
          case 'reject':
            add(NotificationRejected(emotionId, emotion));
            break;
          case 'later':
            add(NotificationPostponed(emotion, emotionId, intensity));
            break;
          case null:
            // Default tap on notification (no specific action)
            print('Default notification tap - treating as accept');
            add(NotificationAccepted(emotion, emotionId));
            break;
          default:
            print('Unknown action ID: ${response.actionId}');
            break;
        }
      }

      // Initialize with the response handler
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: notificationResponseHandler,
      );

      // Force foreground notification presentation on iOS
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Get permissions for Firebase Messaging
      final permissionGranted = await _requestNotificationPermissions();
      print('Firebase messaging permission granted: $permissionGranted');

      // Handle notification when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received Firebase message: ${message.data}');
        
        final data = message.data;
        if (data.containsKey('emotion') && data.containsKey('emotionId')) {
          final emotion = data['emotion'] as String;
          final emotionId = data['emotionId'] as String;
          final intensity = double.tryParse(data['intensity'] ?? '0.0') ?? 0.0;

          add(ShowEmotionNotification(emotion, intensity, emotionId));
        }
      });

      emit(NotificationReady());
      print('Notifications initialized successfully');
    } catch (e) {
      print('Error initializing notifications: $e');
      // Even if there's an error, we'll still emit ready state to avoid blocking the app
      emit(NotificationReady());
    }
  }

  FutureOr<void> _onShowEmotionNotification(
      ShowEmotionNotification event, Emitter<NotificationState> emit) async {
    try {
      print('Showing notification for emotion: ${event.emotion}');
      
      // Store active notification info
      _activeNotification = ActiveNotification(
        event.emotion, 
        event.emotionId, 
        event.intensity
      );
      
      // Show the notification
      await _showNotification(event.emotion, event.emotionId, event.intensity);
      
      emit(NotificationShowing(event.emotion, event.emotionId));
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> checkNotificationPermissions() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  FutureOr<void> _onNotificationAccepted(
      NotificationAccepted event, Emitter<NotificationState> emit) async {
    try {
      print('Notification accepted for ${event.emotion}');
      
      // Cancel the notification first
      await flutterLocalNotificationsPlugin.cancel(0);
      _activeNotification = null;

      // Update treatment status - this will also emit NavigateToTreatment state
      add(UpdateTreatmentStatus(event.emotionId, 'accepted', event.emotion));
    } catch (e) {
      print('Error handling accepted notification: $e');
    }
  }

  FutureOr<void> _onNotificationRejected(
      NotificationRejected event, Emitter<NotificationState> emit) async {
    try {
      print('Notification rejected for ID: ${event.emotionId}');
      
      // Cancel the notification first
      await flutterLocalNotificationsPlugin.cancel(0);
      _activeNotification = null;

      // Update status
      add(UpdateTreatmentStatus(event.emotionId, 'rejected', event.emotion));
      
      // Return to ready state
      emit(NotificationReady());
    } catch (e) {
      print('Error handling rejected notification: $e');
      emit(NotificationReady());
    }
  }

  FutureOr<void> _onNotificationPostponed(
      NotificationPostponed event, Emitter<NotificationState> emit) async {
    try {
      print('Notification postponed for ${event.emotion}');
      
      // Cancel current notification
      await flutterLocalNotificationsPlugin.cancel(0);
      _activeNotification = null;

      // Update status
      add(UpdateTreatmentStatus(event.emotionId, 'pending', event.emotion));

      // Schedule to show notification again later
      await Future.delayed(const Duration(minutes: 30));
      print('Re-showing postponed notification after delay');
      add(ShowEmotionNotification(
          event.emotion, event.intensity, event.emotionId));
    } catch (e) {
      print('Error postponing notification: $e');
    }
  }

  Future<void> _showNotification(
      String emotion, String emotionId, double intensity) async {
    try {
      // Get Arabic emotion name
      String emotionArabic =
          _emotionNamesArabic[emotion.toLowerCase()] ?? 'مشاعر';

      // Get treatment text for this emotion
      String treatmentText = _emotionTreatments[emotion.toLowerCase()] ??
          'لدينا اقتراحات لمساعدتك مع مشاعرك الحالية.';

      // Create actions
      List<AndroidNotificationAction> actions = [
        const AndroidNotificationAction(
          'accept',
          'قبول',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'reject',
          'رفض',
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'later',
          'لاحقاً',
          cancelNotification: false,
        ),
      ];

      // Configure the notification details
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'emotion_channel',
        'Emotion Notifications',
        channelDescription: 'Notifications for detected emotions',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Emotion detected',
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        actions: actions,
      );

      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final payload = 'EMOTION|$emotion|$emotionId|$intensity';
      
      print('Showing notification with payload: $payload');
      
      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        0, // Use ID 0 for simplicity (we only show one emotion notification at a time)
        'تم اكتشاف مشاعر: $emotionArabic',
        'أنت تشعر بـ $emotionArabic... $treatmentText',
        platformChannelSpecifics,
        payload: payload,
      );
      
      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late NotificationBloc _notificationBloc;
  bool _isInitialized = false;

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
    );

    _notificationBloc.add(InitializeNotifications());
    _isInitialized = true;
    print('NotificationService initialized successfully');
  }

  NotificationBloc get bloc => _notificationBloc;
}

class TreatmentNavigator extends StatelessWidget {
  const TreatmentNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      bloc: NotificationService().bloc,
      listenWhen: (previous, current) => current is NavigateToTreatment,
      listener: (context, state) {
        // Only handle NavigateToTreatment states
        if (state is NavigateToTreatment) {
          print('TreatmentNavigator received NavigateToTreatment state: ${state.emotion}');
          // Route to appropriate treatment page based on emotion type
          _navigateToTreatment(context, state.emotion, state.emotionId, state.userTreatmentId);
        }
      },
      child: Container(), // This widget doesn't render anything visible
    );
  }

  void _navigateToTreatment(
      BuildContext context, String emotion, String emotionId, String userTreatmentId) {
    // Determine the route
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

      case 'fear':
      case 'anxiety':
      case 'anxious':
        route = '/deep-breathing';
        break;

      default:
        route = '/cbt-therapy';
        break;
    }
    
    // Build arguments
    final arguments = {
      'emotion': emotion,
      'emotionId': emotionId,
      'userTreatmentId': userTreatmentId,
    };
    
    print('Navigating to $route with args: $arguments');
    
    // Use Navigator.of(context).pushNamed instead of Navigator.pushNamed
    // to ensure we get the correct navigator
    Navigator.of(context).pushNamed(
      route,
      arguments: arguments,
    );
  }
}