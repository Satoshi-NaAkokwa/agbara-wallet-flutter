import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/wallet.dart';

/// Encrypted wallet persistence using AES-256 (hardware-backed on Android 6+)
class WalletStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  static const _keyWallet = 'ejemma_wallet_v1';
  static const _keyMnemonic = 'ejemma_mnemonic_v1';
  static const _keyBiometric = 'ejemma_biometric_enabled';

  /// Save wallet + mnemonic to encrypted storage
  static Future<void> saveWallet(WalletInfo wallet, String mnemonic) async {
    final walletJson = jsonEncode({
      'wallet_id': wallet.walletId,
      'address': wallet.address,
      'pubkey': wallet.pubkey,
      'network': wallet.network,
    });
    await _storage.write(key: _keyWallet, value: walletJson);
    await _storage.write(key: _keyMnemonic, value: mnemonic);
  }

  /// Load wallet from encrypted storage (returns null if not found)
  static Future<WalletInfo?> loadWallet() async {
    final walletJson = await _storage.read(key: _keyWallet);
    if (walletJson == null) return null;
    try {
      final map = jsonDecode(walletJson) as Map<String, dynamic>;
      return WalletInfo(
        walletId: map['wallet_id'] ?? '',
        address: map['address'] ?? '',
        pubkey: map['pubkey'] ?? '',
        network: map['network'] ?? 'regtest',
      );
    } catch (_) {
      return null;
    }
  }

  /// Load mnemonic from encrypted storage
  static Future<String?> loadMnemonic() async {
    return await _storage.read(key: _keyMnemonic);
  }

  /// Persist biometric unlock preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometric, value: enabled ? '1' : '0');
  }

  /// Read biometric unlock preference
  static Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _keyBiometric);
    return v == '1';
  }

  /// Clear all wallet data (erase)
  static Future<void> clear() async {
    await _storage.delete(key: _keyWallet);
    await _storage.delete(key: _keyMnemonic);
    await _storage.delete(key: _keyBiometric);
  }

  /// Check if a wallet exists in storage
  static Future<bool> hasWallet() async {
    final w = await _storage.read(key: _keyWallet);
    return w != null;
  }
}
