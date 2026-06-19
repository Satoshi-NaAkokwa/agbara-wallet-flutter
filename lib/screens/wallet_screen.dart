import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../providers/api_provider.dart';
import '../models/wallet.dart';

final walletProvider = StateProvider<WalletInfo?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorProvider = StateProvider<String?>((ref) => null);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Wallet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (wallet == null)
            ElevatedButton(
              onPressed: isLoading ? null : () => _createWallet(ref),
              child: isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Liquid Wallet'),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Address', style: Theme.of(context).textTheme.titleMedium),
                    SelectableText(wallet.address),
                    const SizedBox(height: 8),
                    Text('Public Key', style: Theme.of(context).textTheme.titleMedium),
                    SelectableText(wallet.pubkey),
                  ],
                ),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Future<void> _createWallet(WidgetRef ref) async {
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;

    try {
      final mnemonic = bip39.generateMnemonic(strength: 128);
      final client = ref.read(apiClientProvider);
      final wallet = await client.createWallet(mnemonic, '');
      ref.read(walletProvider.notifier).state = wallet;
    } catch (e) {
      ref.read(errorProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
