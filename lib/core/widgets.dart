import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/cart_state.dart';
import 'theme.dart';

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String yes = 'Yes',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
      ],
    ),
  );
  return r == true;
}

Future<void> signOutAndReset(BuildContext context) async {
  final cart = context.read<CartState>();
  Navigator.of(context).popUntil((r) => r.isFirst);
  cart.clear();
  await AuthService.signOut();
}

class HLogo extends StatelessWidget {
  const HLogo({
    super.key,
    this.size = 28,
    this.light = false,
    this.showText = true,
  });
  final double size;
  final bool light;
  final bool showText;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/logo/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white : HColors.forest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.eco,
            color: light ? HColors.forest : Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
      if (showText) ...[
        const SizedBox(width: 8),
        Text(
          'Harvesta',
          style: TextStyle(
            color: light ? Colors.white : HColors.forest,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    ],
  );
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, [this.subtitle, this.trailing]);
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(color: HColors.muted, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: HColors.forest,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  );
}

class HCard extends StatelessWidget {
  const HCard({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.selected = false,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets margin, padding;
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: HColors.card,
        borderRadius: radius,
        border: Border.all(
          color: selected ? HColors.forest : HColors.line,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (accent != null) Container(width: 4, color: accent),
                  Expanded(
                    child: Padding(padding: padding, child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(
    this.text, {
    super.key,
    this.color = HColors.forest,
    this.bg = HColors.mint,
  });
  final String text;
  final Color color, bg;

  factory StatusChip.orange(String t) =>
      StatusChip(t, color: HColors.orange, bg: HColors.orangeSoft);
  factory StatusChip.red(String t) =>
      StatusChip(t, color: HColors.danger, bg: HColors.dangerSoft);
  factory StatusChip.grey(String t) =>
      StatusChip(t, color: HColors.muted, bg: const Color(0xFFEFEBDA));

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

StatusChip orderChip(String status, String label) {
  switch (status) {
    case 'delivered':
    case 'confirmed':
      return StatusChip(label);
    case 'declined':
    case 'cancelled':
      return StatusChip.red(label);
    default:
      return StatusChip.orange(label);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label,
    this.onPressed, {
    super.key,
    this.loading = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: HColors.forest,
      disabledBackgroundColor: HColors.forest.withAlpha(120),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
  );
}

class SoftButton extends StatelessWidget {
  const SoftButton(
    this.label,
    this.onPressed, {
    super.key,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: danger ? HColors.dangerSoft : HColors.lime,
      foregroundColor: danger ? HColors.danger : HColors.forest,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class OutlineBtn extends StatelessWidget {
  const OutlineBtn(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: HColors.forest,
      side: const BorderSide(color: HColors.forest),
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class HField extends StatelessWidget {
  const HField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.obscure = false,
    this.keyboard,
    this.validator,
    this.maxLines = 1,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HColors.muted,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          validator: validator,
          maxLines: obscure ? 1 : maxLines,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 18, color: HColors.muted),
          ),
        ),
      ],
    ),
  );
}

class KV extends StatelessWidget {
  const KV(this.k, this.v, {super.key, this.bold = false});
  final String k, v;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: HColors.muted, fontSize: 12.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class EmojiTile extends StatelessWidget {
  const EmojiTile(this.emoji, {super.key, this.size = 56});
  final String emoji;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: HColors.lime,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(emoji, style: TextStyle(fontSize: size * 0.55)),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_outlined});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(icon, size: 44, color: HColors.muted),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: HColors.muted),
        ),
      ],
    ),
  );
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 10,
    this.max,
  });
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double? max;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _btn(
        Icons.remove,
        () => onChanged((value - step).clamp(1, max ?? 1e9).toDouble()),
      ),
      Container(
        width: 76,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: HColors.line),
        ),
        child: Text(
          '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} kg',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      _btn(
        Icons.add,
        () => onChanged((value + step).clamp(1, max ?? 1e9).toDouble()),
      ),
    ],
  );

  Widget _btn(IconData i, VoidCallback f) => InkWell(
    onTap: f,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HColors.line),
      ),
      child: Icon(i, size: 18, color: HColors.forest),
    ),
  );
}

/// Subscribes to a Firestore stream once (in initState) so rebuilds don't re-subscribe.
class Live<T> extends StatefulWidget {
  const Live({super.key, required this.create, required this.builder});
  final Stream<T> Function() create;
  final Widget Function(BuildContext context, T data) builder;
  @override
  State<Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<Live<T>> {
  late final Stream<T> _stream = widget.create();
  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _stream,
    builder: (c, snap) {
      if (snap.hasError) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Could not load data.\n${snap.error}',
            style: const TextStyle(color: HColors.danger, fontSize: 12),
          ),
        );
      }
      if (snap.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return widget.builder(c, snap.data as T);
    },
  );
}

/// Pushed page layout: logo app bar + scrolling content + optional pinned bottom area.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.bottom,
    this.actions,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? bottom;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const HLogo(), centerTitle: false, actions: actions),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [ScreenTitle(title, subtitle), ...children],
    ),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: bottom,
            ),
          ),
  );
}
