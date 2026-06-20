import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/app_providers.dart';
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

class WalletExchangeScreen extends ConsumerStatefulWidget {
  const WalletExchangeScreen({super.key});

  @override
  ConsumerState<WalletExchangeScreen> createState() => _WalletExchangeScreenState();
}

class _WalletExchangeScreenState extends ConsumerState<WalletExchangeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EJEMMA'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallet'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Exchange'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _WalletTab(),
          _ExchangeTab(),
        ],
      ),
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: EjmSymbol(size: 24, color: Theme.of(ctx).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Balance', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                Text('EJEMMA (EJM)', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              EjmAmount(
                amount: ejm ?? lbtc,
                showSymbol: true,
                symbolSize: 28,
                style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(ejm != null ? 'EJM' : 'L-BTC', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            ]),
            if (assets.length > 1) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text('Assets', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 4),
              ...assets.where((a) => a['ticker'] != 'L-BTC').map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Text(a['ticker'] ?? a['asset_id']?.toString().substring(0, 8) ?? 'Asset', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(a['balance']?.toString() ?? '0', style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
                ]),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiveCard(BuildContext ctx, WalletInfo w, String? mnemonic) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.qr_code, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Receive', style: Theme.of(ctx).textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: QrImageView(data: w.address, version: QrVersions.auto, size: 160.0, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(w.address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  if (mnemonic != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Text('Seed: ${mnemonic.split(' ').take(3).join(' ')} ...',
                          style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () {
                        Clipboard.setData(ClipboardData(text: mnemonic));
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Mnemonic copied')));
                      }),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () { Clipboard.setData(ClipboardData(text: w.address)); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Address copied'))); },
                icon: const Icon(Icons.copy, size: 16), label: const Text('Copy'),
              ),
              TextButton.icon(
                onPressed: () async { final uri = Uri(scheme: 'bitcoin', path: w.address); if (await canLaunchUrl(uri)) await launchUrl(uri); },
                icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Open'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext ctx, WidgetRef ref, WalletInfo w) {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showSendSheet(ctx, ref, w),
          icon: const Icon(Icons.send), label: const Text('Send'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(ctx).colorScheme.primary, foregroundColor: Colors.white),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showScanSheet(ctx, ref, w),
          icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
            Text('Issue new assets on the Liquid sidechain', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
            title: asset == 'EJM'
              ? EjmAmount(amount: amt, style: const TextStyle(fontWeight: FontWeight.w600))
              : Text('$amt $asset', style: const TextStyle(fontWeight: FontWeight.w600)),
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
            ref.read(walletProvider.notifier).state = w;
            ref.read(mnemonicProvider.notifier).state = ctrl.text.trim();
            await _refreshWallet(ref);
          } catch (e) { ref.read(errorProvider.notifier).state = e.toString(); }
          finally { ref.read(isLoadingProvider.notifier).state = false; }
        }, child: const Text('Restore')),
      ],
    ));
  }

  void _showSendSheet(BuildContext ctx, WidgetRef ref, WalletInfo w) {
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    final assetCtrl = TextEditingController(text: 'EJM');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.send, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Send Remittance', style: Theme.of(c).textTheme.titleLarge),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Recipient Address', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              EjmSymbol(size: 24, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: amtCtrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount required';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: assetCtrl,
              decoration: const InputDecoration(labelText: 'Asset', prefixIcon: Icon(Icons.token)),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: memoCtrl,
              decoration: const InputDecoration(labelText: 'Memo (optional)', prefixIcon: Icon(Icons.note), hintText: 'e.g., Family remittance June'),
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
                  final amountSats = (double.parse(amtCtrl.text) * 100000000).toInt();
                  final txid = await client.sendAsset(
                    fromAddress: w.address,
                    toAddress: addrCtrl.text.trim(),
                    amount: amountSats,
                    assetId: assetCtrl.text.trim(),
                    memo: memoCtrl.text.trim(),
                  );
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Transaction broadcast: $txid')));
                  await _refreshWallet(ref);
                } catch (e) {
                  ref.read(errorProvider.notifier).state = 'Send failed: $e';
                } finally {
                  ref.read(isLoadingProvider.notifier).state = false;
                }
              },
              icon: const Icon(Icons.send), label: const Text('Broadcast'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(ctx).colorScheme.primary, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _showScanSheet(BuildContext ctx, WidgetRef ref, WalletInfo w) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SizedBox(
        height: MediaQuery.of(c).size.height * 0.7,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Icon(Icons.qr_code_scanner, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Scan QR Code', style: Theme.of(c).textTheme.titleLarge),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
            ]),
          ),
          Expanded(child: MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  Navigator.pop(c);
                  // Show send sheet pre-filled with scanned address
                  final addrCtrl = TextEditingController(text: raw);
                  final amtCtrl = TextEditingController();
                  final memoCtrl = TextEditingController();
                  showModalBottomSheet(context: ctx, isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (c2) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom, left: 20, right: 20, top: 20),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('Send to Scanned Address', style: Theme.of(c2).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address'), readOnly: true),
                        const SizedBox(height: 12),
                        Row(children: [
                          EjmSymbol(size: 24),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (EJM)'), keyboardType: TextInputType.number)),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'Memo (optional)')),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(c2);
                            ref.read(isLoadingProvider.notifier).state = true;
                            try {
                              final client = ref.read(apiClientProvider);
                              final amountSats = (double.parse(amtCtrl.text) * 100000000).toInt();
                              final txid = await client.sendAsset(
                                fromAddress: w.address,
                                toAddress: addrCtrl.text.trim(),
                                amount: amountSats,
                                assetId: 'EJM',
                                memo: memoCtrl.text.trim(),
                              );
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Sent: $txid')));
                              await _refreshWallet(ref);
                            } catch (e) {
                              ref.read(errorProvider.notifier).state = 'Send failed: $e';
                            } finally {
                              ref.read(isLoadingProvider.notifier).state = false;
                            }
                          },
                          icon: const Icon(Icons.send), label: const Text('Send'),
                        ),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  );
                  break;
                }
              }
            },
          )),
        ]),
      ),
    );
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
                    content: SelectableText('Asset ID: ${asset.assetId}\nTx ID: ${asset.txid}'),
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
class _ExchangeTab extends ConsumerStatefulWidget {
  const _ExchangeTab();

