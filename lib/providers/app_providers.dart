import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../services/api_client.dart';

/// Dark mode toggle (shared across all screens)
final darkModeProvider = StateProvider<bool>((ref) => false);

/// Wallet info (shared across wallet/settings screens)
final walletProvider = StateProvider<WalletInfo?>((ref) => null);

/// Mnemonic backup (shared across wallet/settings screens)
final mnemonicProvider = StateProvider<String?>((ref) => null);

/// Loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error message display
final errorProvider = StateProvider<String?>((ref) => null);

/// Balance cache
final balanceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Transaction history
final txsProvider = StateProvider<List<dynamic>>((ref) => []);

/// API client singleton
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
