import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import 'farmer_pages.dart';

class FarmerShell extends StatefulWidget {
  const FarmerShell({super.key, required this.user});
  final AppUser user;
  @override
  State<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends State<FarmerShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final pages = <Widget>[
      FarmerOverview(user: u, onOpenTab: (i) => setState(() => _i = i)),
      MyHarvestTab(user: u),
      FarmerOrdersTab(user: u),
      const MarketPricesTab(),
      EarningsTab(user: u),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const HLogo(),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmerProfilePage()),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: HColors.forest,
                child: Text(
                  u.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            label: 'My Harvest',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Prices'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Earnings',
          ),
        ],
      ),
    );
  }
}
