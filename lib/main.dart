import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EjemmaWalletApp()));
}

class EjemmaWalletApp extends ConsumerWidget {
  const EjemmaWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final restoreAsync = ref.watch(persistedWalletProvider);
    const seedColor = Color(0xFF1B5E20); // Deep green — Biafran identity

    return MaterialApp(
      title: 'EJEMMA Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: seedColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: const Color(0xFF0D3B10),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: restoreAsync.when(
        data: (_) => const HomeScreen(),
        loading: () => const _SplashScreen(),
        error: (_, __) => const HomeScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1B5E20),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text('EJEMMA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Loading wallet...', style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
