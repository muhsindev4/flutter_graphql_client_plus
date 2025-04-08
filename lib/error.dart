import 'package:graphql_flutter/graphql_flutter.dart';

class ErrorModel {
  final String message;

  ErrorModel({required this.message});

  factory ErrorModel.fromGraphQLException(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      return ErrorModel(message: exception.graphqlErrors.first.message);
    } else if (exception.linkException != null) {
      return ErrorModel(message: exception.linkException.toString());
    } else {
      return ErrorModel(message: 'Unknown error occurred');
    }
  }
}
