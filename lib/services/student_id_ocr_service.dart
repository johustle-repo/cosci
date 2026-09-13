import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class StudentIdOcrService {
  const StudentIdOcrService();

  Future<String> extractText({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (imageBytes.isEmpty) {
      throw StateError('The selected ID image is empty.');
    }

    if (!Platform.isAndroid) {
      throw UnsupportedError('Student ID OCR requires an Android device.');
    }

    TextRecognizer? recognizer;
    File? temporaryFile;

    try {
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final directory = await getTemporaryDirectory();

      final extension = mimeType.toLowerCase().contains('png') ? 'png' : 'jpg';

      temporaryFile = File(
        '${directory.path}/student_id_'
        '${DateTime.now().microsecondsSinceEpoch}'
        '.$extension',
      );

      await temporaryFile.writeAsBytes(imageBytes, flush: true);

      final inputImage = InputImage.fromFilePath(temporaryFile.path);

      final result = await recognizer.processImage(inputImage);

      return result.text.trim();
    } on MissingPluginException {
      throw StateError(
        'Google ML Kit OCR is unavailable. '
        'Perform a full rebuild and run the application on an Android device.',
      );
    } finally {
      if (recognizer != null) {
        try {
          await recognizer.close();
        } catch (_) {}
      }

      if (temporaryFile != null) {
        try {
          if (await temporaryFile.exists()) {
            await temporaryFile.delete();
          }
        } catch (_) {}
      }
    }
  }
}
