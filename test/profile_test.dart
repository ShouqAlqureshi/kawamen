import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:kawamen/features/Profile/Bloc/profile_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock Classes
class MockFirebaseAppPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {
  @override
  bool get isAutoInitEnabled => true;
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {
  @override
  String get uid => super.noSuchMethod(
        Invocation.getter(#uid),
        returnValue: 'test-uid',
        returnValueForMissingStub: 'test-uid',
      );
}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockBuildContext extends Mock implements BuildContext {}
// Setup Firebase Mocks
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup mock instance
  final platformMock = MockFirebaseAppPlatform();
  FirebasePlatform.instance = platformMock;
}

void main() async {
  setupFirebaseMocks();
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockDocumentReference mockDocRef;
  late MockCollectionReference mockCollectionRef;
  late MockBuildContext mockContext;
  late ProfileBloc profileBloc;

  setUp(() {
    mockUser = MockUser();
    mockDocRef = MockDocumentReference();
    mockCollectionRef = MockCollectionReference();
    mockContext = MockBuildContext();
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
// Initialize bloc with all required dependencies
    profileBloc = ProfileBloc(
      context: mockContext,
      auth: mockAuth,
      firestore: mockFirestore,
    );
    // Setup basic mocks
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');
    when(mockFirestore.collection('users')).thenReturn(mockCollectionRef);
    when(mockCollectionRef.doc('test-user-id')).thenReturn(mockDocRef);
  });

  group('UpdateUserInfo', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdated] when updating profile without email change',
      build: () {
        when(mockUser.uid).thenReturn('test12');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockDocRef.update({
          'fullName': 'Test Name',
          'age': '25',
        })).thenAnswer((_) async => null);
        when(mockAuth.setLanguageCode(any)).thenAnswer((_) async => null);

        return profileBloc;
      },
      setUp: () {
        mockContext = MockBuildContext();
        mockAuth = MockFirebaseAuth();
        mockFirestore = MockFirebaseFirestore();
// Initialize bloc with all required dependencies
        profileBloc = ProfileBloc(
          context: mockContext,
          auth: mockAuth,
          firestore: mockFirestore,
        );
      },
      act: (bloc) => bloc.add(UpdateUserInfo(
        name: 'Test Name',
        age: "25",
        email: 'test@example.com',
      )),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdated>(),
      ],
      verify: (_) {
        verify(mockDocRef.update({
          'fullName': 'Test Name',
          'age': '25',
        })).called(1);
        verify(mockAuth.setLanguageCode("ar")).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileNeedsVerification] when email is changed',
      build: () {
        when(mockUser.email).thenReturn('old@example.com');
        when(mockDocRef.update({
          'fullName': 'Test Name',
          'age': '25',
        })).thenAnswer((_) async => null);
        when(mockUser.verifyBeforeUpdateEmail('new@example.com'))
            .thenAnswer((_) async => null);

        return profileBloc;
      },
      setUp: () {
        mockContext = MockBuildContext();
        mockAuth = MockFirebaseAuth();
        mockFirestore = MockFirebaseFirestore();
// Initialize bloc with all required dependencies
        profileBloc = ProfileBloc(
          context: mockContext,
          auth: mockAuth,
          firestore: mockFirestore,
        );
      },
      act: (bloc) => bloc.add(UpdateUserInfo(
        name: 'Test Name',
        age: "25",
        email: 'new@example.com',
      )),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileNeedsVerification>(),
      ],
      verify: (_) {
        verify(mockUser.verifyBeforeUpdateEmail('new@example.com')).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] when no user is logged in',
      build: () {
        when(mockAuth.currentUser).thenReturn(null);
        return profileBloc;
      },
      act: (bloc) => bloc.add(UpdateUserInfo(
        name: 'Test Name',
        age: "25",
        email: 'test@example.com',
      )),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] when Firebase Auth throws exception',
      build: () {
        when(mockUser.email).thenReturn('old@example.com');
        when(mockDocRef.update({
          'fullName': 'Test Name',
          'age': '25',
        })).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
        return profileBloc;
      },
      setUp: () {
        mockContext = MockBuildContext();
        mockAuth = MockFirebaseAuth();
        mockFirestore = MockFirebaseFirestore();
// Initialize bloc with all required dependencies
        profileBloc = ProfileBloc(
          context: mockContext,
          auth: mockAuth,
          firestore: mockFirestore,
        );
      },
      act: (bloc) => bloc.add(UpdateUserInfo(
        name: 'Test Name',
        age: "25",
        email: 'new@example.com',
      )),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );
  });

  tearDown(() {
    profileBloc.close();
  });
}
