import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/bloc/cbt_therapy_bloc.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/repository/CBT_therapy_repository.dart';

// Mock Repository
class MockCBTRepository extends Mock implements CBTRepository {}

class MockRoute extends Fake implements Route<dynamic> {}

// Create a mock class for the bloc
class MockCBTTherapyBloc extends Mock implements CBTTherapyBloc {
  // Add a stream controller to emit states
  final _stateStreamController = StreamController<CBTTherapyState>.broadcast();

  // Override the stream getter
  @override
  Stream<CBTTherapyState> get stream => _stateStreamController.stream;

  // Correctly override the close method
  @override
  Future<void> close() async {
    _stateStreamController.close();
  }

  // Constructor to set initial state
  MockCBTTherapyBloc() {
    when(() => state).thenReturn(
      const CBTTherapyState(
        isPlaying: true,
        userTreatmentId: 'test-id',
        progress: 50.0,
        currentStep: 2,
        totalSteps: 5,
      ),
    );
  }
}

// Create a mock for NavigatorObserver
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockCBTTherapyBloc mockBloc;
  late MockNavigatorObserver mockNavigatorObserver;

  setUpAll(() {
    // Register fallback values for any classes used in verify() calls
    // Register the new fallback for Route
    registerFallbackValue(MockRoute());
    registerFallbackValue(const PauseCBTTreatmentEvent());
  });

  setUp(() {
    mockBloc = MockCBTTherapyBloc();
    mockNavigatorObserver = MockNavigatorObserver();

    // Setup basic state behavior
    when(() => mockBloc.state).thenReturn(
      const CBTTherapyState(
        isPlaying: true,
        userTreatmentId: 'test-id',
        progress: 50.0,
        currentStep: 2,
        totalSteps: 5,
      ),
    );
  });

  // Extracted dialog function matching your original implementation
  Future<bool> showExitConfirmationDialog(BuildContext context) async {
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
                      // Save progress before exiting
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
        false; // Default to false if dialog is dismissed
  }

  // Helper function to build our widget under test
  Widget createTestApp() {
    return MaterialApp(
      home: BlocProvider<CBTTherapyBloc>.value(
        value: mockBloc,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CBT Therapy'),
            leading: Builder(
              builder: (context) => BackButton(
                onPressed: () async {
                  final shouldPop = await showExitConfirmationDialog(context);
                  if (shouldPop) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ),
          body: const Center(child: Text('Test Screen')),
        ),
      ),
      navigatorObservers: [mockNavigatorObserver],
    );
  }

  testWidgets(
      'Should show dialog and add PauseCBTTreatmentEvent when back button is pressed',
      (WidgetTester tester) async {
    // Arrange: Build the widget tree
    await tester.pumpWidget(createTestApp());

    // Find and tap the back button
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle(); // Wait for dialog to show

    // Assert: Verify the dialog is shown
    expect(find.text('هل أنت متأكد؟'), findsOneWidget);
    expect(find.text('إذا غادرت الآن، ستفقد التقدم في جلسة العلاج الحالية.'),
        findsOneWidget);

    // Find and tap the "مغادرة" (Leave) button
    final leaveButton = find.text('مغادرة');
    expect(leaveButton, findsOneWidget);
    await tester.tap(leaveButton);
    await tester.pump(const Duration(milliseconds: 100)); // Wait for the delay

    // Verify that PauseCBTTreatmentEvent was added to the bloc
    verify(() => mockBloc.add(const PauseCBTTreatmentEvent())).called(1);

    // Wait for animation to complete
    await tester.pumpAndSettle();
  });

  testWidgets('Should stay in app when cancel button is pressed in dialog',
      (WidgetTester tester) async {
    // Arrange: Build the widget
    await tester.pumpWidget(createTestApp());

    // Find and tap the back button
    final backButton = find.byType(BackButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle(); // Wait for dialog to show

    // Make sure dialog is shown
    expect(find.byType(AlertDialog), findsOneWidget);

    // Find and tap the "البقاء" (Stay) button - using textDirection
    final stayButton = find.text('البقاء');
    expect(stayButton, findsOneWidget,
        reason: 'Stay button not found in the dialog');
    await tester.tap(stayButton);
    await tester.pumpAndSettle(); // Wait for dialog to close

    // Verify that PauseCBTTreatmentEvent was NOT added to the bloc
    verifyNever(() => mockBloc.add(any()));

    // After closing dialog, we should still be on the main screen
    expect(find.text('Test Screen'), findsOneWidget);
  });
  testWidgets('Should navigate out of tretment screen when Leave button is clicked in dialog',
      (WidgetTester tester) async {
    // Arrange: Build the widget tree
    await tester.pumpWidget(createTestApp());

    // Find and tap the back button to show the dialog
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle(); // Wait for dialog to show

    // Verify dialog is showing
    expect(find.byType(AlertDialog), findsOneWidget);

    // Find the red "مغادرة" (Leave) button
    final leaveButton = find.widgetWithText(FilledButton, 'مغادرة');
    expect(leaveButton, findsOneWidget);

    // Verify button has the correct styling
    final filledButton = tester.widget<FilledButton>(leaveButton);
    final buttonStyle = filledButton.style;
    final backgroundColor = buttonStyle?.backgroundColor?.resolve({});
    final foregroundColor = buttonStyle?.foregroundColor?.resolve({});
    expect(backgroundColor, Colors.red);
    expect(foregroundColor, Colors.white);

    // Tap the Leave button
    await tester.tap(leaveButton);
    await tester.pump(const Duration(milliseconds: 100)); // Wait for the delay

    // Verify that PauseCBTTreatmentEvent was added to the bloc
    verify(() => mockBloc.add(const PauseCBTTreatmentEvent())).called(1);

    // Wait for animation to complete
    await tester.pumpAndSettle();

    // Verify navigation occurred twice (dialog pop + screen pop)
    verify(() => mockNavigatorObserver.didPop(any(), any())).called(2);

    // Alternative verification: Check that the app has returned to previous screen
    expect(find.text('Test Screen'), findsNothing);
  });

  tearDown(() {
    mockBloc.close();
  });
}
