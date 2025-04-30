import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import 'package:kawamen/features/Dashboard/bloc/dashboard_bloc.dart';
import 'package:kawamen/features/Dashboard/bloc/treatmentsDashboard_bloc.dart';
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
  //for demo only
  final Map<int, int> angerEmotions = {
    1: 0,
    2: 2,
    3: 1,
    4: 0,
    5: 4,
    6: 1,
    7: 0
  };
  final Map<int, int> sadEmotions = {1: 1, 2: 1, 3: 3, 4: 0, 5: 4, 6: 2, 7: 1};
  @override
  void initState() {
    super.initState();
  }

  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardBloc()..add(FetchDashboard()),
        ),
        BlocProvider(
          create: (context) => TreatmentBloc()..add(FetchTreatmentData()),
        ),
      ],
      child: Builder(
          builder: (context) => ThemedScaffold(
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
                        Theme.of(context),
                        state,
                      );
                    } else if (state is DashboardError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyLarge,
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
                    } else if (state is DashboardPreviewReady) {
                      final bloc = context.read<DashboardBloc>();
                      // Show preview dialog
                      _showPreviewDialog(
                          context, state.imageBytes, bloc, Theme.of(context));
                    }
                  },
                ),
              )),
    );
  }

  Widget buildDashboard(
    BuildContext context,
    ThemeData theme,
    DashboardLoaded state,
  ) {
    return Padding(
      // Adjust padding - remove bottom padding when nav bar is present
      padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 00.0),
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            key: _boundaryKey,
            child: RefreshIndicator(
              onRefresh: () async {
                // Force refresh data
                context
                    .read<DashboardBloc>()
                    .add(FetchDashboard(forceRefresh: true));

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
                // Ensure content scrolls all the way to the bottom
                physics: const AlwaysScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Trigger the capture process
                            context
                                .read<DashboardBloc>()
                                .add(CaptureScreenshot(_boundaryKey));
                          },
                          icon: const Icon(
                            Icons.share,
                            color: Colors.greenAccent,
                          ),
                        ),
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
                    // No extra padding at the bottom
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, Uint8List imageBytes,
      DashboardBloc bloc, ThemeData theme) {
    bool _shareIsLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF241c2e),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'معاينة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    child: Image.memory(imageBytes),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor:
                              Theme.of(dialogContext).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.5),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          // Refresh dashboard after closing dialog
                          bloc.add(FetchDashboard());
                        },
                        child: Text(
                          'إلغاء', // Arabic for "Cancel"
                          style: Theme.of(dialogContext)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color:
                                    Theme.of(dialogContext).colorScheme.primary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(dialogContext).primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                _shareIsLoading = true;
                              });
                              try {
                                // Close the preview dialog first
                                Navigator.of(dialogContext).pop();

                                // Share the image bytes directly without re-capturing
                                bloc.add(ShareScreenshot(imageBytes));
                              } catch (e) {
                                log('Error sharing image: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to share image'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _shareIsLoading = false;
                                  });
                                }
                              }
                            },
                            child: _shareIsLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : Text(
                                    'شارك', // Arabic for "Share"
                                    style: Theme.of(dialogContext)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
