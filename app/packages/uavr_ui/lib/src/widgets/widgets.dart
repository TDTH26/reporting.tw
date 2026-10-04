import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/uavr_localizations.dart';
import '../labels.dart';
import '../theme.dart';

class SeverityChip extends StatelessWidget {
  const SeverityChip(this.severity, {super.key, this.compact = false});
  final int severity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = UavrColors.severity(severity);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
      child: Text(
        severityLabel(UavrL10n.of(context), severity),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: compact ? 11 : 13),
      ),
    );
  }
}

/// Small coloured pill for any status-like label.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: c), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Ticking countdown to [deadline]; turns red and shows +mm:ss once overdue.
class Countdown extends StatefulWidget {
  const Countdown(this.deadline, {super.key, this.style});
  final DateTime deadline;
  final TextStyle? style;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late final Timer _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deadline.difference(DateTime.now());
    final over = d.isNegative;
    final a = d.abs();
    final txt = '${over ? '+' : ''}${a.inMinutes.toString().padLeft(2, '0')}:${(a.inSeconds % 60).toString().padLeft(2, '0')}';
    return Text(
      txt,
      style: (widget.style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: over ? UavrColors.critical : (d.inSeconds < 60 ? UavrColors.medium : null),
        fontWeight: over ? FontWeight.w700 : null,
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = UavrL10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(l.errorGeneric, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l.retry)),
          ],
        ]),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
      );
}

/// Titled card section used across console, field and informant screens.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.child, this.trailing, this.padding});
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
              ?trailing,
            ]),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );
}

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key, this.mono = false});
  final String label;
  final String? value;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: SelectableText(
              value ?? '—',
              style: mono ? const TextStyle(fontFamily: 'monospace', fontSize: 12) : null,
            ),
          ),
        ]),
      );
}

/// "If anyone is in danger, call 110" banner shown on the informant report flow.
class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: UavrColors.critical.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.local_phone, size: 18, color: UavrColors.critical),
          const SizedBox(width: 8),
          Expanded(child: Text(UavrL10n.of(context).emergency110)),
        ]),
      );
}

/// Red notice that this deployment is the Taiwan Defense Tech Hackathon 2026 demo.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              UavrL10n.of(context).demoDisclaimer,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
    );
  }
}
