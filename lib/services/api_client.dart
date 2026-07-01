import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiClient {
  static const String _defaultDaemonBase = 'https://wallet.ugogbe.info/daemon/v1';
  static const String _defaultApiBase = 'https://wallet.ugogbe.info/api/v1';
  static const String _apiKey = 'ejemma_dev_key_2026';

  final String baseUrl;
  final String apiBaseUrl;

  ApiClient({String? baseUrl, String? apiBaseUrl})
      : baseUrl = baseUrl ?? _defaultDaemonBase,
        apiBaseUrl = apiBaseUrl ?? _defaultApiBase;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  Future<WalletInfo> createWallet(String mnemonic, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet'),
      headers: _headers,
      body: jsonEncode({'mnemonic': mnemonic, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return WalletInfo.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getBalance(String address) async {
    final response = await http.get(
      Uri.parse('$baseUrl/balance/$address'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('balance fetch failed: ${response.statusCode}');
    }
  }

  Future<String> sendAsset({
    required String fromAddress,
    required String toAddress,
    required int amount,
    required String assetId,
    String? memo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send'),
      headers: _headers,
      body: jsonEncode({
        'from_address': fromAddress,
        'to_address': toAddress,
        'amount': amount,
        'asset_id': assetId,
        if (memo != null && memo.isNotEmpty) 'memo': memo,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['txid'] as String? ?? body['hash'] as String? ?? 'unknown';
    } else {
      throw ApiException('send failed: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions(String address) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$address'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body);
      if (list is List) return list.cast<Map<String, dynamic>>();
      return [];
    } else {
      throw ApiException('tx fetch failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> issueAsset({
    required String ticker,
    required int precision,
    required int initialSupply,
    String? domain,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/factory/assets'),
      headers: _headers,
      body: jsonEncode({
        'ticker': ticker,
        'precision': precision,
        'initialSupply': initialSupply,
        if (domain != null) 'domain': domain,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('${response.statusCode}: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> listAssets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/factory/assets'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body.containsKey('assets')) {
        final list = body['assets'];
        if (list is List) return list.cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw ApiException('asset list failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> health() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/health'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('health check failed: ${response.statusCode}');
    }
  }

  Future<int> estimateFee(String presetName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fee-estimate/$presetName'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['fee_rate_sats_per_byte'] ?? body['fee'] ?? 3).toInt();
    }
    // Fallback defaults
    final fallback = {'save': 1, 'standard': 3, 'express': 10};
    return fallback[presetName.toLowerCase()] ?? 3;
  }
}
