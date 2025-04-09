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
