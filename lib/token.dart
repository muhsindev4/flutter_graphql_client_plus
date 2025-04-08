class Token {
  String accessToken;
  String refreshToken;

  Token({required this.accessToken, required this.refreshToken});

  Token copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return Token(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
