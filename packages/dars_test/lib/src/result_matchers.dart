import 'package:dars/dars.dart';
import 'package:matcher/matcher.dart';

/// A matcher that matches a [Result] that is [Ok].
///
/// Can be used as a constant:
/// ```dart
/// expect(result, isOk);
/// ```
///
/// Or with a value, matcher, or predicate:
/// ```dart
/// expect(result, isOk(42));
/// expect(result, isOk(greaterThan(0)));
/// expect(result, isOk((v) => v.isNotEmpty));
/// ```
///
/// Or with a type check:
/// ```dart
/// expect(result, isOk<int>(42));
/// ```
const isOk = _ResultRootMatcher(expectsOk: true);

/// A matcher that matches a [Result] that is [Err].
///
/// Can be used as a constant:
/// ```dart
/// expect(result, isErr);
/// ```
///
/// Or with a value, matcher, or predicate:
/// ```dart
/// expect(result, isErr('error'));
/// expect(result, isErr(contains('not found')));
/// expect(result, isErr((e) => e is MyException));
/// ```
///
/// Or with a type check:
/// ```dart
/// expect(result, isErr<String>('error'));
/// ```
const isErr = _ResultRootMatcher(expectsOk: false);

/// Sentinel value to detect when no expectation is provided.
const _sentinel = Object();

/// Keys used in matchState map for tracking match failures.
class _MatchStateKey {
  static const typeMismatch = 'typeMismatch';
  static const predicateMismatch = 'predicateMismatch';
  static const actualType = 'actualType';
}

/// Root matcher that can be used as a constant or called as a function.
class _ResultRootMatcher extends _ResultVariantMatcher<dynamic> {
  const _ResultRootMatcher({required super.expectsOk}) : super();

  /// Returns a matcher that matches the [Result] variant and its value/error.
  _ResultVariantMatcher<T> call<T>([Object? valueOrMatcher = _sentinel]) {
    return _ResultVariantMatcher<T>(
      expectsOk: _expectsOk,
      expectation: valueOrMatcher == _sentinel ? null : valueOrMatcher,
      hasExpectation: valueOrMatcher != _sentinel,
    );
  }
}

/// Matcher for Result variants with optional value/type checking.
class _ResultVariantMatcher<V> extends Matcher {
  const _ResultVariantMatcher({
    required bool expectsOk,
    Object? expectation,
    bool hasExpectation = false,
  })  : _expectsOk = expectsOk,
        _expectation = expectation,
        _hasExpectation = hasExpectation;

  /// Whether this matcher expects an Ok variant (true) or Err variant (false).
  final bool _expectsOk;

  /// The expected value, matcher, or predicate function.
  final Object? _expectation;

  /// Whether an expectation was explicitly provided.
  final bool _hasExpectation;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Result) return false;

    // Check if the variant matches
    final isExpectedVariant = _expectsOk ? item.isOk : item.isErr;
    if (!isExpectedVariant) return false;

    // If no type check and no expectation, match any value
    if (!_hasExpectation && V == dynamic) return true;

    // Get the actual value from the Result
    final actualValue = _expectsOk ? item.ok() : item.err();
    return _matchesValue(actualValue, matchState);
  }

  /// Checks if the actual value matches the expected value/type/matcher.
  bool _matchesValue(Object? actual, Map<dynamic, dynamic> matchState) {
    // Type check
    if (V != dynamic && actual is! V) {
      matchState[_MatchStateKey.typeMismatch] = true;
      matchState[_MatchStateKey.actualType] = actual.runtimeType;
      return false;
    }

    // No expectation means type-only check passed
    if (!_hasExpectation) return true;

    final expected = _expectation;

    // Matcher expectation
    if (expected is Matcher) {
      return expected.matches(actual, matchState);
    }

    // Predicate function expectation
    if (expected is Function) {
      try {
        // Dynamic call is necessary to support arbitrary predicate functions.
        // ignore: avoid_dynamic_calls
        if (expected(actual) == true) return true;
        matchState[_MatchStateKey.predicateMismatch] = true;
        return false;
      } catch (_) {
        return false;
      }
    }

    // Value equality expectation
    return equals(expected).matches(actual, matchState);
  }

  @override
  Description describe(Description description) {
    final variantName = _expectsOk ? 'Ok' : 'Err';
    description.add(variantName);

    if (V != dynamic) {
      description.add('<$V>');
    }

    if (_hasExpectation) {
      description.add('(');
      _describeExpectation(description);
      description.add(')');
    }
    return description;
  }

  /// Describes the expected value/matcher/predicate.
  void _describeExpectation(Description description) {
    final expected = _expectation;
    if (expected is Matcher) {
      expected.describe(description);
    } else if (expected is Function) {
      description.add('matches predicate');
    } else {
      description.addDescriptionOf(expected);
    }
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Result) {
      return mismatchDescription.add('is not a Result');
    }

    final actualVariant = item.isOk ? 'Ok' : 'Err';
    final actualValue = item.isOk ? item.ok() : item.err();

    // Variant mismatch (Ok vs Err)
    if (item.isOk != _expectsOk) {
      return _describeActualResult(
        mismatchDescription,
        actualVariant,
        actualValue,
      );
    }

    // Type mismatch
    if (matchState[_MatchStateKey.typeMismatch] == true) {
      final actualType = matchState[_MatchStateKey.actualType];
      return _describeActualResult(
        mismatchDescription,
        actualVariant,
        actualValue,
        typeAnnotation: '$actualType',
      );
    }

    // Value/predicate/matcher mismatch
    _describeActualResult(mismatchDescription, actualVariant, actualValue);

    if (matchState[_MatchStateKey.predicateMismatch] == true) {
      mismatchDescription.add(' which does not match predicate');
    } else if (_hasExpectation && _expectation is Matcher) {
      mismatchDescription.add(' which ');
      _expectation.describeMismatch(
        actualValue,
        mismatchDescription,
        matchState,
        verbose,
      );
    }

    return mismatchDescription;
  }

  /// Formats the actual result for mismatch description.
  Description _describeActualResult(
    Description description,
    String variantName,
    Object? value, {
    String? typeAnnotation,
  }) {
    description.add('was: ').add(variantName);
    if (typeAnnotation != null) {
      description.add('<$typeAnnotation>');
    }
    description.add('(').addDescriptionOf(value).add(')');
    return description;
  }
}
