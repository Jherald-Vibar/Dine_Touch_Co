import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/menu_screen.dart';
import 'screens/kitchen_screen.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// ─── Admin credentials (hashed) ─────────────────────────────────────────────
const _kAdminUsername = 'dine_touch_admin';

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

bool _validateAdmin(String username, String password) {
  return username == _kAdminUsername &&
      _hashPassword(password) == _hashPassword('dine12345678');
}

// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
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
// Launcher — Kiosk mode only; Kitchen hidden behind admin login
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

  static const Color _gold = Color(0xFFD4AF6A);
  static const Color _darkBg = Color(0xFF0A0A0A);

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

  void _onKitchenIconTap() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => _AdminLoginDialog(
        onSuccess: () {
          Navigator.of(context).pop();
          // Switch to landscape for kitchen
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          Navigator.pushReplacement(
            context,
            _fadeRoute(const KitchenScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── Dot-grid background ──────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Ambient glow top-center ──────────────────────
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 500,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(300),
                  gradient: RadialGradient(
                    colors: [_gold.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────
          FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Logo ──────────────────────────────
                        _buildLogo(),

                        const SizedBox(height: 16),

                        const Text(
                          'DINE TOUCH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 28, height: 1, color: _gold),
                            const SizedBox(width: 10),
                            const Text(
                              'Every dish, made for you.',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 28, height: 1, color: _gold),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // ── Kiosk card — fills width with side padding ──
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: _ModeCard(
                            emoji: '🍽',
                            title: 'Customer Kiosk',
                            subtitle: 'Browse menu & place orders',
                            accent: _gold,
                            onTap: () => Navigator.pushReplacement(
                              context,
                              _fadeRoute(const MenuScreen()),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: _gold, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap to get started',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF555555),
                                  letterSpacing: 1.5),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: _gold, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Hidden Kitchen access — top-right corner ─────
          Positioned(
            top: 12,
            right: 12,
            child: _KitchenAccessButton(onTap: _onKitchenIconTap),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF6A).withOpacity(0.40),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/dine_touch_co.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF6A),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text(
                'DT',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
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

// ─── Kitchen access button (subtle, top-right) ───────────────────────────────
class _KitchenAccessButton extends StatefulWidget {
  final VoidCallback onTap;
  const _KitchenAccessButton({required this.onTap});

  @override
  State<_KitchenAccessButton> createState() => _KitchenAccessButtonState();
}

class _KitchenAccessButtonState extends State<_KitchenAccessButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFF1E1E1E)
              : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF3A3A3A)
                : const Color(0xFF222222),
          ),
        ),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: Color(0xFF444444),
          size: 18,
        ),
      ),
    );
  }
}

// ─── Admin Login Dialog ───────────────────────────────────────────────────────
class _AdminLoginDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AdminLoginDialog({required this.onSuccess});

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _loading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));

    if (_validateAdmin(_userCtrl.text.trim(), _passCtrl.text)) {
      setState(() => _loading = false);
      widget.onSuccess();
    } else {
      setState(() {
        _loading = false;
        _error = 'Invalid username or password';
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A2A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Color(0xFF1E1E1E))),
                ),
                child: Column(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2E2E2E)),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFFD4AF6A), size: 22),
                  ),
                  const SizedBox(height: 14),
                  const Text('Kitchen Access',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Admin credentials required',
                      style: TextStyle(
                          color: Color(0xFF666666), fontSize: 12)),
                ]),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  _buildField(
                    controller: _userCtrl,
                    hint: 'Username',
                    icon: Icons.person_outline_rounded,
                    obscure: false,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _passCtrl,
                    hint: 'Password',
                    icon: Icons.key_outlined,
                    obscure: _obscure,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF555555),
                        size: 18,
                      ),
                    ),
                    onSubmit: _submit,
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 15),
                        const SizedBox(width: 8),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          foregroundColor: const Color(0xFF666666),
                          side: const BorderSide(color: Color(0xFF2A2A2A)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF6A),
                          foregroundColor: const Color(0xFF0A0A0A),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0A0A0A)))
                            : const Text('Enter Kitchen',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                      ),
                    ),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
    VoidCallback? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onSubmitted: (_) => onSubmit?.call(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF444444), fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFF555555), size: 18),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12), child: suffix)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          isDense: true,
        ),
      ),
    );
  }
}

// ── Mode Card ────────────────────────────────────────────────────────────────
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
        builder: (context, child) => Transform.scale(
          scale: 1.0 - (_hover.value * 0.02),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity, // ← KEY FIX: fills the Padding constraint
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
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
                  color: widget.accent
                      .withOpacity(_pressed ? 0.18 : 0.0),
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: widget.accent.withOpacity(0.25), width: 1),
              ),
              child: Center(
                child: Text(widget.emoji,
                    style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 2,
              decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Text(
              widget.subtitle,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.5,
                  letterSpacing: 0.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select',
                  style: TextStyle(
                      fontSize: 12,
                      color: widget.accent,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1),
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

// ── Dot-grid background painter ──────────────────────────────────────────────
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