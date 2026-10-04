import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:uavr_api/uavr_api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum LiveState { disconnected, connecting, connected }

/// Live channel to /v1/ws with automatic reconnect and seq-based resync.
///
/// The server may deliver events slightly out of seq order and replays a 30 s window on
/// resume, so events are de-duplicated by seq here. `resync_required` means the gap was too
/// large: listeners must reload their lists from REST.
class LiveChannel {
  LiveChannel(this.api, this.token);

  final UavrApi api;
  final Future<String?> Function() token;

  final _events = StreamController<LiveMessage>.broadcast();
  final _state = StreamController<LiveState>.broadcast();
  final _seen = <int>{}; // insertion-ordered (LinkedHashSet)
  WebSocketChannel? _ws;
  StreamSubscription? _sub;
  Timer? _ping, _retry;
  int _lastSeq = 0;
  int _attempt = 0;
  bool _closed = false;
  LiveState state = LiveState.disconnected;

  Stream<LiveMessage> get events => _events.stream;
  Stream<LiveState> get states => _state.stream;
  int get lastSeq => _lastSeq;

  /// Start from the seq returned with the REST queue so nothing between load and connect is lost.
  void start({int fromSeq = 0}) {
    _lastSeq = max(_lastSeq, fromSeq);
    _closed = false;
    if (state != LiveState.disconnected || _retry?.isActive == true) return; // already running
    _connect();
  }

  void _set(LiveState s) {
    state = s;
    _state.add(s);
  }

  Future<void> _connect() async {
    if (_closed || state == LiveState.connecting) return;
    _set(LiveState.connecting);
    final t = await token();
    if (t == null) {
      _set(LiveState.disconnected);
      _scheduleRetry();
      return;
    }
    try {
      final ws = WebSocketChannel.connect(api.wsUri(t));
      await ws.ready;
      _ws = ws;
      _sub = ws.stream.listen(_onData, onDone: _onClosed, onError: (_) => _onClosed());
      _attempt = 0;
      _set(LiveState.connected);
      _send({'type': 'resume', 'last_seq': _lastSeq});
      _ping = Timer.periodic(const Duration(seconds: 25), (_) => _send({'type': 'ping'}));
    } catch (_) {
      _onClosed();
    }
  }

  void _send(Map<String, Object?> m) {
    try {
      _ws?.sink.add(jsonEncode(m));
    } catch (_) {}
  }

  void _onData(dynamic raw) {
    final m = LiveMessage.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    switch (m.type) {
      case 'event':
        final seq = m.seq!;
        if (!_seen.add(seq)) return;
        if (_seen.length > 5000) _seen.remove(_seen.first);
        _lastSeq = max(_lastSeq, seq);
        _events.add(m);
      case 'resync_required':
        if (m.seq != null) _lastSeq = m.seq!;
        _events.add(m);
      case 'hello':
        if (_lastSeq == 0 && m.seq != null) _lastSeq = m.seq!;
    }
  }

  void _onClosed() {
    _ping?.cancel();
    _sub?.cancel();
    _ws = null;
    _set(LiveState.disconnected);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed) return;
    _retry?.cancel();
    final delay = Duration(milliseconds: min(30000, 500 * pow(2, _attempt++).toInt()));
    _retry = Timer(delay, _connect);
  }

  Future<void> close() async {
    _closed = true;
    _retry?.cancel();
    _ping?.cancel();
    await _sub?.cancel();
    await _ws?.sink.close();
    _set(LiveState.disconnected);
  }
}
