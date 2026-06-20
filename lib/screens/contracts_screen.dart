import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Smart Contract UI for Ikoro contracts
/// - P2P Exchange (order book trading)
/// - Escrow (buyer/seller protection)
/// - Rotating Credit (ROSCA savings)
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Contracts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.swap_horiz), text: 'P2P Trade'),
            Tab(icon: Icon(Icons.verified_user), text: 'Escrow'),
            Tab(icon: Icon(Icons.groups), text: 'ROSCA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _P2PExchangeTab(),
          _EscrowTab(),
          _RotatingCreditTab(),
        ],
      ),
    );
  }
}

// ─── P2P Exchange ───
class _P2PExchangeTab extends ConsumerWidget {
  const _P2PExchangeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            context,
            icon: Icons.swap_horiz,
            title: 'P2P Exchange',
            subtitle: 'Trade EJM directly with other users. No intermediaries.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Create Order',
            icon: Icons.add_circle_outline,
            onTap: () => _showCreateOrderSheet(context, ref),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'Active Orders',
            icon: Icons.format_list_bulleted,
            onTap: () => _showOrdersList(context, ref),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'My Trades',
            icon: Icons.history,
            onTap: () => _showMyTrades(context, ref),
          ),
          const SizedBox(height: 20),
          Text(
            'How it works',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildStepTile(context, '1', 'Post buy/sell order with price', Icons.post_add),
          _buildStepTile(context, '2', 'Counterparty matches your order', Icons.connect_without_contact),
          _buildStepTile(context, '3', 'Escrow secures the trade', Icons.verified_user),
          _buildStepTile(context, '4', 'Funds release after confirmation', Icons.done_all),
        ],
      ),
    );
  }

  void _showCreateOrderSheet(BuildContext context, WidgetRef ref) {
    final priceCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isBuy = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
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
              Text('Create Order', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Buy EJM'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: false, label: Text('Sell EJM'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {isBuy},
                onSelectionChanged: (set) => setState(() => isBuy = set.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (EJM)',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Price per EJM (in LBTC)',
                  prefixIcon: Icon(Icons.price_change),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${isBuy ? "Buy" : "Sell"} order posted')),
                  );
                },
                icon: Icon(isBuy ? Icons.arrow_downward : Icons.arrow_upward),
                label: Text('Post ${isBuy ? "Buy" : "Sell"} Order'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrdersList(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Active Orders', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildOrderTile(ctx, 'Buy', '500 EJM', '0.0001 LBTC/EJM', '2 mins ago', Colors.green),
                  _buildOrderTile(ctx, 'Sell', '1,200 EJM', '0.00012 LBTC/EJM', '5 mins ago', Colors.red),
                  _buildOrderTile(ctx, 'Buy', '300 EJM', '0.000098 LBTC/EJM', '12 mins ago', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyTrades(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('My Trades', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('No trades yet', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, String type, String amount, String price, String time, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(type == 'Buy' ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
      ),
      title: Text('$type $amount'),
      subtitle: Text('$price • $time'),
      trailing: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Text('Match'),
      ),
    );
  }
}

// ─── Escrow ───
class _EscrowTab extends ConsumerWidget {
  const _EscrowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            context,
            icon: Icons.verified_user,
            title: 'Escrow Protection',
            subtitle: 'Secure your trades with 2-of-3 multi-sig escrow.',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Create Escrow',
            icon: Icons.add_circle_outline,
            onTap: () => _showCreateEscrow(context, ref),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'Active Escrows',
            icon: Icons.list_alt,
            onTap: () => _showActiveEscrows(context, ref),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'Dispute Resolution',
            icon: Icons.gavel,
            onTap: () => _showDispute(context, ref),
          ),
          const SizedBox(height: 20),
          Text('How it works', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStepTile(context, '1', 'Buyer & seller agree on terms', Icons.handshake),
          _buildStepTile(context, '2', 'Funds locked in 2-of-3 escrow', Icons.lock),
          _buildStepTile(context, '3', 'Buyer confirms receipt', Icons.check_circle),
          _buildStepTile(context, '4', 'Arbiter resolves if disputed', Icons.balance),
        ],
      ),
    );
  }

  void _showCreateEscrow(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
            Text('Create Escrow', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Counterparty Address',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount (EJM)',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                hintText: 'e.g., Payment for goods',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Escrow created — funds locked')),
                );
              },
              icon: const Icon(Icons.lock),
              label: const Text('Lock Funds'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showActiveEscrows(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Active Escrows', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('No active escrows', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDispute(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispute Resolution'),
        content: const Text(
          'If a trade is disputed, the arbiter reviews evidence from both parties and releases funds to the rightful owner.\n\nArbiter fee: 1% of escrow amount.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

// ─── Rotating Credit (ROSCA) ───
class _RotatingCreditTab extends ConsumerWidget {
  const _RotatingCreditTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            context,
            icon: Icons.groups,
            title: 'Rotating Savings (ROSCA)',
            subtitle: 'Pool funds with trusted members. Each round, one member receives the full pot.',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Create ROSCA',
            icon: Icons.add_circle_outline,
            onTap: () => _showCreateRosca(context, ref),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'Join ROSCA',
            icon: Icons.group_add,
            onTap: () => _showJoinRosca(context, ref),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'My ROSCAs',
            icon: Icons.groups,
            onTap: () => _showMyRoscas(context, ref),
          ),
          const SizedBox(height: 20),
          Text('How it works', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStepTile(context, '1', 'Create or join a savings group', Icons.group_add),
          _buildStepTile(context, '2', 'Each member contributes per round', Icons.paid),
          _buildStepTile(context, '3', 'One member receives the pot each cycle', Icons.redeem),
          _buildStepTile(context, '4', 'Smart contract enforces payouts', Icons.verified),
        ],
      ),
    );
  }

  void _showCreateRosca(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
            Text('Create ROSCA', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Group Name',
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Contribution per round (EJM)',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Number of members',
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Round duration (days)',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ROSCA created — invite members')),
                );
              },
              icon: const Icon(Icons.groups),
              label: const Text('Create Group'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showJoinRosca(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join ROSCA', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Group ID or Invite Code',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request sent to group admin')),
                );
              },
              icon: const Icon(Icons.group_add),
              label: const Text('Request to Join'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyRoscas(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('My ROSCAs', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('No ROSCAs yet', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Components ───
Widget _buildInfoCard(BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  return Card(
    color: color.withOpacity(0.05),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildActionCard(BuildContext context, {
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 1,
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

Widget _buildStepTile(BuildContext context, String number, String text, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    ),
  );
}
