import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

/// Wraps the whole app: shows a slim banner while there is no connection.
/// Firestore keeps a local cache, so saved data stays readable offline.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({
    super.key,
    required this.child,
    required this.navigatorKey,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  void _apply(List<ConnectivityResult> r) {
    final off = r.every((e) => e == ConnectivityResult.none);
    if (off != _offline && mounted) setState(() => _offline = off);
  }

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_apply);
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: widget.child),
      if (_offline)
        Material(
          color: HColors.orange,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: () => widget.navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const OfflinePage()),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You're offline. Saved data is available.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});
  @override
  Widget build(BuildContext context) => SubPage(
    title: 'Offline',
    subtitle: 'No internet connection. Saved data is available.',
    children: [
      const HCard(
        accent: HColors.forest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved data available',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Orders, schedules and catalogue you opened before are cached on this device.',
              style: TextStyle(color: HColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const HCard(
        accent: HColors.orange,
        child: Text(
          'Changes you make offline are queued and sync automatically when you are back online. New orders need a connection to be confirmed.',
          style: TextStyle(color: HColors.muted, fontSize: 12),
        ),
      ),
      PrimaryButton('Back to app', () => Navigator.of(context).pop()),
    ],
  );
}
