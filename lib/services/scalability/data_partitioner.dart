/// Client-side data partitioning and pagination strategy.
///
/// At millions of users, a single SELECT on `emergencies` or
/// `location_history` without proper partitioning and cursor-based
/// pagination would time out.  [DataPartitioner] provides utilities
/// for:
///
/// * Geographic region-based partition key computation.
/// * Time-range partitioning for historical data.
/// * Cursor-based pagination helpers.
class DataPartitioner {
  /// Number of geographic regions (e.g. geohash grid cells).
  final int regionCount;

  /// Maximum rows per page.
  final int defaultPageSize;

  const DataPartitioner({
    this.regionCount = 256,
    this.defaultPageSize = 50,
  });

  // ── Geographic partitioning ────────────────────────────────

  /// Compute a partition key for a given latitude/longitude.
  ///
  /// Divides the world into a grid of [regionCount] cells using a
  /// simple quantisation of lat/lng.  This allows the backend to
  /// route queries to the correct shard/partition.
  int regionKeyFor(double latitude, double longitude) {
    // Normalise to 0..1 range.
    final normLat = (latitude + 90) / 180;
    final normLng = (longitude + 180) / 360;
    final gridSize = _gridSide;
    final row = (normLat * gridSize).floor().clamp(0, gridSize - 1);
    final col = (normLng * gridSize).floor().clamp(0, gridSize - 1);
    return row * gridSize + col;
  }

  int get _gridSide {
    // Square-root of regionCount rounded up.
    var side = 1;
    while (side * side < regionCount) {
      side++;
    }
    return side;
  }

  // ── Time-range partitioning ────────────────────────────────

  /// Compute a partition suffix for the month containing [date].
  ///
  /// E.g. `2026_03` for March 2026.  This maps directly to a
  /// Postgres-style monthly partition table name suffix.
  String monthPartition(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}_$m';
  }

  /// Compute all monthly partition suffixes between [start] and
  /// [end] (inclusive of the months they fall in).
  List<String> monthPartitionRange(DateTime start, DateTime end) {
    final partitions = <String>[];
    var cursor = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!cursor.isAfter(last)) {
      partitions.add(monthPartition(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return partitions;
  }

  // ── Cursor-based pagination ────────────────────────────────

  /// Build a cursor-based query filter map.
  ///
  /// Returns a map with `limit`, `order`, and optionally `after`
  /// that can be merged into a Supabase query.
  Map<String, dynamic> cursorPage({
    String? afterId,
    int? pageSize,
    String orderColumn = 'created_at',
    bool ascending = false,
  }) {
    final result = <String, dynamic>{
      'limit': pageSize ?? defaultPageSize,
      'order': orderColumn,
      'ascending': ascending,
    };
    if (afterId != null) {
      result['after'] = afterId;
    }
    return result;
  }
}
