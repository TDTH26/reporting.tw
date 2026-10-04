import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uavr_api/uavr_api.dart';
import 'package:uavr_core/uavr_core.dart';
import '../json_util.dart';

/// Live case events for this officer (the hub only forwards events of cases the officer is
/// assigned to, plus case.field_assigned). Injectable so tests can push events.
abstract class FieldLive {
  Stream<LiveMessage> get events;
  void start();
}

class ChannelFieldLive implements FieldLive {
  ChannelFieldLive(this.channel);
  final LiveChannel channel;
  bool _started = false;

  @override
  Stream<LiveMessage> get events => channel.events;

  @override
  void start() {
    if (_started) return;
    _started = true;
    channel.start();
  }
}

final fieldLiveProvider = Provider<FieldLive>((ref) => ChannelFieldLive(ref.watch(liveChannelProvider)));

/// Case id an event is about, if any (payload = {"case": CaseSummary JSON, ...}).
String? liveCaseId(LiveMessage m) => obj(m.payload['case'])?['id'] as String? ?? m.payload['case_id'] as String?;
