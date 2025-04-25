import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_graphql_client_plus/flutter_graphql_client_plus.dart';
import 'package:flutter_graphql_client_plus/src/utils/string_format.dart';

import '../debugger/debug_web_socket.dart';
import '../models/graphql_request_log.dart';

class GraphQLService {
  late GraphQLClient _client;
  final FlutterGraphqlClient _config = FlutterGraphqlClient.instance;
  final DebugWebSocket _debugWebSocket = DebugWebSocket();
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
        'User-Agent':
            "${Platform.operatingSystem.toString().capitalizeFirst}/${Platform.version}",
      },
    );

    final socketUrl =
        _config.webSocketUrl != null ? "${_config.webSocketUrl}" : "";

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
      query: queries,
      operationType: OperationType.query,
      executor:
          () => _client.query(
            QueryOptions(
              document: gql(queries),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.noCache,
            ),
          ),
      retryOnTokenExpiry: () => query(queries, variables: variables),
      variable: variables,
    );
  }

  Future<ResponseModel> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    return _execute(
      query: mutation,
      operationType: OperationType.mutation,
      executor:
          () => _client.mutate(
            MutationOptions(
              document: gql(mutation),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.noCache,
            ),
          ),
      retryOnTokenExpiry: () => mutate(mutation, variables: variables),
      variable: variables,
    );
  }

  Future<StreamSubscription<QueryResult>> subscribe(
    String subscription, {
    Map<String, dynamic>? variables,
    required void Function(QueryResult result) onData,
    void Function()? onDone,
    void Function(Object error)? onError,
  }) async {
    log(
      "🛰️ Subscribing: ${_getOperationName(subscription)} Variables: ${jsonEncode(variables)}",
    );

    final stream = _client.subscribe(
      SubscriptionOptions(
        document: gql(subscription),
        variables: variables ?? {},
      ),
    );

    final subscriptionStream = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: false,
    );

    return subscriptionStream;
  }

  Future<ResponseModel> _execute({
    required String query,
    required OperationType operationType,
    required Map<String, dynamic>? variable,
    required Future<QueryResult> Function() executor,
    required Future<ResponseModel> Function() retryOnTokenExpiry,
  }) async {
    String operationName = _getOperationName(query);
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
      log(
        "📥 Executing $operationType: $operationName \n Variables: ${jsonEncode(variable)}",
      );

      final stopwatch = Stopwatch()..start();
      final result = await executor();
      stopwatch.stop();

      if (_config.debugWebSocketUrl != null) {
        GraphQLRequestLog requestLog = GraphQLRequestLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          operationType: operationType,
          operationName: operationName,
          query: query,
          variables: variable,
          responseData: result.data,
          errorMessage:
              result.hasException ? result.exception.toString() : null,
          durationMs: stopwatch.elapsedMilliseconds,
        );

        _debugWebSocket.sendRequestInfo(requestLog);
      }

      if (result.hasException) {
        final exception = result.exception;

        // ❌ No retry for network failures
        if (exception?.linkException != null) {
          log(
            "📡 Network error in $operationName: ${exception?.linkException}",
          );
          return ResponseModel(
            data: null,
            error: ErrorModel(
              message: 'Network error: ${exception?.linkException}',
              code: ErrorType.networkError,
            ),
          );
        }

        log("⚠️ GraphQL $operationType error in $operationName:\n$exception");

        String? errorCode;
        final errors = exception?.graphqlErrors ?? [];
        if (errors.isNotEmpty) {
          errorCode = errors.first.extensions?['code'];
        }

        if (errorCode == _config.tokenExpiryErrorCode) {
          log("🔑 Token expired for $operationName.");

          if (_tokenRefreshCompleter != null) {
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
          error: ErrorModel.fromGraphQLException(exception!),
        );
      }

      log(
        "✅ $operationType $operationName took ${stopwatch.elapsedMilliseconds}ms completed successfully.",
      );
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
