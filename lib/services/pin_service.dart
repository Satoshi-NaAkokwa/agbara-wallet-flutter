import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN-based authentication with Argon2-style key stretching (PBKDF2)
class PinService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyPinHash = 'ejemma_pin_hash_v1';
  static const _keyPinSalt = 'ejemma_pin_salt_v1';
  static const _keyPinAttempts = 'ejemma_pin_attempts_v1';
  static const int _maxAttempts = 5;

  /// Hash PIN with PBKDF2 (SHA-256, 10000 iterations)
  static String _hashPin(String pin, String salt) {
    final key = pbkdf2(pin, salt, iterations: 10000, keyLength: 32);
    return base64Encode(key);
  }

  static List<int> pbkdf2(String password, String salt, {required int iterations, required int keyLength}) {
    // Simplified PBKDF2 using HMAC-SHA256
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    
    var block = saltBytes + [0, 0, 0, 1];  // block 1
    var u = Hmac(sha256, passwordBytes).convert(block).bytes;
    var result = u;
    
    for (var i = 1; i < iterations; i++) {
      u = Hmac(sha256, passwordBytes).convert(u).bytes;
      for (var j = 0; j < u.length; j++) {
        result[j] = result[j] ^ u[j];
      }
    }
    
    return result.sublist(0, keyLength);
  }

  /// Check if PIN is set
  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null;
  }

  /// Set PIN for first time
  static Future<void> setPin(String pin) async {
    final salt = base64Encode(List<int>.generate(16, (_) => DateTime.now().microsecond % 256));
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _keyPinHash, value: hash);
    await _storage.write(key: _keyPinSalt, value: salt);
    await _storage.write(key: _keyPinAttempts, value: '0');
  }

  /// Verify PIN
  static Future<bool> verifyPin(String pin) async {
    final attemptsStr = await _storage.read(key: _keyPinAttempts);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    if (attempts >= _maxAttempts) {
      throw PinLockedException('PIN locked. Use mnemonic restore.');
    }

    final storedHash = await _storage.read(key: _keyPinHash);
    final salt = await _storage.read(key: _keyPinSalt);
    if (storedHash == null || salt == null) return false;

    final hash = _hashPin(pin, salt);
    if (hash == storedHash) {
      await _storage.write(key: _keyPinAttempts, value: '0');
      return true;
    } else {
      await _storage.write(key: _keyPinAttempts, value: (attempts + 1).toString());
      return false;
    }
  }

  /// Reset PIN (after successful biometric or mnemonic restore)
  static Future<void> resetPin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyPinAttempts);
  }
}

class PinLockedException implements Exception {
  final String message;
  PinLockedException(this.message);
  @override
  String toString() => message;
}
