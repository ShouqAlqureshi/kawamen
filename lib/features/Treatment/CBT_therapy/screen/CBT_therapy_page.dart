import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawamen/core/navigation/MainNavigator.dart';
import 'package:kawamen/core/utils/Loadingscreen.dart';
import 'package:kawamen/features/Profile/Screens/view_profile_screen.dart';
import 'dart:math';
import 'package:kawamen/features/Treatment/CBT_therapy/bloc/CBT_therapy_bloc.dart';

class CBTTherapyPage extends StatelessWidget {
  final String? userTreatmentId;
  final String? treatmentId;
  const CBTTherapyPage(
      {Key? key, this.userTreatmentId, this.treatmentId = 'CBTtherapy'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract parameters from route arguments if they exist
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Use route arguments if available, otherwise use constructor parameters
    final String? routeTreatmentId = args?['treatmentId'] as String?;
    final String? routeUserTreatmentId = args?['userTreatmentId'] as String?;

    // Print debug information
    print(
        'CBTTherapyPage BUILD - Constructor userTreatmentId: $userTreatmentId');
    print(
        'CBTTherapyPage BUILD - Route userTreatmentId: $routeUserTreatmentId');

    // Prioritize route parameters over constructor parameters
    final String? effectiveTreatmentId = routeTreatmentId ?? treatmentId;
    final String? effectiveUserTreatmentId =
        routeUserTreatmentId ?? userTreatmentId;

    print(
        'CBTTherapyPage BUILD - Effective userTreatmentId: $effectiveUserTreatmentId');

    return BlocProvider(
      create: (_) {
        final bloc = CBTTherapyBloc();

        // If we have a user treatment ID, load it immediately
        if (effectiveUserTreatmentId != null &&
            effectiveUserTreatmentId.isNotEmpty) {
          print(
              'CBTTherapyPage - Loading existing treatment: $effectiveUserTreatmentId');
          bloc.add(LoadUserCBTTreatmentEvent(
            userTreatmentId: effectiveUserTreatmentId,
            treatmentId: effectiveTreatmentId ?? 'CBTtherapy',
          ));
        } else {
          // Otherwise just load the treatment data
          print(
              'CBTTherapyPage - No userTreatmentId, loading template data only');
          bloc.add(LoadCBTDataEvent(
              treatmentId: effectiveTreatmentId ?? 'CBTtherapy'));
        }

        return bloc;
      },
      child: _CBTTherapyView(
        userTreatmentId: effectiveUserTreatmentId,
        treatmentId: effectiveTreatmentId,
      ),
    );
  }
}

class _CBTTherapyView extends StatefulWidget {
  final String? userTreatmentId;
  final String? treatmentId;

  const _CBTTherapyView({this.userTreatmentId, this.treatmentId});

