import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../services/db.dart';

Widget _stat(String label, String value, String sub) => Expanded(
  child: HCard(
    margin: const EdgeInsets.only(right: 8, bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: HColors.muted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(sub, style: const TextStyle(color: HColors.muted, fontSize: 10.5)),
      ],
    ),
  ),
);

Widget _row(Color dot, String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
    ],
  ),
);

Widget _page(List<Widget> children) =>
    ListView(padding: const EdgeInsets.all(16), children: children);

// ====================================================================== overview
class AdminOverview extends StatelessWidget {
  const AdminOverview({super.key});
  @override
  Widget build(BuildContext context) => Live<List<AppUser>>(
    create: Db.watchUsers,
    builder: (context, users) => Live<List<HOrder>>(
      create: Db.watchAllOrders,
      builder: (context, orders) {
        final biz = users.where((u) => u.role == 'business').length;
        final farmers = users.where((u) => u.role == 'farmer').toList();
        final admins = users.where((u) => u.role == 'admin').length;
        int n(String s) => orders.where((o) => o.status == s).length;
        return _page([
          Row(
            children: [
              _stat('Business users', '$biz', 'Active • role-based access'),
              _stat(
                'Farmers',
                '${farmers.length}',
                'Verified • ${farmers.where((f) => f.isVerified).length} / pending ${farmers.where((f) => f.verificationStatus == 'pending').length}',
              ),
            ],
          ),
          Row(
            children: [
              _stat('Admins', '$admins', 'Least-privilege roles'),
              _stat(
                'Orders',
                '${orders.length}',
                '${orders.where((o) => o.isActive).length} active',
              ),
            ],
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User roles',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _row(HColors.forest, 'Business users', '$biz'),
                _row(
                  HColors.limeStrong,
                  'Farmers / suppliers',
                  '${farmers.length}',
                ),
                _row(HColors.orange, 'Admins', '$admins'),
              ],
            ),
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery performance',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _row(HColors.forest, 'Delivered', '${n('delivered')}'),
                _row(HColors.limeStrong, 'In transit', '${n('collected')}'),
                _row(HColors.orange, 'Awaiting supplier', '${n('pending')}'),
                _row(
                  HColors.danger,
                  'Declined / cancelled',
                  '${n('declined') + n('cancelled')}',
                ),
              ],
            ),
          ),
        ]);
      },
    ),
  );
}

// ====================================================================== verification
class AdminVerification extends StatelessWidget {
  const AdminVerification({super.key});

  Future<void> _decide(BuildContext context, AppUser f, String status) async {
    await Db.setVerification(f.uid, status);
    if (context.mounted) snack(context, '${f.farmName} marked as $status.');
  }

