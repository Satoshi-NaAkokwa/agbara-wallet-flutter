import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import '../services/wallet_storage.dart';

final biometricEnabledProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await WalletStorage.isBiometricEnabled();
    if (mounted) {
      ref.read(biometricEnabledProvider.notifier).state = enabled;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => _showMnemonicReveal(context, mnemonic, ref),
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

            _buildSectionHeader(context, 'Support'),
            _buildCard(context, [
              ListTile(
                leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                title: const Text('FAQ'),
                subtitle: const Text('Frequently asked questions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFAQ(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                title: const Text('Security'),
                subtitle: const Text('How your assets are protected'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSecurity(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                title: const Text('View Source'),
                subtitle: const Text('github.com/Satoshi-NaAkokwa/agbara-wallet-flutter'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () async {
                  final uri = Uri.parse('https://github.com/Satoshi-NaAkokwa/agbara-wallet-flutter');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'Security'),
            _buildCard(context, [
              ListTile(
                leading: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
                title: const Text('PIN / Biometric'),
                subtitle: const Text('Secure wallet with PIN or device biometrics'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _promptSetPin(context, ref, mnemonic ?? ''),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                secondary: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
                title: const Text('Unlock with Biometrics'),
                subtitle: const Text('Use fingerprint/face to unlock app'),
                value: ref.watch(biometricEnabledProvider),
                onChanged: (v) async {
                  if (v) {
                    final ok = await AuthService.canAuthenticate();
                    if (!ok) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No biometrics enrolled on this device')),
                        );
                      }
                      return;
                    }
                    final didAuth = await AuthService.authenticate(reason: 'Enable biometric unlock');
                    if (didAuth) {
                      await WalletStorage.setBiometricEnabled(true);
                      if (mounted) {
                        ref.read(biometricEnabledProvider.notifier).state = true;
                        if (!(await PinService.hasPin())) {
                          _promptSetPin(context, ref, mnemonic ?? '');
                        }
                      }
                    }
                  } else {
                    await WalletStorage.setBiometricEnabled(false);
                    if (mounted) {
                      ref.read(biometricEnabledProvider.notifier).state = false;
                    }
                  }
                },
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'About'),
            _buildCard(context, [
              ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                title: const Text('EJEMMA Wallet'),
                subtitle: const Text('v0.4.1 • Phase 1 Release\nSelf-custodial wallet • Asset factory • Smart contracts'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.shield, color: Colors.green[700]),
                title: const Text('Asset Safety Guarantee'),
                subtitle: const Text('Self-custodial • BIP-39 mnemonic • No third-party control'),
              ),
            ]),
            const SizedBox(height: 40),

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
                          'EJEMMA • ₵',
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

  void _showMnemonicReveal(BuildContext context, String mnemonic, WidgetRef ref) async {
    // Step 1: Try biometric authentication
    final bioOk = await AuthService.canAuthenticate();
    if (bioOk) {
      final didAuth = await AuthService.authenticate(reason: 'Reveal your recovery phrase');
      if (didAuth) {
        if (!context.mounted) return;
        _displayMnemonic(context, mnemonic);
        return;
      }
    }

    // Step 2: Fall back to PIN
    final hasPin = await PinService.hasPin();
    if (hasPin) {
      if (!context.mounted) return;
      final pin = await _showPinDialog(context);
      if (pin == null) return;
      try {
        final ok = await PinService.verifyPin(pin);
        if (ok && context.mounted) {
          _displayMnemonic(context, mnemonic);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
        }
      } on PinLockedException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    } else {
      // Step 3: No PIN set — prompt to set one
      if (!context.mounted) return;
      _promptSetPin(context, ref, mnemonic);
    }
  }

  void _displayMnemonic(BuildContext context, String mnemonic) {
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

  Future<String?> _showPinDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter PIN'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'PIN',
              counterText: '',
              hintText: '••••••',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctx.mounted) Navigator.pop(ctx, ctrl.text.trim());
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
  }

  void _promptSetPin(BuildContext context, WidgetRef ref, String mnemonic) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set PIN for Security'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set a 6-digit PIN to protect your wallet. You can also enable biometrics in your device settings.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN',
                  counterText: '',
                  hintText: '••••••',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = ctrl.text.trim();
                if (pin.length == 6) {
                  await PinService.setPin(pin);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mnemonic.isNotEmpty) {
                    if (context.mounted) {
                      _showMnemonicReveal(context, mnemonic, ref);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN set successfully')),
                      );
                    }
                  }
                }
              },
              child: const Text('Set PIN'),
            ),
          ],
        );
      },
    );
  }

  void _confirmErase(BuildContext context, WidgetRef ref) async {
    // Require PIN/biometric before erase
    final bioOk = await AuthService.canAuthenticate();
    bool authorized = false;
    if (bioOk) {
      authorized = await AuthService.authenticate(reason: 'Erase wallet from device');
    }
    if (!authorized) {
      final hasPin = await PinService.hasPin();
      if (hasPin) {
        final pin = await _showPinDialog(context);
        if (pin != null) {
          try { authorized = await PinService.verifyPin(pin); }
          catch (_) {}
        }
      }
    }
    if (!authorized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required to erase wallet')),
        );
      }
      return;
    }

    if (!context.mounted) return;
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
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear all persistent data
              await WalletStorage.clear();
              await PinService.resetPin();
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

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => const _FaqSheet(),
    );
  }

  void _showSecurity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(children: [
                Icon(Icons.security, color: Theme.of(c).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text('Security Architecture', style: Theme.of(c).textTheme.headlineSmall),
              ]),
              const SizedBox(height: 20),
              _securityItem(c, 'Self-Custodial Design', 
                'Your private keys never leave your device. They are derived from your BIP-39 mnemonic using industry-standard secp256k1 cryptography. No server, cloud, or third party ever sees your keys.',
                Icons.vpn_key),
              _securityItem(c, 'Mnemonic Backup',
                'Your 12-word seed phrase is the master key to ALL your assets. Write it on paper, store it in a secure physical location, and never photograph, email, or message it.',
                Icons.backup),
              _securityItem(c, 'Encrypted Storage',
                'Wallet data is stored using AES-256-GCM encryption with Argon2 key derivation. Even if your device is compromised, the attacker cannot extract your keys without your knowledge.',
                Icons.enhanced_encryption),
              _securityItem(c, 'Asset Issuance Security',
                'All issued assets are anchored to the Bitcoin blockchain. Asset IDs are deterministic and cryptographically verifiable. The issuer contract is immutable once deployed.',
                Icons.verified),
              _securityItem(c, 'Transaction Validation',
                'Every transaction is signed locally on your device, then broadcast to the network. The daemon validates but never signs — you retain exclusive signing authority.',
                Icons.check_circle),
              _securityItem(c, 'Fee Structure',
                'Network fees: Paid in ₿ to network validators.\nProtocol fees: Paid in ₵ to the treasury.\nEscrow fees: 0.2% paid to escrow agents.\nNo hidden fees. All rates are transparent and on-chain.',
                Icons.attach_money),
              _securityItem(c, 'Recovery Process',
                'If your device is lost, stolen, or damaged: Install EJEMMA on a new device, select "Restore from Mnemonic", enter your 12 words in order, and your full balance reappears instantly.',
                Icons.restore),
              _securityItem(c, 'Smart Contract Audits',
                'All smart contracts (P2P Exchange, Escrow, ROSCA) are open source and subject to community review. Formal verification and third-party audits are planned for v1.0.',
                Icons.policy),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.shield, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text('Asset Safety Guarantee', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'EJEMMA guarantees that:\n'
                    '1. Your assets are always under your control\n'
                    '2. No entity can freeze or confiscate your funds\n'
                    '3. All transactions are final and irreversible\n'
                    '4. Your mnemonic is the sole recovery method\n'
                    '5. The code is open source and auditable',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(answer, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _securityItem(BuildContext context, String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }
}


class _FaqSheet extends StatefulWidget {
  const _FaqSheet();

  @override
  State<_FaqSheet> createState() => _FaqSheetState();
}

class _FaqSheetState extends State<_FaqSheet> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  final _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/faq.json');
      final list = jsonDecode(raw) as List<dynamic>;
      if (mounted) setState(() {
        _all = list.cast<Map<String, dynamic>>();
        _filtered = List.from(_all);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _all.where((f) {
        final qn = (f['question'] ?? '').toString().toLowerCase();
        final ans = (f['answer'] ?? '').toString().toLowerCase();
        final cat = (f['category'] ?? '').toString().toLowerCase();
        return qn.contains(lower) || ans.contains(lower) || cat.contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Help Center', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Search questions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); _filter(''); }) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No matching questions'))
                    : ListView(
                        controller: scrollCtrl,
                        children: _filtered.map((f) => _faqSheetItem(context, f)).toList(),
                      ),
          ),
        ]),
      ),
    );
  }
}


Widget _faqSheetItem(BuildContext context, Map<String, dynamic> f) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      title: Text(f['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(f['category'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(f['answer'] ?? '', style: TextStyle(color: Colors.grey[700], height: 1.4)),
        ),
      ],
    ),
  );
}
