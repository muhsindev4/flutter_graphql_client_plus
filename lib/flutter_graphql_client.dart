export 'package:flutter_graphql_client_plus/responds.dart';
export 'package:flutter_graphql_client_plus/error.dart';
export 'package:flutter_graphql_client_plus/graphql_request_service.dart';
export 'package:flutter_graphql_client_plus/token.dart';
export 'package:flutter_graphql_client_plus/graphql_action_cable_link.dart';
export 'package:graphql/src/cache/cache.dart';
export 'package:graphql/src/core/core.dart';
export 'package:graphql/src/core/query_result.dart';
export 'package:graphql/src/core/policies.dart';
export 'package:graphql/src/exceptions.dart';
export 'package:graphql/src/graphql_client.dart';
export 'package:graphql/src/links/links.dart';
export 'package:graphql/src/utilities/helpers.dart'
    show gql, optimizedDeepEquals;

import 'dart:developer';
import 'package:flutter_graphql_client_plus/token.dart';
import 'graphql_request_service.dart';

class FlutterGraphqlClient {
  final String graphQlEndPoint;
  final String? webSocketUrl;
  Token? token;

  String? tokenExpiryErrorCode;

  final Future<Token?> Function(String refreshToken, GraphQLService service)
  refreshTokenHandler;
  final Function(GraphQLService service)? onTokenRefreshFailed;

  static FlutterGraphqlClient? _instance;

  GraphQLService? graphQLService;

  FlutterGraphqlClient._internal({
    required this.graphQlEndPoint,
    this.webSocketUrl,
    this.token,
    this.tokenExpiryErrorCode,
    required this.refreshTokenHandler,
    required this.onTokenRefreshFailed,
  }) {
    log("🚀 FlutterGraphqlClient initialized with endpoint: $graphQlEndPoint");
    if (webSocketUrl != null) log("🧩 WebSocket URL set: $webSocketUrl");
    if (token != null) log("🔐 Access Token initialized.");
  }

  factory FlutterGraphqlClient.init({
    required String graphQlEndPoint,
    String? webSocketUrl,
    String? accessToken,
    Token? token,
    String? tokenExpiryErrorCode,
    Function(GraphQLService service)? onTokenRefreshFailed,
    required Future<Token?> Function(
      String refreshToken,
      GraphQLService service,
    )
    refreshTokenHandler,
  }) {
    _instance ??= FlutterGraphqlClient._internal(
      graphQlEndPoint: graphQlEndPoint,
      webSocketUrl: webSocketUrl,
      token: token,
      tokenExpiryErrorCode: tokenExpiryErrorCode,
      refreshTokenHandler: refreshTokenHandler,
      onTokenRefreshFailed: onTokenRefreshFailed,
    );
    _instance!.graphQLService = GraphQLService();
    _instance!.graphQLService!.initializeClient();
    return _instance!;
  }

  static FlutterGraphqlClient get instance {
    if (_instance == null) {
      throw Exception(
        "FlutterGraphqlClient is not initialized. Call init(...) first.",
      );
    }
    return _instance!;
  }

  void updateAccessToken(String token) {
    log("🔄 Updating Access Token...");
    if (this.token == null) {
      this.token = Token(accessToken: token, refreshToken: "");
    } else {
      this.token = this.token!.copyWith(accessToken: token);
    }

    graphQLService!.initializeClient();
  }

  void updateRefreshToken(String token) {
    log("🔄 Updating Refresh Token...");
    if (this.token == null) {
      this.token = Token(accessToken: "", refreshToken: token);
    } else {
      this.token = this.token!.copyWith(refreshToken: token);
    }

    graphQLService!.initializeClient();
  }
}