  @override
  Widget build(BuildContext context) => Live<List<AppUser>>(
    create: Db.watchUsers,
    builder: (context, users) {
      final farmers = users.where((u) => u.role == 'farmer').toList();
      final pending = farmers
          .where((f) => f.verificationStatus == 'pending')
          .toList();
      final verified = farmers.where((f) => f.isVerified).length;
      return _page([
        Row(
          children: [
            _stat('Pending', '${pending.length}', 'Verification queue'),
            _stat('Verified', '$verified', 'Approved suppliers'),
          ],
        ),
        const SectionHeader('Verification queue'),
        if (pending.isEmpty)
          const EmptyState(
            'No applications waiting for review.',
            icon: Icons.verified_outlined,
          ),
        for (final f in pending)
          HCard(
            accent: HColors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.farmName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${f.name} • ${f.phone} • ${f.location}',
                  style: const TextStyle(color: HColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(f.farmInfo, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        'Approve',
                        () => _decide(context, f, 'verified'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SoftButton(
                        'Reject',
                        () => _decide(context, f, 'rejected'),
                        danger: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SectionHeader('All farmers'),
        for (final f in farmers.where((f) => f.verificationStatus != 'pending'))
          HCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.farmName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        f.location,
                        style: const TextStyle(
                          color: HColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                verificationStatusChip(f),
                PopupMenuButton<String>(
                  onSelected: (s) => _decide(context, f, s),
                  itemBuilder: (c) => const [
                    PopupMenuItem(
                      value: 'verified',
                      child: Text('Mark verified'),
                    ),
                    PopupMenuItem(
                      value: 'rejected',
                      child: Text('Mark rejected'),
                    ),
                    PopupMenuItem(
                      value: 'pending',
                      child: Text('Move to pending'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ]);
    },
  );

  static StatusChip verificationStatusChip(AppUser f) => f.isVerified
      ? const StatusChip('Verified')
      : (f.verificationStatus == 'rejected'
            ? StatusChip.red('Rejected')
            : StatusChip.orange('Pending'));
}

// ====================================================================== supply
class AdminSupply extends StatelessWidget {
  const AdminSupply({super.key});
  @override
  Widget build(BuildContext context) => Live<List<AppUser>>(
    create: Db.watchUsers,
    builder: (context, users) => Live<List<Product>>(
      create: Db.watchAllHarvests,
      builder: (context, harvests) {
        final farmers = users
            .where((u) => u.role == 'farmer' && u.isVerified)
            .toList();
        final published = harvests
            .where((h) => h.status == 'published')
            .toList();
        final kg = published.fold(0.0, (a, b) => a + b.qtyKg);
        final byLoc = <String, int>{};
        for (final f in farmers) {
          final k = f.location.isEmpty
              ? 'Unknown'
              : f.location.split(',').first.trim();
          byLoc[k] = (byLoc[k] ?? 0) + 1;
        }
        return _page([
          Row(
            children: [
              _stat(
                'Primary sources',
                '${farmers.length}',
                'Verified farmers / groups',
              ),
              _stat('Published batches', '${published.length}', kgText(kg)),
            ],
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Source hierarchy',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _row(
                  HColors.forest,
                  'Primary • Farmers / groups',
                  '${farmers.length}',
                ),
                _row(
                  HColors.limeStrong,
                  'Secondary • Collection centres',
                  'Configured in policy',
                ),
                _row(
                  HColors.orange,
                  'Contingency • Backup suppliers',
                  'Last resort',
                ),
              ],
            ),
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supply coverage by location',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (byLoc.isEmpty)
                  const Text(
                    'No verified farmers yet.',
                    style: TextStyle(color: HColors.muted, fontSize: 12),
                  ),
                for (final e in byLoc.entries)
                  _row(HColors.forest, e.key, '${e.value} farmers'),
              ],
            ),
          ),
        ]);
      },
    ),
  );
}

// ====================================================================== order aggregation
class AdminAggregation extends StatelessWidget {
  const AdminAggregation({super.key});
  @override
  Widget build(BuildContext context) => Live<List<HOrder>>(
    create: Db.watchAllOrders,
    builder: (context, orders) => Live<List<Product>>(
      create: Db.watchAllHarvests,
      builder: (context, harvests) {
        final open = orders
            .where((o) => o.status == 'pending' || o.status == 'confirmed')
            .toList();
        final demand = <String, double>{};
        for (final o in open) {
          for (final i in o.items) {
            demand[i.name] = (demand[i.name] ?? 0) + i.qtyKg;
          }
        }
        final supply = <String, double>{};
        for (final h in harvests.where((h) => h.status == 'published')) {
          supply[h.name] = (supply[h.name] ?? 0) + h.qtyKg;
        }
        final totalDemand = demand.values.fold(0.0, (a, b) => a + b);
        final matched = demand.entries.fold(
          0.0,
          (a, e) =>
              a +
              (e.value < (supply[e.key] ?? 0) ? e.value : (supply[e.key] ?? 0)),
        );
        final pending = open.where((o) => o.status == 'pending').toList();
        return _page([
          const ScreenTitle(
            'Demand matching',
            'Match aggregated business demand with available farmer batches.',
          ),
          Row(
            children: [
              _stat(
                'Aggregated demand',
                kgText(totalDemand),
                '${open.length} open orders',
              ),
              _stat('Matched harvest', kgText(matched), 'from farmer batches'),
            ],
          ),
          HCard(
            accent: HColors.forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aggregated demand',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (demand.isEmpty)
                  const Text(
                    'No open orders.',
                    style: TextStyle(color: HColors.muted, fontSize: 12),
                  ),
                for (final e in demand.entries)
                  _row(
                    HColors.forest,
                    '${e.key} • supply ${kgText(supply[e.key] ?? 0)}',
                    kgText(e.value),
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
                  'Allocation summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                KV('Matched', kgText(matched)),
                KV('Unmatched', kgText(totalDemand - matched)),
                KV('Pending supplier replies', '${pending.length}'),
              ],
            ),
          ),
          PrimaryButton(
            'Approve allocation (confirm ${pending.length} pending)',
            pending.isEmpty
                ? null
                : () async {
                    if (await confirm(
                      context,
                      'Approve allocation?',
                      'This confirms ${pending.length} pending orders on behalf of suppliers.',
                      yes: 'Approve',
                    )) {
                      for (final o in pending) {
                        await Db.setOrderStatus(o.id, 'confirmed');
                      }
                    }
                  },
          ),
        ]);
      },
    ),
  );
}

// ====================================================================== reports
class AdminReports extends StatelessWidget {
  const AdminReports({super.key});
  @override
  Widget build(BuildContext context) => Live<List<HOrder>>(
    create: Db.watchAllOrders,
    builder: (context, orders) => Live<List<Product>>(
      create: Db.watchAllHarvests,
      builder: (context, harvests) {
        final demand = <String, double>{};
        for (final o in orders.where((o) => o.isActive)) {
          for (final i in o.items) {
            demand[i.name] = (demand[i.name] ?? 0) + i.qtyKg;
          }
        }
        final supply = <String, double>{};
        for (final h in harvests.where((h) => h.status == 'published')) {
          supply[h.name] = (supply[h.name] ?? 0) + h.qtyKg;
        }
        final names = {...demand.keys, ...supply.keys}.toList()..sort();
        final maxV = [
          1.0,
          ...demand.values,
          ...supply.values,
        ].reduce((a, b) => a > b ? a : b);
        int n(String s) => orders.where((o) => o.status == s).length;

        String csv() {
          final b = StringBuffer('produce,demand_kg,supply_kg\n');
          for (final k in names) {
            b.writeln('$k,${demand[k] ?? 0},${supply[k] ?? 0}');
          }
          b.writeln('\norder_status,count');
          for (final s in [
            'pending',
            'confirmed',
            'collected',
            'delivered',
            'declined',
            'cancelled',
          ]) {
            b.writeln('$s,${n(s)}');
          }
          return b.toString();
        }

        return _page([
          const ScreenTitle(
            'Reports',
            'Demand, supply, order and delivery analytics.',
          ),
          PrimaryButton('Export report (copy CSV)', () async {
            await Clipboard.setData(ClipboardData(text: csv()));
            if (context.mounted)
              snack(context, 'Report copied to clipboard as CSV.');
          }, icon: Icons.download),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(
                'Demand / Available',
                '${kgText(demand.values.fold(0.0, (a, b) => a + b))} / ${kgText(supply.values.fold(0.0, (a, b) => a + b))}',
                'open orders vs published',
              ),
              _stat(
                'Orders',
                '${orders.length}',
                '${n('pending')} pending • ${n('confirmed')} confirmed',
              ),
            ],
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demand vs available supply (kg)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (names.isEmpty)
                  const Text(
                    'No data yet.',
                    style: TextStyle(color: HColors.muted, fontSize: 12),
                  ),
                for (final k in names) ...[
                  Text(
                    k,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _bar(
                    (demand[k] ?? 0) / maxV,
                    HColors.forest,
                    'Demand ${kgText(demand[k] ?? 0)}',
                  ),
                  const SizedBox(height: 3),
                  _bar(
                    (supply[k] ?? 0) / maxV,
                    HColors.limeStrong,
                    'Supply ${kgText(supply[k] ?? 0)}',
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Orders & delivery status',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _row(HColors.orange, 'Pending', '${n('pending')}'),
                _row(HColors.forest, 'Confirmed', '${n('confirmed')}'),
                _row(HColors.limeStrong, 'In transit', '${n('collected')}'),
                _row(HColors.forest, 'Delivered', '${n('delivered')}'),
              ],
            ),
          ),
        ]);
      },
    ),
  );

  Widget _bar(double f, Color c, String label) => Row(
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: f.clamp(0.0, 1.0),
            minHeight: 8,
            color: c,
            backgroundColor: HColors.line,
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 90,
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: HColors.muted),
        ),
      ),
    ],
  );
}

