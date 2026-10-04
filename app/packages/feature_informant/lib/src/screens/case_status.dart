import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';
import 'package:uavr_ui/uavr_ui.dart';

import '../services/capture.dart';
import '../services/my_reports.dart';
import '../services/uploads.dart';
import '../widgets/common.dart';

const _timelineSteps = ['received', 'in_review', 'in_progress', 'completed'];

/// Status, outcome and evidence requests for one report stored on this device.
class CaseStatusScreen extends ConsumerWidget {
  const CaseStatusScreen(this.caseNumber, {super.key});
  final String caseNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(informantCaseProvider(caseNumber));
    ref.watch(evidenceCaptureProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l.caseTitle(caseNumber))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(informantCaseProvider(caseNumber).future),
        child: switch (lookup) {
          AsyncData(:final value) => _CaseBody(value),
          AsyncError(:final error) => ListView(children: [
              ErrorView(
                error is ApiException && error.isNetwork ? context.u.errorNetwork : error,
                onRetry: () => ref.invalidate(informantCaseProvider(caseNumber)),
              ),
            ]),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _CaseBody extends StatelessWidget {
  const _CaseBody(this.lookup);
  final CaseLookup lookup;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final stored = lookup.stored;
    final c = lookup.live;
    if (stored == null || c == null) {
      return ListView(children: [EmptyView(l.caseNotOnDevice, icon: Icons.search_off)]);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Pill(informantStatusLabel(context.u, c.status), color: statusColor(c.status)),
            const SizedBox(width: 12),
            Expanded(child: Text(l.caseUpdated(relativeTime(context.u, c.updatedAt)))),
          ]),
          const SizedBox(height: 16),
          Section(title: l.caseProgress, child: _Timeline(c)),
          if (c.outcomeText != null) ...[
            const SizedBox(height: 12),
            Section(title: l.caseOutcome, child: Text(c.outcomeText!, style: Theme.of(context).textTheme.bodyLarge)),
          ],
          if (c.evidenceRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Section(
              title: l.caseEvidenceRequests,
              child: Column(children: [
                for (final r in c.evidenceRequests) _EvidenceRequestCard(stored, r),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline(this.c);
  final InformantCase c;

  @override
  Widget build(BuildContext context) {
    final reached = _timelineSteps.indexOf(c.status);
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      for (var i = 0; i < _timelineSteps.length; i++)
        Builder(builder: (context) {
          final step = _timelineSteps[i];
          final at = c.timeline.where((t) => t.status == step).firstOrNull?.at;
          final done = i <= reached || at != null;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? UavrColors.low : scheme.outline),
            title: Text(informantStatusLabel(context.u, step),
                style: TextStyle(fontWeight: i == reached ? FontWeight.w700 : null)),
            trailing: at == null ? null : Text(dateTime(at)),
          );
        }),
    ]);
  }
}

/// A templated request from the dispatcher. It only ever asks for media the informant can
/// capture from where they are.
class _EvidenceRequestCard extends ConsumerStatefulWidget {
  const _EvidenceRequestCard(this.stored, this.request);
  final StoredReport stored;
  final EvidenceRequestItem request;

  @override
  ConsumerState<_EvidenceRequestCard> createState() => _EvidenceRequestCardState();
}

class _EvidenceRequestCardState extends ConsumerState<_EvidenceRequestCard> {
  final _media = <CapturedMedia>[];
  bool _busy = false;

  List<MediaKind> get _kinds {
    final kinds = [for (final k in MediaKind.values) if (widget.request.requestedKinds.contains(k.name)) k];
    return kinds.isEmpty ? MediaKind.values : kinds;
  }

  Future<void> _capture(MediaKind kind) async {
    final capture = ref.read(evidenceCaptureProvider);
    final failed = context.l.evidenceCaptureFailed;
    setState(() => _busy = true);
    try {
      final m = await captureMedia(context, capture, kind);
      if (m != null && mounted) setState(() => _media.add(m));
    } catch (_) {
      _snack(failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final api = ref.read(publicApiProvider);
    final uploads = ref.read(evidenceUploadsProvider);
    final caseNumber = widget.stored.caseNumber;
    setState(() => _busy = true);
    try {
      final tickets = await api.answerEvidenceRequest(
          widget.stored.token, widget.request.id, [for (final m in _media) m.toDeclaration()]);
      await startUploads(uploads, caseNumber, List.of(_media), tickets);
      if (!mounted) return;
      _snack(context.l.caseEvidenceSent);
      ref.invalidate(informantCaseProvider(caseNumber));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        _snack(context.l.caseEvidenceClosed);
        ref.invalidate(informantCaseProvider(caseNumber));
      } else {
        _snack(e.isNetwork ? context.u.errorNetwork : context.u.errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final r = widget.request;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(r.isOpen ? Icons.add_a_photo_outlined : Icons.check, color: r.isOpen ? UavrColors.medium : UavrColors.low),
          const SizedBox(width: 8),
          Expanded(child: Text(r.text, style: theme.textTheme.bodyLarge)),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 32, top: 4),
          child: Text(relativeTime(context.u, r.createdAt), style: theme.textTheme.bodySmall),
        ),
        const SizedBox(height: 8),
        if (!r.isOpen)
          Text(r.status == 'answered' ? l.caseEvidenceAnswered : l.caseEvidenceClosed)
        else ...[
          Text(l.caseEvidenceSafety, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          CaptureButtons(kinds: _kinds, onCapture: _capture, enabled: !_busy),
          for (final m in _media) MediaTile(m, onRemove: _busy ? null : () => setState(() => _media.remove(m))),
          if (_media.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(l.caseEvidenceSend(_media.length)),
              ),
            ),
          ],
        ],
      ]),
    );
  }
}
