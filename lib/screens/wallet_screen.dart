import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/app_providers.dart';
import '../services/wallet_storage.dart';
import '../models/wallet.dart';

// ─── EJM Symbol Widget ───
class EjmSymbol extends StatelessWidget {
  final double size;
  final Color? color;
  const EjmSymbol({super.key, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ejm_symbol.png',
      width: size,
      height: size,
      color: color,
      errorBuilder: (_, __, ___) => Text(
        '₵',
        style: TextStyle(fontSize: size * 0.8, fontWeight: FontWeight.bold, color: color ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

// ─── Currency Display Widget ───
class EjmAmount extends StatelessWidget {
  final String amount;
  final TextStyle? style;
  final bool showSymbol;
  final double symbolSize;
  const EjmAmount({super.key, required this.amount, this.style, this.showSymbol = true, this.symbolSize = 14});

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? Theme.of(context).textTheme.bodyLarge!;
    if (!showSymbol) return Text(amount, style: textStyle);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EjmSymbol(size: symbolSize, color: textStyle.color),
        const SizedBox(width: 2),
        Text(amount, style: textStyle),
      ],
    );
  }
}

enum FeePreset { save, standard, express }

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EJEMMA'),
        centerTitle: true,
      ),
      body: const _WalletTab(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WALLET TAB
// ═══════════════════════════════════════════════════════════
class _WalletTab extends ConsumerStatefulWidget {
  const _WalletTab();

  @override
  ConsumerState<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends ConsumerState<_WalletTab> {
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
            if (wallet == null) ...[
              _buildOnboarding(context, ref, isLoading),
            ] else ...[
              _buildBalanceCard(context, balance),
              const SizedBox(height: 16),
              _buildReceiveCard(context, wallet, mnemonic),
              const SizedBox(height: 16),
              _buildActionRow(context, ref, wallet),
              const SizedBox(height: 16),
              _buildFactorySection(context, ref),
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
            _buildBrandingFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboarding(BuildContext ctx, WidgetRef ref, bool loading) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [EjmSymbol(size: 48)]),
            const SizedBox(height: 16),
            Text('Welcome to EJEMMA', textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'The official currency of the Biafran Government in Exile.\nSend remittances instantly.',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loading ? null : () => _createWallet(ref),
              icon: loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
              label: const Text('Create Wallet'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading ? null : () => _showRestoreDialog(ctx, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Mnemonic'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext ctx, Map<String, dynamic>? bal) {
    final lbtc = bal?['lbtc']?.toString() ?? '0.00000000';
    final ejm = bal?['ejm']?.toString();
    final assets = bal?['assets'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EJEMMA',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Testnet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (ejm != null) ...[
                Text(
                  ejm,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '₵EJM',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  lbtc,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '₿',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '~\$0.00 USD',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          if (assets.length > 1) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text(
              'Assets',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...assets.where((a) => a['ticker'] != 'L-BTC').map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    a['ticker'] ?? a['asset_id']?.toString().substring(0, 8) ?? 'Asset',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    a['balance']?.toString() ?? '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiveCard(BuildContext ctx, WalletInfo w, String? mnemonic) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFE8F5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.08), blurRadius: 12, spreadRadius: 1)],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.account_balance_wallet, color: Theme.of(ctx).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Your Wallet', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text(
              w.address.substring(0, 18) + '...' + w.address.substring(w.address.length - 8),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text('Tap to view QR code', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
        ElevatedButton.icon(
          onPressed: () => _showReceiveModal(ctx, w),
          icon: const Icon(Icons.qr_code),
          label: const Text('Receive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  void _showReceiveModal(BuildContext ctx, WalletInfo w) {
    final addressUri = 'bitcoin:${w.address}';
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.qr_code, color: Theme.of(ctx).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text('Receive ₵', style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
          ]),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1B5E20), width: 3),
                boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.15), blurRadius: 16, spreadRadius: 2)],
              ),
              child: QrImageView(
                data: addressUri,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E20),
                embeddedImage: const AssetImage('assets/images/ejm_symbol.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(48, 48)),
                errorStateBuilder: (ctx, err) => const Center(child: Text('QR Error', style: TextStyle(color: Colors.red))),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SelectableText(w.address, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: w.address));
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Address copied')));
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = 'https://blockstream.info/liquidtestnet/address/${w.address}';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not open explorer for ${w.address}')));
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.security, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Self-custodial: Keys never leave this device. Share only this address.',
                style: TextStyle(fontSize: 12, color: Colors.green[700]),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildActionRow(BuildContext ctx, WidgetRef ref, WalletInfo w) {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showSendSheet(ctx, ref, w),
          icon: const Icon(Icons.send), label: const Text('Send'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(ctx).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showReceiveModal(ctx, w),
          icon: const Icon(Icons.qr_code), label: const Text('Receive'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showScanSheet(ctx, ref, w),
          icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
    ]);
  }

  Widget _buildFactorySection(BuildContext ctx, WidgetRef ref) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.factory, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Asset Factory', style: Theme.of(ctx).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            Text('Issue new assets on the EJEMMA network', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showIssueAssetSheet(ctx, ref),
              icon: const Icon(Icons.add_circle),
              label: const Text('Issue New Asset'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxHistory(BuildContext ctx, List<dynamic> txs) {
    if (txs.isEmpty) {
      return Card(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(children: [
          Icon(Icons.receipt_long, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text('No transactions yet', style: TextStyle(color: Colors.grey[600])),
        ]),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('History', style: Theme.of(ctx).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...txs.map((tx) {
        final dir = tx['direction'] ?? 'receive';
        final amt = tx['amount']?.toString() ?? '0';
        final asset = tx['asset'] ?? 'L-BTC';
        return Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dir == 'send' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(dir == 'send' ? Icons.arrow_upward : Icons.arrow_downward,
                color: dir == 'send' ? Colors.red : Colors.green, size: 20),
            ),
            title: Text.rich(TextSpan(children: [
              const TextSpan(text: '₵', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$amt $asset', style: const TextStyle(fontWeight: FontWeight.w600)),
            ])),
            subtitle: Text(tx['txid']?.toString().substring(0, 16) ?? '...'),
            trailing: Text(tx['status'] ?? 'confirmed', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.primary)),
          ),
        );
      }),
    ]);
  }

  Widget _buildBrandingFooter(BuildContext ctx) {
    return Center(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(ctx).colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            EjmSymbol(size: 24, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            Text('EJEMMA • EJM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(ctx).colorScheme.primary)),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Biafran Government in Exile — Official Currency', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
    );
  }

  Future<void> _createWallet(WidgetRef ref) async {
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;
    try {
      final mnemonic = bip39.generateMnemonic(strength: 128);
      final client = ref.read(apiClientProvider);
      final wallet = await client.createWallet(mnemonic, '');
      // 🔐 Persist to encrypted storage
      await WalletStorage.saveWallet(wallet, mnemonic);
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
    final w = ref.read(walletProvider);
    if (w == null) return;
    final client = ref.read(apiClientProvider);
    try {
      final bal = await client.getBalance(w.address);
      ref.read(balanceProvider.notifier).state = bal;
    } catch (e) {
      ref.read(errorProvider.notifier).state = 'Balance refresh failed: $e';
    }
    try {
      final txs = await client.getTransactions(w.address);
      ref.read(txsProvider.notifier).state = txs;
    } catch (_) { ref.read(txsProvider.notifier).state = []; }
  }

  void _showRestoreDialog(BuildContext ctx, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: ctx, builder: (c) => AlertDialog(
      title: const Text('Restore Wallet'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'BIP-39 Mnemonic (12 words)'), maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(c); ref.read(isLoadingProvider.notifier).state = true;
          try {
            final client = ref.read(apiClientProvider);
            final w = await client.createWallet(ctrl.text.trim(), '');
            // 🔐 Persist restored wallet
            await WalletStorage.saveWallet(w, ctrl.text.trim());
            ref.read(walletProvider.notifier).state = w;
            ref.read(mnemonicProvider.notifier).state = ctrl.text.trim();
            await _refreshWallet(ref);
          } catch (e) { ref.read(errorProvider.notifier).state = e.toString(); }
          finally { ref.read(isLoadingProvider.notifier).state = false; }
        }, child: const Text('Restore')),
      ],
    ));
  }

  void _showSendSheet(BuildContext ctx, WidgetRef ref, WalletInfo w, {String? prefilledAddress}) {
    final addrCtrl = TextEditingController(text: prefilledAddress);
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    final assetCtrl = TextEditingController(text: 'EJM');
    final formKey = GlobalKey<FormState>();
    final feePreset = StateProvider<FeePreset>((ref) => FeePreset.standard);
    final feeEstimate = StateProvider<int>((ref) => 0);

    // Fetch fee estimate on open
    _fetchFeeEstimate(ctx, ref, FeePreset.standard, feeEstimate);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => StatefulBuilder(
        builder: (c, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.send, color: Theme.of(ctx).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Send Remittance', style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: addrCtrl,
                decoration: InputDecoration(
                  labelText: 'Recipient Address',
                  hintText: 'Liquid address or ₵ username',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final scanned = await _scanAddress(ctx, ref);
                      if (scanned != null) addrCtrl.text = scanned;
                    },
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Recipient address required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name (optional)',
                  prefixIcon: Icon(Icons.label_outline),
                  hintText: 'e.g., Uncle Chinedu',
                ),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: EjmSymbol(size: 28, color: Theme.of(ctx).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: amtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      suffixText: '₵',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount required';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: assetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Asset',
                  prefixIcon: EjmSymbol(size: 20),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: memoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Memo (optional)',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'e.g., Family remittance June',
                ),
              ),
              const SizedBox(height: 20),
              Text('Fee Preset', style: Theme.of(c).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Consumer(
                builder: (_, ref, __) {
                  final selected = ref.watch(feePreset);
                  return Row(children: [
                    _feeChip(c, ref, feePreset, feeEstimate, 'Save', FeePreset.save, '~20 min', selected),
                    const SizedBox(width: 8),
                    _feeChip(c, ref, feePreset, feeEstimate, 'Standard', FeePreset.standard, '~3 min', selected),
                    const SizedBox(width: 8),
                    _feeChip(c, ref, feePreset, feeEstimate, 'Express', FeePreset.express, '~1 min', selected),
                  ]);
                },
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (_, ref, __) {
                  final fee = ref.watch(feeEstimate);
                  return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Network fee:', style: TextStyle(color: Colors.grey[600])),
                    Text('~${fee > 0 ? fee.toString() : '...'} sat', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) return;
                  final preset = ref.read(feePreset);
                  Navigator.pop(c);
                  ref.read(isLoadingProvider.notifier).state = true;
                  ref.read(errorProvider.notifier).state = null;
                  try {
                    final client = ref.read(apiClientProvider);
                    final amountSats = (double.parse(amtCtrl.text) * 100000000).toInt();
                    final txid = await client.sendAsset(
                      fromAddress: w.address,
                      toAddress: addrCtrl.text.trim(),
                      amount: amountSats,
                      assetId: assetCtrl.text.trim(),
                      memo: memoCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text('Sent ₵${amtCtrl.text} to ${nameCtrl.text.isNotEmpty ? nameCtrl.text : addrCtrl.text.trim().substring(0, 12)}... — txid: $txid'),
                        duration: const Duration(seconds: 5),
                      ));
                    }
                    await _refreshWallet(ref);
                  } catch (e) {
                    ref.read(errorProvider.notifier).state = 'Send failed: $e';
                  } finally {
                    ref.read(isLoadingProvider.notifier).state = false;
                  }
                },
                icon: const Icon(Icons.send), label: const Text('Review & Broadcast'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Future<String?> _scanAddress(BuildContext ctx, WidgetRef ref) async {
    String? result;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SizedBox(
        height: MediaQuery.of(c).size.height * 0.7,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Icon(Icons.qr_code_scanner, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Scan Address', style: Theme.of(c).textTheme.titleLarge),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
            ]),
          ),
          Expanded(child: MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  result = raw;
                  Navigator.pop(c);
                  return;
                }
              }
            },
          )),
        ]),
      ),
    );
    return result;
  }

  void _fetchFeeEstimate(BuildContext ctx, WidgetRef ref, FeePreset preset, StateProvider<int> feeEstimate) async {
    try {
      final client = ref.read(apiClientProvider);
      final fee = await client.estimateFee(preset.name);
      ref.read(feeEstimate.notifier).state = fee;
    } catch (_) {
      ref.read(feeEstimate.notifier).state = preset == FeePreset.save ? 100 : preset == FeePreset.standard ? 250 : 500;
    }
  }

  Widget _feeChip(BuildContext ctx, WidgetRef ref, StateProvider<FeePreset> presetProvider, StateProvider<int> feeEstimate, String label, FeePreset value, String eta, FeePreset selected) {
    final isSelected = selected == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(presetProvider.notifier).state = value;
          _fetchFeeEstimate(ctx, ref, value, feeEstimate);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Theme.of(ctx).colorScheme.primary : Colors.grey.shade300),
          ),
          child: Column(children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(eta, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey[600])),
          ]),
        ),
      ),
    );
  }

  void _showScanSheet(BuildContext ctx, WidgetRef ref, WalletInfo w) async {
    final scanned = await _scanAddress(ctx, ref);
    if (scanned != null && ctx.mounted) {
      _showSendSheet(ctx, ref, w, prefilledAddress: scanned);
    }
  }


  void _showIssueAssetSheet(BuildContext ctx, WidgetRef ref) {
    final tickerCtrl = TextEditingController(text: 'EJM');
    final supplyCtrl = TextEditingController(text: '1000000000');
    final precisionCtrl = TextEditingController(text: '8');
    final domainCtrl = TextEditingController(text: 'ugogbe.info');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Issue Asset on Liquid', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: tickerCtrl,
              decoration: const InputDecoration(labelText: 'Ticker', prefixIcon: Icon(Icons.label)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: supplyCtrl,
              decoration: const InputDecoration(labelText: 'Initial Supply', prefixIcon: Icon(Icons.inventory)),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: precisionCtrl,
              decoration: const InputDecoration(labelText: 'Precision (decimals)', prefixIcon: Icon(Icons.calculate)),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final p = int.tryParse(v);
                if (p == null || p < 0 || p > 8) return '0-8 only';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: domainCtrl,
              decoration: const InputDecoration(labelText: 'Domain (for NIP-05)', prefixIcon: Icon(Icons.language)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(c);
                ref.read(isLoadingProvider.notifier).state = true;
                ref.read(errorProvider.notifier).state = null;
                try {
                  final client = ref.read(apiClientProvider);
                  final asset = await client.issueAsset(
                    ticker: tickerCtrl.text.trim(),
                    precision: int.parse(precisionCtrl.text),
                    initialSupply: int.parse(supplyCtrl.text),
                    domain: domainCtrl.text.trim(),
                  );
                  showDialog(context: ctx, builder: (c2) => AlertDialog(
                    title: const Text('Asset Issued'),
                    content: SelectableText('Asset ID: ${asset['assetId']}\nTx ID: ${asset['txid']}'),
                    actions: [TextButton(onPressed: () => Navigator.pop(c2), child: const Text('OK'))],
                  ));
                } catch (e) {
                  ref.read(errorProvider.notifier).state = 'Asset issuance failed: $e';
                } finally {
                  ref.read(isLoadingProvider.notifier).state = false;
                }
              },
              icon: const Icon(Icons.factory), label: const Text('Issue Asset'),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// EXCHANGE TAB (P2P + Escrow + Order Book)
// ═══════════════════════════════════════════════════════════
