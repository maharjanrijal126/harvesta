import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';

/// Runs an auth action, shows errors, and on success pops back to the root so the
/// AuthGate (main.dart) can show the right dashboard for the signed-in role.
Future<void> _run(
  BuildContext context,
  ValueChanged<bool> setLoading,
  Future<void> Function() action,
) async {
  setLoading(true);
  try {
    await action();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  } catch (e) {
    if (context.mounted) snack(context, AuthService.friendly(e));
  } finally {
    if (context.mounted) setLoading(false);
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    this.subtitle,
    required this.children,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const HLogo(), centerTitle: false),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  subtitle!,
                  style: const TextStyle(color: HColors.muted, fontSize: 13),
                ),
              ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- role selection
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  Widget _role(String title, String sub, VoidCallback onTap) => HCard(
    accent: HColors.forest,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: HColors.muted, fontSize: 12)),
      ],
    ),
  );

  void _go(BuildContext c, Widget w) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Fresh produce. Reliable supply. Better business.',
    subtitle: 'Nepal B2B fresh produce: business demand → local harvest.',
    children: [
      _role(
        'Business',
        'Find suppliers, compare produce and order.',
        () => _go(context, const BusinessLoginPage()),
      ),
      _role(
        'Farmer / Supplier',
        'List harvests, set prices and manage supply.',
        () => _go(context, const FarmerLoginPage()),
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        'Continue as Business',
        () => _go(context, const BusinessLoginPage()),
      ),
      const SizedBox(height: 10),
      SoftButton(
        'Continue as Farmer/Supplier',
        () => _go(context, const FarmerLoginPage()),
      ),
      const SizedBox(height: 10),
      SoftButton(
        'Administrator login',
        () => _go(context, const AdminLoginPage()),
      ),
      const SizedBox(height: 28),
      const Center(
        child: Text(
          'Administrator login is for approved Harvesta staff.',
          style: TextStyle(color: HColors.muted, fontSize: 11),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------- business login / register
class BusinessLoginPage extends StatefulWidget {
  const BusinessLoginPage({super.key});
  @override
  State<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends State<BusinessLoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      context,
      (v) => setState(() => _loading = v),
      () => AuthService.signIn(
        email: _email.text,
        password: _pass.text,
        role: 'business',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Business Login',
    subtitle: 'Sign in to access your procurement workspace.',
    children: [
      Form(
        key: _form,
        child: Column(
          children: [
            HField(
              controller: _email,
              hint: 'Business email',
              icon: Icons.mail_outline,
              keyboard: TextInputType.emailAddress,
              validator: emailV,
            ),
            HField(
              controller: _pass,
              hint: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              validator: reqV,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      PrimaryButton('Login', _submit, loading: _loading),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ForgotPasswordPage(initial: _email.text),
            ),
          ),
          child: const Text('Forgot password?'),
        ),
      ),
      Row(
        children: [
          const Text(
            'New business? ',
            style: TextStyle(color: HColors.muted, fontSize: 12),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessRegisterPage()),
            ),
            child: const Text(
              'Create an account',
              style: TextStyle(
                color: HColors.forest,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const Text(
            ' to start ordering.',
            style: TextStyle(color: HColors.muted, fontSize: 12),
          ),
        ],
      ),
    ],
  );
}

class BusinessRegisterPage extends StatefulWidget {
  const BusinessRegisterPage({super.key});
  @override
  State<BusinessRegisterPage> createState() => _BusinessRegisterPageState();
}

class _BusinessRegisterPageState extends State<BusinessRegisterPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_email, _phone, _name, _city, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      context,
      (v) => setState(() => _loading = v),
      () => AuthService.registerBusiness(
        email: _email.text,
        password: _pass.text,
        phone: _phone.text,
        businessName: _name.text,
        city: _city.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Business Register',
    subtitle: 'Create your procurement account for fresh produce sourcing.',
    children: [
      Form(
        key: _form,
        child: Column(
          children: [
            HField(
              controller: _email,
              hint: 'Business email',
              icon: Icons.mail_outline,
              keyboard: TextInputType.emailAddress,
              validator: emailV,
            ),
            HField(
              controller: _phone,
              hint: 'Phone number',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: phoneV,
            ),
            HField(
              controller: _name,
              hint: 'Business name',
              icon: Icons.business_outlined,
              validator: reqV,
            ),
            HField(
              controller: _city,
              hint: 'City / District',
              icon: Icons.place_outlined,
              validator: reqV,
            ),
            HField(
              controller: _pass,
              hint: 'Password (6+ characters)',
              icon: Icons.lock_outline,
              obscure: true,
              validator: passV,
            ),
          ],
        ),
      ),
      PrimaryButton('Create account', _submit, loading: _loading),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Text(
          'Already have an account? Sign in to continue.',
          style: TextStyle(color: HColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------- farmer login / register
class FarmerLoginPage extends StatefulWidget {
  const FarmerLoginPage({super.key});
  @override
  State<FarmerLoginPage> createState() => _FarmerLoginPageState();
}

class _FarmerLoginPageState extends State<FarmerLoginPage> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      context,
      (v) => setState(() => _loading = v),
      () => AuthService.signIn(
        email: _id.text,
        password: _pass.text,
        role: 'farmer',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Farmer / Supplier Login',
    subtitle: 'Sign in to manage your harvest and supply.',
    children: [
      Form(
        key: _form,
        child: Column(
          children: [
            HField(
              controller: _id,
              label: 'Phone number or email',
              hint: 'ram.tamang@example.com',
              keyboard: TextInputType.emailAddress,
              validator: reqV,
            ),
            HField(
              controller: _pass,
              label: 'Password',
              hint: 'Password',
              obscure: true,
              validator: reqV,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      PrimaryButton('Login', _submit, loading: _loading),
      const SizedBox(height: 10),
      SoftButton(
        'Forgot password?',
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordPage(initial: _id.text),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'New to Harvesta? ',
            style: TextStyle(color: HColors.muted, fontSize: 12),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FarmerRegisterPage()),
            ),
            child: const Text(
              'Register your farm, group or supplier account.',
              style: TextStyle(
                color: HColors.forest,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 40),
      const Center(
        child: Text(
          'Your prices remain your choice. Market prices are guidance only.',
          style: TextStyle(color: HColors.muted, fontSize: 11),
        ),
      ),
    ],
  );
}

class FarmerRegisterPage extends StatefulWidget {
  const FarmerRegisterPage({super.key});
  @override
  State<FarmerRegisterPage> createState() => _FarmerRegisterPageState();
}

class _FarmerRegisterPageState extends State<FarmerRegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _farm = TextEditingController();
  final _loc = TextEditingController();
  final _info = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _farm, _loc, _info, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      context,
      (v) => setState(() => _loading = v),
      () => AuthService.registerFarmer(
        fullName: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _pass.text,
        farmName: _farm.text,
        location: _loc.text,
        farmInfo: _info.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Farmer / Supplier Registration',
    subtitle: 'Tell us about your farm or supplier group.',
    children: [
      Form(
        key: _form,
        child: Column(
          children: [
            HField(
              controller: _name,
              label: 'Full name',
              hint: 'Ram Tamang',
              validator: reqV,
            ),
            HField(
              controller: _email,
              label: 'Email',
              hint: 'ram.tamang@example.com',
              icon: Icons.mail_outline,
              keyboard: TextInputType.emailAddress,
              validator: emailV,
            ),
            HField(
              controller: _phone,
              label: 'Phone number',
              hint: '+977 9800000000',
              keyboard: TextInputType.phone,
              validator: phoneV,
            ),
            HField(
              controller: _farm,
              label: 'Farm / Group / Cooperative name',
              hint: 'Green Valley Farmer Group',
              validator: reqV,
            ),
            HField(
              controller: _loc,
              label: 'Location',
              hint: 'Kavre, Bagmati',
              validator: reqV,
            ),
            HField(
              controller: _info,
              label: 'Farm information',
              hint: 'List of vegetables, type of farm...',
              maxLines: 2,
              validator: reqV,
            ),
            HField(
              controller: _pass,
              label: 'Password',
              hint: '6+ characters',
              obscure: true,
              validator: passV,
            ),
          ],
        ),
      ),
      const Text(
        'Types: Individual farm • Group • Cooperative • Supplier',
        style: TextStyle(color: HColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 18),
      PrimaryButton('Submit for verification', _submit, loading: _loading),
    ],
  );
}

// ---------------------------------------------------------------- admin login
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _run(
      context,
      (v) => setState(() => _loading = v),
      () => AuthService.signIn(
        email: _email.text,
        password: _pass.text,
        role: 'admin',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Administrator Login',
    subtitle: 'Secure access for approved Harvesta staff.',
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: StatusChip(
          'Approved staff only',
          color: Color(0xFF3B5BA9),
          bg: Color(0xFFE4EBFA),
        ),
      ),
      const SizedBox(height: 12),
      Form(
        key: _form,
        child: Column(
          children: [
            HField(
              controller: _email,
              label: 'Staff email',
              hint: 'admin@harvesta.example',
              keyboard: TextInputType.emailAddress,
              validator: emailV,
            ),
            HField(
              controller: _pass,
              label: 'Password',
              hint: 'Password',
              obscure: true,
              validator: reqV,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      PrimaryButton('Login to admin console', _submit, loading: _loading),
      const SizedBox(height: 10),
      const Text(
        'No public staff registration. Contact your platform administrator to request access.',
        style: TextStyle(color: HColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 14),
      SoftButton(
        'Back to role selection',
        () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    ],
  );
}

// ---------------------------------------------------------------- forgot password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initial = ''});
  final String initial;
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final _id = TextEditingController(text: widget.initial);
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_id.text.trim().isEmpty) {
      snack(context, 'Enter your registered phone number or email.');
      return;
    }
    setState(() => _loading = true);
    try {
      final emailed = await AuthService.requestReset(_id.text);
      if (!mounted) return;
      snack(
        context,
        emailed ? 'Reset link sent. Check your inbox and spam folder.' : 'Phone accounts are reset by our team. Your request was sent to support.',
      );
    } catch (e) {
      if (mounted) snack(context, AuthService.friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
    title: 'Forgot Password',
    subtitle: 'Recover access to your Harvesta account.',
    children: [
      HField(
        controller: _id,
        label: 'Registered phone number or email',
        hint: 'ram.tamang@example.com',
        keyboard: TextInputType.emailAddress,
      ),
      const Text(
        'Use the phone or email associated with your business, farmer or staff account.',
        style: TextStyle(color: HColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 14),
      PrimaryButton('Send reset instructions', _send, loading: _loading),
      const SizedBox(height: 14),
      HCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              "Didn't receive instructions? Check your spam folder, confirm your details, or contact Harvesta support.",
              style: TextStyle(color: HColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SoftButton(
              'Contact support',
              () => snack(
                context,
                'Email support@harvesta.example (replace with your support address).',
              ),
            ),
          ],
        ),
      ),
      OutlineBtn('Back to login', () => Navigator.of(context).pop()),
    ],
  );
}
