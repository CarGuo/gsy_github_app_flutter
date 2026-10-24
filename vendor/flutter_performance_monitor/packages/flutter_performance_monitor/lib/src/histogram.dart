import 'model.dart';

/// A fixed, non-cumulative histogram: each sample belongs to exactly one bucket.
/// Equality belongs to the bucket whose upper bound equals the sample.
final class Histogram {
  factory Histogram(List<num> bounds, {num? budgetUs}) {
    num previous = -1;
    if (bounds.isEmpty || bounds.length > 64) {
      throw ArgumentError('Histogram needs 1 to 64 finite increasing bounds');
    }
    for (final bound in bounds) {
      if (!bound.isFinite ||
          bound < 0 ||
          bound <= previous ||
          bound > maxTelemetryInteger) {
        throw ArgumentError('Histogram bounds must be finite and increasing');
      }
      previous = bound;
    }
    if (budgetUs != null &&
        (!budgetUs.isFinite ||
            budgetUs <= 0 ||
            budgetUs > maxTelemetryInteger)) {
      throw ArgumentError('Histogram budget must be positive and finite');
    }
    return Histogram._(List<num>.unmodifiable(bounds), budgetUs);
  }

  Histogram._(this.bounds, this.budgetUs)
    : _bucketCounts = List<int>.filled(bounds.length + 1, 0);

  final List<num> bounds;
  final num? budgetUs;
  final List<int> _bucketCounts;
  int _count = 0;
  num _sum = 0;
  num _max = 0;
  int _overBudgetCount = 0;

  int get count => _count;
  num get sum => _sum;
  num get max => _max;
  int get overBudgetCount => _overBudgetCount;
  List<int> get bucketCounts => List<int>.unmodifiable(_bucketCounts);

  /// False means invalid input or numeric capacity; no state is changed.
  bool add(num value) {
    if (!value.isFinite ||
        value < 0 ||
        value > maxTelemetryInteger ||
        _count >= maxTelemetryInteger) {
      return false;
    }
    final nextSum = _sum + value;
    if (!nextSum.isFinite || nextSum > maxTelemetryInteger) return false;
    var low = 0;
    var high = bounds.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (value <= bounds[middle]) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    _bucketCounts[low]++;
    _count++;
    _sum = nextSum;
    if (value > _max) _max = value;
    if (budgetUs != null && value > budgetUs!) _overBudgetCount++;
    return true;
  }
}
