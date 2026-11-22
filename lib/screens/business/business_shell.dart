import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../models/sample_data.dart';
import '../../services/db.dart';
import '../../state/cart_state.dart';
import 'catalogue_pages.dart';
import 'order_pages.dart';
import 'settings_page.dart';
import 'supplier_pages.dart';

class BusinessShell extends StatefulWidget {
  const BusinessShell({super.key, required this.user});
  final AppUser user;
  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      BusinessHome(user: widget.user, onOpenTab: (i) => setState(() => _i = i)),
      const CatalogueView(),
      OrdersTab(user: widget.user),
      const SuppliersTab(),
      BusinessSettings(user: widget.user),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const HLogo(),
        centerTitle: false,
        actions: const [CartButton()],
      ),
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Suppliers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class CartButton extends StatelessWidget {
  const CartButton({super.key});
  @override
  Widget build(BuildContext context) => Consumer<CartState>(
    builder: (c, cart, _) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: () =>
            Navigator.of(c)
                .push(MaterialPageRoute(builder: (_) => const CartPage())),
        icon: Badge(
          isLabelVisible: cart.count > 0,
          label: Text('${cart.count}'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    ),
  );
}

class BusinessHome extends StatelessWidget {
  const BusinessHome({super.key, required this.user, required this.onOpenTab});
  final AppUser user;
  final ValueChanged<int> onOpenTab;

  void _push(BuildContext c, Widget w) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      ScreenTitle('Business Dashboard', '${greeting()}, ${user.displayName}'),
      TextField(
        textInputAction: TextInputAction.search,
        onSubmitted: (q) => _push(context, CataloguePage(initialQuery: q)),
        decoration: const InputDecoration(
          hintText: 'Search produce, supplier, or order',
          prefixIcon: Icon(Icons.search, size: 20),
        ),
      ),
      const SizedBox(height: 8),
      SectionHeader(
        'Product Categories',
        action: 'See all',
        onAction: () => onOpenTab(1),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in productCategories)
            ActionChip(
              label: Text(
                c,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: HColors.line),
              onPressed: () =>
                  _push(context, CataloguePage(initialCategory: c)),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Live<List<Product>>(
        create: Db.watchProducts,
        builder: (context, products) {
          final top = [...products]..sort((a, b) => b.qtyKg.compareTo(a.qtyKg));
          final suppliers = suppliersFrom(products);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                'Recommended produce',
                action: 'See all',
                onAction: () => onOpenTab(1),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [for (final p in top.take(4)) _MiniProduct(p)],
              ),
              SectionHeader(
                'Verified suppliers',
                action: 'See all',
                onAction: () => onOpenTab(3),
              ),
              for (final s in suppliers.take(3)) SupplierTile(s, products),
            ],
          );
        },
      ),
    ],
  );
}

class _MiniProduct extends StatelessWidget {
  const _MiniProduct(this.p);
  final Product p;
  @override
  Widget build(BuildContext context) => HCard(
    margin: EdgeInsets.zero,
    onTap: () => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emojiFor(p.name), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${p.supplierName} • ${p.location}',
          style: const TextStyle(color: HColors.muted, fontSize: 10.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              '${npr(p.price)}/kg',
              style: const TextStyle(fontSize: 11, color: HColors.muted),
            ),
            const Spacer(),
            Text(
              kgText(p.qtyKg),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}
