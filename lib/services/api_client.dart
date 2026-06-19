import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';
import '../models/asset.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiClient {
  static const String _defaultDaemonBase = 'https://wallet.ugogbe.info/daemon/v1';
  static const String _defaultApiBase = 'https://wallet.ugogbe.info/api/v1';

  final String baseUrl;
  final String apiBaseUrl;

  ApiClient({String? baseUrl, String? apiBaseUrl})
      : baseUrl = baseUrl ?? _defaultDaemonBase,
        apiBaseUrl = apiBaseUrl ?? _defaultApiBase;

  Future<WalletInfo> createWallet(String mnemonic, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet'),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
    required String privateKeyWif,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'from_address': fromAddress,
        'to_address': toAddress,
        'amount': amount,
        'asset_id': assetId,
        'private_key_wif': privateKeyWif,
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
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body);
      if (list is List) return list.cast<Map<String, dynamic>>();
      return [];
    } else {
      throw ApiException('tx fetch failed: ${response.statusCode}');
    }
  }

  Future<IssuedAsset> issueAsset({
    required String ticker,
    required int precision,
    required int initialSupply,
    String? domain,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/factory/assets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ticker': ticker,
        'precision': precision,
        'initial_supply': initialSupply,
        if (domain != null) 'domain': domain,
      }),
    );

    if (response.statusCode == 200) {
      return IssuedAsset.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('${response.statusCode}: ${response.body}');
    }
  }

  Future<String> health() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/health'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ApiException('health check failed: ${response.statusCode}');
    }
  }
}
