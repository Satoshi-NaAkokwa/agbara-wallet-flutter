import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class ExchangeScreen extends ConsumerStatefulWidget {
  const ExchangeScreen({super.key});

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  int _subTab = 0;
  List<Map<String, dynamic>> _assets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final client = ref.read(apiClientProvider);
      final assets = await client.listAssets();
      if (mounted) {
        setState(() {
          _assets = assets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange'),
        centerTitle: true,
      ),
      body: Column(children: [
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
        Expanded(child: IndexedStack(index: _subTab, children: [
          _P2PSubTab(assets: _assets, loading: _loading, error: _error, onRefresh: _loadAssets),
          const _EscrowSubTab(),
          const _MyOrdersSubTab(),
        ])),
      ]),
    );
  }
}

class _P2PSubTab extends StatelessWidget {
  final List<Map<String, dynamic>> assets;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  const _P2PSubTab({required this.assets, required this.loading, this.error, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text('Error loading assets: $error', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildInfoCard(context, Icons.swap_horiz, 'P2P Exchange', 'Trade ₵ directly with other users. Escrow-protected. Coming in v0.5.', const Color(0xFF1B5E20)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Factory Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (assets.isEmpty)
                const Text('No assets issued yet. Use the Factory to create your first token.', style: TextStyle(color: Colors.grey))
              else
                ...assets.map((a) => _assetRow(a)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('P2P order creation coming in v0.5'))),
          icon: const Icon(Icons.add), label: const Text('Create Order'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  Widget _assetRow(Map<String, dynamic> asset) {
    final ticker = asset['ticker'] ?? asset['asset_id']?.toString().substring(0, 8) ?? 'UNKNOWN';
    final assetId = asset['asset_id'] ?? '-';
    final balance = asset['balance'] ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF1B5E20).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(ticker, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(assetId, style: const TextStyle(fontFamily: 'monospace', fontSize: 11), overflow: TextOverflow.ellipsis)),
        Text('Bal: $balance', style: const TextStyle(fontSize: 12)),
      ]),
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
        _buildInfoCard(context, Icons.verified_user, 'Escrow Protection', '2-of-3 multi-sig held by you, buyer, and arbitrator. Coming in v0.5.', const Color(0xFFC8A415)),
        const SizedBox(height: 16),
        _EmptyState(icon: Icons.hourglass_empty, message: 'No active escrows\nEscrow trades will appear here after P2P launch'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escrow creation coming in v0.5'))),
          icon: const Icon(Icons.lock), label: const Text('Create Escrow'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }
}

class _MyOrdersSubTab extends StatelessWidget {
  const _MyOrdersSubTab();

  @override
  Widget build(BuildContext context) {
    return _EmptyState(icon: Icons.list_alt, message: 'No orders yet\nYour P2P and escrow orders will appear here after v0.5');
  }
}

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
