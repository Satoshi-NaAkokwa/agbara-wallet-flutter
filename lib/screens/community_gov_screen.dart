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
            'Pool funds with trusted members. Each round, one member receives the full pot. Smart contract enforced.',
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
          _EmptyState(icon: Icons.groups, message: 'No active groups\nCreate or join a ROSCA to start saving'),
          const SizedBox(height: 24),
          Text('How ROSCA Works', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStep(context, '1', 'Create or join a savings group with trusted members'),
          _buildStep(context, '2', 'Each member contributes EJM per round'),
          _buildStep(context, '3', 'One member receives the pot each cycle via smart contract'),
          _buildStep(context, '4', 'Continue until all members have received their turn'),
        ],
      ),
    );
  }

  void _showCreateRosca(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final contribCtrl = TextEditingController();
    final membersCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Create ROSCA', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Group Name', prefixIcon: Icon(Icons.edit)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            Row(children: [
              EjmSymbol(size: 24),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: contribCtrl,
                decoration: const InputDecoration(labelText: 'Contribution per round (EJM)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid' : null,
              )),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: membersCtrl,
              decoration: const InputDecoration(labelText: 'Number of members', prefixIcon: Icon(Icons.people)),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = int.tryParse(v);
                if (n == null || n < 2 || n > 50) return '2-50 members';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: durationCtrl,
              decoration: const InputDecoration(labelText: 'Round duration (days)', prefixIcon: Icon(Icons.timer)),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Invalid' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(c);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('ROSCA created (smart contract integration pending)')));
              },
              icon: const Icon(Icons.groups), label: const Text('Create Group'),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _showJoinRosca(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();

    showModalBottomSheet(context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Join ROSCA', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Group ID or Invite Code', prefixIcon: Icon(Icons.qr_code)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(c);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Join request sent')));
              },
              icon: const Icon(Icons.group_add), label: const Text('Request to Join'),
            ),
          ]),
        ),
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
// GOV/HERALD TAB
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
            'On-chain governance for the Biafran diaspora. Propose, vote, and allocate treasury funds transparently.',
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
                _EmptyState(icon: Icons.how_to_vote, message: 'No active proposals\nSubmit the first proposal to start governance'),
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
                _EmptyState(icon: Icons.account_balance_wallet, message: 'Treasury will display here\nwhen governance is active'),
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
            'Your voting power equals your EJM balance. 1 EJM = 1 vote. Locked EJM (in escrow or ROSCA) does NOT count toward voting power.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showCreateProposal(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final fundCtrl = TextEditingController();

    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Submit Proposal', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Proposal Title', prefixIcon: Icon(Icons.title)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)), maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            Row(children: [
              EjmSymbol(size: 24),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: fundCtrl,
                decoration: const InputDecoration(labelText: 'Funding Request (EJM, optional)'),
                keyboardType: TextInputType.number,
              )),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(c);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Proposal submitted for review')));
              },
              icon: const Icon(Icons.send), label: const Text('Submit'),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ─── Empty State ───
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ]),
      ),
    );
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
