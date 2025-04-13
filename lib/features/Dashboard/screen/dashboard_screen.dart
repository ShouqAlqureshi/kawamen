import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/features/Dashboard/bloc/dashboard_bloc.dart';
import 'package:kawamen/features/Dashboard/repository/chart.dart';
import 'package:kawamen/features/Dashboard/repository/dashboardloadingscreen.dart';
import 'package:kawamen/features/Dashboard/repository/progress_bar.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/screen/CBT_therapy_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => DashboardBloc()..add(FetchDashboard()),
      child: Builder(
          builder: (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text(
                  "لوحة البيانات",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.right,
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Instead of simply popping, navigate to DeepBreathingPage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CBTTherapyPage(),
                      ),
                    );
                  },
                ),
              ),
              body: BlocConsumer<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardInitial) {
                    return buildDashboard(
                      context,
                      theme,
                    );
                    // return const DashboardLoadingScreen();
                  } else if (state is DashboardLoaded) {
                    return buildDashboard(
                      context,
                      theme,
                    );
                  } else if (state is DashboardLoading) {
                    return const LoadingScreen();
                    // return const Center(child: CircularProgressIndicator());
                  } else if (state is DashboardError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  return const SizedBox(width: 0);
                },
                listener: (context, state) {
                  if (state is DashboardError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
              ))),
    );
  }

  Widget buildDashboard(
    BuildContext context,
    ThemeData theme,
    // DashboardLoaded state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Stack(children: <Widget>[
        Column(
          children: [
            SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(
                    10), // Add padding around the progress bar
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 42, 24, 49), // Light
                      Color.fromARGB(255, 38, 23, 48), // Darker
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  border: Border.all(
                    color: Colors.transparent, // Border color
                    width: 2, // Border width
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1.23,
                  child: Stack(
                    children: <Widget>[
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 37,
                          ),
                          Text(
                            "المشاعر المكتشفه هاذا الاسبوع",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 37,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 16, left: 6),
                              child: EmotionalTrendGraph(
                                angerEmotionalData: {
                                  1: 3,
                                  2: 1,
                                  3: 0,
                                  4: 0,
                                  5: 2,
                                  6: 6,
                                  7: 8
                                },
                                sadEmotionalData: {
                                  1: 0,
                                  2: 4,
                                  3: 3,
                                  4: 2,
                                  5: 6,
                                  6: 1,
                                  7: 4
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white.withValues(alpha: 1.0),
                        ),
                        onPressed: () {
                          context.read<DashboardBloc>().add(FetchDashboard());
                        },
                      ),
                      // if (state.isEmpty)
                      //   Center(
                      //     child: Container(
                      //       padding: const EdgeInsets.all(16),
                      //       decoration: BoxDecoration(
                      //         color: Colors.black.withValues(alpha: .8),
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       child: const Text(
                      //         'There is no emotion detected for this week',
                      //         style: TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ),
            const TreatmentProgressTracker(
              progress: 0.8,
            ) //fetch progress (Completed treatments/ All treatment of this week)
          ],
        ),
      ]),
    );
  }
}
