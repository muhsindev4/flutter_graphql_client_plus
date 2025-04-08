import 'package:flutter/material.dart';
import 'package:flutter_graphql_client/flutter_graphql_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the client
  FlutterGraphqlClient.init(
    graphQlEndPoint: "https://your-api.com/graphql",
    webSocketUrl: "wss://your-api.com/cable",
    tokenExpiryErrorCode: "TOKEN_EXPIRED",
    token: Token(accessToken: "initialAccessToken", refreshToken: "initialRefreshToken"),
    refreshTokenHandler: (refreshToken) async {
      // Call refresh token API here
      print("Refreshing token with: $refreshToken");

      // Return new tokens (simulate network call)
      await Future.delayed(Duration(seconds: 1));
      return Token(accessToken: "newAccessToken", refreshToken: "newRefreshToken");
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GraphQLService client = FlutterGraphqlClient.instance.graphQLService!;

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
    final response = await client.query(
      '''
      query {
        user {
          id
          name
        }
      }
      ''',
    );

    if (response.error != null) {
      print("Error: ${response.error!.message}");
    } else {
      print("User: ${response.data}");
    }
  }
}
