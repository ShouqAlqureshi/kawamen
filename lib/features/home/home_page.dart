import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/screen/CBT_therapy_page.dart';
import 'package:kawamen/features/Treatment/deep_breathing/screen/deep_breathing_page.dart';
import 'package:kawamen/features/home/bloc/home_state.dart';
import '../../core/services/Notification_service.dart';
import 'bloc/home_bloc.dart';

class HomePage extends StatelessWidget {
  final bool showBottomNav;

  const HomePage({super.key, this.showBottomNav = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(FetchTreatmentHistory()),
      child: _HomePageContent(showBottomNav: showBottomNav),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  final bool showBottomNav;

  const _HomePageContent({required this.showBottomNav});

  @override
  Widget build(BuildContext context) {
    // Access the theme from the context
    final theme = Theme.of(context);

    return ThemedScaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: Icon(Icons.menu, color: theme.colorScheme.onBackground),
        title: Text(
          'الرئيسية',
          style: theme.textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      //  refresh scroll to force refresh from network
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<HomeBloc>()
              .add(const FetchTreatmentHistory(forceRefresh: true));
          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refreshing treatment data...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is LoadingHomeState) {
                return const LoadingScreen();
              } else if (state is ErrorHomeState) {
                return Center(child: Text(state.message));
              } else if (state is TreatmentHistoryLoaded) {
                return _buildMainContent(context, state.treatments);
              }
              return _buildMainContent(context, []);
            },
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              backgroundColor: theme.colorScheme.surface,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.mic), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
              ],
            )
          : null,
    );
  }

  Widget _buildMainContent(
      BuildContext context, List<TreatmentData> treatments) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        const SizedBox(height: 20),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ ',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                height: 1.8,
              ),
              children: [
                TextSpan(
                  text: 'القلوب',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Icon(Icons.auto_awesome,
            color: theme.colorScheme.primary.withOpacity(0.8)),
        const SizedBox(height: 30),
        Text(
          "جلساتك",
          textAlign: TextAlign.right,
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 10),
        ...treatments.map((treatment) => _buildSessionCard(
              context: context,
              treatment: treatment,
            )),
        // Add a placeholder card if no treatments are available
        if (treatments.isEmpty)
          _buildSessionCard(
            context: context,
            label: '',
            title: "ليس لديك جلسات ",
            icon: Icons.self_improvement,
            isActive: true,
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSessionCard({
    required BuildContext context,
    TreatmentData? treatment,
    String? label,
    String? title,
    IconData? icon,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);

    // If treatment is provided, use its data; otherwise, use the provided parameters
    final displayLabel = treatment?.emotion ?? label ?? '';
    final displayTitle = treatment?.treatmentId ?? title ?? '';
    final isOngoing = treatment != null && treatment.progress < 100.0;

    // Choose icon based on status
    IconData displayIcon;
    if (treatment != null) {
      if (treatment.status == 'completed') {
        displayIcon = Icons.check_circle;
      } else if (isOngoing) {
        displayIcon = Icons.access_time;
      } else {
        // Choose icon based on treatment ID
        switch (treatment.treatmentId) {
          case 'CBTtherapy':
            displayIcon = Icons.sync_alt;
            break;
          case 'DeepBreathing':
            displayIcon = Icons.self_improvement;
            break;
          default:
            displayIcon = Icons.edit_note;
        }
      }
    } else {
      displayIcon = icon ?? Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(displayIcon,
              color: treatment?.status == 'completed'
                  ? Colors.greenAccent
                  : theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getTreatmentTitle(displayTitle),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  _getEmotionText(displayLabel),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium,
                ),
                if (treatment != null &&
                    treatment.progress > 0 &&
                    treatment.progress < 100)
                  LinearProgressIndicator(
                    value: treatment.progress / 100,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary),
                  ),
              ],
            ),
          ),
          if (isOngoing)
            Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    if (treatment != null) {
                      final sessionId = treatment.userTreatmentId;
                      // In HomePage._buildSessionCard method
                      if (treatment.treatmentId == "CBTtherapy") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CBTTherapyPage(
                              userTreatmentId: treatment.userTreatmentId,
                              treatmentId: treatment.treatmentId,
                            ),
                          ),
                        );
                      } else if (treatment.treatmentId == 'DeepBreathing') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeepBreathingPage(
                              userTreatmentId: treatment.userTreatmentId,
                              treatmentId: treatment.treatmentId,
                            ),
                          ),
                        );
                      }
                      log("Session ID: $sessionId, Treatment: ${treatment.treatmentId}, Emotion: ${treatment.emotion}");
                    }
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'استئناف',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // Helper method to get a proper treatment title based on treatment ID
  String _getTreatmentTitle(String treatmentId) {
    switch (treatmentId) {
      case 'CBTtherapy':
        return 'إعادة التركيز وتحدي الأفكار السلبية';
      case 'DeepBreathing':
        return 'التنفس العميق والاسترخاء العضلي';
      default:
        return treatmentId;
    }
  }

  // Helper method to translate emotion types
  String _getEmotionText(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'sad':
        return 'الحزن';
      case 'anxiety':
        return 'القلق';
      case 'angry':
        return 'الغضب';
      case 'fear':
        return 'الخوف';
      default:
        return emotion;
    }
  }
}
