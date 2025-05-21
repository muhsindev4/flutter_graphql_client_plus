
## 2.0.5
- Debugger tool improvements
## 2.0.4
- Debugger tool improvements

## 2.0.3
- Patch work

## 2.0.2
- Patch work


## 2.0.1
- Patch work

## 2.0.0
### Added
- Added debugging tool

## 1.0.11
### Added
- Added time log for request tracking.

### Fixed
- Missing subscription cleanup: ensured `StreamSubscription` is exposed and can be canceled to prevent memory leaks.
- Improved lifecycle management for subscriptions.
- Changed architecture


## 1.0.10
- added `updateWebSocketUrl` function

## 1.0.9
- Patch work

## 1.0.8
- Added log for `FetchPolicy.noCache`
## 1.0.7
- Added `FetchPolicy.noCache`
## 1.0.6
- Patch work
## 1.0.5
- Patch work

## 1.0.4
- Patch work

## 1.0.3

### Changed
- Refactored and structured `FlutterGraphqlClient` and `GraphQLService` for better modularity and initialization.
- Improved logging with emojis for better developer clarity and debugging.

### Added
- Request cancellation and resumption support using `_isCancelled` flag in `GraphQLService`.
- `cancelAllRequests()` and `resumeRequests()` methods to handle request flow programmatically.
- `GraphQLService` now allows pausing and resuming request execution with clear logs.

### Fixed
- Ensured stability by guarding against uninitialized access to singleton instance.
- Fixed issue where `initializeClient()` did not reinitialize after token update.


## 1.0.1

### Added
- Prevent multiple simultaneous token refresh calls using `Completer` lock mechanism.
- Ensured only one request triggers refresh while others wait, improving stability and reducing redundant API calls.

## 0.0.1

* Initial release with:
    - GraphQL client setup using `graphql_flutter`.
    - ActionCable WebSocket support for subscriptions.
    - Centralized query, mutation, and subscription methods.
    - Automatic token refresh handling for expired tokens.
