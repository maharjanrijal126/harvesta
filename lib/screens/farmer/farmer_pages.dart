import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../services/session.dart';

StatusChip verificationChip(AppUser u) {
  switch (u.verificationStatus) {
    case 'verified':
      return const StatusChip('Verified');
    case 'rejected':
      return StatusChip.red('Rejected');
    default:
      return StatusChip.orange('Pending verification');
  }
}

// ====================================================================== overview
class FarmerOverview extends StatelessWidget {
  const FarmerOverview({
    super.key,
    required this.user,
    required this.onOpenTab,
  });
  final AppUser user;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      ScreenTitle('Farmer Dashboard', '${user.farmName} • ${user.location}'),
      HCard(
        accent: HColors.forest,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VerificationStatusPage()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Verification status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                verificationChip(user),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user.isVerified
                  ? '${user.name} • ${user.location}. You can publish harvest batches to business buyers.'
                  : 'Selling stays unavailable until staff approve your account. Tap to see progress.',
              style: const TextStyle(color: HColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Live<Map<String, List<double>>>(
        create: Db.watchPrices,
        builder: (c, prices) => HCard(
          accent: HColors.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Market price guidance',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusChip.orange('Guidance only'),
                ],
              ),
              const SizedBox(height: 6),
              KV(
                'Tomato',
                '${npr(prices['Tomato']![0])}–${prices['Tomato']![1].round()}/kg',
              ),
              KV(
                'Cauliflower',
                '${npr(prices['Cauliflower']![0])}–${prices['Cauliflower']![1].round()}/kg',
              ),
              const SizedBox(height: 4),
              const Text(
                'Your prices remain your choice.',
                style: TextStyle(color: HColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      Live<List<Product>>(
        create: () => Db.watchHarvests(user.uid),
        builder: (c, batches) {
          final published = batches
              .where((b) => b.status == 'published')
              .toList();
          return HCard(
            accent: HColors.forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Available harvest batches',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusChip('${published.length} batches'),
                  ],
                ),
                const SizedBox(height: 8),
                if (published.isEmpty)
                  const Text(
                    'No published batches yet.',
                    style: TextStyle(color: HColors.muted, fontSize: 12),
                  ),
                for (final b in published.take(3))
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HColors.orangeSoft.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${b.name} • ${kgText(b.qtyKg)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        Text(
                          '${npr(b.price)}/kg',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                SoftButton('Manage harvest', () => onOpenTab(1)),
              ],
            ),
          );
        },
      ),
      Live<List<HOrder>>(
        create: () => Db.watchSupplierOrders(user.uid),
        builder: (c, orders) {
          final pending = orders.where((o) => o.status == 'pending').length;
          return HCard(
            accent: HColors.orange,
            onTap: () => onOpenTab(2),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Business orders',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                pending > 0
                    ? StatusChip.orange('$pending need your reply')
                    : const StatusChip('All caught up'),
              ],
            ),
          );
        },
      ),
    ],
  );
}

