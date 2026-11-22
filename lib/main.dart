import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/widgets.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/auth_pages.dart';
import 'screens/business/business_shell.dart';
import 'screens/farmer/farmer_shell.dart';
import 'screens/offline_page.dart';
import 'services/auth_service.dart';
import 'services/db.dart';
import 'services/session.dart';
import 'state/cart_state.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HarvestaApp());
}

class HarvestaApp extends StatelessWidget {
  const HarvestaApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CartState(),
    child: MaterialApp(
      title: 'Harvesta',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      builder: (context, child) => ConnectivityBanner(
        navigatorKey: navigatorKey,
        child: child ?? const SizedBox(),
      ),
      home: const AuthGate(),
    ),
  );
}

/// Same idea as the reference project: listen to authStateChanges and choose the screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const _Splash();
      final user = snapshot.data;
      if (user == null) {
        Session.user = null;
        return const RoleSelectionPage();
      }
      return UserRouter(uid: user.uid);
    },
  );
}

/// Reads users/{uid} and opens the dashboard that matches the role.
class UserRouter extends StatelessWidget {
  const UserRouter({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
    stream: Db.watchUser(uid),
    builder: (context, snap) {
      final user = snap.data;
      if (user == null) {
        // Profile is still being created (right after sign-up) or is missing.
        return _Splash(
          showSignOut: snap.connectionState == ConnectionState.active,
          message: snap.connectionState == ConnectionState.active
              ? 'Setting up your account…'
              : null,
        );
      }
      Session.user = user;
      switch (user.role) {
        case 'farmer':
          return FarmerShell(user: user);
        case 'admin':
          return AdminShell(user: user);
        default:
          return BusinessShell(user: user);
      }
    },
  );
}

class _Splash extends StatelessWidget {
  const _Splash({this.message, this.showSignOut = false});
  final String? message;
  final bool showSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HLogo(size: 44),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: HColors.muted)),
          ],
          if (showSignOut) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: AuthService.signOut,
              child: const Text('Sign out'),
            ),
          ],
        ],
      ),
    ),
  );
}
