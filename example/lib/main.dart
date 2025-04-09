import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_graphql_client_plus/flutter_graphql_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the client
  FlutterGraphqlClient.init(
    graphQlEndPoint: "https://your-api.com/graphql",
    webSocketUrl: "wss://your-api.com/cable",
    tokenExpiryErrorCode: "TOKEN_EXPIRED",
    token: Token(
      accessToken: "initialAccessToken",
      refreshToken: "initialRefreshToken",
    ),
    refreshTokenHandler: (refreshToken, service) async {
      // Return new tokens (simulate network call)
      await Future.delayed(Duration(seconds: 1));
      return Token(
        accessToken: "newAccessToken",
        refreshToken: "newRefreshToken",
      );
    },
    onTokenRefreshFailed: (GraphQLService service) {
      service.cancelAllRequests();
      service.resumeRequests();
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GraphQLService client = FlutterGraphqlClient.instance.graphQLService!;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraphQL Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('GraphQL Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: _performQuery,
            child: Text('Run Query'),
          ),
        ),
      ),
    );
  }

  void _performQuery() async {
    final response = await client.query('''
      query {
        user {
          id
          name
        }
      }
      ''');

    if (response.error != null) {
      log("Error: ${response.error!.message}");
    } else {
      log("User: ${response.data}");
    }
  }
}