  @override
  State<_CBTTherapyView> createState() => _CBTTherapyViewState();
}

class _CBTTherapyViewState extends State<_CBTTherapyView>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;
  final TextEditingController _supportingEvidenceController =
      TextEditingController();
  final TextEditingController _contradictingEvidenceController =
      TextEditingController();
  final TextEditingController _thoughtController = TextEditingController();
  final TextEditingController _alternativeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing treatment or new treatment
    if (widget.userTreatmentId != null && widget.treatmentId != null) {
      // Load existing treatment
      context.read<CBTTherapyBloc>().add(
            LoadUserCBTTreatmentEvent(
              userTreatmentId: widget.userTreatmentId!,
              treatmentId: widget.treatmentId!,
            ),
          );
    } else {
      // Load new treatment
      context.read<CBTTherapyBloc>().add(
            const LoadCBTDataEvent(treatmentId: 'CBTtherapy'),
          );
    }
    // Initialize pulse animation controller (for the thought bubble)
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize glow animation controller
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize congratulations popup animation controllers
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );
    // Add listeners to the text controllers to trigger validation on text changes
    _thoughtController.addListener(() {
      setState(() {}); // This will rebuild the UI to show/hide error messages
    });

    _alternativeController.addListener(() {
      setState(() {}); // This will rebuild the UI to show/hide error messages
    });
    _supportingEvidenceController.addListener(() {
      setState(() {}); // This will rebuild the UI when text changes
    });

    _contradictingEvidenceController.addListener(() {
      setState(() {}); // This will rebuild the UI when text changes
    });
    // Start the continuous animations
    _pulseAnimationController.repeat(reverse: true);
    _glowAnimationController.repeat(reverse: true);
    context
        .read<CBTTherapyBloc>()
        .add(const LoadCBTDataEvent(treatmentId: 'CBTtherapy'));
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _glowAnimationController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    _thoughtController.dispose();
    _alternativeController.dispose();
    _supportingEvidenceController.dispose();
    _contradictingEvidenceController.dispose();
    super.dispose();
  }

  bool _validateInput(String text) {
    // Check if the text is empty or only contains whitespace
    return text.trim().isNotEmpty;
  }

  // Update animations based on the current state
  void _updateAnimations(CBTTherapyState state) {
    if (!state.isPlaying) {
      // Pause animations when exercise is paused
      _pulseAnimationController.stop();
      _glowAnimationController.stop();
    } else {
      // Resume animations when exercise is playing
      _pulseAnimationController.repeat(reverse: true);
      _glowAnimationController.repeat(reverse: true);
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Hide keyboard method
  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _updateTextControllers(CBTTherapyState state) {
    // Only update if text is not empty to avoid overwriting user edits
    if (state.userThought.isNotEmpty &&
        _thoughtController.text != state.userThought) {
      _thoughtController.text = state.userThought;
    }

    if (state.alternativeThought.isNotEmpty &&
        _alternativeController.text != state.alternativeThought) {
      _alternativeController.text = state.alternativeThought;
    }

    if (state.supportingEvidence.isNotEmpty &&
        _supportingEvidenceController.text != state.supportingEvidence) {
      _supportingEvidenceController.text = state.supportingEvidence;
    }

    if (state.contradictingEvidence.isNotEmpty &&
        _contradictingEvidenceController.text != state.contradictingEvidence) {
      _contradictingEvidenceController.text = state.contradictingEvidence;
    }
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final bloc = context.read<CBTTherapyBloc>();

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'هل أنت متأكد؟',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'إذا غادرت الآن، ستفقد التقدم في جلسة العلاج الحالية.',
                  textAlign: TextAlign.right,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false); // Don't exit
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                    child: const Text('البقاء'),
                  ),
                  FilledButton(
                    onPressed: () {
                      // IMPORTANT FIX: Save progress before exiting, by using PauseCBTTreatmentEvent
                      // This event will handle the database update
                      bloc.add(const PauseCBTTreatmentEvent());

                      // Add a small delay to ensure database operation completes
                      Future.delayed(const Duration(milliseconds: 100), () {
                        Navigator.of(dialogContext).pop(true); // Confirm exit
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('مغادرة'),
                  ),
                ],
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
          },
        ) ??
        false; // Default to false (don't exit) if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CBTTherapyBloc, CBTTherapyState>(
      listener: (context, state) {
        // Update animations based on state
        _updateAnimations(state);

        // Show completion popup when exercise is completed
        if (state.isCompleting) {
          _showCongratulationsPopup(context);
        }
        _updateTextControllers(state);
      },
      builder: (context, state) {
        // Get theme colors from context
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return WillPopScope(
          onWillPop: () async {
            // Show confirmation dialog if the session is active
            if (state.isPlaying) {
              bool shouldPop = await _showExitConfirmationDialog(context);
              return shouldPop;
            }
            // If not playing, allow normal back navigation
            return true;
          },
          child: GestureDetector(
            // Add this GestureDetector to dismiss keyboard when tapping outside
            onTap: _hideKeyboard,
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Stack(
                children: [
                  // Background animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary
                                    .withOpacity(_glowAnimation.value * 0.6),
                                colorScheme.primary
                                    .withOpacity(_glowAnimation.value * 0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary
                                    .withOpacity(_glowAnimation.value * 0.3),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Main UI content
                  Opacity(
                    opacity: 0.95,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Scaffold(
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          title: LayoutBuilder(builder: (context, constraints) {
                            final screenWidth =
                                MediaQuery.of(context).size.width;
                            return Text(
                              screenWidth < 320
                                  ? 'العلاج المعرفي السلوكي'
                                  : 'جلسة العلاج المعرفي السلوكي',
                              style: TextStyle(
                                color: theme.colorScheme.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    screenWidth < 360 ? 18 : screenWidth * 0.05,
                              ),
                              textDirection: TextDirection.rtl,
                            );
                          }),
                          centerTitle: true,
                        ),
                        backgroundColor: Colors.transparent,
                        body: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.psychology_rounded,
                                  color: colorScheme.primary,
                                  size: 70,
                                ),
                                const SizedBox(height: 20),

                                // Step counter
                                Text(
                                  '${state.currentStep} / ${state.totalSteps}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.7),
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Instruction text with fixed height container
                                Container(
                                  height: 60,
                                  alignment: Alignment.center,
                                  child: state.isLoading
                                      ? const LoadingScreen()
                                      : AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          opacity: state.instructionOpacity,
                                          child: state.instructions.isEmpty
                                              ? const Text(
                                                  "لا توجد تعليمات متاحة",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                )
                                              : Text(
                                                  state.instructions[state
                                                      .currentInstructionIndex],
                                                  style: TextStyle(
                                                    color: theme.colorScheme
                                                        .onBackground,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                        ),
                                ),

                                const SizedBox(height: 20),

                                // Content based on current step
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: _buildCurrentStepContent(
                                      context, state, colorScheme),
                                ),

                                const SizedBox(height: 30),

                                // Next/Prev Button Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Back button (only show when not on first step)
                                    if (state.currentStep > 1)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16.0),
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            _hideKeyboard(); // Hide keyboard when navigating
                                            context
                                                .read<CBTTherapyBloc>()
                                                .add(PreviousCBTStepEvent());
                                          },
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('السابق'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                colorScheme.primary,
                                            side: BorderSide(
                                                color: colorScheme.primary),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Next/Check Button (now using FilledButton instead of OutlinedButton)
                                    FilledButton.icon(
                                      onPressed: () {
                                        _hideKeyboard(); // Hide keyboard when pressing next
                                        if (!state.isPlaying) {
                                          context
                                              .read<CBTTherapyBloc>()
                                              .add(StartCBTExerciseEvent());
                                        } else if (state.currentStep ==
                                            state.totalSteps) {
                                          // If on the last step, complete the exercise
                                          context
                                              .read<CBTTherapyBloc>()
                                              .add(CompleteCBTExerciseEvent());
                                        } else {
                                          // For step 1, validate the negative thought input
                                          if (state.currentStep == 1 &&
                                              !_validateInput(
                                                  _thoughtController.text)) {
                                            // Show a snackbar or toast message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'الرجاء إدخال فكرتك قبل المتابعة',
                                                    textDirection:
                                                        TextDirection.rtl),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return; // Don't proceed if validation fails
                                          }

                                          // For step 3, validate both evidence fields
                                          if (state.currentStep == 3 &&
                                              (!_validateInput(
                                                      _supportingEvidenceController
                                                          .text) ||
                                                  !_validateInput(
                                                      _contradictingEvidenceController
                                                          .text))) {
                                            // Show a snackbar or toast message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'الرجاء إدخال الأدلة في كلا الحقلين قبل المتابعة',
                                                    textDirection:
                                                        TextDirection.rtl),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return; // Don't proceed if validation fails
                                          }

                                          // For step 4, validate the alternative thought input
                                          if (state.currentStep == 4 &&
                                              !_validateInput(
                                                  _alternativeController
                                                      .text)) {
                                            // Show a snackbar or toast message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'الرجاء إدخال الفكرة البديلة قبل المتابعة',
                                                    textDirection:
                                                        TextDirection.rtl),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return; // Don't proceed if validation fails
                                          }

                                          // Otherwise, move to the next step
                                          context
                                              .read<CBTTherapyBloc>()
                                              .add(NextCBTStepEvent(
                                                userThought:
                                                    _thoughtController.text,
                                                alternativeThought:
                                                    _alternativeController.text,
                                                // Add supporting and contradicting evidence
                                                supportingEvidence:
                                                    _supportingEvidenceController
                                                        .text,
                                                contradictingEvidence:
                                                    _contradictingEvidenceController
                                                        .text,
                                              ));
                                        }
                                      },
                                      icon: Icon(
                                        !state.isPlaying
                                            ? Icons.play_arrow
                                            : (state.currentStep ==
                                                    state.totalSteps
                                                ? Icons.check
                                                : Icons.arrow_forward),
                                      ),
                                      label: Text(
                                        !state.isPlaying
                                            ? 'البدء'
                                            : (state.currentStep ==
                                                    state.totalSteps
                                                ? 'إنهاء'
                                                : 'التالي'),
                                      ),
                                      style: FilledButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    )
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Build the current step's specific content
  Widget _buildCurrentStepContent(
      BuildContext context, CBTTherapyState state, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    // If not playing, show start screen
    if (!state.isPlaying) {
      return Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'اضغط على زر البدء للشروع في جلسة العلاج المعرفي السلوكي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }
    // Otherwise, show step-specific content
    switch (state.currentStep) {
      case 1: // Identify negative thought
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4EE6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'فكر في الموقف، ثم اكتب الأفكار السلبية التي راودتك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _thoughtController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب فكرتك السلبية هنا...',
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                // Add error text that appears when validation fails
                errorText: _thoughtController.text.isEmpty
                    ? null
                    : _validateInput(_thoughtController.text)
                        ? null
                        : 'لا يمكن أن يكون الحقل فارغًا',
              ),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              // Enable Arabic text input explicitly
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ],
        );

      case 2: // Identify thought distortions
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فكرتك: "${state.userThought}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 15),
              Text(
                'ما نوع التشويه المعرفي في هذه الفكرة؟',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF4CAF50),
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),
              _buildDistortionCheckboxes(context, state),
            ],
          ),
        );

      case 3: // Challenge the thought
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                    onPressed: () {
                      // Hide keyboard when showing the dialog
                      _hideKeyboard();
                      // Show info dialog explaining step 3
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: const Text(
                                'تحدي الأفكار',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'في هذه الخطوة، نقوم بتحليل الفكرة السلبية من خلال جمع الأدلة:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      '• في عمود "مع": اكتب الأدلة التي تؤيد الفكرة السلبية',
                                      textAlign: TextAlign.right,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      '• في عمود "ضد": اكتب الأدلة التي تعارض الفكرة السلبية',
                                      textAlign: TextAlign.right,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'هذه الخطوة تساعدك على النظر بموضوعية إلى أفكارك وتقييم مدى دقتها بناءً على الأدلة الفعلية.',
                                      textAlign: TextAlign.right,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'اسأل نفسك: "هل هناك طريقة أخرى للنظر إلى هذا الموقف؟" و "ما هي الحقائق الفعلية المتوفرة؟"',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Color(0xFF4CAF50),
                                  ),
                                  child: const Text('فهمت'),
                                ),
                              ],
                              backgroundColor: const Color(0xFF2A2A2A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              contentTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              titleTextStyle: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    tooltip: 'معلومات حول تحدي الأفكار',
                  ),
                  Expanded(
                    child: Text(
                      'فكرتك: "${state.userThought}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'ما هو الدليل الذي يدعم أو يعارض هذه الفكرة؟',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF4CAF50),
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Supporting Evidence Column
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE64E4E).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "مع",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[400],
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _supportingEvidenceController,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: 'اكتب الدليل الذي يدعم الفكرة...',
                              hintStyle: const TextStyle(color: Colors.white60),
                              // Add clear borders to make it obvious this is an input field
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              // Conditionally show error text if the field is empty
                              errorText: _supportingEvidenceController
                                      .text.isEmpty
                                  ? null
                                  : _validateInput(
                                          _supportingEvidenceController.text)
                                      ? null
                                      : 'لا يمكن أن يكون الحقل فارغًا',
                            ),
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Contradicting Evidence Column
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "ضد",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[400],
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _contradictingEvidenceController,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: 'اكتب الدليل الذي يعارض الفكرة...',
                              hintStyle: const TextStyle(color: Colors.white60),
                              // Add clear borders to make it obvious this is an input field
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.green[400]!.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.green[400]!,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              // Conditionally show error text if the field is empty
                              errorText: _contradictingEvidenceController
                                      .text.isEmpty
                                  ? null
                                  : _validateInput(
                                          _contradictingEvidenceController.text)
                                      ? null
                                      : 'لا يمكن أن يكون الحقل فارغًا',
                            ),
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 4: // Create alternative thought
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4EE6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'اكتب فكرة بديلة أكثر توازناً وواقعية:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _alternativeController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب الفكرة البديلة هنا...',
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                // Add error text that appears when validation fails
                errorText: _alternativeController.text.isEmpty
                    ? null
                    : _validateInput(_alternativeController.text)
                        ? null
                        : 'لا يمكن أن يكون الحقل فارغًا',
              ),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              // Enable Arabic text input explicitly
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ],
        );

      case 5: // Review and reflect
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مراجعة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF4CAF50),
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 15),

              // Original thought
              _buildComparisonItem(
                "الفكرة الأصلية:",
                state.userThought,
                const Color(0xFFE64E4E).withOpacity(0.15),
                colorScheme,
              ),
              const SizedBox(height: 10),

              // Alternative thought
              _buildComparisonItem(
                "الفكرة البديلة:",
                state.alternativeThought,
                const Color(0xFF4CAF50).withOpacity(0.15),
                colorScheme,
              ),

              const SizedBox(height: 20),

              // // Reflection question
              // Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFF5D4EE6).withOpacity(0.2),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: const Text(
              //     'كيف يشعر جسمك الآن بعد استبدال الفكرة السلبية بفكرة أكثر توازناً؟',
              //     style: TextStyle(
              //       fontWeight: FontWeight.bold,
              //       fontSize: 16,
              //       color: Colors.white,
              //     ),
              //     textAlign: TextAlign.center,
              //   ),
              // ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

