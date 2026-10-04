enum ChannelRole {
  owner,
  member;

  bool get isOwner => this == ChannelRole.owner;
  bool get isMember => this == ChannelRole.member;

  static ChannelRole fromString(String? role) {
    if (role == 'owner') return ChannelRole.owner;
    return ChannelRole.member;
  }
}
