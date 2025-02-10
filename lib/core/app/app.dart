import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/app/app_view.dart';
import 'package:kawamen/features/registration/bloc/auth_bloc.dart';
import 'package:kawamen/features/registration/repository/auth_repository.dart';
import 'package:kawamen/features/login/bloc/login_bloc.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(AuthRepository()),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(context),
        ),
      ],
      child: const AppView(), // Delegating UI decisions to AppView
    );
  }
}
