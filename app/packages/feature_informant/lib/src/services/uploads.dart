import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_capture/uavr_capture.dart';

/// Evidence uploads after the metadata packet ("metadata travels first, media follows").
abstract class EvidenceUploads {
  Stream<List<UploadJob>> get changes;
  List<UploadJob> get jobs;
  Future<void> enqueue(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets);

  /// Uploads everything pending in this process.
  Future<void> run();

  /// Asks the OS to finish uploads in the background (Android WorkManager).
  Future<void> kickBackground();
}

class QueueUploads implements EvidenceUploads {
  QueueUploads(this._q);
  final UploadQueue _q;

  @override
  Stream<List<UploadJob>> get changes => _q.changes;
  @override
  List<UploadJob> get jobs => _q.jobs;
  @override
  Future<void> enqueue(String caseNumber, List<CapturedMedia> media, List<UploadTicket> tickets) =>
      _q.enqueue(caseNumber, media, tickets);
  @override
  Future<void> run() => _q.run();
  @override
  Future<void> kickBackground() => kickBackgroundUploads();
}

final evidenceUploadsProvider = Provider<EvidenceUploads>((ref) => QueueUploads(UploadQueue()));

/// Uploads [media] for [caseNumber] now and hand the rest to the background worker.
Future<void> startUploads(EvidenceUploads uploads, String caseNumber, List<CapturedMedia> media,
    List<UploadTicket> tickets) async {
  if (tickets.isEmpty) return;
  await uploads.enqueue(caseNumber, media, tickets);
  uploads.run().ignore();
  uploads.kickBackground().ignore();
}
