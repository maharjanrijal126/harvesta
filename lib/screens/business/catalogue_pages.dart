import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../state/cart_state.dart';
import 'order_pages.dart';
import 'supplier_pages.dart';

/// Adds to the cart, asking before replacing a cart that belongs to another supplier.
Future<bool> addToCart(BuildContext context, Product p, double qty) async {
  final cart = context.read<CartState>();
  if (!cart.canAdd(p)) {
    final ok = await confirm(
      context,
      'Start a new order?',
      'Your cart has items from ${cart.supplierName}. An order can only contain one supplier. Replace the cart with ${p.supplierName}?',
      yes: 'Replace cart',
    );
    if (!ok) return false;
    cart.clear();
  }
  cart.add(p, qty);
  return true;
}

class CataloguePage extends StatelessWidget {
  const CataloguePage({
    super.key,
    this.initialQuery = '',
    this.initialCategory = 'All',
  });
  final String initialQuery, initialCategory;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const HLogo(), centerTitle: false),
    body: CatalogueView(
      initialQuery: initialQuery,
      initialCategory: initialCategory,
    ),
  );
}

class CatalogueView extends StatefulWidget {
  const CatalogueView({
    super.key,
    this.initialQuery = '',
    this.initialCategory = 'All',
  });
  final String initialQuery, initialCategory;
  @override
  State<CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<CatalogueView> {
  late final TextEditingController _q;
  late String _cat;
  bool _gradeA = false, _verified = false;
  String _sort = 'relevance';

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.initialQuery);
    _cat = widget.initialCategory;
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      const ScreenTitle(
        'Produce Catalogue',
        'Fresh produce from verified local suppliers.',
      ),
      TextField(
        controller: _q,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search produce, supplier, or location',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _q.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(_q.clear),
                ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final c in ['All', ...productCategories])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _cat == c,
                  showCheckmark: false,
                  selectedColor: HColors.forest,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _cat == c ? Colors.white : HColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _cat = c),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _filter('Grade A', _gradeA, (v) => setState(() => _gradeA = v)),
            _filter(
              'Verified',
              _verified,
              (v) => setState(() => _verified = v),
            ),
            _filter(
              'Price: low to high',
              _sort == 'price',
              (v) => setState(() => _sort = v ? 'price' : 'relevance'),
            ),
            _filter(
              'Most available',
              _sort == 'qty',
              (v) => setState(() => _sort = v ? 'qty' : 'relevance'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Live<List<Product>>(
        create: Db.watchProducts,
        builder: (context, all) {
          final q = _q.text.trim().toLowerCase();
          var list = all.where((p) {
            if (_cat != 'All' && p.category != _cat) return false;
            if (_gradeA && p.grade != 'A') return false;
            if (_verified && !p.verified) return false;
            if (q.isEmpty) return true;
            return p.name.toLowerCase().contains(q) ||
                p.supplierName.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q);
          }).toList();
          if (_sort == 'price') list.sort((a, b) => a.price.compareTo(b.price));
          if (_sort == 'qty') list.sort((a, b) => b.qtyKg.compareTo(a.qtyKg));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${list.length} matching products',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const EmptyState(
                  'No produce matches your search.',
                  icon: Icons.search_off,
                ),
              for (final p in list) ProductTile(p),
              const Text(
                'Verified suppliers • Prices are set by suppliers. Availability and prices shown are sample prototype data until farmers publish batches.',
                style: TextStyle(color: HColors.muted, fontSize: 10.5),
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _filter(String label, bool on, ValueChanged<bool> f) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      selected: on,
      onSelected: f,
      showCheckmark: false,
      selectedColor: HColors.lime,
      backgroundColor: Colors.white,
      side: BorderSide(color: on ? HColors.forest : HColors.line),
    ),
  );
}

class ProductTile extends StatelessWidget {
  const ProductTile(this.p, {super.key});
  final Product p;
  @override
  Widget build(BuildContext context) => HCard(
    onTap: () => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))),
    child: Row(
      children: [
        EmojiTile(emojiFor(p.name)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.name} Grade ${p.grade}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const StatusChip('In stock'),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${p.supplierName} • ${p.location}',
                style: const TextStyle(color: HColors.muted, fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${npr(p.price)} / kg',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const Spacer(),
                  Text(
                    '${kgText(p.qtyKg)} available',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              if (p.verified)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Verified supplier',
                    style: TextStyle(
                      color: HColors.forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late double _qty = widget.product.qtyKg < 50 ? widget.product.qtyKg : 50;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartState>();
    return SubPage(
      title: 'Product Detail',
      subtitle: 'Fresh harvest from verified local suppliers.',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton('Add to order', () async {
            final ok = await addToCart(context, p, _qty);
            if (ok && context.mounted) {
              snack(context, '${p.name} added to your order.');
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CartPage()));
            }
          }),
          const SizedBox(height: 8),
          OutlineBtn(
            'Compare suppliers',
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SupplierComparisonPage(produce: p.name, qty: _qty),
              ),
            ),
          ),
        ],
      ),
      children: [
        Container(
          height: 170,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HColors.lime,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(emojiFor(p.name), style: const TextStyle(fontSize: 84)),
        ),
        const SizedBox(height: 14),
        HCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${p.name} Grade ${p.grade}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${npr(p.price)} / kg',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: HColors.forest,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        HCard(
          accent: HColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${kgText(p.qtyKg)} • Harvest: ${dShort(p.harvestDate)}',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        HCard(
          accent: HColors.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supplier',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${p.verified ? 'Verified ' : ''}${p.supplierName} • ${p.location}',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        HCard(
          accent: HColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${dShort(cart.deliveryDate)} • ${cart.window} (change at checkout)',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        HCard(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              QtyStepper(
                value: _qty,
                max: p.qtyKg,
                onChanged: (v) => setState(() => _qty = v),
              ),
            ],
          ),
        ),
        Text(
          'Line total: ${npr(p.price * _qty)}',
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
