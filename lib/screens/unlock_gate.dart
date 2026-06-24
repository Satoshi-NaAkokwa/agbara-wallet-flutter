import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';

/// Guards access to the wallet behind PIN or biometric unlock.
/// Shows only when a wallet exists and either PIN or biometric is configured.
class UnlockGate extends ConsumerStatefulWidget {
  const UnlockGate({super.key});

  @override
  ConsumerState<UnlockGate> createState() => _UnlockGateState();
}

class _UnlockGateState extends ConsumerState<UnlockGate> {
  bool _verifying = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attemptUnlock();
  }

  Future<void> _attemptUnlock() async {
    final wallet = ref.read(walletProvider);
    final hasPin = await PinService.hasPin();
    final bioEnabled = ref.read(biometricEnabledProvider);

    if (wallet == null || (!hasPin && !bioEnabled)) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    if (bioEnabled) {
      final ok = await AuthService.authenticate(reason: 'Unlock EJEMMA Wallet');
      if (ok) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        return;
      }
    }

    // Biometric failed or not enabled — fall back to PIN
    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_verifying) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B5E20),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text('EJEMMA is locked', style: TextStyle(fontSize: 18, color: Colors.white)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text('Enter PIN to unlock', style: TextStyle(fontSize: 18, color: Colors.white)),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              _PinKeypad(onPinEntered: _onPinEntered),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPinEntered(String pin) async {
    final ok = await PinService.verifyPin(pin);
    if (ok) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }
}

class _PinKeypad extends StatefulWidget {
  final ValueChanged<String> onPinEntered;
  const _PinKeypad({required this.onPinEntered});

  @override
  State<_PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<_PinKeypad> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length < 6) setState(() => _pin += d);
    if (_pin.length == 6) widget.onPinEntered(_pin);
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? Colors.white : Colors.white24,
            ),
          )),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '←'],
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((label) {
                  if (label.isEmpty) return const SizedBox(width: 64, height: 64);
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: MaterialButton(
                        shape: const CircleBorder(),
                        color: Colors.white12,
                        onPressed: label == '←' ? _onBackspace : () => _onDigit(label),
                        child: label == '←'
                            ? const Icon(Icons.backspace_outlined, color: Colors.white)
                            : Text(label, style: const TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ],
    );
  }
}