// ====================================================================== market prices
class AdminPrices extends StatelessWidget {
  const AdminPrices({super.key});

  Future<void> _edit(BuildContext context, String name, List<double> r) async {
    final lo = TextEditingController(text: r[0].round().toString());
    final hi = TextEditingController(text: r[1].round().toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$name price guidance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HField(
              controller: lo,
              hint: '90',
              label: 'Min NPR / kg',
              keyboard: TextInputType.number,
            ),
            HField(
              controller: hi,
              hint: '105',
              label: 'Max NPR / kg',
              keyboard: TextInputType.number,
            ),
          ],
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
    if (ok == true && toD(lo.text) > 0 && toD(hi.text) >= toD(lo.text)) {
      await Db.setPrice(name, toD(lo.text), toD(hi.text));
    }
    lo.dispose();
    hi.dispose();
  }

  @override
  Widget build(BuildContext context) => Live<Map<String, List<double>>>(
    create: Db.watchPrices,
    builder: (context, prices) => _page([
      const ScreenTitle(
        'Market Prices',
        'Guidance shown to farmers. Tap a card to update today\'s range.',
      ),
      for (final e in prices.entries)
        HCard(
          onTap: () => _edit(context, e.key, e.value),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        color: HColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'NPR ${e.value[0].round()}–${e.value[1].round()}/kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18, color: HColors.forest),
            ],
          ),
        ),
    ]),
  );
}

