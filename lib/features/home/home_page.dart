// ignore_for_file: non_constant_identifier_names

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/core/utils/theme/ThemedScaffold.dart';
import 'package:kawamen/core/utils/theme/theme.dart';
import 'package:kawamen/features/LogIn/view/login_view.dart';
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
      create: (context) {
        // initialize both the data fetch and stream subscription
        final bloc = HomeBloc();
        bloc.add(StartTreatmentStreamSubscription()); // Start real-time updates
        bloc.add(const FetchTreatmentHistory()); // Initial data load
        return bloc;
      },
      child: _HomePageContent(showBottomNav: showBottomNav),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  final bool showBottomNav;

  const _HomePageContent({required this.showBottomNav});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<HomeBloc>()
              .add(const FetchTreatmentHistory(forceRefresh: true));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refreshing treatment data...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: _HomeStateHandler(),
        ),
      ),
      bottomNavigationBar: showBottomNav ? const _BottomNavBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: Icon(Icons.menu, color: theme.colorScheme.onBackground),
      title: Text(
        'الرئيسية',
        style: theme.textTheme.headlineMedium,
      ),
      centerTitle: true,
    );
  }
}

// Extracted widget to handle state changes
class _HomeStateHandler extends StatelessWidget {
  const _HomeStateHandler();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is UsernNotAuthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
            (_) => false,
          );
        }
      },
      builder: (context, state) {
        if (state is LoadingHomeState) {
          return const LoadingScreen();
        } else if (state is ErrorHomeState) {
          return Center(child: Text(state.message));
        } else if (state is TreatmentHistoryLoaded) {
          return _MainContent(treatments: state.treatments);
        }
        return const _MainContent(treatments: []);
      },
    );
  }
}

// Extract the bottom navigation bar into a separate widget
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
      ],
    );
  }
}

// Main content extracted for better performance
class _MainContent extends StatelessWidget {
  final List<TreatmentData> treatments;

  const _MainContent({required this.treatments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool hasTreatments = treatments.isNotEmpty;

    return ListView.builder(
      itemCount: hasTreatments ? treatments.length + 4 : 5,
      itemBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 20);
        if (index == 1) return const _HeaderWidget();
        if (index == 2) {
          return Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "جلساتك",
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        }

        if (!hasTreatments && index == 3) {
          return const _SessionCard(
            label: '',
            title: "ليس لديك جلسات ",
            icon: Icons.self_improvement,
            isActive: true,
          );
        }

        if (index == (hasTreatments ? treatments.length + 3 : 4)) {
          return const SizedBox(height: 80);
        }

        // جلسات عادية
        return _SessionCard(treatment: treatments[index - 3]);
      },
    );
  }
}

// Header widget extracted for better performance
class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
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
    );
  }
}

// Separate widget for session cards
class _SessionCard extends StatelessWidget {
  final TreatmentData? treatment;
  final String? label;
  final String? title;
  final IconData? icon;
  final bool isActive;

  const _SessionCard({
    this.treatment,
    this.label,
    this.title,
    this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract variables once instead of accessing repeatedly
    final displayLabel = treatment?.emotion ?? label ?? '';
    final displayTitle = treatment?.treatmentId ?? title ?? '';
    final isOngoing = treatment != null && treatment!.progress < 100.0;
    final IconData displayIcon = _getDisplayIcon();

    var showProgress = treatment != null &&
        treatment!.progress > 0 &&
        treatment!.progress < 100;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconWidget(displayIcon, theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TitleWidget(displayTitle, theme),
                EmotionWidget(displayLabel, theme),
                if (showProgress) ProgressBar(theme),
              ],
            ),
          ),
          if (isOngoing) _ContinueButton(treatment: treatment),
        ],
      ),
    );
  }

  LinearProgressIndicator ProgressBar(ThemeData theme) {
    return LinearProgressIndicator(
      value: treatment!.progress / 100,
      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
    );
  }

  Text EmotionWidget(String displayLabel, ThemeData theme) {
    return Text(
      _getEmotionText(displayLabel),
      textAlign: TextAlign.right,
      style: theme.textTheme.bodyMedium,
    );
  }

  Text TitleWidget(String displayTitle, ThemeData theme) {
    return Text(
      _getTreatmentTitle(displayTitle),
      textAlign: TextAlign.right,
      style: theme.textTheme.bodyLarge,
    );
  }

  SizedBox IconWidget(IconData displayIcon, ThemeData theme) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Icon(displayIcon,
          color: treatment?.status == 'completed'
              ? Colors.greenAccent
              : theme.colorScheme.primary),
    );
  }

  IconData _getDisplayIcon() {
    if (treatment != null) {
      if (treatment!.status == 'completed') {
        return Icons.check_circle;
      } else if (treatment!.progress < 100.0) {
        return Icons.access_time;
      } else {
        // Choose icon based on treatment ID
        switch (treatment!.treatmentId) {
          case 'CBTtherapy':
            return Icons.sync_alt;
          case 'DeepBreathing':
            return Icons.self_improvement;
          default:
            return Icons.edit_note;
        }
      }
    } else {
      return icon ?? Icons.help_outline;
    }
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

// Continue button extracted as a separate widget
class _ContinueButton extends StatelessWidget {
  final TreatmentData? treatment;

  const _ContinueButton({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: () => _handleNavigation(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
      ),
    );
  }

  void _handleNavigation(BuildContext context) {
    if (treatment == null) return;

    final sessionId = treatment!.userTreatmentId;

    switch (treatment!.treatmentId) {
      case "CBTtherapy":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CBTTherapyPage(
              userTreatmentId: treatment!.userTreatmentId,
              treatmentId: treatment!.treatmentId,
            ),
          ),
        );
        break;
      case 'DeepBreathing':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeepBreathingPage(
              userTreatmentId: treatment!.userTreatmentId,
              treatmentId: treatment!.treatmentId,
            ),
          ),
        );
        break;
    }

    log("Session ID: $sessionId, Treatment: ${treatment!.treatmentId}, Emotion: ${treatment!.emotion}");
  }
}
