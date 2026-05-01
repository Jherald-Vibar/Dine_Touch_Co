import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/menu_item_card.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _categories = ['All'];
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final restaurantId = await ApiService.getRestaurantId();
      final data = await ApiService.fetchMenu(restaurantId);
      final cats = ['All'];
      for (final c in (data['categories'] as List)) {
        cats.add(c['name'] as String);
      }
      final items = (data['items'] as List)
          .map((i) => MenuItem.fromJson(i as Map<String, dynamic>))
          .toList();
      setState(() {
        _categories = cats;
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MenuItem> get _filteredItems => _menuItems.where((item) {
        final matchCat =
            _selectedCategory == 'All' || item.category == _selectedCategory;
        final matchSearch =
            item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchCat && matchSearch && item.isAvailable;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      // ── Use resizeToAvoidBottomInset so keyboard doesn't squeeze layout ──
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildCategoryTabs(),
            // ── Expanded + clipped so grid never overflows ──
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      // ── Cart bar as proper bottomNavigationBar so Scaffold handles spacing ──
      bottomNavigationBar: cart.isEmpty ? null : _buildCartBar(context, cart),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border:
            Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/dine_touch_co.jpg',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('DT',
                        style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('MENU',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ]),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search menu...',
                hintStyle:
                    TextStyle(color: AppTheme.textHint, fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: AppTheme.textHint, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.border),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0A0A0A)
                              : AppTheme.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Loading menu...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Could not load menu',
                style:
                    TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textHint)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadMenu, child: const Text('Try Again')),
          ],
        ),
      );
    }
    final items = _filteredItems;
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🍽', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No items found',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      // ── padding bottom 16 is enough; cart bar is handled by Scaffold ──
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      // ── physics lets it scroll freely without fighting Column ──
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => MenuItemCard(item: items[i]),
    );
  }

  Widget _buildCartBar(BuildContext context, CartProvider cart) {
    // ── Wrap in SafeArea so it clears the home indicator on notched phones ──
    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CartScreen())),
        child: Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text('${cart.itemCount}',
                        style: const TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 13,
                            fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              const Text('View Order',
                  style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('₱${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF0A0A0A), size: 16),
            ]),
          ),
        ),
      ),
    );
  }
}