// Helper to build distortion checkboxes
  Widget _buildDistortionCheckboxes(
      BuildContext context, CBTTherapyState state) {
    return Column(
      children: [
        for (var distortion in state.cognitiveDistortions.entries)
          CheckboxListTile(
            title: Text(
              distortion.key,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white),
            ),
            value: distortion.value,
            onChanged: (bool? value) {
              context
                  .read<CBTTherapyBloc>()
                  .add(ToggleDistortionEvent(distortion: distortion.key));
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF4CAF50),
            checkColor: Colors.black,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

// Helper to build comparison items in the review screen
  Widget _buildComparisonItem(
      String title, String content, Color bgColor, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: bgColor == const Color(0xFFE64E4E).withOpacity(0.15)
              ? const Color(0xFFE64E4E).withOpacity(0.3)
              : const Color(0xFF4CAF50).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

// Show congratulations popup when exercise is completed
  void _showCongratulationsPopup(BuildContext context) {
    // Get reference to the bloc before showing the dialog
    final cbtTherapyBloc = context.read<CBTTherapyBloc>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Reset and start animations
        _scaleController.reset();
        _confettiController.reset();
        _scaleController.forward();
        _confettiController.forward();

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Confetti animation overlay
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _confettiAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ConfettiPainter(
                          progress: _confettiAnimation.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),

                // Main popup card with scale animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon with glow effect
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            color: Colors.amber,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Congratulations text
                        Text(
                          'تهانينا!',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لقد أكملت جلسة العلاج المعرفي السلوكي بنجاح',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Repeat button - Now with outlined style
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                cbtTherapyBloc.add(ResetCBTExerciseEvent());
                                cbtTherapyBloc.add(StartCBTExerciseEvent());
                              },
                              icon: Icon(
                                Icons.replay_rounded,
                                color: theme.colorScheme
                                    .secondary, // Explicitly set icon color to match text
                              ),
                              label: const Text('إعادة'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.secondary,
                                side: BorderSide(
                                    color: theme.colorScheme.secondary),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            // Okay button - Now with filled style
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  dialogContext,
                                  MaterialPageRoute(
                                      builder: (_) => const MainNavigator()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: theme.colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('حسنا'),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// Confetti painter for celebration animation
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random random = Random();

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final confettiCount = 100;
    final paint = Paint();

    for (var i = 0; i < confettiCount; i++) {
      // Calculate confetti position based on progress
      final x = random.nextDouble() * size.width;
      final startY = -20.0 - random.nextDouble() * 100;
      final endY = size.height * 0.7 + random.nextDouble() * 100;
      final currentY = startY + (endY - startY) * progress;

      // Random size for each confetti piece
      final confettiSize = 5.0 + random.nextDouble() * 5;

      // Random rotation for each confetti piece
      final rotation = random.nextDouble() * 2 * pi;

      // Random color for each confetti piece - using theme colors
      final colors = [
        const Color(0xFFFF6B4A), // Orange from chart
        const Color(0xFF5D4EE6), // Purple from chart
        const Color(0xFF4CAF50), // Green accent
        const Color(0xFFE64E4E), // Red from chart
      ];
      paint.color = colors[random.nextInt(colors.length)];

      // Save the current canvas state
      canvas.save();

      // Move to the confetti position and rotate
      canvas.translate(x, currentY);
      canvas.rotate(rotation);

      // Draw the confetti (rectangle or circle)
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: const Offset(0, 0),
            width: confettiSize,
            height: confettiSize * 1.5,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(const Offset(0, 0), confettiSize / 2, paint);
      }

      // Restore the canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
