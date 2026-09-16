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
  try {
    anchor.click();

    // Give the browser enough time to take ownership of the object URL before
    // it is revoked. Revoking it immediately can cancel downloads on mobile
    // browsers and leave the certificate flow looking unfinished.
    await Future<void>.delayed(const Duration(seconds: 1));
  } finally {
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
  }
}
