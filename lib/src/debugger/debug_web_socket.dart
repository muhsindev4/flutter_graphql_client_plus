import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/io.dart';
import '../models/graphql_request_log.dart';

class DebugWebSocket {
  static final DebugWebSocket _instance = DebugWebSocket._internal();

  factory DebugWebSocket() => _instance;

  DebugWebSocket._internal();

  IOWebSocketChannel? _channel;

  void connect([String url = "ws://localhost:4040"]) {
    try {
      _channel = IOWebSocketChannel.connect(url);
      log("🔌 Connected to Debug WebSocket at $url");
    } catch (e) {
      log("❌ Debug WebSocket connect error: $e");
    }
  }

  void sendRequestInfo(GraphQLRequestLog data) {
    try {
      if (_channel == null ) {
        log("🚫 Cannot send: Debug WebSocket is not connected.");
        return;
      }
      final payload = jsonEncode(data.toJson());
      _channel?.sink.add(payload);
      log("📤 Sent GraphQL request log: $payload");
    } catch (e) {
      log("⚠️ Debug Debug WebSocket send error: $e");
    }
  }

  void dispose() {
    try {
      if (_channel == null ) {
        log("🚫 Cannot dispose: Debug WebSocket is not connected.");
        return;
      }
      _channel?.sink.close();
      log("🔌 Debug WebSocket connection closed.");
    } catch (e) {
      log("⚠️ Error while closing Debug WebSocket: $e");
    }
  }
}
