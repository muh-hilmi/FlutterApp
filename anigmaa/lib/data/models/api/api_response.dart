import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final T? data;
  final String? error;
  final String? message;
  final PaginationMeta? pagination;

  ApiResponse({
    this.data,
    this.error,
    this.message,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  bool get isSuccess => error == null || error!.isEmpty;
  bool get hasData => data != null;
}

@JsonSerializable()
class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'total_pages')
  final int? totalPages;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}
