import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/features/Dashboard/bloc/dashboard_bloc.dart';
import 'package:kawamen/features/Dashboard/bloc/treatments_boxes_bloc.dart';
import 'package:kawamen/features/Dashboard/repository/chart.dart';
import 'package:kawamen/features/Dashboard/screen/treatment_progress_screen.dart';
import 'package:kawamen/features/Dashboard/screen/treatment_boxes_screen.dart';
import 'package:kawamen/features/LogIn/view/login_view.dart';

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

  final GlobalKey _boundaryKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => DashboardBloc()..add(FetchDashboard()),
      child: Builder(
          builder: (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                centerTitle: true,
                title: Text(
                  "لوحة البيانات",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              body: BlocConsumer<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardInitial ||
                      state is DashboardLoading ||
                      state is DashboardExporting) {
                    return const LoadingScreen();
                  } else if (state is DashboardLoaded) {
                    return buildDashboard(
                      context,
                      theme,
                      state,
                    );
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
                  } else if (state is DashboardExported) {
                    context.read<DashboardBloc>().add(FetchDashboard());
                  } else if (state is UsernNotAuthenticated) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginView()),
                        (_) => false);
                  }
                },
              ))),
    );
  }

  Widget buildDashboard(
    BuildContext context,
    ThemeData theme,
    DashboardLoaded state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            key: _boundaryKey,
            child: RefreshIndicator(
              onRefresh: () async {
                // Force refresh data
                context.read<DashboardBloc>().add(FetchDashboard(forceRefresh: true));
                
                // Show a snackbar to inform the user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing dashboard data...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Wait a moment to simulate network request
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: Colors.greenAccent,
              backgroundColor: const Color(0xFF2B2B2B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              context
                                  .read<DashboardBloc>()
                                  .add(ExportDashboard(_boundaryKey));
                            },
                            icon: const Icon(
                              Icons.share,
                              color: Colors.greenAccent,
                            )),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Treatment stats container
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2B2B2B),
                            Color.fromARGB(255, 24, 24, 24)
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.transparent, width: 2),
                      ),
                      child: const TreatmentStatsBoxes(),
                    ),
                    const SizedBox(height: 20),
                    // Emotional trend container
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2B2B2B),
                            Color.fromARGB(255, 24, 24, 24),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.23,
                        child: Stack(
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const SizedBox(height: 37),
                                const Text(
                                  "المشاعر المكتشفه هاذا الاسبوع",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 37),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 16, left: 6),
                                    child: EmotionalTrendGraph(
                                      angerEmotionalData:
                                          state.angerEmotionalData,
                                      sadEmotionalData: state.sadEmotionalData,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                            if (state.isEmpty)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'ليس لديك مشاعر مكتشفه لهاذا الاسبوع',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress tracker container - now full width
                    Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2B2B2B),
                            Color.fromARGB(255, 24, 24, 24),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const TreatmentProgressTracker(),
                    ),
                    // Add extra padding at the bottom to ensure pull-to-refresh works well
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}