import 'dart:convert';

enum OperationType { query, mutation, subscription }

extension OperationTypeExtension on OperationType {
  String get name => toString().split('.').last;
}

extension StringFormatter on String {

  OperationType get  fromString {
    return OperationType.values.firstWhere(
          (e) => e.name.toLowerCase() == toLowerCase(),
      orElse: () => OperationType.query,
    );
  }
}

class GraphQLRequestLog {
  final String id;
  final OperationType operationType;
  final String operationName;
  final String query;
  final Map<String, dynamic>? variables;
  final dynamic responseData;
  final String? errorMessage;
  final int durationMs;
  final DateTime timestamp;

  GraphQLRequestLog({
    required this.id,
    required this.operationType,
    required this.operationName,
    required this.query,
    this.variables,
    this.responseData,
    this.errorMessage,
    required this.durationMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GraphQLRequestLog.fromJson(Map<String, dynamic> json) {
    return GraphQLRequestLog(
      id: json['id'],
      operationType: json['operationType'].toString().fromString,
      operationName: json['operationName'],
      variables: json['variables'] != null
          ? Map<String, dynamic>.from(json['variables'])
          : null,
      responseData: json['responseData'],
      errorMessage: json['errorMessage'],
      durationMs: json['durationMs'],
      timestamp: DateTime.parse(json['timestamp']), query: json['query'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType.name,
      'operationName': operationName,
      'query': query,
      'variables': variables,
      'responseData': responseData,
      'errorMessage': errorMessage,
      'durationMs': durationMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  GraphQLRequestLog copyWith({
    String? id,
    OperationType? operationType,
    String? operationName,
    String? query,
    Map<String, dynamic>? variables,
    dynamic responseData,
    String? errorMessage,
    int? durationMs,
    DateTime? timestamp,
  }) {
    return GraphQLRequestLog(
        id: id ?? this.id,
        operationType: operationType ?? this.operationType,
        operationName: operationName ?? this.operationName,
        variables: variables ?? this.variables,
        responseData: responseData ?? this.responseData,
        errorMessage: errorMessage ?? this.errorMessage,
        durationMs: durationMs ?? this.durationMs,
        timestamp: timestamp ?? this.timestamp, query:  query ?? this.query
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GraphQLRequestLog &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              operationType == other.operationType &&
              operationName == other.operationName &&
              durationMs == other.durationMs &&
              timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      operationType.hashCode ^
      operationName.hashCode ^
      durationMs.hashCode ^
      timestamp.hashCode;
}
