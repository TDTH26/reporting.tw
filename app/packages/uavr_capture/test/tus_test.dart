import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uavr_api/uavr_api.dart' show MediaKind;
import 'package:uavr_capture/uavr_capture.dart';

/// In-memory tus server: just enough of the protocol to exercise the client.
class FakeTus {
  final uploads = <String, BytesBuilder>{};
  final lengths = <String, int>{};
  int patches = 0;
  bool failNextPatchWith409 = false;

  Future<http.Response> handle(http.Request r) async {
    expect(r.headers['Tus-Resumable'], '1.0.0');
    if (r.method == 'POST') {
      if (r.headers['Upload-Token'] != 'good') return http.Response('invalid upload token', 403);
      final meta = r.headers['Upload-Metadata']!;
      expect(utf8.decode(base64.decode(meta.split(',').firstWhere((m) => m.startsWith('filetype')).split(' ')[1])),
          'image/jpeg');
      final id = 'u${uploads.length}';
      uploads[id] = BytesBuilder();
      lengths[id] = int.parse(r.headers['Upload-Length']!);
      return http.Response('', 201, headers: {'location': '/files/$id'});
    }
    final id = r.url.pathSegments.last;
    final b = uploads[id]!;
    if (r.method == 'HEAD') return http.Response('', 200, headers: {'upload-offset': '${b.length}'});
    if (r.method == 'PATCH') {
      patches++;
      if (failNextPatchWith409) {
        failNextPatchWith409 = false;
        return http.Response('offset mismatch', 409);
      }
      expect(int.parse(r.headers['Upload-Offset']!), b.length);
      b.add(r.bodyBytes);
      return http.Response('', 204, headers: {'upload-offset': '${b.length}'});
    }
    return http.Response('', 405);
  }
}

void main() {
  final data = Uint8List.fromList(List<int>.generate(2500, (i) => i % 251));

  test('creates, uploads in chunks and resyncs on 409', () async {
    final server = FakeTus()..failNextPatchWith409 = true;
    final tus = TusClient(client: MockClient(server.handle), chunkSize: 1000);
    final url = await tus.create('http://t/files/', length: data.length, uploadToken: 'good', metadata: {'filetype': 'image/jpeg'});
    expect(url, 'http://t/files/u0');
    final progress = <int>[];
    await tus.upload(url, XFile.fromData(data), onProgress: (s, _) => progress.add(s));
    expect(server.uploads['u0']!.toBytes(), data);
    expect(progress, [1000, 2000, 2500]);
    expect(server.patches, 4); // one rejected with 409, then three chunks
  });

  test('rejected ticket is a permanent failure', () async {
    final tus = TusClient(client: MockClient(FakeTus().handle));
    expect(
      () => tus.create('http://t/files/', length: 1, uploadToken: 'bad'),
      throwsA(isA<TusException>().having((e) => e.permanent, 'permanent', true)),
    );
  });

  test('ingestBytes hashes exactly the uploaded bytes', () async {
    final m = await ingestBytes(data, MediaKind.photo, 'image/jpeg', slot: 'p1');
    expect(m.sha256, sha256.convert(data).toString());
    expect(await sha256OfStream(m.file.openRead()), m.sha256);
    expect(m.toDeclaration().toJson()['size_bytes'], 2500);
  });
}
