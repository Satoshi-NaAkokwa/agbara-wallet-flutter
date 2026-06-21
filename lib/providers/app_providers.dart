import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../services/api_client.dart';
import '../services/wallet_storage.dart';

/// Dark mode toggle (shared across all screens)
final darkModeProvider = StateProvider<bool>((ref) => false);

/// Wallet info (auto-loaded from encrypted storage on startup)
final walletProvider = StateProvider<WalletInfo?>((ref) => null);

/// Mnemonic backup (auto-loaded from encrypted storage on startup)
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

/// Async provider to load persisted wallet on app startup
final persistedWalletProvider = FutureProvider<void>((ref) async {
  final wallet = await WalletStorage.loadWallet();
  final mnemonic = await WalletStorage.loadMnemonic();
  if (wallet != null && mnemonic != null) {
    ref.read(walletProvider.notifier).state = wallet;
    ref.read(mnemonicProvider.notifier).state = mnemonic;
    // Auto-refresh balance
    try {
      final client = ref.read(apiClientProvider);
      final bal = await client.getBalance(wallet.address);
      ref.read(balanceProvider.notifier).state = bal;
    } catch (_) {}
  }
});
