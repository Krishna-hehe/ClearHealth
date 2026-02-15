import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clear_health/core/services/auth_service.dart';
import 'package:clear_health/core/services/audit_service.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuditService extends Mock implements AuditService {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  late AuthService authService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockAuditService mockAuditService;

  setUpAll(() {
    registerFallbackValue(AuditAction.loginSuccess);
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockAuditService = MockAuditService();

    // Mock SupabaseClient.auth to return our MockGoTrueClient
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    // Mock AuditService.log to do nothing
    when(
      () => mockAuditService.log(any(), details: any(named: 'details')),
    ).thenAnswer((_) async {});

    authService = AuthService(mockSupabaseClient, mockAuditService);
  });

  group('AuthService', () {
    const email = 'test@example.com';
    const password = 'password123';

    test(
      'signIn calls supabase.auth.signInWithPassword and logs success',
      () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();

        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result, mockResponse);
        verify(
          () => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          ),
        ).called(1);
        verify(
          () => mockAuditService.log(
            AuditAction.loginSuccess,
            details: any(named: 'details'),
          ),
        ).called(1);
      },
    );

    test(
      'signUp calls supabase.auth.signUp with metadata and logs success',
      () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        const firstName = 'John';

        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockGoTrueClient.signUp(
            email: email,
            password: password,
            data: {'first_name': firstName},
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authService.signUp(
          email,
          password,
          firstName: firstName,
        );

        // Assert
        expect(result, mockResponse);
        verify(
          () => mockGoTrueClient.signUp(
            email: email,
            password: password,
            data: {'first_name': firstName},
          ),
        ).called(1);
        verify(
          () => mockAuditService.log(
            AuditAction.signupSuccess,
            details: any(named: 'details'),
          ),
        ).called(1);
      },
    );

    test('signUp passes null data if firstName is omitted', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockResponse.user).thenReturn(mockUser);
      when(
        () => mockGoTrueClient.signUp(
          email: email,
          password: password,
          data: null,
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await authService.signUp(email, password);

      // Assert
      verify(
        () => mockGoTrueClient.signUp(
          email: email,
          password: password,
          data: null, // Important: Verify it sends null, not empty map
        ),
      ).called(1);
    });
  });
}
