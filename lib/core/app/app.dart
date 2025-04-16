import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/app/app_view.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/LogIn/view/login_page.dart';
import 'package:kawamen/features/Profile/Bloc/profile_bloc.dart';
import 'package:kawamen/features/emotion_detection/Bloc/emotion_detection_bloc.dart';
import 'package:kawamen/features/emotion_detection/repository/emotion_detection_repository.dart';
import 'package:kawamen/features/emotion_detection/service/audio_recorder_service.dart';
import 'package:kawamen/features/registration/bloc/auth_bloc.dart';
import 'package:kawamen/features/registration/bloc/auth_event.dart';
import 'package:kawamen/features/registration/bloc/auth_state.dart';
import 'package:kawamen/features/registration/repository/auth_repository.dart';
import 'package:kawamen/features/login/bloc/login_bloc.dart';
import '../../features/Treatment/bloc/emotion_bloc.dart';
import '../navigation/MainNavigator.dart';
import '../services/Notification_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final EmotionBloc _emotionBloc = EmotionBloc();
  final EmotionDetectionBloc _emotionDetectionBloc = EmotionDetectionBloc(
      repository: EmotionDetectionRepository(),
      recorderService: AudioRecorderService());
      
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().connectToEmotionBloc(_emotionBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(AuthRepository())..add(CheckAuthStatus()),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(),
        ),
        BlocProvider(
            create: (context) =>
                ProfileBloc(context: context)..add(FetchToggleStates())),
        BlocProvider<EmotionBloc>.value(value: _emotionBloc),
        BlocProvider<EmotionDetectionBloc>.value(value: _emotionDetectionBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRoutes.generateRoute,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              return const MainNavigator();
            } else {
              // Assuming you have a login screen route
              return const LoginPage(); // Replace with your actual login screen
            }
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emotionBloc.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _emotionDetectionBloc.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, check for pending notifications
    }
  }
}
