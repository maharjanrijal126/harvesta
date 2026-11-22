import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../models/sample_data.dart';
import '../../services/db.dart';
import '../../state/cart_state.dart';

import 'package:provider/provider.dart';

import 'catalogue_pages.dart';
import 'order_pages.dart';

class SupplierTile extends StatelessWidget {
  const SupplierTile(this.s, this.products, {super.key});
  final SupplierInfo s;
  final List<Product> products;
  @override
  Widget build(BuildContext context) => HCard(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SupplierProfilePage(supplier: s))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            StatusChip('${s.rating}'),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${s.location} • Verified • ${s.onTime}% on-time',
          style: const TextStyle(color: HColors.muted, fontSize: 11.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final n in [...s.produce.take(2), s.location])
              StatusChip.grey(n),
          ],
        ),
      ],
    ),
  );
}

class SuppliersTab extends StatefulWidget {
  const SuppliersTab({super.key});
  @override
  State<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends State<SuppliersTab> {
  final _q = TextEditingController();

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
        'Suppliers',
        'Discover reliable, verified local suppliers.',
      ),
      TextField(
        controller: _q,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search name or district',
          prefixIcon: Icon(Icons.search, size: 20),
        ),
      ),
      const SizedBox(height: 12),
      Live<List<Product>>(
        create: Db.watchProducts,
        builder: (context, products) {
          final q = _q.text.trim().toLowerCase();
          final list = suppliersFrom(products)
              .where(
                (s) =>
                    q.isEmpty ||
                    s.name.toLowerCase().contains(q) ||
                    s.location.toLowerCase().contains(q),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Verified supplier directory',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${list.length} suppliers',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (list.isEmpty) const EmptyState('No suppliers found.'),
              for (final s in list) SupplierTile(s, products),
              const Text(
                'Ratings and reliability are historical sample metrics, not live performance data.',
                style: TextStyle(color: HColors.muted, fontSize: 10.5),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class SupplierProfilePage extends StatelessWidget {
  const SupplierProfilePage({super.key, required this.supplier});
  final SupplierInfo supplier;
  @override
  Widget build(BuildContext context) => SubPage(
    title: 'Supplier Profile',
    subtitle: 'Your local partner for dependable supply.',
    bottom: PrimaryButton(
      'View products → Catalogue',
      () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CataloguePage(initialQuery: supplier.name),
        ),
      ),
    ),
    children: [
      HCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    supplier.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                StatusChip('${supplier.rating}'),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${supplier.location} • Verified supplier',
              style: const TextStyle(color: HColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            StatusChip.grey(supplier.location),
          ],
        ),
      ),
      HCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Quality & reliability',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const StatusChip('Grade A produce'),
              ],
            ),
            const SizedBox(height: 8),
            KV('On-time supply', '${supplier.onTime}%'),
            KV('Completed orders', '${supplier.completed}'),
            const SizedBox(height: 6),
            const Text(
              'Fresh, sorted produce with batch traceability and quality checks before dispatch.',
              style: TextStyle(color: HColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
      const SectionHeader('Available produce'),
      Live<List<Product>>(
        create: Db.watchProducts,
        builder: (c, all) => Column(
          children: [
            for (final p in all.where((p) => p.supplierId == supplier.id))
              ProductTile(p),
          ],
        ),
      ),
    ],
  );
}

class SupplierComparisonPage extends StatefulWidget {
  const SupplierComparisonPage({
    super.key,
    required this.produce,
    required this.qty,
  });
  final String produce;
  final double qty;
  @override
  State<SupplierComparisonPage> createState() => _SupplierComparisonPageState();
}

class _SupplierComparisonPageState extends State<SupplierComparisonPage> {
  late double _qty = widget.qty;

  Future<void> _choose(Product p) async {
    final q = _qty > p.qtyKg ? p.qtyKg : _qty;
    final ok = await addToCart(context, p, q);
    if (ok && mounted)
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CartPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    return Live<List<Product>>(
      create: Db.watchProducts,
      builder: (context, all) {
        final list = all.where((p) => p.name == widget.produce).toList()
          ..sort((a, b) => a.price.compareTo(b.price));
        Product? best;
        for (final p in list) {
          if (p.qtyKg >= _qty) {
            best = p;
            break;
          }
        }
        return SubPage(
          title: 'Supplier Comparison',
          subtitle: 'Compare price, available quantity, quality, location, delivery window and reliability.',
          bottom: best == null
              ? null
              : PrimaryButton(
                  'Choose ${best.supplierName.split(' ').first}',
                  () => _choose(best!),
                ),
          children: [
            HCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected quantity',
                          style: TextStyle(color: HColors.muted, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        QtyStepper(
                          value: _qty,
                          onChanged: (v) => setState(() => _qty = v),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Line price',
                        style: TextStyle(color: HColors.muted, fontSize: 11),
                      ),
                      Text(
                        best == null ? '—' : npr(best.price * _qty),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: HColors.forest,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (list.isEmpty)
              const EmptyState('No suppliers currently offer this produce.'),
            for (final p in list)
              HCard(
                selected: p.id == best?.id,
                onTap: () => _choose(p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.supplierName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                p.location,
                                style: const TextStyle(
                                  color: HColors.muted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (p.verified) const StatusChip('Verified'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _cell('Price', '${npr(p.price)} / kg')),
                        Expanded(child: _cell('Available', kgText(p.qtyKg))),
                        Expanded(child: _cell('Quality', 'Grade ${p.grade}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _cell(
                            'Delivery',
                            '${dShort(cart.deliveryDate)} • ${cart.window}',
                          ),
                        ),
                        Expanded(
                          child: _cell(
                            'Reliability',
                            '${metaFor(p.supplierId).onTime}% on time',
                          ),
                        ),
                        Expanded(
                          child: _cell(
                            'Rating',
                            '${metaFor(p.supplierId).rating}',
                          ),
                        ),
                      ],
                    ),
                    if (p.id == best?.id)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              'Recommended for ${_qty.round()} kg',
                              style: const TextStyle(
                                color: HColors.forest,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              npr(p.price * _qty),
                              style: const TextStyle(
                                color: HColors.forest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (p.qtyKg < _qty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Not enough stock for this quantity.',
                          style: TextStyle(
                            color: HColors.orange,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cell(String k, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: const TextStyle(color: HColors.muted, fontSize: 10.5)),
      Text(
        v,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    ],
  );
}
