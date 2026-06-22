/// Multi-asset model with branding-neutral terminology
class Asset {
  final String id;              // Hex asset ID or "native" for L-BTC
  final String symbol;            // Display symbol (e.g., "₿", "₵")
  final String name;              // Human-readable name
  final int precision;            // Decimal places (8 for BTC, 0 for EJM)
  final String? iconUrl;          // Remote or local icon
  final bool isNative;            // True for Bitcoin/L-BTC
  final bool isUserIssued;        // True for factory assets
  final String? domain;           // Issuance domain for verification
  final BigInt balanceSats;       // Raw balance in satoshi units

  Asset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.precision,
    this.iconUrl,
    this.isNative = false,
    this.isUserIssued = false,
    this.domain,
    BigInt? balanceSats,
  }) : balanceSats = balanceSats ?? BigInt.zero;

  /// Format balance for display with proper decimal places
  String displayBalance() {
    if (precision == 0) return balanceSats.toString();
    final divisor = BigInt.from(10).pow(precision);
    final whole = balanceSats ~/ divisor;
    final fraction = balanceSats % divisor;
    final fractionStr = fraction.toString().padLeft(precision, '0');
    // Trim trailing zeros
    final trimmed = fractionStr.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return whole.toString();
    return '$whole.$trimmed';
  }

  /// Short balance for card display
  String shortBalance() {
    final bal = displayBalance();
    if (bal.length <= 12) return bal;
    return '${bal.substring(0, 10)}...';
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] ?? json['asset_id'] ?? '',
      symbol: json['symbol'] ?? json['ticker'] ?? '',
      name: json['name'] ?? json['ticker'] ?? 'Unknown',
      precision: json['precision'] ?? 8,
      iconUrl: json['icon_url'],
      isNative: json['is_native'] ?? false,
      isUserIssued: json['is_user_issued'] ?? false,
      domain: json['domain'],
      balanceSats: BigInt.parse(json['balance_sats']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'precision': precision,
    'icon_url': iconUrl,
    'is_native': isNative,
    'is_user_issued': isUserIssued,
    'domain': domain,
    'balance_sats': balanceSats.toString(),
  };
}

/// Pre-defined native assets
class NativeAssets {
  static Asset bitcoin() => Asset(
    id: 'native',
    symbol: '₿',
    name: 'Bitcoin',
    precision: 8,
    isNative: true,
    iconUrl: null, // Uses default Bitcoin icon
  );

  static Asset ejemma() => Asset(
    id: 'EJM', // Will be replaced with actual hex on load
    symbol: '₵',
    name: 'EJEMMA',
    precision: 0,
    isUserIssued: true,
    iconUrl: 'assets/images/ejm_symbol.png',
  );
}

/// Fee estimation presets
enum FeePreset { save, standard, express }

extension FeePresetExtension on FeePreset {
  String get label {
    switch (this) {
      case FeePreset.save: return 'Save';
      case FeePreset.standard: return 'Standard';
      case FeePreset.express: return 'Express';
    }
  }

  String get description {
    switch (this) {
      case FeePreset.save: return '~10 min';
      case FeePreset.standard: return '~3 min';
      case FeePreset.express: return '~1 min';
    }
  }

  int get targetBlocks {
    switch (this) {
      case FeePreset.save: return 6;
      case FeePreset.standard: return 3;
      case FeePreset.express: return 1;
    }
  }
}
