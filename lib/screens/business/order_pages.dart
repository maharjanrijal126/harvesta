import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../state/cart_state.dart';

// ====================================================================== cart
class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    return SubPage(
      title: 'Bulk Order Cart',
      subtitle: 'Review quantities and delivery details.',
      bottom: PrimaryButton(
        'Continue to schedule',
        cart.isEmpty
            ? null
            : () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SchedulePage())),
      ),
      children: [
        if (cart.isEmpty)
          const EmptyState(
            'Your cart is empty.\nBrowse the catalogue to add produce.',
            icon: Icons.shopping_cart_outlined,
          ),
        for (var i = 0; i < cart.lines.length; i++)
          HCard(
            accent: HColors.forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cart.lines[i].product.name} • ${cart.lines[i].qty.round()} kg',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => cart.removeAt(i),
                    ),
                  ],
                ),
                Text(
                  '${npr(cart.lines[i].total)} • Grade ${cart.lines[i].product.grade} • ${cart.lines[i].product.supplierName}',
                  style: const TextStyle(color: HColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                QtyStepper(
                  value: cart.lines[i].qty,
                  max: cart.lines[i].product.qtyKg > 0
                      ? cart.lines[i].product.qtyKg
                      : null,
                  onChanged: (v) => cart.setQty(i, v),
                ),
              ],
            ),
          ),
        if (!cart.isEmpty) ...[
          const SectionHeader('Delivery'),
          HCard(
            accent: HColors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dShort(cart.deliveryDate)} • ${cart.window}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${Session.user?.address.isNotEmpty == true ? Session.user!.address : 'Set your address in Profile'} • Scheduled',
                  style: const TextStyle(color: HColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          HCard(
            child: Column(
              children: [
                KV('Subtotal', npr(cart.subtotal)),
                KV('Delivery', npr(deliveryFee)),
                KV('Service fee', npr(serviceFee)),
                const Divider(),
                KV('Total', npr(cart.total), bold: true),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ====================================================================== schedule step
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    return SubPage(
      title: 'Delivery Schedule',
      subtitle: 'Choose when to receive this order, or repeat it weekly.',
      bottom: PrimaryButton(
        'Continue to checkout',
        () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CheckoutPage())),
      ),
      children: [
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery date & window',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: cart.window,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Delivery window',
                      ),
                      items: [
                        for (final w in deliveryWindows)
                          DropdownMenuItem(value: w, child: Text(w)),
                      ],
                      onChanged: (v) => cart.update(win: v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: HColors.ink,
                        side: const BorderSide(color: HColors.line),
                      ),
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(dShort(cart.deliveryDate)),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: cart.deliveryDate,
                          firstDate: dayOnly(DateTime.now()),
                          lastDate: dayOnly(DateTime.now())
                              .add(const Duration(days: 120)),
                        );
                        if (d != null) cart.update(date: d);
                      },
                    ),
                  ),
                ],
              ),
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
                      'Repeat this order weekly',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Switch(
                    value: cart.repeat,
                    onChanged: (v) => cart.update(rep: v),
                  ),
                ],
              ),
              if (cart.repeat) ...[
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: cart.repeatTitle,
                  onChanged: (v) => cart.update(title: v),
                  decoration: const InputDecoration(
                    labelText: 'Recurring order name',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Delivery weekdays',
                  style: TextStyle(
                    fontSize: 12,
                    color: HColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                WeekdayPicker(
                  days: cart.repeatDays,
                  onChanged: (d) => cart.update(days: d),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your recurring template is saved under Orders → Scheduled. Each delivery is confirmed with the supplier.',
                  style: TextStyle(color: HColors.muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({super.key, required this.days, required this.onChanged});
  final List<int> days;
  final ValueChanged<List<int>> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (var i = 0; i < 7; i++)
        FilterChip(
          label: Text(
            weekdayShort[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: days.contains(i + 1) ? Colors.white : HColors.ink,
            ),
          ),
          selected: days.contains(i + 1),
          showCheckmark: false,
          selectedColor: HColors.forest,
          backgroundColor: Colors.white,
          onSelected: (on) {
            final l = [...days];
            on ? l.add(i + 1) : l.remove(i + 1);
            onChanged(l);
          },
        ),
    ],
  );
}

// ====================================================================== checkout
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _placing = false;

  Future<void> _place() async {
    final cart = context.read<CartState>();
    final user = Session.user;
    if (user == null || cart.isEmpty) return;
    if (cart.repeat && cart.repeatDays.isEmpty) {
      snack(context, 'Pick at least one weekday for the recurring order.');
      return;
    }
    setState(() => _placing = true);
    try {
      final order = HOrder(
        number: 'HV-${1000 + Random().nextInt(9000)}',
        businessId: user.uid,
        businessName: user.displayName,
        supplierId: cart.supplierId,
        supplierName: cart.supplierName,
        items: [
          for (final l in cart.lines)
            OrderItem(
              productId: l.product.id,
              name: l.product.name,
              grade: l.product.grade,
              price: l.product.price,
              qtyKg: l.qty,
            ),
        ],
        subtotal: cart.subtotal,
        fees: cart.fees,
        total: cart.total,
        deliveryDate: cart.deliveryDate,
        window: cart.window,
        address: user.address.isNotEmpty ? user.address : user.city,
        payment: 'Cash on delivery',
        recurring: cart.repeat,
      );
      await Db.placeOrder(order);
      if (cart.repeat) {
        await Db.addSchedule(
          Schedule(
            businessId: user.uid,
            title: cart.repeatTitle.trim().isEmpty
                ? 'Weekly pack'
                : cart.repeatTitle.trim(),
            supplierId: cart.supplierId,
            supplierName: cart.supplierName,
            lines: [
              for (final l in cart.lines)
                ScheduleLine(
                  name: l.product.name,
                  grade: l.product.grade,
                  price: l.product.price,
                  qtyKg: l.qty,
                ),
            ],
            weekdays: cart.repeatDays,
            window: cart.window,
            startDate: cart.deliveryDate,
          ),
        );
      }
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderConfirmationPage(order: order)),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (mounted)
        snack(
          context,
          'Could not place the order. Check your connection and try again.',
        );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final user = Session.user;
    return SubPage(
      title: 'Checkout',
      subtitle: 'Confirm your order and payment details.',
      bottom: PrimaryButton(
        'Place order • ${npr(cart.total)}',
        _place,
        loading: _placing,
      ),
      children: [
        HCard(
          accent: HColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              for (final l in cart.lines)
                KV(
                  '${l.product.name} ${l.qty.round()} kg × ${npr(l.product.price)}',
                  npr(l.total),
                ),
              KV('Delivery + service', npr(cart.fees)),
            ],
          ),
        ),
        HCard(
          accent: HColors.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                user?.address.isNotEmpty == true
                    ? user!.address
                    : (user?.city ?? ''),
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
              Text(
                '${dShort(cart.deliveryDate)} • ${cart.window}',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
              Text(
                'Contact: ${user?.name ?? ''}',
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const HCard(
          accent: HColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(
                'Cash on delivery (selected)',
                style: TextStyle(color: HColors.muted, fontSize: 12),
              ),
              Text(
                'Digital payment (coming soon)',
                style: TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (cart.repeat)
          HCard(
            accent: HColors.forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recurring schedule',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Every ${([...cart.repeatDays]..sort()).map((d) => weekdayShort[d - 1]).join(' • ')} • ${cart.window}',
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
                'Supplier',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                cart.supplierName,
                style: const TextStyle(color: HColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total • ${npr(cart.total)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.order});
  final HOrder order;
  @override
  Widget build(BuildContext context) => SubPage(
    title: 'Order Confirmation',
    subtitle: 'Your order has been placed successfully.',
    bottom: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          'Back Home',
          () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    ),
    children: [
      HCard(
        accent: HColors.forest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order.number}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${npr(order.total)} • ${dShort(order.deliveryDate)} • ${order.window}',
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
            Text(
              order.supplierName,
              style: const TextStyle(color: HColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Waiting for the supplier to accept. Track it under Orders → Active.',
              style: TextStyle(color: HColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    ],
  );
}

// ====================================================================== orders tab
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key, required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) => Live<List<HOrder>>(
    create: () => Db.watchBusinessOrders(user.uid),
    builder: (context, orders) {
      final active = orders.where((o) => o.isActive).toList();
      final done = orders.where((o) => !o.isActive).toList();
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ScreenTitle(
                  'Orders',
                  'Active, scheduled and completed orders.',
                ),
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: 'Active (${active.length})'),
                const Tab(text: 'Scheduled'),
                Tab(text: 'Completed (${done.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OrderList(orders: active, empty: 'No active orders.'),
                  _ScheduledList(user: user),
                  _OrderList(orders: done, empty: 'No completed orders yet.'),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.empty});
  final List<HOrder> orders;
  final String empty;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (orders.isEmpty) EmptyState(empty),
      for (final o in orders) _OrderCard(o),
    ],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.o);
  final HOrder o;

  Future<void> _repeat(BuildContext context) async {
    final cart = context.read<CartState>();
    cart.clear();
    for (final i in o.items) {
      cart.add(
        Product(
          id: i.productId,
          name: i.name,
          grade: i.grade,
          category: categoryFor(i.name),
          price: i.price,
          qtyKg: i.qtyKg,
          supplierId: o.supplierId,
          supplierName: o.supplierName,
          location: '',
          harvestDate: DateTime.now(),
        ),
        i.qtyKg,
      );
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CartPage()));
  }

  @override
  Widget build(BuildContext context) => HCard(
    accent: o.status == 'delivered'
        ? HColors.forest
        : (o.isActive ? HColors.orange : HColors.muted),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Order #${o.number}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            orderChip(o.status, o.statusLabel),
          ],
        ),
        Text(
          '${o.supplierName} • ${dShort(o.deliveryDate)} • ${o.window}',
          style: const TextStyle(color: HColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        for (final i in o.items)
          KV('${i.name} ${i.qtyKg.round()} kg × ${npr(i.price)}', npr(i.total)),
        const Divider(height: 14),
        KV('Total', npr(o.total), bold: true),
        const SizedBox(height: 8),
        if (o.status == 'pending')
          SoftButton('Cancel order', () async {
            if (await confirm(
              context,
              'Cancel this order?',
              'The supplier has not accepted it yet.',
              yes: 'Cancel order',
            )) {
              await Db.setOrderStatus(o.id, 'cancelled');
            }
          }, danger: true),
        if (!o.isActive) OutlineBtn('Repeat order', () => _repeat(context)),
      ],
    ),
  );
}

class _ScheduledList extends StatelessWidget {
  const _ScheduledList({required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) => Live<List<Schedule>>(
    create: () => Db.watchSchedules(user.uid),
    builder: (context, list) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (list.isEmpty)
          const EmptyState(
            'No recurring orders yet.\nTurn on "Repeat this order weekly" at checkout.',
            icon: Icons.event_repeat,
          ),
        for (final s in list) _ScheduleCard(s),
      ],
    ),
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(this.s);
  final Schedule s;
  @override
  Widget build(BuildContext context) {
    final next = s.nextDelivery;
    return HCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              s.paused ? StatusChip.grey('Paused') : const StatusChip('Active'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.weekdayText} • ${s.window}',
            style: const TextStyle(
              color: HColors.forest,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            s.supplierName,
            style: const TextStyle(color: HColors.muted, fontSize: 11.5),
          ),
          const Divider(height: 16),
          for (final l in s.lines)
            KV(l.name, '${l.qtyKg.round()} kg × ${npr(l.price)}'),
          const Divider(height: 16),
          KV(
            'Total per delivery',
            npr(s.perDelivery + deliveryFee + serviceFee),
            bold: true,
          ),
          if (!s.paused && next != null)
            KV('Next', '${dShort(next)} • ${s.window}'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  'Edit schedule',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditSchedulePage(schedule: s),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SoftButton(s.paused ? 'Resume' : 'Pause', () async {
                  s.paused = !s.paused;
                  await Db.saveSchedule(s);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SoftButton('Cancel recurring order', () async {
            if (await confirm(
              context,
              'Cancel recurring order?',
              'This removes "${s.title}". Past orders are kept.',
              yes: 'Cancel recurring',
            )) {
              await Db.deleteSchedule(s.id);
            }
          }, danger: true),
        ],
      ),
    );
  }
}

class EditSchedulePage extends StatefulWidget {
  const EditSchedulePage({super.key, required this.schedule});
  final Schedule schedule;
  @override
  State<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends State<EditSchedulePage> {
  late final Schedule s = widget.schedule;
  late final _title = TextEditingController(text: s.title);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (s.weekdays.isEmpty) {
      snack(context, 'Pick at least one delivery weekday.');
      return;
    }
    setState(() => _saving = true);
    try {
      s.title = _title.text.trim().isEmpty ? s.title : _title.text.trim();
      await Db.saveSchedule(s);
      if (!mounted) return;
      snack(context, 'Schedule updated.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) snack(context, 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(
    title: 'Edit Recurring Schedule',
    subtitle: '${s.supplierName}',
    bottom: Row(
      children: [
        Expanded(
          child: PrimaryButton('Save schedule', _save, loading: _saving),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SoftButton(
            'Cancel changes',
            () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
    children: [
      HField(controller: _title, hint: 'Name', label: 'Recurring order name'),
      HCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produce per delivery',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final l in s.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l.name} • ${npr(l.price)}/kg',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    QtyStepper(
                      value: l.qtyKg,
                      onChanged: (v) => setState(() => l.qtyKg = v),
                    ),
                  ],
                ),
              ),
            KV(
              'Total incl. fees',
              npr(s.perDelivery + deliveryFee + serviceFee),
              bold: true,
            ),
          ],
        ),
      ),
      HCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery weekdays',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            WeekdayPicker(
              days: s.weekdays,
              onChanged: (d) => setState(() => s.weekdays = d),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: deliveryWindows.contains(s.window)
                        ? s.window
                        : deliveryWindows[1],
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Delivery window',
                    ),
                    items: [
                      for (final w in deliveryWindows)
                        DropdownMenuItem(value: w, child: Text(w)),
                    ],
                    onChanged: (v) => setState(() => s.window = v ?? s.window),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: HColors.ink,
                      side: const BorderSide(color: HColors.line),
                    ),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(dShort(s.startDate)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: s.startDate.isBefore(DateTime.now())
                            ? DateTime.now()
                            : s.startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => s.startDate = d);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      HCard(
        accent: HColors.forest,
        child: const Text(
          'Saved schedules apply to future deliveries. Each delivery is still confirmed with the supplier.',
          style: TextStyle(color: HColors.muted, fontSize: 11.5),
        ),
      ),
    ],
  );
}