// ====================================================================== my harvest
class MyHarvestTab extends StatelessWidget {
  const MyHarvestTab({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      const ScreenTitle(
        'My Harvest',
        'Dated batches ready for business orders and collection.',
      ),
      Live<List<Product>>(
        create: () => Db.watchHarvests(user.uid),
        builder: (context, list) => Column(
          children: [
            if (list.isEmpty)
              const EmptyState(
                'No harvest batches yet.\nAdd your first batch below.',
                icon: Icons.spa_outlined,
              ),
            for (final b in list)
              HCard(
                accent: b.status == 'published'
                    ? HColors.forest
                    : HColors.orange,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddHarvestPage(existing: b),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${b.name} • ${kgText(b.qtyKg)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        b.status == 'published'
                            ? const StatusChip('Published')
                            : StatusChip.orange('Draft'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    KV('Harvest date', dShort(b.harvestDate)),
                    KV('Price/kg', npr(b.price)),
                    KV(
                      'Collection',
                      b.collectionDate == null
                          ? '—'
                          : dShort(b.collectionDate!),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (b.status != 'published' && !user.isVerified) {
                                snack(
                                  context,
                                  'You can publish once your account is verified.',
                                );
                                return;
                              }
                              await Db.setHarvestStatus(
                                b.id,
                                b.status == 'published' ? 'draft' : 'published',
                              );
                            },
                            child: Text(
                              b.status == 'published' ? 'Unpublish' : 'Publish',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: HColors.danger,
                          ),
                          onPressed: () async {
                            if (await confirm(
                              context,
                              'Delete batch?',
                              'Remove ${b.name} • ${kgText(b.qtyKg)}?',
                              yes: 'Delete',
                            )) {
                              await Db.deleteHarvest(b.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      PrimaryButton(
        'Add another batch',
        () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddHarvestPage())),
        icon: Icons.add,
      ),
    ],
  );
}

class AddHarvestPage extends StatefulWidget {
  const AddHarvestPage({super.key, this.existing});
  final Product? existing;
  @override
  State<AddHarvestPage> createState() => _AddHarvestPageState();
}

class _AddHarvestPageState extends State<AddHarvestPage> {
  final _form = GlobalKey<FormState>();
  late String _produce = widget.existing?.name ?? 'Tomato';
  late String _grade = widget.existing?.grade ?? 'A';
  late DateTime _harvest =
      widget.existing?.harvestDate ?? dayOnly(DateTime.now());
  late DateTime _collect =
      widget.existing?.collectionDate ??
      dayOnly(DateTime.now()).add(const Duration(days: 1));
  late final _qty = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.qtyKg.round().toString(),
  );
  late final _price = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.price.round().toString(),
  );
  late final _loc = TextEditingController(
    text: widget.existing?.location ?? Session.user?.location ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _loc.dispose();
    super.dispose();
  }

  Future<void> _pick(bool harvest) async {
    final d = await showDatePicker(
      context: context,
      initialDate: harvest ? _harvest : _collect,
      firstDate: dayOnly(DateTime.now()).subtract(const Duration(days: 7)),
      lastDate: dayOnly(DateTime.now()).add(const Duration(days: 90)),
    );
    if (d != null) setState(() => harvest ? _harvest = d : _collect = d);
  }

  Future<void> _save(String status) async {
    if (!_form.currentState!.validate()) return;
    final u = Session.user!;
    if (status == 'published' && !u.isVerified) {
      snack(
        context,
        'Your account is not verified yet. Save as a draft for now.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await Db.saveHarvest(
        Product(
          id: widget.existing?.id ?? '',
          name: _produce,
          grade: _grade,
          category: categoryFor(_produce),
          price: toD(_price.text),
          qtyKg: toD(_qty.text),
          supplierId: u.uid,
          supplierName: u.farmName.isNotEmpty ? u.farmName : u.name,
          location: _loc.text.trim(),
          harvestDate: _harvest,
          collectionDate: _collect,
          verified: u.isVerified,
          status: status,
        ),
      );
      if (!mounted) return;
      snack(
        context,
        status == 'published'
            ? 'Batch published to business buyers.'
            : 'Draft saved.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) snack(context, 'Could not save the batch. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(
    title: widget.existing == null ? 'Add Harvest' : 'Edit Harvest',
    subtitle:
        'Set your own price and publish a harvest batch for business buyers.',
    bottom: Row(
      children: [
        Expanded(
          child: SoftButton(
            'Save draft',
            _saving ? null : () => _save('draft'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PrimaryButton(
            'Publish',
            () => _save('published'),
            loading: _saving,
          ),
        ),
      ],
    ),
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HCard(
              accent: HColors.forest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _produce,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Produce',
                          ),
                          items: [
                            for (final p in produceNames)
                              DropdownMenuItem(value: p, child: Text(p)),
                          ],
                          onChanged: (v) =>
                              setState(() => _produce = v ?? _produce),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _grade,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Grade'),
                          items: [
                            for (final g in ['A', 'B'])
                              DropdownMenuItem(
                                value: g,
                                child: Text('Grade $g'),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _grade = v ?? _grade),
                        ),
                      ),
                    ],
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
                    'Harvest date',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pick(true),
                          child: Text('Harvest: ${dShort(_harvest)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pick(false),
                          child: Text('Available: ${dShort(_collect)}'),
                        ),
                      ),
                    ],
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
                    'Available quantity & price',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: HField(
                          controller: _qty,
                          hint: '120',
                          label: 'Quantity (kg)',
                          keyboard: TextInputType.number,
                          validator: (v) => toD(v) > 0 ? null : 'Enter kg',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HField(
                          controller: _price,
                          hint: '95',
                          label: 'Your price / kg',
                          keyboard: TextInputType.number,
                          validator: (v) => toD(v) > 0 ? null : 'Enter price',
                        ),
                      ),
                    ],
                  ),
                  Live<Map<String, List<double>>>(
                    create: Db.watchPrices,
                    builder: (c, p) {
                      final r = p[_produce] ?? p['Mixed']!;
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: HColors.orangeSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Market guidance: NPR ${r[0].round()}–${r[1].round()}/kg. The final price is your choice.',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      );
                    },
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
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  HField(controller: _loc, hint: 'Kavre', validator: reqV),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ====================================================================== business orders
class FarmerOrdersTab extends StatelessWidget {
  const FarmerOrdersTab({super.key, required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      const ScreenTitle(
        'Business Orders',
        'Review incoming orders and confirm collection details.',
      ),
      Live<List<HOrder>>(
        create: () => Db.watchSupplierOrders(user.uid),
        builder: (context, orders) => Column(
          children: [
            if (orders.isEmpty)
              const EmptyState(
                'No orders yet.\nOrders for your published batches will appear here.',
              ),
            for (final o in orders)
              HCard(
                accent: o.status == 'pending' ? HColors.orange : HColors.forest,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CollectionDetailsPage(orderId: o.id),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.businessName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        orderChip(o.status, o.statusLabel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final i in o.items)
                      KV(i.name, '${kgText(i.qtyKg)} × ${npr(i.price)}'),
                    KV('Total', npr(o.total), bold: true),
                    KV('Collection', '${dShort(o.deliveryDate)} • ${o.window}'),
                    if (o.status == 'pending') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              'Accept',
                              () => Db.setOrderStatus(o.id, 'confirmed'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlineBtn('Decline', () async {
                              if (await confirm(
                                context,
                                'Decline order?',
                                'The buyer will be notified.',
                                yes: 'Decline',
                              )) {
                                await Db.setOrderStatus(o.id, 'declined');
                              }
                            }),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class CollectionDetailsPage extends StatelessWidget {
  const CollectionDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) => Live<HOrder?>(
    create: () => Db.watchOrder(orderId),
    builder: (context, o) {
      if (o == null)
        return const SubPage(
          title: 'Collection Details',
          children: [EmptyState('This order no longer exists.')],
        );
      final u = Session.user;
      final next = o.status == 'confirmed'
          ? 'collected'
          : (o.status == 'collected' ? 'delivered' : null);
      return SubPage(
        title: 'Collection Details',
        subtitle: 'Confirm quality requirements, location and quantity before pickup.',
        bottom: o.status == 'pending'
            ? Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      'Accept',
                      () => Db.setOrderStatus(o.id, 'confirmed'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlineBtn(
                      'Decline',
                      () => Db.setOrderStatus(o.id, 'declined'),
                    ),
                  ),
                ],
              )
            : (next == null
                  ? null
                  : PrimaryButton(
                      next == 'collected'
                          ? 'Mark as collected'
                          : 'Mark as delivered',
                      () => Db.setOrderStatus(o.id, next),
                    )),
        children: [
          HCard(
            accent: HColors.forest,
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Order summary',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    orderChip(o.status, o.statusLabel),
                  ],
                ),
                const SizedBox(height: 6),
                KV('Order', '#${o.number}'),
                KV('Business', o.businessName),
                for (final i in o.items) ...[
                  KV('Produce', '${kgText(i.qtyKg)} ${i.name}'),
                  KV('Price/kg', npr(i.price)),
                ],
                KV('Total', npr(o.total), bold: true),
              ],
            ),
          ),
          const HCard(
            accent: HColors.orange,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quality requirements',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                KV('Grade', 'As listed'),
                KV('Packaging', 'Clean crates'),
                KV('Handling', 'No bruising'),
              ],
            ),
          ),
          HCard(
            accent: HColors.forest,
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Collection location',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                KV('Address', '${u?.farmName ?? ''}, ${u?.location ?? ''}'),
                KV('Contact', '${u?.name ?? ''} ${u?.phone ?? ''}'),
                KV('Window', '${dShort(o.deliveryDate)} • ${o.window}'),
                KV('Deliver to', o.address),
              ],
            ),
          ),
        ],
      );
    },
  );
}

// ====================================================================== market prices
class MarketPricesTab extends StatelessWidget {
  const MarketPricesTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      const ScreenTitle(
        'Market Prices',
        'Updated by Harvesta staff • Guidance only. Farmers choose their own price.',
      ),
      Live<Map<String, List<double>>>(
        create: Db.watchPrices,
        builder: (context, prices) => Live<List<Product>>(
          create: () => Db.watchHarvests(Session.user!.uid),
          builder: (context, mine) => Column(
            children: [
              for (final e in prices.entries.where((e) => e.key != 'Mixed'))
                HCard(
                  accent: HColors.forest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          StatusChip.orange('Guidance only'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NPR ${e.value[0].round()}–${e.value[1].round()}/kg',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Builder(
                        builder: (c) {
                          final m = mine.where((b) => b.name == e.key).toList();
                          return Text(
                            m.isEmpty
                                ? 'Review before setting a harvest price.'
                                : 'Your current harvest price is ${npr(m.first.price)}/kg.',
                            style: const TextStyle(
                              color: HColors.muted,
                              fontSize: 11.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ====================================================================== earnings
class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key, required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      const ScreenTitle(
        'Earnings & Payout',
        'Completed orders, transparent fees and final payout.',
      ),
      Live<List<HOrder>>(
        create: () => Db.watchSupplierOrders(user.uid),
        builder: (context, orders) {
          final done = orders.where((o) => o.status == 'delivered').toList();
          final gross = done.fold(0.0, (a, o) => a + o.subtotal);
          final fee = gross * platformFeeRate;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HCard(
                accent: HColors.forest,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Current cycle',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(npr(gross - fee)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    KV('Completed orders', '${done.length}'),
                    KV('Gross earnings', npr(gross)),
                    KV(
                      'Platform fee (${(platformFeeRate * 100).round()}%)',
                      '− ${npr(fee)}',
                    ),
                    const Divider(),
                    KV('Final payout', npr(gross - fee), bold: true),
                  ],
                ),
              ),
              PrimaryButton(
                'Request payout',
                done.isEmpty
                    ? null
                    : () async {
                        await Db.requestPayout(user.uid, gross - fee);
                        if (context.mounted)
                          snack(
                            context,
                            'Payout request sent to Harvesta staff.',
                          );
                      },
              ),
              const SectionHeader('Completed order records'),
              if (done.isEmpty)
                const EmptyState(
                  'Delivered orders will be listed here.',
                  icon: Icons.receipt_long_outlined,
                ),
              for (final o in done)
                HCard(
                  child: Column(
                    children: [
                      KV('#${o.number} • ${dShort(o.deliveryDate)}', ''),
                      KV(
                        'Gross ${npr(o.subtotal)} − fee ${npr(o.subtotal * platformFeeRate)}',
                        npr(o.subtotal * (1 - platformFeeRate)),
                        bold: true,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

// ====================================================================== profile & verification
class FarmerProfilePage extends StatelessWidget {
  const FarmerProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final u = Session.user!;
    return SubPage(
      title: 'Farmer Profile',
      subtitle: 'Verification, farm information and payout history.',
      children: [
        HCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: HColors.forest,
                child: Text(
                  u.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${u.isVerified ? 'Verified farmer' : 'Farmer'} • ${u.location}',
                      style: const TextStyle(
                        color: HColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      u.farmName,
                      style: const TextStyle(
                        color: HColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    verificationChip(u),
                  ],
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Farm information',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _edit(context, u),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: HColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              KV('Location', u.location),
              KV('Phone', u.phone),
              KV('Practices / crops', u.farmInfo.isEmpty ? '—' : u.farmInfo),
            ],
          ),
        ),
        Live<List<HOrder>>(
          create: () => Db.watchSupplierOrders(u.uid),
          builder: (c, orders) {
            final done = orders.where((o) => o.status == 'delivered').length;
            return HCard(
              accent: HColors.orange,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Supply history',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusChip('$done orders'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  KV('Completed orders', '$done'),
                  KV('Total orders received', '${orders.length}'),
                ],
              ),
            );
          },
        ),
        OutlineBtn(
          'Verification status',
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VerificationStatusPage()),
          ),
        ),
        const SizedBox(height: 10),
        SoftButton('Sign out', () => signOutAndReset(context)),
      ],
    );
  }

  Future<void> _edit(BuildContext context, AppUser u) async {
    final loc = TextEditingController(text: u.location);
    final info = TextEditingController(text: u.farmInfo);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Farm information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HField(
                controller: loc,
                hint: 'Kavre, Bagmati',
                label: 'Location',
              ),
              HField(
                controller: info,
                hint: 'Tomato, potato, cauliflower…',
                label: 'Crops & practices',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true)
      await Db.updateUser(u.uid, {
        'location': loc.text.trim(),
        'farmInfo': info.text.trim(),
      });
    loc.dispose();
    info.dispose();
  }
}

class VerificationStatusPage extends StatelessWidget {
  const VerificationStatusPage({super.key});

  Widget _step(
    String text,
    String sub,
    bool done, {
    bool failed = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          failed ? Icons.cancel : (done ? Icons.check_circle : Icons.schedule),
          size: 20,
          color: failed
              ? HColors.danger
              : (done ? HColors.forest : HColors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: HColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final u = Session.user!;
    final verified = u.isVerified,
        rejected = u.verificationStatus == 'rejected';
    return SubPage(
      title: 'Verification Status',
      subtitle: verified
          ? 'Your account is approved.'
          : 'Pending account • Staff review',
      children: [
        HCard(
          accent: HColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your application',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  verificationChip(u),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                verified
                    ? 'You can publish harvest batches and receive business orders.'
                    : rejected
                    ? 'Your application was not approved. Contact support with clearer documents or farm details.'
                    : 'Details received. Staff are reviewing your supplier details. Selling remains unavailable until approval.',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review progress',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              _step(
                'Application submitted',
                'Registration details received',
                true,
              ),
              _step(
                'Details received',
                'Identity, location and farm information',
                true,
              ),
              _step(
                'Staff review',
                'Checking identity, location and farm details',
                verified || rejected,
              ),
              _step(
                rejected ? 'Application rejected' : 'Decision',
                rejected
                    ? 'Please contact support'
                    : (verified ? 'Approved' : 'Awaiting staff decision'),
                verified || rejected,
                failed: rejected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
