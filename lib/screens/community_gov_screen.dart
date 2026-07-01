import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class CommunityGovScreen extends ConsumerStatefulWidget {
  const CommunityGovScreen({super.key});

  @override
  ConsumerState<CommunityGovScreen> createState() => _CommunityGovScreenState();
}

class _CommunityGovScreenState extends ConsumerState<CommunityGovScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _assets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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
        children: [
          _CommunityTab(assets: _assets, loading: _loading, error: _error, onRefresh: _loadData),
          _GovHeraldTab(assets: _assets, loading: _loading, error: _error, onRefresh: _loadData),
        ],
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final List<Map<String, dynamic>> assets;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  const _CommunityTab({required this.assets, required this.loading, this.error, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text('Error: $error', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildInfoCard(context, Icons.groups, 'Rotating Savings (ROSCA / Isusu)',
          'Pool funds with trusted members. Each round, one member receives the full pot. Smart contract enforced.',
          const Color(0xFF1B5E20)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create ROSCA coming in v0.5'))),
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20)),
              label: const Text('Create Group', style: TextStyle(color: Color(0xFF1B5E20))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join ROSCA coming in v0.5'))),
              icon: const Icon(Icons.person_add),
              label: const Text('Join Group'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text('Issued Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (assets.isEmpty) ...[
          const _EmptyState(icon: Icons.token, message: 'No assets issued yet\nUse the Factory tab to create your first token'),
        ] else ...[
          ...assets.map((a) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.token, color: Color(0xFFC8A415)),
              title: Text(a['ticker'] ?? a['asset_id']?.toString().substring(0, 8) ?? 'Unknown'),
              subtitle: Text(a['asset_id'] ?? '-', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              trailing: Text('${a['balance'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
        ],
        const SizedBox(height: 20),
        Text('How ROSCA Works', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildStep(context, '1', 'Create or join a savings group with trusted members.'),
        _buildStep(context, '2', 'Each member contributes the agreed amount every round.'),
        _buildStep(context, '3', 'One member receives the pot each round, enforced by smart contract.'),
      ]),
    );
  }

  Widget _buildStep(BuildContext ctx, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.primary, shape: BoxShape.circle),
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14))),
      ]),
    );
  }
}

class _GovHeraldTab extends StatelessWidget {
  final List<Map<String, dynamic>> assets;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  const _GovHeraldTab({required this.assets, required this.loading, this.error, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text('Error: $error', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildInfoCard(context, Icons.account_balance, 'Biafran Government in Exile',
          'On-chain governance for the Biafran diaspora. Propose, vote, and allocate treasury funds transparently.',
          const Color(0xFF1B5E20)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Treasury Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (assets.isEmpty)
                const Text('No assets in treasury.', style: TextStyle(color: Colors.grey))
              else
                ...assets.map((a) => _governanceCard(context, a['asset_id'] ?? '-', a['ticker'] ?? 'Unknown', 'Active', a['balance'] ?? '0')),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        _governanceCard(context, 'EJM-001', 'Adopt Ofo-based identity verification', 'Open', '72% Yes'),
        const SizedBox(height: 10),
        _governanceCard(context, 'EJM-002', 'Lower remittance fees to 0.1%', 'Voting ends tomorrow', '58% Yes'),
        const SizedBox(height: 10),
        _governanceCard(context, 'EJM-003', 'Add NGN off-ramp integration', 'Queued', '-'),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _showCreateProposal(context),
          icon: const Icon(Icons.add_comment), label: const Text('Submit Proposal'),
        ),
        const SizedBox(height: 24),
        Text('Voting Power', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Your voting power equals your ₵ balance. 1 ₵ = 1 vote. Locked ₵ (in escrow or ROSCA) does NOT count toward voting power.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ]),
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
            TextFormField(
              controller: fundCtrl,
              decoration: const InputDecoration(labelText: 'Funding Request (₵, optional)', prefixIcon: Icon(Icons.paid)),
              keyboardType: TextInputType.number,
            ),
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

  Widget _governanceCard(BuildContext ctx, String id, String title, String status, String vote) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: status == 'Open' ? Colors.green[50] : Colors.grey[100], borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(fontSize: 11, color: status == 'Open' ? Colors.green[700] : Colors.grey[700])),
            ),
          ]),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Latest vote: $vote', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ]),
      ),
    );
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
