class WalletInfo {
  final String walletId;
  final String address;
  final String pubkey;
  final String network;

  WalletInfo({
    this.walletId = '',
    required this.address,
    this.pubkey = '',
    this.network = 'regtest',
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      walletId: json['wallet_id']?.toString() ?? '',
      address: json['address'] as String,
      pubkey: json['pubkey'] as String,
      network: json['network']?.toString() ?? 'regtest',
    );
  }
}
