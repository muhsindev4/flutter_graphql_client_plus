import 'dart:developer';
import 'package:flutter_graphql_client_plus/src/models/token.dart';
import '../debugger/debug_web_socket.dart';
import 'request_service.dart';

class FlutterGraphqlClient {
  final String graphQlEndPoint;
  String? webSocketUrl;
  String? debugWebSocketUrl;
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
    this.debugWebSocketUrl,
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
    String? debugWebSocketUrl,
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
      debugWebSocketUrl: debugWebSocketUrl,
      token: token,
      tokenExpiryErrorCode: tokenExpiryErrorCode,
      refreshTokenHandler: refreshTokenHandler,
      onTokenRefreshFailed: onTokenRefreshFailed,
    );
    _instance!.graphQLService = GraphQLService();
    _instance!.graphQLService!.initializeClient();

    if (debugWebSocketUrl != null) {
      DebugWebSocket().connect(debugWebSocketUrl);
    }

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

  void updateWebSocketUrl(String webSocketUrl) {
    this.webSocketUrl = webSocketUrl;
    graphQLService!.initializeClient();
  }
}
