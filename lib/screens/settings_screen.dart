import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final client = ref.read(apiClientProvider);
    final mnemonic = ref.watch(mnemonicProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(context, 'Network'),
            _buildCard(context, [
              _buildCopyTile(
                context: context,
                icon: Icons.cloud,
                title: 'Daemon URL',
                value: client.baseUrl,
              ),
              const Divider(height: 1, indent: 56),
              _buildCopyTile(
                context: context,
                icon: Icons.api,
                title: 'API URL',
                value: client.apiBaseUrl,
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'Appearance'),
            _buildCard(context, [
              SwitchListTile(
                secondary: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle app theme'),
                value: isDark,
                onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'Wallet'),
            _buildCard(context, [
              if (mnemonic != null)
                ListTile(
                  leading: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Reveal Mnemonic'),
                  subtitle: Text(
                    '${mnemonic.split(' ').take(3).join(' ')} ...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMnemonicReveal(context, mnemonic),
                )
              else
                ListTile(
                  leading: Icon(Icons.visibility_off, color: Colors.grey[400]),
                  title: const Text('Reveal Mnemonic'),
                  subtitle: const Text('No wallet loaded'),
                  enabled: false,
                ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Erase Wallet', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Remove keys from this device'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmErase(context, ref),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'About'),
            _buildCard(context, [
              ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                title: const Text('About EJEMMA Wallet'),
                subtitle: const Text('v0.1.1 • Biafran Remittance • Liquid sidechain'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                title: const Text('View Source'),
                subtitle: const Text('github.com/Satoshi-NaAkokwa/agbara-wallet-flutter'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 40),

            // EJEMMA branding footer
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_exchange, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'EJEMMA • EJM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For the Biafran Government in Exile',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildCopyTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title copied'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showMnemonicReveal(BuildContext context, String mnemonic) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Backup Mnemonic'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
              ),
              child: Text(
                'Write these words down on paper and store them in a secure place. NEVER share them online or screenshot them.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                mnemonic,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mnemonic copied (keep it safe)')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy to clipboard'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmErase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Erase Wallet?'),
          ],
        ),
        content: const Text(
          'This permanently removes all wallet data from this device.\n\nMake sure your 12-word mnemonic is backed up on paper before proceeding.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              // Clear ALL shared providers
              ref.read(walletProvider.notifier).state = null;
              ref.read(mnemonicProvider.notifier).state = null;
              ref.read(balanceProvider.notifier).state = null;
              ref.read(txsProvider.notifier).state = [];
              ref.read(errorProvider.notifier).state = null;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet erased. Restart app to create a new one.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Erase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
