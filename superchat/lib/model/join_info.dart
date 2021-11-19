class JoinInfo {
  String inviteToken;
  String joinCode;

  JoinInfo(this.inviteToken, this.joinCode);

  @override
  String toString() {
    return 'inViteToken: $inviteToken, joinCode: $joinCode';
  }
}