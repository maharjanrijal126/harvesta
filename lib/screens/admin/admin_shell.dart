import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import 'admin_pages.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 8,
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: HColors.forest,
        foregroundColor: Colors.white,
        title: const Text(
          'Harvesta Admin',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          Live<List<HOrder>>(
            create: Db.watchAllOrders,
            builder: (c, orders) => Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${orders.where((o) => o.isActive).length} active orders',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => signOutAndReset(context),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: HColors.limeStrong,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Verification'),
            Tab(text: 'Supply'),
            Tab(text: 'Order Aggregation'),
            Tab(text: 'Reports'),
            Tab(text: 'Market Prices'),
            Tab(text: 'Quality & Delivery'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          AdminOverview(),
          AdminVerification(),
          AdminSupply(),
          AdminAggregation(),
          AdminReports(),
          AdminPrices(),
          AdminQuality(),
          AdminSettings(),
        ],
      ),
    ),
  );
}
