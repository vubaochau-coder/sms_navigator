/// Chế độ white-list của máy gửi — đồng bộ với `WhitelistMode` phía native.
enum WhitelistMode {
  explicit('EXPLICIT'),
  allAddresses('ALL_ADDRESSES');

  const WhitelistMode(this.nativeName);

  final String nativeName;

  static WhitelistMode fromName(String? name) =>
      WhitelistMode.values.firstWhere(
        (mode) => mode.nativeName == name,
        orElse: () => WhitelistMode.explicit,
      );
}
