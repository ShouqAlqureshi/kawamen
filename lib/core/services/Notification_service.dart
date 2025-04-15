import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kawamen/features/Treatment/bloc/emotion_bloc.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
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

  const NavigateToTreatment(this.emotion, this.emotionId);

  @override
  List<Object> get props => [emotion, emotionId];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging firebaseMessaging;
  
  final Map<String, String> _emotionTreatments = {
    'anger': 'جرب تمارين التنفس العميق للتهدئة.',
  'disgust': 'مارس اليقظة الذهنية لمعالجة مشاعرك.',
  'fear': 'استخدم تقنيات التأريض للشعور بالأمان.',
  'happiness': 'شارك فرحتك مع شخص مقرب منك.',
  'neutral': 'ما رأيك بممارسة تمرين اليقظة الذهنية؟',
  'sadness': 'تواصل مع شخص تثق به أو مارس الرحمة الذاتية.',
  'surprise': 'خذ لحظة لمعالجة ما حدث.',
    
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
    
  }
  Future<bool> _requestNotificationPermissions() async {
  final settings = await firebaseMessaging.requestPermission();
  return settings.authorizationStatus == AuthorizationStatus.authorized;
}


  FutureOr<void> _onInitializeNotifications(
      InitializeNotifications event, Emitter<NotificationState> emit) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
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
            final intensity = parts.length >= 4 ? double.tryParse(parts[3]) ?? 0.0 : 0.0;
            
            switch (action) {
              case 'ACCEPT':
                add(NotificationAccepted(emotion, emotionId));
                break;
              case 'REJECT':
                add(NotificationRejected());
                break;
              case 'LATER':
                add(NotificationPostponed(emotion, emotionId, intensity));
                break;
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

  FutureOr<void> _onNotificationAccepted(
      NotificationAccepted event, Emitter<NotificationState> emit) {
    flutterLocalNotificationsPlugin.cancel(0);
    
    // navigate state to move to treatment page
    emit(NavigateToTreatment(event.emotion, event.emotionId));
  }

  FutureOr<void> _onNotificationRejected(
      NotificationRejected event, Emitter<NotificationState> emit) {
    flutterLocalNotificationsPlugin.cancel(0);
    emit(NotificationReady());
  }

  FutureOr<void> _onNotificationPostponed(
      NotificationPostponed event, Emitter<NotificationState> emit) async {
    flutterLocalNotificationsPlugin.cancel(0);
    
    await Future.delayed(const Duration(minutes: 30));
    add(ShowEmotionNotification(event.emotion, event.intensity, event.emotionId));
  }

  Future<void> _showNotification(String emotion, String emotionId, double intensity) async {
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
      'تم اكتشاف مشاعر:${emotion.toUpperCase()}',
      'أنت تشعر بـ $emotion... $treatmentText',
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

  void connectToEmotionBloc(EmotionBloc emotionBloc) {
    emotionBloc.stream.listen((state) {
      if (state is EmotionProcessed) {
        final latestEmotion = emotionBloc.historyQueue.queue.isNotEmpty 
            ? emotionBloc.historyQueue.queue.last
            : null;
        
        final emotionId = latestEmotion?['emotionId'] as String? ?? 
                          DateTime.now().millisecondsSinceEpoch.toString();
        
        _notificationBloc.add(ShowEmotionNotification(
          state.emotion,
          state.intensity,
          emotionId,
        ));
      }
    });
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
          _navigateToTreatment(context, state.emotion, state.emotionId);
        }
      },
      child: Container(), // This widget doesn't render anything visible
    );
  }

  void _navigateToTreatment(BuildContext context, String emotion, String emotionId) {
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
          },
        );
        break;
    }
  }
}