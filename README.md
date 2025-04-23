
# 🚀 flutter_graphql_client_plus

A simple, extendable GraphQL client for Flutter applications with support for authentication, token refreshing, and ActionCable-based subscriptions (ideal for Rails backends).

## ✨ Features

- Execute GraphQL **queries**, **mutations**, and **subscriptions**
- Built-in **token-based authentication**
- Auto **refresh expired tokens**
- Support for **Rails ActionCable** WebSocket subscriptions
- Simple and clean API
- Retry Mechanism
- 🧪 Debugging Tool Support (New!)

---

## 🧪 Debugging Tool Support (New!)

We now support live debugging of your GraphQL requests with the Flutter GraphQL Plus Tool.

When enabled, this tool creates a WebSocket debug server that logs all GraphQL queries, mutations, and subscriptions sent from your app — helping you visualize and debug real-time traffic.

### 🔌 Usage with Debug Tool
Clone and run the debug tool app locally or on your desired machine.
The tool creates a WebSocket server (e.g., ws://152.162.57.112:4040).
Point your Flutter app to the debug tool using the debugWebSocketUrl:

      FlutterGraphqlClient.init(
      graphQlEndPoint: Const.graphQlEndPoint,
      debugWebSocketUrl: "ws://152.162.57.112:4040", // 👈 Debug server
      tokenExpiryErrorCode: "UNAUTHENTICATED",
      token: Token(accessToken: "your_token", refreshToken: "your_refresh_token"),
      refreshTokenHandler: (refreshToken, GraphQLService service) {
        return authController.generateToken(service: service);
      },
    );
Once set up, every GraphQL request from your app will be logged in real-time inside the debug tool app.

✅ Ideal for inspecting queries, tracking headers, responses, and debugging token issues.


## 🛠 Installation

Add the package to your `pubspec.yaml`:


    dependencies:
      flutter_graphql_client_plus: ^latest 



## 🔧 Setup

### Initialize the Client

    FlutterGraphqlClient.init(
      graphQlEndPoint: "https://your-api.com/graphql",
      webSocketUrl: "wss://your-api.com/cable",
      tokenExpiryErrorCode: "TOKEN_EXPIRED", // your backend's token expiry code
      token: Token(accessToken: "abc", refreshToken: "xyz"),
      refreshTokenHandler: (refreshToken) async {
        // Call your refresh API here and return a new Token
        return Token(accessToken: "newAccessToken", refreshToken: "newRefreshToken");
      },
    );


## ✅ Usage

### Query

    final response = await FlutterGraphqlClient.instance.graphQLService!.query(
      '''
      query GetUser {
        user {
          id
          name
        }
      }
      ''',
    );


### Mutation

    final response = await FlutterGraphqlClient.instance.graphQLService!.mutate(
      '''
      mutation UpdateUser(\$id: ID!, \$name: String!) {
        updateUser(id: \$id, name: \$name) {
          id
          name
        }
      }
      ''',
      variables: {
        'id': '123',
        'name': 'New Name',
      },
    );

### Subscription

    FlutterGraphqlClient.instance.graphQLService!.subscribe(
      '''
      subscription OnUserUpdated {
        userUpdated {
          id
          name
        }
      }
      ''',
    ).listen((result) {
      print(result.data);
    });

##  🧪 Token Management

    FlutterGraphqlClient.instance.updateAccessToken("new_access_token");
    FlutterGraphqlClient.instance.updateRefreshToken("new_refresh_token");

##  💥 Error Handling
Errors are wrapped in a `ResponseModel`, which contains:

    class ResponseModel {
      final dynamic data;
      final ErrorModel? error;
    }

You can access error messages and codes like this:

    if (response.error != null) {
      print(response.error!.message);
    }
## 📡 ActionCable Subscriptions

This client supports Rails ActionCable subscriptions via  `ActionCableLink`. You can customize:

-   Channel name

-   Authentication headers

-   Retry duration


By default:

-   Channel:  `GraphqlChannel`

-   Action:  `execute`

-   Auth Header:  `Authorization: Bearer <token>`

de or point to information on how to
start using the package.

