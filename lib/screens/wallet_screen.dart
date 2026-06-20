import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/app_providers.dart';
import '../models/wallet.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('EJEMMA Wallet'),
        centerTitle: true,
        actions: [
          if (wallet != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshWallet(ref),
              tooltip: 'Refresh balance',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshWallet(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wallet == null) ...[
                _buildOnboardingCard(context, ref, isLoading),
              ] else ...[
                _buildPrimaryBalanceCard(context, balance),
                const SizedBox(height: 16),
                _buildReceiveCard(context, wallet, mnemonic),
                const SizedBox(height: 16),
                _buildActionRow(context, ref, wallet),
                const SizedBox(height: 16),
                _buildAssetBreakdown(context, balance),
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
              const SizedBox(height: 40),
              // EJEMMA branding
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.currency_exchange, size: 24, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'EJEMMA • EJM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Biafran Government in Exile — Official Currency',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Onboarding ───
  Widget _buildOnboardingCard(BuildContext context, WidgetRef ref, bool isLoading) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Welcome to EJEMMA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The official currency of the Biafran Government in Exile.\nSend remittances, receive payments, and manage your EJM assets securely.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _createWallet(ref),
              icon: isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: const Text('Create New Wallet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : () => _showRestoreDialog(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Mnemonic'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'By creating a wallet you agree to keep your mnemonic safe. EJEMMA cannot recover lost seeds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Primary Balance (EJM) ───
  Widget _buildPrimaryBalanceCard(BuildContext context, Map<String, dynamic>? balance) {
    final ejmBalance = _extractEjmBalance(balance);
    final secondary = _extractSecondaryBalances(balance);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.currency_exchange,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Balance', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    Text('EJEMMA (EJM)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ejmBalance,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'EJM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (secondary.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text('Other Assets', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: secondary.map((asset) {
                  return Chip(
                    avatar: Icon(Icons.token, size: 14, color: Theme.of(context).colorScheme.primary),
                    label: Text('${asset['amount']} ${asset['ticker']}', style: const TextStyle(fontSize: 11)),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Receive Address ───
  Widget _buildReceiveCard(BuildContext context, WalletInfo wallet, String? mnemonic) {
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: wallet.address,
                  version: QrVersions.auto,
                  size: 160.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    wallet.address,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  if (mnemonic != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seed: ${mnemonic.split(' ').take(3).join(' ')} ...',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: mnemonic));
                            // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mnemonic copied')),
                            );
                          },
                          tooltip: 'Copy mnemonic',
                        ),
                      ],
                    ),
                  ],
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
                    // ignore: use_build_context_synchronously
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

  // ─── Action Row ───
  Widget _buildActionRow(BuildContext context, WidgetRef ref, WalletInfo wallet) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSendSheet(context, ref, wallet),
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showScanSheet(context, ref, wallet),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Asset Breakdown ───
  Widget _buildAssetBreakdown(BuildContext context, Map<String, dynamic>? balance) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets on Liquid', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.currency_exchange, color: Theme.of(context).colorScheme.primary),
              title: const Text('EJEMMA'),
              subtitle: const Text('Native Biafran currency'),
              trailing: Text(
                _extractEjmBalance(balance),
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(Icons.water_drop, color: Colors.blue[400]),
              title: const Text('Liquid Bitcoin'),
              subtitle: const Text('L-BTC (peg-in)'),
              trailing: Text(balance?['lbtc']?.toString() ?? '0.00000000 LBTC'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Transaction History ───
  Widget _buildTxHistory(BuildContext context, List<dynamic> txs) {
    if (txs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
          final asset = tx['asset'] ?? 'EJM';
          final isEjm = asset.toString().toLowerCase().contains('ejm') || asset.toString().toLowerCase().contains('ejemma');
          return Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: direction == 'send'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  direction == 'send' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: direction == 'send' ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              title: Text('$amount $asset', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx['txid']?.toString().substring(0, 16) ?? '...'),
              trailing: Text(
                tx['status'] ?? 'confirmed',
                style: TextStyle(
                  fontSize: 12,
                  color: isEjm ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Helpers ───
  String _extractEjmBalance(Map<String, dynamic>? balance) {
    if (balance == null) return '0.00000000';
    return balance['ejm']?.toString()
        ?? balance['EJM']?.toString()
        ?? balance['ejemma']?.toString()
        ?? balance['lbtc']?.toString()
        ?? '0.00000000';
  }

  List<Map<String, dynamic>> _extractSecondaryBalances(Map<String, dynamic>? balance) {
    if (balance == null) return [];
    final result = <Map<String, dynamic>>[];
    balance.forEach((key, value) {
      if (key != 'ejm' && key != 'EJM' && key != 'ejemma' && key != 'lbtc') {
        result.add({'ticker': key.toUpperCase(), 'amount': value.toString()});
      }
    });
    return result;
  }

  // ─── Wallet Creation ───
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
      ref.read(balanceProvider.notifier).state = {
        'ejm': '0.00000000',
        'lbtc': '0.00000000',
      };
    }
    try {
      final txs = await client.getTransactions(wallet.address);
      ref.read(txsProvider.notifier).state = txs;
    } catch (_) {
      ref.read(txsProvider.notifier).state = [];
    }
  }

  // ─── Restore Dialog ───
  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Wallet'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'BIP-39 Mnemonic (12 or 24 words)',
            hintText: 'word1 word2 word3 ...',
          ),
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
                final mnemonic = ctrl.text.trim();
                final wallet = await client.createWallet(mnemonic, '');
                ref.read(walletProvider.notifier).state = wallet;
                ref.read(mnemonicProvider.notifier).state = mnemonic;
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

  // ─── Send Sheet ───
  void _showSendSheet(BuildContext context, WidgetRef ref, WalletInfo wallet) {
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    String selectedAsset = 'EJM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Send Remittance', style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Send EJM or other Liquid assets to any address',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Address',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAsset,
                  decoration: const InputDecoration(
                    labelText: 'Asset',
                    prefixIcon: Icon(Icons.token),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'EJM', child: Text('EJEMMA (EJM)')),
                    DropdownMenuItem(value: 'LBTC', child: Text('Liquid Bitcoin (L-BTC)')),
                  ],
                  onChanged: (v) => setModalState(() => selectedAsset = v ?? 'EJM'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Memo (optional)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'e.g., Family remittance June',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ref.read(isLoadingProvider.notifier).state = true;
                    try {
                      final client = ref.read(apiClientProvider);
                      final assetId = selectedAsset == 'EJM'
                          ? '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381e526d' // L-BTC ID as default; daemon will resolve EJM
                          : '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381e526d';
                      final txid = await client.sendAsset(
                        fromAddress: wallet.address,
                        toAddress: addrCtrl.text.trim(),
                        amount: int.tryParse(amtCtrl.text) ?? 0,
                        assetId: assetId,
                        privateKeyWif: '',
                      );
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Remittance sent: $txid')),
                        );
                      }
                      await _refreshWallet(ref);
                    } catch (e) {
                      ref.read(errorProvider.notifier).state = e.toString();
                    } finally {
                      ref.read(isLoadingProvider.notifier).state = false;
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Broadcast Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── QR Scan Sheet (real mobile_scanner) ───
  void _showScanSheet(BuildContext context, WidgetRef ref, WalletInfo wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Scan QR Code', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final raw = barcode.rawValue;
                    if (raw != null && raw.isNotEmpty) {
                      Navigator.pop(ctx);
                      // Open send sheet pre-filled with scanned address
                      _showSendSheetWithAddress(context, ref, wallet, raw);
                      break;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendSheetWithAddress(BuildContext context, WidgetRef ref, WalletInfo wallet, String address) {
    final addrCtrl = TextEditingController(text: address);
    final amtCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    String selectedAsset = 'EJM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Send to Scanned Address', style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addrCtrl,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Address',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAsset,
                  decoration: const InputDecoration(
                    labelText: 'Asset',
                    prefixIcon: Icon(Icons.token),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'EJM', child: Text('EJEMMA (EJM)')),
                    DropdownMenuItem(value: 'LBTC', child: Text('Liquid Bitcoin (L-BTC)')),
                  ],
                  onChanged: (v) => setModalState(() => selectedAsset = v ?? 'EJM'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Memo (optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ref.read(isLoadingProvider.notifier).state = true;
                    try {
                      final client = ref.read(apiClientProvider);
                      final assetId = selectedAsset == 'EJM'
                          ? '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381e526d'
                          : '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381e526d';
                      final txid = await client.sendAsset(
                        fromAddress: wallet.address,
                        toAddress: addrCtrl.text.trim(),
                        amount: int.tryParse(amtCtrl.text) ?? 0,
                        assetId: assetId,
                        privateKeyWif: '',
                      );
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sent: $txid')),
                        );
                      }
                      await _refreshWallet(ref);
                    } catch (e) {
                      ref.read(errorProvider.notifier).state = e.toString();
                    } finally {
                      ref.read(isLoadingProvider.notifier).state = false;
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Broadcast'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
