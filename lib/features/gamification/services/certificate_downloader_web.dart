import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadCertificateFile({
  required Uint8List bytes,
  required String filename,
}) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(objectUrl);
}
