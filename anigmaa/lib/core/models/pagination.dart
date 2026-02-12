import 'package:equatable/equatable.dart';

/// Pagination metadata from API responses
///
/// Backend should return this structure in all list endpoints:
/// ```json
/// {
///   "success": true,
///   "data": [...],
///   "meta": {
///     "total": 150,
///     "limit": 20,
///     "offset": 0,
///     "hasNext": true,
///     "hasPrevious": false
///   }
/// }
/// ```
class PaginationMeta extends Equatable {
  final int total;
  final int limit;
  final int offset;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationMeta({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Calculate current page number (1-based)
  int get currentPage => (offset ~/ limit) + 1;

  /// Calculate total pages
  int get totalPages => (total / limit).ceil();

  /// Check if this is the first page
  bool get isFirstPage => !hasPrevious && offset == 0;

  /// Check if this is the last page
  bool get isLastPage => !hasNext;

  /// Get offset for next page
  int get nextOffset => offset + limit;

  /// Get offset for previous page
  int get previousOffset => (offset - limit).clamp(0, total);

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? json['has_next'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? json['has_previous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'limit': limit,
      'offset': offset,
      'hasNext': hasNext,
    };
  }

  /// Create empty pagination (no data)
  factory PaginationMeta.empty() {
    return const PaginationMeta(
      total: 0,
      limit: 20,
      offset: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  /// Create default pagination for first page
  factory PaginationMeta.firstPage({int limit = 20}) {
    return const PaginationMeta(
      total: 0,
      limit: 20,
      offset: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  List<Object?> get props => [total, limit, offset, hasNext];

  @override
  String toString() => 'PaginationMeta(total: $total, page: $currentPage/$totalPages, hasNext: $hasNext)';
}

/// Wrapper for paginated list responses
class PaginatedResponse<T> extends Equatable {
  final List<T> data;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.data,
    required this.meta,
  });

  /// Check if this is the first page
  bool get isFirstPage => meta.offset == 0;

  /// Check if this is the last page
  bool get isLastPage => !meta.hasNext;

  /// Check if response has data
  bool get isEmpty => data.isEmpty;

  /// Check if response has data
  bool get isNotEmpty => data.isNotEmpty;

  @override
  List<Object?> get props => [data, meta];

  @override
  String toString() => 'PaginatedResponse(items: ${data.length}, $meta)';
}
