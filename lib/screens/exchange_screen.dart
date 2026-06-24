import 'package:flutter/material.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  int _subTab = 0;

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
        Expanded(child: IndexedStack(index: _subTab, children: const [
          _P2PSubTab(),
          _EscrowSubTab(),
          _MyOrdersSubTab(),
        ])),
      ]),
    );
  }
}

class _P2PSubTab extends StatelessWidget {
  const _P2PSubTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildInfoCard(context, Icons.swap_horiz, 'P2P Exchange', 'Trade ₵ directly with other users. Escrow-protected. Coming in v0.5.', const Color(0xFF1B5E20)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order Book Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _orderRow('SELL', '1,000 ₵', '0.00002000 ₿/₵', 'Okenze'),
              const Divider(height: 1),
              _orderRow('BUY', '5,000 ₵', '0.00002100 ₿/₵', 'Chioma'),
              const Divider(height: 1),
              _orderRow('SELL', '10,000 ₵', '0.00002250 ₿/₵', 'Emeka'),
              const Divider(height: 1),
              _orderRow('BUY', '2,500 ₵', '0.00001950 ₿/₵', 'Ngozi'),
              const SizedBox(height: 12),
              Text('Sample data — real order book coming after mainnet launch.', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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

  Widget _orderRow(String side, String amount, String price, String user) {
    final isSell = side == 'SELL';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSell ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(side, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSell ? Colors.red[700] : Colors.green[700])),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(amount, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(price, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(width: 12),
        Text(user, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
