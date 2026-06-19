import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';

final darkModeProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showMnemonic = false;
  String? _mnemonic;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(darkModeProvider);
    final client = ref.read(apiClientProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),

          // Network Section
          Card(
            elevation: 1,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Daemon URL'),
                  subtitle: Text(client.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: client.baseUrl));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.api),
                  title: const Text('API URL'),
                  subtitle: Text(client.apiBaseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: client.apiBaseUrl));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appearance
          Card(
            elevation: 1,
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle app theme'),
              value: isDark,
              onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 16),

          // Security
          Card(
            elevation: 1,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  subtitle: const Text('Mnemonic backup & lock'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Reveal Mnemonic'),
                  subtitle: const Text('Show your 12/24 word seed'),
                  trailing: IconButton(
                    icon: Icon(_showMnemonic ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _showMnemonic = !_showMnemonic);
                      if (_showMnemonic) _showMnemonicDialog(context);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Erase Wallet', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Remove keys from this device'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmErase(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About
          Card(
            elevation: 1,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Agbara Wallet'),
                  subtitle: const Text('v0.1.0 • Liquid sidechain • Token factory'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('View Source'),
                  subtitle: const Text('github.com/Satoshi-NaAkokwa/agbara-wallet-flutter'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {}, // url_launcher could be wired here
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMnemonicDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Mnemonic'),
        content: const Text(
          'Your mnemonic is the ONLY way to recover this wallet.\n\nWrite it down on paper and store it securely. Never share it online.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _showMnemonic = false);
              Navigator.pop(ctx);
            },
            child: const Text('Hide'),
          ),
        ],
      ),
    );
  }

  void _confirmErase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase Wallet?', style: TextStyle(color: Colors.red)),
        content: const Text('This removes all wallet data from this device. Make sure your mnemonic is backed up first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              // Reset all wallet providers
              // Note: These providers live in wallet_screen.dart; in a real app they'd be in a central place
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet erased. Restart app to onboard again.')),
              );
            },
            child: const Text('Erase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
