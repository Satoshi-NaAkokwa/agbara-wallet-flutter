import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('API Base URL'),
            subtitle: const Text('http://localhost:4000/api/v1'),
          ),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Liquid sidechain'),
            subtitle: const Text('Confidential assets enabled'),
          ),
        ],
      ),
    );
  }
}
