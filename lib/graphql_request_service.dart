import 'dart:async';
import 'dart:developer';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'flutter_graphql_client.dart';
import 'graphql_action_cable_link.dart';

class GraphQLService {
  late GraphQLClient _client;
  final FlutterGraphqlClient _config = FlutterGraphqlClient.instance;

  void initializeClient() {
    log("🧰 Initializing GraphQL client...");
    final httpLink = HttpLink(
      _config.graphQlEndPoint,
      defaultHeaders: {
        'Authorization': 'Bearer ${_config.token?.accessToken ?? ''}',
      },
    );

    final socketUrl =
        _config.webSocketUrl != null
            ? "${_config.webSocketUrl}?token=${_config.token!.accessToken}"
            : "";

    if (_config.webSocketUrl != null) {
      log("📡 ActionCable WebSocket initialized: $socketUrl");
    }

    final actionCableLink = ActionCableLink(socketUrl);

    final link = Link.split(
      (request) => request.isSubscription,
      actionCableLink,
      httpLink,
    );

    _client = GraphQLClient(cache: GraphQLCache(), link: link);
  }

  Future<ResponseModel> query(
    String queries, {
    Map<String, dynamic>? variables,
  }) async {
    return _execute(
      operationName: _getOperationName(queries),
      operationType: "Query",
      executor:
          () => _client.query(
            QueryOptions(
              document: gql(queries),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          ),
      retryOnTokenExpiry: () => query(queries, variables: variables),
    );
  }

  Future<ResponseModel> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    return _execute(
      operationName: _getOperationName(mutation),
      operationType: "Mutation",
      executor:
          () => _client.mutate(
            MutationOptions(
              document: gql(mutation),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          ),
      retryOnTokenExpiry: () => mutate(mutation, variables: variables),
    );
  }

  Stream<QueryResult> subscribe(
    String subscription, {
    Map<String, dynamic>? variables,
  }) {
    log(
      "🛰️ Subscribing: ${_getOperationName(subscription)}\nToken: ${_config.token!.accessToken}",
    );

    return _client.subscribe(
      SubscriptionOptions(
        document: gql(subscription),
        variables: variables ?? {},
      ),
    );
  }

  Future<ResponseModel> _execute({
    required String operationName,
    required String operationType,
    required Future<QueryResult> Function() executor,
    required Future<ResponseModel> Function() retryOnTokenExpiry,
  }) async {
    try {
      log("📥 Executing $operationType: $operationName");
      final result = await executor();

      if (result.hasException) {
        log(
          "⚠️ GraphQL $operationType error in $operationName:\n${result.exception}",
        );

        final error = result.exception!.graphqlErrors.first;
        final errorCode = error.extensions?['code'];

        if (errorCode == _config.tokenExpiryErrorCode) {
          log("🔑 Token expired for $operationName. Attempting to refresh...");

          final newToken = await _config.refreshTokenHandler(
            _config.token!.refreshToken,
          );
          _config.updateAccessToken(newToken.accessToken);
          _config.updateRefreshToken(newToken.refreshToken);

          log("✅ Token refreshed. Retrying $operationName...");
          initializeClient();

          return retryOnTokenExpiry();
        }

        return ResponseModel(
          data: null,
          error: ErrorModel.fromGraphQLException(result.exception!),
        );
      }

      log("✅ $operationType $operationName completed successfully.");
      return ResponseModel(data: result.data, error: null);
    } catch (e, stackTrace) {
      log(
        "🔥 Unexpected $operationType error in $operationName: $e\n$stackTrace",
      );
      return ResponseModel(
        data: null,
        error: ErrorModel(message: 'Unexpected error: $e'),
      );
    }
  }

  String _getOperationName(String raw) {
    return raw
        .split('{')
        .first
        .trim()
        .replaceAll(RegExp(r'(mutation|query|subscription)'), '')
        .trim();
  }
}
