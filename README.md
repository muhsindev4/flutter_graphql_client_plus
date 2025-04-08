<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provi
# 🚀 flutter_graphql_client

A simple, extendable GraphQL client for Flutter applications with support for authentication, token refreshing, and ActionCable-based subscriptions (ideal for Rails backends).

## ✨ Features

- Execute GraphQL **queries**, **mutations**, and **subscriptions**
- Built-in **token-based authentication**
- Auto **refresh expired tokens**
- Support for **Rails ActionCable** WebSocket subscriptions
- Simple and clean API

---

## 🛠 Installation

Add the package to your `pubspec.yaml`:


    dependencies:
      flutter_graphql_client: ^latest 



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

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
