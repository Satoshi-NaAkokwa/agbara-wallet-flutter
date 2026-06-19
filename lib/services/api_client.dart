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
  final String baseUrl;
  ApiClient({this.baseUrl = 'http://localhost:4000/api/v1'});

  Future<WalletInfo> createWallet(String mnemonic, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mnemonic': mnemonic, 'password': password}),
    );

    if (response.statusCode == 200) {
      return WalletInfo.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('${response.statusCode}: ${response.body}');
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
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ApiException('health check failed: ${response.statusCode}');
    }
  }
}
