import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/core/services/cache_service.dart';
import 'package:kawamen/core/services/testNotification_interface.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/LogIn/view/login_page.dart';
import 'package:kawamen/features/Profile/Bloc/microphone_bloc.dart';
import 'package:kawamen/features/Profile/Bloc/profile_bloc.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/screen/CBT_therapy_page.dart';
import 'package:kawamen/features/Treatment/deep_breathing/screen/deep_breathing_page.dart';
import 'package:kawamen/features/emotion_detection/Bloc/emotion_detection_bloc.dart';
import 'package:kawamen/features/emotion_detection/Bloc/emotion_detection_state.dart';
import 'package:kawamen/features/emotion_detection/repository/emotion_detection_repository.dart';
import 'package:kawamen/features/emotion_detection/service/audio_recorder_service.dart';
import 'package:kawamen/features/home/screen/home_page.dart';
import 'package:kawamen/features/registration/bloc/auth_bloc.dart';
import 'package:kawamen/features/registration/bloc/auth_event.dart';
import 'package:kawamen/features/registration/bloc/auth_state.dart';
import 'package:kawamen/features/registration/repository/auth_repository.dart';
import 'package:kawamen/features/login/bloc/login_bloc.dart';
import '../navigation/MainNavigator.dart';
import '../services/Notification_service.dart';
import 'package:kawamen/features/emotion_detection/screens/performance_metrics_screen.dart'; // Ensure this is the correct path

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  // Remove the EmotionBloc instance
  final EmotionDetectionBloc _emotionDetectionBloc = EmotionDetectionBloc(
    repository: EmotionDetectionRepository(),
    recorderService: AudioRecorderService(),
  );
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final UserCacheService _userCache = UserCacheService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Remove the connectToEmotionBloc call
    // Initialize notification service - must be done to accept notifications
    NotificationService().initialize();
    _initializeUser();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(AuthRepository())..add(CheckAuthStatus()),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(),
        ),
        BlocProvider(
          create: (context) {
            final profileBloc = ProfileBloc(context: context);
            profileBloc.add(FetchToggleStates());
            return profileBloc;
          },
        ),
        // Remove the EmotionBloc provider
        BlocProvider<EmotionDetectionBloc>.value(value: _emotionDetectionBloc),
        BlocProvider(
          create: (context) => MicrophoneBloc(),
        ),
      ],
      child: BlocListener<EmotionDetectionBloc, EmotionDetectionState>(
        listener: (context, state) {
          // When detection stops or completes, update the toggle
          if (state is DetectionStopped ||
              state is DetectionSuccess ||
              state is DetectionFailure) {
            context.read<ProfileBloc>().add(
                  UpdateToggleState(
                    toggleName: 'emotionDetectionToggle',
                    newValue: false,
                  ),
                );
          }
        },
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRoutes.generateRoute,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return const MainNavigator();
              } else {
                return const LoginPage();
              }
            },
          ),
          navigatorKey: NotificationService().getNavigatorKey,
          routes: {
            '/deep-breathing': (context) => const DeepBreathingPage(),
            '/cbt-therapy': (context) => const CBTTherapyPage(),
            '/performance-metrics': (context) => PerformanceMetricsScreen(),
            // other routes...
          },
        ),
      ),
    );
  }

  Future<void> _initializeUser() async {
    if (currentUserId != null) {
      await _userCache.initializeUser(currentUserId!);
    }
  }

  @override
  void dispose() {
    // Remove the _emotionBloc.close() call
    _emotionDetectionBloc.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, check for pending notifications
    }
  }
}
