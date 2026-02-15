import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clear_health/core/supabase_service.dart';
import 'package:clear_health/core/services/input_validation_service.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockInputValidationService extends Mock
    implements InputValidationService {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Generic Mocks for Builders involving PostgrestList (List<Map<String, dynamic>>)
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {}

// Fake Builder that can be awaited (for insert) which usually returns null/void when awaited for void operations,
// or the data if select is used. For uploadLabResult, it expects void/null interaction or we can return null.
class FakeAwaitablePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) async {
    return onValue(
      <Map<String, dynamic>>[],
    ); // Return properly typed empty list
  }
}

// Fake Transform Builder that returns specific data when awaited
class FakeAwaitablePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  final PostgrestList _data;
  FakeAwaitablePostgrestTransformBuilder(this._data);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) async {
    return onValue(_data);
  }
}

void main() {
  late SupabaseService supabaseService;
  late MockSupabaseClient mockClient;
  late MockInputValidationService mockValidator;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late MockPostgrestTransformBuilder mockTransformBuilder;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockValidator = MockInputValidationService();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockTransformBuilder = MockPostgrestTransformBuilder();

    supabaseService = SupabaseService(mockClient, mockValidator);

    when(
      () => mockValidator.sanitizeForDb(any()),
    ).thenAnswer((i) => i.positionalArguments.first as String);
  });

  test('getLabResults fetches data successfully', () async {
    // Arrange
    final List<Map<String, dynamic>> mockData = [
      {'id': '1', 'lab_name': 'Test Lab'},
    ];
    final fakeTransformBuilder = FakeAwaitablePostgrestTransformBuilder(
      mockData,
    );

    when(
      () => mockClient.from('lab_results'),
    ).thenAnswer((_) => mockQueryBuilder); // Use thenAnswer
    when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterBuilder);
    when(
      () => mockFilterBuilder.order('date', ascending: false),
    ).thenAnswer((_) => mockTransformBuilder);
    // Return the fake builder that yields data when awaited
    when(
      () => mockTransformBuilder.range(any(), any()),
    ).thenAnswer((_) => fakeTransformBuilder);

    // Act
    final result = await supabaseService.getLabResults();

    // Assert
    expect(result, mockData);
    verify(() => mockClient.from('lab_results')).called(1);
  });

  test('uploadLabResult inserts sanitized data', () async {
    // Arrange
    final inputData = {'lab_name': 'Raw <script>'};
    final sanitizedData = {'lab_name': 'Raw &lt;script&gt;'};
    final fakeBuilder = FakeAwaitablePostgrestFilterBuilder();

    when(
      () => mockValidator.sanitizeForDb('Raw <script>'),
    ).thenAnswer((_) => 'Raw &lt;script&gt;');
    when(
      () => mockClient.from('lab_results'),
    ).thenAnswer((_) => mockQueryBuilder);
    // Return the fake builder which can be awaited
    when(
      () => mockQueryBuilder.insert(sanitizedData),
    ).thenAnswer((_) => fakeBuilder);

    // Act
    await supabaseService.uploadLabResult(inputData);

    // Assert
    verify(() => mockClient.from('lab_results')).called(1);
    verify(() => mockQueryBuilder.insert(sanitizedData)).called(1);
  });
}
