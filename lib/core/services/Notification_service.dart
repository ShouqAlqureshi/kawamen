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

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging firebaseMessaging;

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
        final userTreatmentId = await _createTreatmentDocument(emotion, event.status);
        
        // Update the emotion document with a reference to the treatment
        await emotionDocRef.update({
          'userTreatmentId': userTreatmentId,
          // We don't need treatmentStatus here anymore, as it will be in the treatment document
        });
        
        emit(TreatmentStatusUpdated(event.emotionId, event.status, userTreatmentId: userTreatmentId));
        
        // If accepted, we'll want to navigate to the treatment
        if (event.status == 'accepted') {
          emit(NavigateToTreatment(emotion, event.emotionId, userTreatmentId));
        }
      }
    } catch (e) {
      print('Error updating treatment status: $e');
    }
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
              switch (response.actionId) {
                case 'accept':
                  add(NotificationAccepted(emotion, emotionId));
                  break;
                case 'reject':
                  add(NotificationRejected());
                  break;
                case 'later':
                  add(NotificationPostponed(emotion, emotionId, intensity));
                  break;
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
  }

  Future<void> checkNotificationPermissions() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  FutureOr<void> _onNotificationAccepted(
      NotificationAccepted event, Emitter<NotificationState> emit) {
    flutterLocalNotificationsPlugin.cancel(0);

    add(UpdateTreatmentStatus(event.emotionId, 'accepted'));
  }

  FutureOr<void> _onNotificationRejected(
      NotificationRejected event, Emitter<NotificationState> emit) {
    if (state is NotificationShowing) {
      final currentState = state as NotificationShowing;
      add(UpdateTreatmentStatus(currentState.emotionId, 'rejected'));
    }

    flutterLocalNotificationsPlugin.cancel(0);
    emit(NotificationReady());
  }

  FutureOr<void> _onNotificationPostponed(
      NotificationPostponed event, Emitter<NotificationState> emit) async {
    flutterLocalNotificationsPlugin.cancel(0);

    add(UpdateTreatmentStatus(event.emotionId, 'pending'));

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
  }

  void _showNotification(String emotion, String emotionId) {
    print('Showing notification for emotion: $emotion');
  }

  void _onNotificationAccepted(String emotion, String emotionId) {
    print('Notification accepted for emotion: $emotion');
  }

  NotificationBloc get bloc => _notificationBloc;
}

class TreatmentNavigator extends StatelessWidget {
  const TreatmentNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      bloc: NotificationService().bloc,
      listener: (context, state) {
        // Handle navigation to treatment page when notification is accepted
        if (state is NavigateToTreatment) {
          // Route to appropriate treatment page based on emotion type
          _navigateToTreatment(context, state.emotion, state.emotionId, state.userTreatmentId);
        }
      },
      child: Container(), // This widget doesn't render anything visible
    );
  }

  void _navigateToTreatment(
      BuildContext context, String emotion, String emotionId, String userTreatmentId) {
    // Map emotions to specific treatment pages
    switch (emotion.toLowerCase()) {
      case 'sadness':
      case 'sad':
        Navigator.pushNamed(
          context,
          '/cbt-therapy',
          arguments: {
            'emotion': emotion,
            'emotionId': emotionId,
            'userTreatmentId': userTreatmentId, // Pass the treatment ID
          },
        );
        break;

      case 'anger':
      case 'angry':
        Navigator.pushNamed(
          context,
          '/deep-breathing',
          arguments: {
            'emotion': emotion,
            'emotionId': emotionId,
            'userTreatmentId': userTreatmentId, // Pass the treatment ID
          },
        );
        break;

      // Add additional cases for other emotions you might handle
      case 'fear':
      case 'anxiety':
      case 'anxious':
        Navigator.pushNamed(
          context,
          '/deep-breathing',
          arguments: {
            'emotion': emotion,
            'emotionId': emotionId,
            'userTreatmentId': userTreatmentId, // Pass the treatment ID
          },
        );
        break;

      default:
        Navigator.pushNamed(
          context,
          '/cbt-therapy',
          arguments: {
            'emotion': emotion,
            'emotionId': emotionId,
            'userTreatmentId': userTreatmentId, // Pass the treatment ID
          },
        );
        break;
    }
  }
}