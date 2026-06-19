import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';

class FactoryScreen extends ConsumerStatefulWidget {
  const FactoryScreen({super.key});

  @override
  ConsumerState<FactoryScreen> createState() => _FactoryScreenState();
}

class _FactoryScreenState extends ConsumerState<FactoryScreen> {
  final _tickerController = TextEditingController();
  final _supplyController = TextEditingController();
  final _domainController = TextEditingController();
  bool _loading = false;
  String? _result;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Token Factory', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _tickerController,
            decoration: const InputDecoration(labelText: 'Ticker'),
          ),
          TextField(
            controller: _supplyController,
            decoration: const InputDecoration(labelText: 'Initial supply'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _domainController,
            decoration: const InputDecoration(labelText: 'Domain (optional)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _issue,
            child: _loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Issue Liquid Asset'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            SelectableText(_result!),
          ],
        ],
      ),
    );
  }

  Future<void> _issue() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final asset = await client.issueAsset(
        ticker: _tickerController.text,
        precision: 8,
        initialSupply: int.tryParse(_supplyController.text) ?? 0,
        domain: _domainController.text.isEmpty ? null : _domainController.text,
      );
      setState(() => _result = 'Asset ID: ${asset.assetId}\nTx: ${asset.txid}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }
}
