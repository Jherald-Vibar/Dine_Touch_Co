import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/menu_screen.dart';
import 'screens/kitchen_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape for tablet kiosk mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for kiosk fullscreen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const DineTouchApp());
}

class DineTouchApp extends StatelessWidget {
  const DineTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Dine Touch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AppLauncher(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Launcher — choose Kiosk or Kitchen mode
// In production: two separate APK builds or separate entry points
// ─────────────────────────────────────────────────────────────
class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
              child: const Center(
                child: Text('DT', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dine Touch',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const Text('Smart Restaurant System',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 56),

            // Mode selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeCard(
                  emoji: '🍽',
                  title: 'Customer Kiosk',
                  subtitle: 'Browse menu & place orders',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  ),
                ),
                const SizedBox(width: 20),
                _ModeCard(
                  emoji: '👨‍🍳',
                  title: 'Kitchen Display',
                  subtitle: 'View & manage incoming orders',
                  color: const Color(0xFF1A1A1A),
                  textColor: Colors.white,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const KitchenScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            const Text('Tap to select mode', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppTheme.surface,
    this.textColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6), height: 1.4),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
