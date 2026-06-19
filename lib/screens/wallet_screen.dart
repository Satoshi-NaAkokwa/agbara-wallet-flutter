import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../providers/api_provider.dart';
import '../models/wallet.dart';

final walletProvider = StateProvider<WalletInfo?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorProvider = StateProvider<String?>((ref) => null);
final mnemonicProvider = StateProvider<String?>((ref) => null);
final balanceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final txsProvider = StateProvider<List<dynamic>>((ref) => []);

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final mnemonic = ref.watch(mnemonicProvider);
    final balance = ref.watch(balanceProvider);
    final txs = ref.watch(txsProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);

    return RefreshIndicator(
      onRefresh: () => _refreshWallet(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Wallet', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (wallet == null) ...[
              _buildOnboardingCard(context, ref, isLoading),
            ] else ...[
              _buildAddressCard(context, wallet, mnemonic),
              const SizedBox(height: 16),
              _buildBalanceCard(context, balance),
              const SizedBox(height: 16),
              _buildActionRow(context, ref, wallet),
              const SizedBox(height: 16),
              _buildTxHistory(context, txs),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(BuildContext context, WidgetRef ref, bool isLoading) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('No Wallet Yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Create a new Liquid wallet or restore from mnemonic.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _createWallet(ref),
              icon: isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: const Text('Create Wallet'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isLoading ? null : () => _showRestoreDialog(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Mnemonic'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, WalletInfo wallet, String? mnemonic) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Receive Address', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                data: wallet.address,
                version: QrVersions.auto,
                size: 180.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(wallet.address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  const SizedBox(height: 4),
                  if (mnemonic != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mnemonic: ${mnemonic.split(' ').take(3).join(' ')}...',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: mnemonic));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mnemonic copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy mnemonic',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: wallet.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri(scheme: 'bitcoin', path: wallet.address);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, Map<String, dynamic>? balance) {
    final btc = balance?['btc']?.toString() ?? balance?['lbtc']?.toString() ?? '—';
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Balance', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(btc, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('LBTC', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text('Tap refresh to update', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref, WalletInfo wallet) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSendSheet(context, ref, wallet),
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showScanSheet(context, ref, wallet),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildTxHistory(BuildContext context, List<dynamic> txs) {
    if (txs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Text('No transactions yet', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...txs.map((tx) {
          final direction = tx['direction'] ?? 'receive';
          final amount = tx['amount']?.toString() ?? '0';
          final asset = tx['asset'] ?? 'LBTC';
          return Card(
            child: ListTile(
              leading: Icon(direction == 'send' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: direction == 'send' ? Colors.red : Colors.green),
              title: Text('$amount $asset'),
              subtitle: Text(tx['txid']?.toString().substring(0, 16) ?? '...'),
              trailing: Text(tx['status'] ?? 'confirmed'),
            ),
          );
        }).toList(),
      ],
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
      ref.read(mnemonicProvider.notifier).state = mnemonic;
      await _refreshWallet(ref);
    } catch (e) {
      ref.read(errorProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _refreshWallet(WidgetRef ref) async {
    final wallet = ref.read(walletProvider);
    if (wallet == null) return;
    final client = ref.read(apiClientProvider);
    try {
      final bal = await client.getBalance(wallet.address);
      ref.read(balanceProvider.notifier).state = bal;
    } catch (_) {
      ref.read(balanceProvider.notifier).state = {'lbtc': '0.00000000'};
    }
    try {
      final txs = await client.getTransactions(wallet.address);
      ref.read(txsProvider.notifier).state = txs;
    } catch (_) {
      ref.read(txsProvider.notifier).state = [];
    }
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Wallet'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'BIP-39 Mnemonic (12 or 24 words)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ref.read(isLoadingProvider.notifier).state = true;
              ref.read(errorProvider.notifier).state = null;
              try {
                final client = ref.read(apiClientProvider);
                final wallet = await client.createWallet(ctrl.text.trim(), '');
                ref.read(walletProvider.notifier).state = wallet;
                ref.read(mnemonicProvider.notifier).state = ctrl.text.trim();
                await _refreshWallet(ref);
              } catch (e) {
                ref.read(errorProvider.notifier).state = e.toString();
              } finally {
                ref.read(isLoadingProvider.notifier).state = false;
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showSendSheet(BuildContext context, WidgetRef ref, WalletInfo wallet) {
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final assetCtrl = TextEditingController(text: '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381e526d'); // L-BTC asset ID on Liquid
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Send Asset', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Recipient Address')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (satoshis)'), keyboardType: TextInputType.number),
            TextField(controller: assetCtrl, decoration: const InputDecoration(labelText: 'Asset ID (default = L-BTC)')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                ref.read(isLoadingProvider.notifier).state = true;
                try {
                  final client = ref.read(apiClientProvider);
                  final txid = await client.sendAsset(
                    fromAddress: wallet.address,
                    toAddress: addrCtrl.text.trim(),
                    amount: int.tryParse(amtCtrl.text) ?? 0,
                    assetId: assetCtrl.text.trim(),
                    privateKeyWif: '', // daemon signs if custody is server-side; stub for client-side later
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast: $txid')));
                  await _refreshWallet(ref);
                } catch (e) {
                  ref.read(errorProvider.notifier).state = e.toString();
                } finally {
                  ref.read(isLoadingProvider.notifier).state = false;
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Broadcast'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showScanSheet(BuildContext context, WidgetRef ref, WalletInfo wallet) {
    // Scanning can be added with mobile_scanner when the page is focused; kept simple here
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('QR scanner placeholder – wire mobile_scanner for camera scan'),
          ],
        ),
      ),
    );
  }
}