// ====================================================================== quality & delivery
class AdminQuality extends StatelessWidget {
  const AdminQuality({super.key});
  @override
  Widget build(BuildContext context) => Live<List<HOrder>>(
    create: Db.watchAllOrders,
    builder: (context, orders) => Live<List<Product>>(
      create: Db.watchAllHarvests,
      builder: (context, harvests) {
        int n(String s) => orders.where((o) => o.status == s).length;
        final a = harvests.where((h) => h.grade == 'A').length;
        final b = harvests.where((h) => h.grade == 'B').length;
        final kg = harvests
            .where((h) => h.status == 'published')
            .fold(0.0, (x, h) => x + h.qtyKg);
        return _page([
          Row(
            children: [
              _stat('Harvest batches', '${harvests.length}', 'All farmers'),
              _stat('Quality grade', 'A:$a • B:$b', 'Batches by grade'),
            ],
          ),
          Row(
            children: [
              _stat('Delivery', '${n('collected')}', 'in transit'),
              _stat('Produce volume', kgText(kg), 'published'),
            ],
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Order state',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusChip('${orders.length}'),
                  ],
                ),
                const SizedBox(height: 6),
                _row(HColors.orange, 'Pending', '${n('pending')}'),
                _row(HColors.forest, 'Confirmed', '${n('confirmed')}'),
                _row(
                  HColors.limeStrong,
                  'Collected / in transit',
                  '${n('collected')}',
                ),
                _row(HColors.forest, 'Delivered', '${n('delivered')}'),
                _row(
                  HColors.danger,
                  'Declined / cancelled',
                  '${n('declined') + n('cancelled')}',
                ),
              ],
            ),
          ),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quality grade',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _row(HColors.forest, 'Grade A', '$a'),
                _row(HColors.limeStrong, 'Grade B', '$b'),
              ],
            ),
          ),
        ]);
      },
    ),
  );
}

// ====================================================================== settings
class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});
  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  Map<String, dynamic>? _s;
  bool _saving = false;

  Widget _sw(String label, String key) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    value: _s![key] == true,
    onChanged: (v) => setState(() => _s![key] = v),
  );

  @override
  Widget build(BuildContext context) => Live<Map<String, dynamic>>(
    create: Db.watchPlatform,
    builder: (context, remote) {
      _s ??= {...remote};
      return _page([
        const ScreenTitle(
          'Platform Settings',
          'Manage marketplace policies, quality and delivery rules.',
        ),
        HCard(
          accent: HColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verification policies',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              _sw('Identity document required', 'identityRequired'),
              _sw('Group / Cooperative registration', 'groupRequired'),
              _sw('Farm & collection location review', 'locationReview'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _s!['reviewTarget'] as String,
                decoration: const InputDecoration(
                  labelText: 'Staff review target',
                ),
                items: [
                  for (final t in [
                    '1 business day',
                    '2 business days',
                    '3 business days',
                  ])
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _s!['reviewTarget'] = v),
              ),
            ],
          ),
        ),
        HCard(
          accent: HColors.orange,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source priority',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              KV('Primary • Farmers / groups', 'First priority'),
              KV('Secondary • Collection centres', 'If shortfall'),
              KV('Contingency • Backup suppliers', 'Last resort'),
            ],
          ),
        ),
        PrimaryButton('Save settings', () async {
          setState(() => _saving = true);
          try {
            await Db.savePlatform(_s!);
            if (context.mounted) snack(context, 'Settings saved.');
          } finally {
            if (mounted) setState(() => _saving = false);
          }
        }, loading: _saving),
      ]);
    },
  );
}
