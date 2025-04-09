import 'dart:async';
import 'dart:developer';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'flutter_graphql_client.dart';
import 'graphql_action_cable_link.dart';

class GraphQLService {
  late GraphQLClient _client;
  final FlutterGraphqlClient _config = FlutterGraphqlClient.instance;
  Completer<void>? _tokenRefreshCompleter;

  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancelAllRequests() {
    _isCancelled = true;
    log("🛑 All ongoing and future requests are cancelled.");
  }

  void resumeRequests() {
    _isCancelled = false;
    log("✅ Requests resumed.");
  }

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
      "🛰️ Subscribing: ${_getOperationName(subscription)}",
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
    if (_isCancelled) {
      log("⚠️ Request $operationName cancelled.");
      return ResponseModel(
        data: null,
        error: ErrorModel(
          message: 'Request cancelled',
          code: ErrorType.cancelRequest,
        ),
      );
    }
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
          log("🔑 Token expired for $operationName.");

          if (_tokenRefreshCompleter != null) {
            // Another refresh is in progress
            log("⏳ Waiting for ongoing token refresh...");
            await _tokenRefreshCompleter!.future;
          } else {
            _tokenRefreshCompleter = Completer();

            try {
              final newToken = await _config.refreshTokenHandler(
                _config.token!.refreshToken,
                this,
              );

              if (newToken != null) {
                _config.updateAccessToken(newToken.accessToken);
                _config.updateRefreshToken(newToken.refreshToken);
                log("✅ Token refreshed successfully.");
                initializeClient();
              } else {
                log("❌ Token refresh failed.");
                _config.onTokenRefreshFailed?.call(this);
              }
            } catch (e) {
              log("🔥 Error during token refresh: $e");
            } finally {
              _tokenRefreshCompleter?.complete();
              _tokenRefreshCompleter = null;
            }
          }

          log("🔁 Retrying $operationName after token refresh...");
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
