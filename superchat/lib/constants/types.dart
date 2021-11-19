typedef ChatItemViewCallback = void Function(String);

enum LoginType {
  rocketChatToken,
  rocketChatUserId,
  google,
  facebook,
}