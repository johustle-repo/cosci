import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pseudocode_apk/features/gamification/services/certificate_downloader.dart';
import 'package:pseudocode_apk/models/achievement.dart';

class CertificateService {
  const CertificateService();

  Future<void> downloadBadgeCertificate({
    required Achievement badge,
    required String learnerName,
    required String learnerId,
  }) async {
    if (!badge.isUnlocked) {
      throw StateError('Certificates are available for unlocked badges only.');
    }

    final bytes = await buildBadgeCertificate(
      badge: badge,
      learnerName: learnerName,
      learnerId: learnerId,
    );
    await downloadCertificateFile(
      bytes: bytes,
      filename: 'CoSci-${_fileSafe(badge.title)}-Certificate.pdf',
    );
  }

  Future<Uint8List> buildBadgeCertificate({
    required Achievement badge,
    required String learnerName,
    required String learnerId,
  }) async {
    if (!badge.isUnlocked) {
      throw StateError('Certificates are available for unlocked badges only.');
    }
    final fonts = await _loadCertificateFonts();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/images/cosci.png')).buffer.asUint8List(),
    );
    final facilitatorSignature = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/juan_dela_cruz_signature.png',
      )).buffer.asUint8List(),
    );
    final issuedAt = badge.unlockedAt ?? DateTime.now();
    final certificateId = _certificateId(
      learnerId: learnerId,
      badgeId: badge.id,
      issuedAt: issuedAt,
    );
    // Certificates use one institutional CoSci palette. Badge accent colors
    // belong to the in-app collection and must not alter the formal document.
    final accent = PdfColor.fromHex('#1D5FD1');
    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        fontFallback: [fonts.semiBold],
      ),
      title: 'CoSci Certificate - ${badge.title}',
      author: 'CoSci Learning Platform',
      subject: badge.milestoneLabel,
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Container(
          color: PdfColor.fromHex('#081B3D'),
          padding: const pw.EdgeInsets.all(14),
          child: pw.Container(
            color: PdfColor.fromHex('#FBFCFF'),
            child: pw.Stack(
              children: [
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: pw.Container(height: 9, color: accent),
                ),
                pw.Positioned(
                  right: -65,
                  top: -70,
                  child: pw.Container(
                    width: 190,
                    height: 190,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColor.fromHex('#EAF2FF'),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(42, 28, 42, 28),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 58,
                                height: 58,
                                padding: const pw.EdgeInsets.all(5),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.circular(14),
                                  border: pw.Border.all(
                                    color: PdfColor.fromHex('#D9E6F8'),
                                  ),
                                ),
                                child: pw.Image(logo),
                              ),
                              pw.SizedBox(width: 13),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'CoSci',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#081B3D'),
                                      fontSize: 23,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Text(
                                    'Programming made clearer',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#64748B'),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'LEARNER ACHIEVEMENT',
                                style: pw.TextStyle(
                                  color: accent,
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Verified milestone certificate',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#64748B'),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        height: 1,
                        color: PdfColor.fromHex('#D9E6F8'),
                      ),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.SizedBox(width: 10),
                            pw.Container(
                              width: 130,
                              height: 130,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: accent.shade(0.90),
                                border: pw.Border.all(color: accent, width: 2),
                              ),
                              padding: const pw.EdgeInsets.all(9),
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  color: accent,
                                ),
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      'COSCI',
                                      style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        letterSpacing: 1.3,
                                      ),
                                    ),
                                    pw.SizedBox(height: 5),
                                    pw.Text(
                                      'ACHIEVEMENT',
                                      style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 5),
                                    pw.Text(
                                      'BADGE',
                                      style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontSize: 17,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 35),
                            pw.Expanded(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'CERTIFICATE OF ACHIEVEMENT',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#123D9B'),
                                      fontSize: 25,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  pw.SizedBox(height: 10),
                                  pw.Text(
                                    'Proudly presented to',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#64748B'),
                                      fontSize: 11,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5),
                                  pw.Text(
                                    learnerName.trim().isEmpty
                                        ? 'CoSci Learner'
                                        : learnerName,
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#081B3D'),
                                      fontSize: 31,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Container(
                                    width: 420,
                                    margin: const pw.EdgeInsets.only(
                                      top: 4,
                                      bottom: 10,
                                    ),
                                    height: 2,
                                    color: accent,
                                  ),
                                  pw.Text(
                                    'for unlocking the ${badge.title} badge',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#123D9B'),
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    badge.description,
                                    style: pw.TextStyle(
                                      color: PdfColor.fromHex('#475569'),
                                      fontSize: 10,
                                    ),
                                  ),
                                  pw.SizedBox(height: 10),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor.fromHex('#EDF4FF'),
                                      borderRadius: pw.BorderRadius.circular(7),
                                      border: pw.Border.all(
                                        color: PdfColor.fromHex('#BFD6FF'),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: pw.Text(
                                      'MILESTONE  |  ${badge.milestoneLabel}',
                                      style: pw.TextStyle(
                                        color: PdfColor.fromHex('#123D9B'),
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        height: 1,
                        color: PdfColor.fromHex('#D9E6F8'),
                      ),
                      pw.SizedBox(height: 14),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(7),
                              border: pw.Border.all(
                                color: PdfColor.fromHex('#D9E6F8'),
                                width: 0.7,
                              ),
                            ),
                            child: pw.Row(
                              children: [
                                pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: certificateId,
                                  width: 46,
                                  height: 46,
                                  color: PdfColor.fromHex('#081B3D'),
                                ),
                                pw.SizedBox(width: 9),
                                _certificateDetail(
                                  label: 'CERTIFICATE ID',
                                  value: certificateId,
                                ),
                              ],
                            ),
                          ),
                          pw.Column(
                            children: [
                              pw.SizedBox(
                                width: 150,
                                height: 35,
                                child: pw.Image(
                                  facilitatorSignature,
                                  fit: pw.BoxFit.contain,
                                ),
                              ),
                              pw.Container(
                                width: 150,
                                height: 1,
                                color: PdfColor.fromHex('#94A3B8'),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Juan Dela Cruz',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#334155'),
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'CoSci Facilitator',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#94A3B8'),
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                          _certificateDetail(
                            label: 'DATE ISSUED',
                            value: DateFormat('MMMM d, yyyy').format(issuedAt),
                            alignRight: true,
                            valueColor: PdfColor.fromHex('#0B1F44'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _certificateDetail({
    required String label,
    required String value,
    bool alignRight = false,
    PdfColor? valueColor,
  }) {
    return pw.Column(
      crossAxisAlignment: alignRight
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColor.fromHex('#94A3B8'),
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor ?? PdfColor.fromHex('#334155'),
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<({pw.Font regular, pw.Font semiBold, pw.Font bold})>
  _loadCertificateFonts() async {
    try {
      return (
        regular: pw.Font.ttf(
          await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
        ),
        semiBold: pw.Font.ttf(
          await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'),
        ),
        bold: pw.Font.ttf(
          await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
        ),
      );
    } catch (_) {
      // A Flutter web hot reload cannot refresh a newly changed asset
      // manifest. Keep certificate downloads available until the next full
      // restart by falling back to PDF's bundled typefaces.
      return (
        regular: pw.Font.helvetica(),
        semiBold: pw.Font.helveticaBold(),
        bold: pw.Font.helveticaBold(),
      );
    }
  }

  String _certificateId({
    required String learnerId,
    required String badgeId,
    required DateTime issuedAt,
  }) {
    final learner = learnerId
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toUpperCase();
    final badge = badgeId.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
    return 'COSCI-${learner.substring(0, learner.length.clamp(0, 6))}-${badge.substring(0, badge.length.clamp(0, 6))}-${DateFormat('yyyyMMdd').format(issuedAt)}';
  }

  String _fileSafe(String value) => value
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
