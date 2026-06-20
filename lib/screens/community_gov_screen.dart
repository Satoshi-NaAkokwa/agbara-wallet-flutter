import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── EJM Symbol (duplicated here to avoid import cycle) ───
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

class CommunityGovScreen extends ConsumerStatefulWidget {
  const CommunityGovScreen({super.key});

  @override
  ConsumerState<CommunityGovScreen> createState() => _CommunityGovScreenState();
}

class _CommunityGovScreenState extends ConsumerState<CommunityGovScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Community & Gov'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.groups), text: 'Community'),
            Tab(icon: Icon(Icons.account_balance), text: 'Gov/Herald'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _CommunityTab(),
          _GovHeraldTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COMMUNITY TAB (ROSCA + Savings Groups)
// ═══════════════════════════════════════════════════════════
class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(context, Icons.groups, 'Rotating Savings (ROSCA)',
            'Pool funds with trusted members. Each round, one member receives the full pot.',
            Colors.purple),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateRosca(context),
            icon: const Icon(Icons.add), label: const Text('Create ROSCA Group'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showJoinRosca(context),
            icon: const Icon(Icons.group_add), label: const Text('Join Group'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
          const SizedBox(height: 24),
          Text('My Groups', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.groups, color: Colors.purple, size: 20),
              ),
              title: const Text('Ejeme Family Savings'),
              subtitle: const Text('12 members • Round 3 of 12'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                EjmSymbol(size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 2),
                const Text('500', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('How ROSCA Works', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStep(context, '1', 'Create or join a savings group'),
          _buildStep(context, '2', 'Each member contributes per round'),
          _buildStep(context, '3', 'One member receives the pot each cycle'),
          _buildStep(context, '4', 'Smart contract enforces payouts'),
        ],
      ),
    );
  }

  void _showCreateRosca(BuildContext ctx) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Create ROSCA', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Group Name', prefixIcon: Icon(Icons.edit))),
          const SizedBox(height: 12),
          Row(children: [
            EjmSymbol(size: 24),
            const SizedBox(width: 8),
            const Expanded(child: TextField(decoration: InputDecoration(labelText: 'Contribution per round (EJM)'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Number of members', prefixIcon: Icon(Icons.people)), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Round duration (days)', prefixIcon: Icon(Icons.timer)), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('ROSCA created'))); },
            icon: const Icon(Icons.groups), label: const Text('Create Group'),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showJoinRosca(BuildContext ctx) {
    showModalBottomSheet(context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Join ROSCA', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Group ID or Invite Code', prefixIcon: Icon(Icons.qr_code))),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Request sent'))); },
            icon: const Icon(Icons.group_add), label: const Text('Request to Join'),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep(BuildContext ctx, String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.primaryContainer, shape: BoxShape.circle),
          child: Center(child: Text(num, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(ctx).colorScheme.primary)))),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GOV/HERALD TAB (Decision Making + P2P Governance)
// ═══════════════════════════════════════════════════════════
class _GovHeraldTab extends StatelessWidget {
  const _GovHeraldTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(context, Icons.account_balance, 'Biafran Government in Exile',
            'On-chain governance for the Biafran diaspora community. Vote on policy, allocate treasury funds, and shape the future of EJM.',
            Colors.green[700]!),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.how_to_vote, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Active Proposals', style: Theme.of(context).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                _ProposalTile(
                  title: 'Increase P2P Exchange Fee to 0.15%',
                  votes: '12,450',
                  status: 'Voting',
                  deadline: '3 days',
                  percent: 0.62,
                ),
                const Divider(height: 1),
                _ProposalTile(
                  title: 'Allocate 1M EJM for Diaspora Aid Fund',
                  votes: '89,200',
                  status: 'Passing',
                  deadline: '1 day',
                  percent: 0.78,
                ),
                const Divider(height: 1),
                _ProposalTile(
                  title: 'Add EUR Proxy Token Support',
                  votes: '45,100',
                  status: 'Tied',
                  deadline: '5 days',
                  percent: 0.50,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.trending_up, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text('Treasury Overview', style: Theme.of(context).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _TreasuryItem('Balance', '2.4M', 'EJM'),
                  _TreasuryItem('Monthly Out', '150K', 'EJM'),
                  _TreasuryItem('Fees Collected', '45K', 'EJM'),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateProposal(context),
            icon: const Icon(Icons.add_comment), label: const Text('Submit Proposal'),
          ),
          const SizedBox(height: 24),
          Text('Voting Power', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your voting power is proportional to your EJM balance. 1 EJM = 1 vote. Locked EJM (in escrow or ROSCA) does NOT count toward voting power.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showCreateProposal(BuildContext ctx) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Submit Proposal', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Proposal Title', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 3),
          const SizedBox(height: 12),
          Row(children: [
            EjmSymbol(size: 24),
            const SizedBox(width: 8),
            const Expanded(child: TextField(decoration: InputDecoration(labelText: 'Funding Request (EJM, optional)'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Proposal submitted for review'))); },
            icon: const Icon(Icons.send), label: const Text('Submit'),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ─── Proposal Tile ───
class _ProposalTile extends StatelessWidget {
  final String title, votes, status, deadline;
  final double percent;
  const _ProposalTile({required this.title, required this.votes, required this.status, required this.deadline, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Passing' ? Colors.green : status == 'Tied' ? Colors.orange : Colors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: percent, minHeight: 6, color: color, backgroundColor: Colors.grey[200])),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            EjmSymbol(size: 12, color: Colors.grey[600]),
            const SizedBox(width: 2),
            Text(votes, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ),
          Text(deadline, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ]),
      ]),
    );
  }
}

// ─── Treasury Item ───
class _TreasuryItem extends StatelessWidget {
  final String label, value, unit;
  const _TreasuryItem(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        EjmSymbol(size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
      Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
    ]);
  }
}

// ─── Info Card ───
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
