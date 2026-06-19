class WalletInfo {
  final String address;
  final String pubkey;

  WalletInfo({required this.address, required this.pubkey});

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      address: json['address'] as String,
      pubkey: json['pubkey'] as String,
    );
  }
}