  @override
  ConsumerState<_ExchangeTab> createState() => _ExchangeTabState();
}

class _ExchangeTabState extends ConsumerState<_ExchangeTab> {
  int _subTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('P2P'), icon: Icon(Icons.people)),
            ButtonSegment(value: 1, label: Text('Escrow'), icon: Icon(Icons.verified_user)),
            ButtonSegment(value: 2, label: Text('My Orders'), icon: Icon(Icons.list_alt)),
          ],
          selected: {_subTab},
          onSelectionChanged: (s) => setState(() => _subTab = s.first),
        ),
      ),
      Expanded(child: IndexedStack(index: _subTab, children: const [
        _P2PSubTab(),
        _EscrowSubTab(),
        _MyOrdersSubTab(),
      ])),
    ]);
  }
}

class _P2PSubTab extends StatelessWidget {
  const _P2PSubTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildInfoCard(context, Icons.swap_horiz, 'P2P Exchange', 'Trade EJM directly with other users. No intermediaries.', Colors.blue),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showCreateOrder(context),
          icon: const Icon(Icons.add), label: const Text('Create Order'),
        ),
        const SizedBox(height: 16),
        Text('Active Orders', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _EmptyState(icon: Icons.receipt_long, message: 'No active orders\nCreate one to start trading'),
      ]),
    );
  }

  void _showCreateOrder(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final amtCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Create Order', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              EjmSymbol(size: 24),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: amtCtrl,
                decoration: const InputDecoration(labelText: 'Amount (EJM)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid' : null,
              )),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price per EJM (in L-BTC)'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(c);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Order created (backend integration pending)')));
              },
              icon: const Icon(Icons.post_add), label: const Text('Post Order'),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _EscrowSubTab extends StatelessWidget {
  const _EscrowSubTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildInfoCard(context, Icons.verified_user, 'Escrow Protection', 'Secure your trades with 2-of-3 multi-sig escrow. All fees paid in EJM.', Colors.orange),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showCreateEscrow(context),
          icon: const Icon(Icons.lock), label: const Text('Create Escrow'),
        ),
        const SizedBox(height: 16),
        _EmptyState(icon: Icons.hourglass_empty, message: 'No active escrows\nCreate one to secure a trade'),
      ]),
    );
  }

  void _showCreateEscrow(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Create Escrow', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Counterparty Address', prefixIcon: Icon(Icons.person)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              EjmSymbol(size: 24),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: amtCtrl,
                decoration: const InputDecoration(labelText: 'Amount (EJM)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid' : null,
              )),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(c);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Escrow created (smart contract integration pending)')));
              },
              icon: const Icon(Icons.lock), label: const Text('Lock Funds'),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _MyOrdersSubTab extends StatelessWidget {
  const _MyOrdersSubTab();

  @override
  Widget build(BuildContext context) {
    return _EmptyState(icon: Icons.list_alt, message: 'No orders yet\nYour P2P and escrow orders will appear here');
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════

Widget _buildInfoCard(BuildContext ctx, IconData icon, String title, String subtitle, Color color) {
  return Card(
    color: color.withOpacity(0.05),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ])),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ]),
      ),
    );
  }
}
