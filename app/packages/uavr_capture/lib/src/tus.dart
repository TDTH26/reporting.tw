import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

class TusException implements Exception {
  TusException(this.status, this.message);
  final int status;
  final String message;

  /// 403/404/409 from the pre-create hook mean the ticket is unusable: don't retry.
  bool get permanent => status == 403 || status == 404 || status == 409 || status == 400;

  @override
  String toString() => 'TusException($status): $message';
}

/// Minimal tus 1.0 client (creation + core protocol) that works on Android and web.
class TusClient {
  TusClient({http.Client? client, this.chunkSize = 1 << 20}) : _http = client ?? http.Client();
  final http.Client _http;
  final int chunkSize;

  static const _v = {'Tus-Resumable': '1.0.0'};

  /// Creates the upload. Returns the absolute upload URL.
  Future<String> create(String endpoint, {required int length, required String uploadToken, Map<String, String>? metadata}) async {
    final meta = {...?metadata, 'upload_token': uploadToken}
        .entries
        .map((e) => '${e.key} ${base64.encode(utf8.encode(e.value))}')
        .join(',');
    final r = await _http.post(Uri.parse(endpoint), headers: {
      ..._v,
      'Upload-Length': '$length',
      'Upload-Token': uploadToken,
      'Upload-Metadata': meta,
    });
    if (r.statusCode != 201) throw TusException(r.statusCode, r.body);
    final loc = r.headers['location'];
    if (loc == null) throw TusException(r.statusCode, 'no Location header');
    return Uri.parse(endpoint).resolve(loc).toString();
  }

  Future<int> offset(String url) async {
    final r = await _http.head(Uri.parse(url), headers: _v);
    if (r.statusCode == 404 || r.statusCode == 410) throw TusException(r.statusCode, 'upload expired');
    if (r.statusCode != 200 && r.statusCode != 204) throw TusException(r.statusCode, 'HEAD failed');
    return int.parse(r.headers['upload-offset'] ?? '0');
  }

  /// Sends [file] from [from] to the end, reporting progress (bytes sent).
  Future<void> upload(String url, XFile file, {int from = 0, void Function(int sent, int total)? onProgress}) async {
    final total = await file.length();
    var off = from;
    var failures = 0;
    while (off < total) {
      final end = min(off + chunkSize, total);
      final chunk = await _read(file, off, end);
      try {
        final r = await _http.patch(Uri.parse(url),
            headers: {..._v, 'Upload-Offset': '$off', 'Content-Type': 'application/offset+octet-stream'}, body: chunk);
        if (r.statusCode == 409) {
          off = await offset(url); // server and client disagree: resync
          continue;
        }
        if (r.statusCode != 204) throw TusException(r.statusCode, r.body);
        off = int.parse(r.headers['upload-offset'] ?? '$end');
        failures = 0;
        onProgress?.call(off, total);
      } on TusException {
        rethrow;
      } catch (e) {
        if (++failures > 5) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 << failures));
        off = await offset(url);
      }
    }
  }

  Future<Uint8List> _read(XFile f, int start, int end) async {
    final b = BytesBuilder(copy: false);
    await for (final c in f.openRead(start, end)) {
      b.add(c);
    }
    return b.takeBytes();
  }
}
