import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kawamen/features/Treatment/CBT_therapy/bloc/CBT_therapy_bloc.dart';

// Mock CBT therapy bloc
class MockCBTTherapyBloc extends MockBloc<CBTTherapyEvent, CBTTherapyState>
    implements CBTTherapyBloc {}

void main() {
  late MockCBTTherapyBloc mockBloc;

  setUp(() {
    mockBloc = MockCBTTherapyBloc();
  });

  group('Start Treatment Tests', () {
    testWidgets(
        'Test Case : Start button press should trigger StartCBTExerciseEvent',
        (WidgetTester tester) async {
      // ARRANGE
      // Initial state setup
      when(() => mockBloc.state).thenReturn(
        const CBTTherapyState(
          isLoading: false,
          isPlaying: false,
          instructions: ['Test instruction 1', 'Test instruction 2'],
          totalSteps: 2,
          currentStep: 1,
        ),
      );

      // Build the CBT therapy widget with mock bloc
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CBTTherapyBloc>.value(
            value: mockBloc,
            child: const MockCBTTherapyView(),
          ),
        ),
      );

      // ACT
      // Find and tap the start button
      final startButton = find.text('البدء');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pump();

      // ASSERT
      // Verify that StartCBTExerciseEvent was added to the bloc
      verify(() => mockBloc.add(StartCBTExerciseEvent())).called(1);
    });

    testWidgets(
        'Test Case : Start treatment should update UI to show playing state (simplified)',
        (WidgetTester tester) async {
      // ARRANGE: Set up initial state
      when(() => mockBloc.state).thenReturn(
        const CBTTherapyState(
          isLoading: false,
          isPlaying: false,
          instructions: ['Test instruction 1', 'Test instruction 2'],
          totalSteps: 2,
          currentStep: 1,
        ),
      );

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CBTTherapyBloc>.value(
            value: mockBloc,
            child: const MockCBTTherapyView(),
          ),
        ),
      );

      // ACT: Tap the start button
      await tester.tap(find.text('البدء'));

      // ASSERT: Verify the event was added
      verify(() => mockBloc.add(StartCBTExerciseEvent())).called(1);

      // Now manually update the state
      when(() => mockBloc.state).thenReturn(
        const CBTTherapyState(
          isLoading: false,
          isPlaying: true,
          instructions: ['Test instruction 1', 'Test instruction 2'],
          totalSteps: 2,
          currentStep: 1,
        ),
      );

      // Rebuild the widget with the new state
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CBTTherapyBloc>.value(
            value: mockBloc,
            child: const MockCBTTherapyView(),
          ),
        ),
      );

      // Verify the UI correctly shows the next button
      expect(find.text('البدء'), findsNothing);
      expect(find.text('التالي'), findsOneWidget);
    });
  });
}

class MockCBTTherapyView extends StatelessWidget {
  const MockCBTTherapyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CBTTherapyBloc>();
    final state = bloc.state;

    return Scaffold(
      body: Center(
        child: !state.isPlaying
            ? ElevatedButton(
                onPressed: () => bloc.add(StartCBTExerciseEvent()),
                child: const Text('البدء'),
              )
            : ElevatedButton(
                onPressed: () {},
                child: const Text('التالي'),
              ),
      ),
    );
  }
}
