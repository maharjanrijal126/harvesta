import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../services/db.dart';

class BusinessSettings extends StatefulWidget {
  const BusinessSettings({super.key, required this.user});
  final AppUser user;
  @override
  State<BusinessSettings> createState() => _BusinessSettingsState();
}

class _BusinessSettingsState extends State<BusinessSettings> {
  late Map<String, dynamic> _p = {...defaultPrefs, ...widget.user.prefs};
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Db.updateUser(widget.user.uid, {'prefs': _p});
      if (mounted) snack(context, 'Preferences saved.');
    } catch (_) {
      if (mounted) snack(context, 'Could not save preferences.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editAccount() async {
    final u = widget.user;
    final name = TextEditingController(text: u.businessName);
    final phone = TextEditingController(text: u.phone);
    final address = TextEditingController(text: u.address);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Account & addresses'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HField(
                controller: name,
                hint: 'Business name',
                label: 'Business name',
              ),
              HField(
                controller: phone,
                hint: 'Phone',
                label: 'Contact phone',
                keyboard: TextInputType.phone,
              ),
              HField(
                controller: address,
                hint: 'Lazimpat, Kathmandu',
                label: 'Default delivery address',
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
    if (ok == true) {
      await Db.updateUser(u.uid, {
        'businessName': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
      });
    }
    name.dispose();
    phone.dispose();
    address.dispose();
  }

  Widget _sw(String title, String sub, String key) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    subtitle: Text(
      sub,
      style: const TextStyle(fontSize: 11, color: HColors.muted),
    ),
    value: _p[key] == true,
    onChanged: (v) => setState(() => _p[key] = v),
  );

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        ScreenTitle('Business Settings', '${u.displayName} • ${u.city}'),
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account & delivery',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              KV('Contact', u.name),
              KV('Email', u.email),
              KV('Phone', u.phone),
              KV('Business', u.businessName),
              KV('Default address', u.address.isEmpty ? '—' : u.address),
              const SizedBox(height: 8),
              SoftButton('Manage account & addresses', _editAccount),
            ],
          ),
        ),
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              _sw(
                'Order & delivery updates',
                'App alerts for confirmations and arrivals',
                'notifyOrders',
              ),
              _sw(
                'Recurring schedule reminders',
                'Before your scheduled deliveries',
                'notifySchedule',
              ),
            ],
          ),
        ),
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Language',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('English'),
                    selected: _p['language'] == 'en',
                    onSelected: (_) => setState(() => _p['language'] = 'en'),
                  ),
                  ChoiceChip(
                    label: const Text('नेपाली'),
                    selected: _p['language'] == 'ne',
                    onSelected: (_) => setState(() => _p['language'] = 'ne'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Preference is saved; Nepali translations can be added later.',
                style: TextStyle(fontSize: 10.5, color: HColors.muted),
              ),
            ],
          ),
        ),
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Network & offline sync',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              _sw(
                'Save drafts offline',
                'Keep unsubmitted order drafts on this device',
                'saveDrafts',
              ),
              _sw('Sync on Wi-Fi only', 'Limit mobile-data usage', 'wifiOnly'),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: PrimaryButton('Save preferences', _save, loading: _saving),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SoftButton('Sign out', () => signOutAndReset(context)),
            ),
          ],
        ),
      ],
    );
  }
}
