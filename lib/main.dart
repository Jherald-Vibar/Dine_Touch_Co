import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/menu_screen.dart';
import 'screens/kitchen_screen.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
// ─────────────────────────────────────────────────────────────
class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  // Gold accent color used throughout
  static const Color _gold = Color(0xFFD4AF6A);
  static const Color _darkBg = Color(0xFF0A0A0A);
  static const Color _cardBg = Color(0xFF111111);
  static const Color _cardBorder = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // ── Subtle dot-grid background ──────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Ambient glow top-center ─────────────────────
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 500,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(300),
                  gradient: RadialGradient(
                    colors: [
                      _gold.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo mark
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withOpacity(0.35),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'DT',
                          style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App name
                    const Text(
                      'DINE TOUCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Tagline with gold accent line
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 28, height: 1, color: _gold),
                        const SizedBox(width: 10),
                        const Text(
                          'Smart Restaurant System',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 28, height: 1, color: _gold),
                      ],
                    ),

                    const SizedBox(height: 52),

                    // Mode cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ModeCard(
                          emoji: '🍽',
                          title: 'Customer Kiosk',
                          subtitle: 'Browse menu & place orders',
                          accent: _gold,
                          onTap: () => Navigator.pushReplacement(
                            context,
                            _fadeRoute(const MenuScreen()),
                          ),
                        ),
                        const SizedBox(width: 20),
                        _ModeCard(
                          emoji: '👨‍🍳',
                          title: 'Kitchen Display',
                          subtitle: 'View & manage incoming orders',
                          accent: const Color(0xFF5E9BFF),
                          onTap: () => Navigator.pushReplacement(
                            context,
                            _fadeRoute(const KitchenScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Hint
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tap a mode to continue',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF555555),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );
}

// ── Mode Card ────────────────────────────────────────────────
class _ModeCard extends StatefulWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;
  final Color accent;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hover;
  bool _pressed = false;

  static const Color _cardBg = Color(0xFF111111);
  static const Color _cardBorder = Color(0xFF242424);

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _hover.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _hover.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _hover.reverse();
      },
      child: AnimatedBuilder(
        animation: _hover,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_hover.value * 0.02),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 220,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _pressed
                      ? widget.accent.withOpacity(0.6)
                      : _cardBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withOpacity(_pressed ? 0.18 : 0.0),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                  const BoxShadow(
                    color: Color(0xFF000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            // Emoji in accent-tinted circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accent.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Accent divider
            Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: widget.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // CTA row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: widget.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot-grid background painter ──────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1;

    const spacing = 32.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}