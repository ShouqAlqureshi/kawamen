import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/app/app_view.dart';
import 'package:kawamen/core/navigation/app_routes.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/Profile/Bloc/profile_bloc.dart';
import 'package:kawamen/features/registration/bloc/auth_bloc.dart';
import 'package:kawamen/features/registration/repository/auth_repository.dart';
import 'package:kawamen/features/login/bloc/login_bloc.dart';

import '../../features/Treatment/bloc/emotion_bloc.dart';
import '../services/Notification_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final EmotionBloc _emotionBloc = EmotionBloc();

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
          create: (context) => AuthBloc(AuthRepository()),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(),
        ),
        BlocProvider(
            create: (context) =>
                ProfileBloc(context: context)..add(FetchToggleStates())),
        BlocProvider<EmotionBloc>.value(value: _emotionBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }

  @override
  void dispose() {
    _emotionBloc.close();
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
