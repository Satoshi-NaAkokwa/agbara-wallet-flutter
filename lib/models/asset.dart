class IssuedAsset {
  final String assetId;
  final String txid;

  IssuedAsset({required this.assetId, required this.txid});

  factory IssuedAsset.fromJson(Map<String, dynamic> json) {
    return IssuedAsset(
      assetId: json['asset_id'] as String,
      txid: json['txid'] as String,
    );
  }
}
