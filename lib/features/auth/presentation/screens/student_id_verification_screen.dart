import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/services/student_id_ocr_service.dart';
import 'package:pseudocode_apk/services/student_id_verification_service.dart';

enum _Stage { capture, review, recheck, approved, rejected }

// Drives the button label/progress indicator so "reading the photo"
// (on-device OCR) and "verifying eligibility" (network call) read as two
// distinct steps instead of one opaque spinner.
enum _ScanPhase { idle, reading, verifying }

const _eligiblePrograms = [
  'BS Information Technology',
  'BS Computer Science',
  'BS Mathematics',
];

class StudentIdVerificationScreen extends StatefulWidget {
  const StudentIdVerificationScreen({super.key});

  @override
  State<StudentIdVerificationScreen> createState() =>
      _StudentIdVerificationScreenState();
}

class _StudentIdVerificationScreenState
    extends State<StudentIdVerificationScreen> {
  static const _psuInstitution = 'Pangasinan State University';

  final _studentNumber = TextEditingController();
  final _institution = TextEditingController();
  final _studentName = TextEditingController();
  final _program = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _image;
  String? _imagePath;
  String _mimeType = 'image/jpeg';
  String? _message;
  String? _recheckReason;
  int _recheckAttempts = 0;
  bool _busy = false;
  _ScanPhase _phase = _ScanPhase.idle;
  _Stage _stage = _Stage.capture;

  @override
  void dispose() {
    _studentNumber.dispose();
    _institution.dispose();
    _studentName.dispose();
    _program.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _message = 'Use an image smaller than 5 MB.');
        return;
      }
      // Capture quality gate: a too-small photo won't have legible text no
      // matter how good the OCR is, so catch it before wasting a scan.
      final size = await _decodedSize(bytes);
      if (!mounted) return;
      if (size != null && (size.width < 600 || size.height < 350)) {
        setState(
          () => _message =
              'This photo is too small to read. Move closer so the ID fills '
              'the frame, then retake it.',
        );
        return;
      }
      setState(() {
        _image = bytes;
        _imagePath = file.path;
        _mimeType =
            file.mimeType ??
            (file.name.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg');
        _message = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = source == ImageSource.camera
            ? 'Camera access was denied or unavailable. Allow camera access in your device settings, or upload from your gallery.'
            : 'Photo access was denied or unavailable. Allow photo access in your device settings and try again.';
      });
    }
  }

  Future<ui.Size?> _decodedSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } catch (_) {
      // Let the format/size checks that already ran stand — a failure to
      // decode here just means this quality gate is skipped, not fatal.
      return null;
    }
  }

  // Step: Upload ID → OCR: Convert ID Image to Text → Extract ID Information.
  Future<void> _scan() async {
    if (_image == null) {
      setState(
        () => _message =
            'Take or upload a clear photo of the front of your PSU ID.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _phase = _ScanPhase.reading;
      _message = null;
    });
    try {
      // On Android/iOS, OCR runs on-device via ML Kit — no network round
      // trip for this step. Other platforms (desktop/web, used for testing)
      // have no ML Kit implementation, so they fall back to the server's
      // OCR endpoint, which runs the same readability check.
      if (StudentIdOcrService.isSupported && _imagePath != null) {
        final ocr = await const StudentIdOcrService().recognize(
          imagePath: _imagePath!,
        );
        if (!mounted) return;
        _institution.text = _psuInstitution;
        _studentName.text = ocr.fields.studentName;
        _studentNumber.text = ocr.fields.studentNumber;
        _program.text = ocr.fields.program;

        // Decision: "ID Information Read Clearly?" — No.
        final extractedFieldsAreComplete =
            _studentName.text.trim().isNotEmpty &&
            _studentNumber.text.trim().isNotEmpty &&
            _program.text.trim().isNotEmpty;
        if (!extractedFieldsAreComplete) {
          setState(() {
            _message =
                'We could not clearly read the institution, name, student '
                'number, and program from this ID. Review the extracted '
                'information or scan the ID again.';
            _recheckReason = 'unclear';
            _recheckAttempts++;
            _stage = _Stage.recheck;
          });
          return;
        }

        // Yes: continue straight into the name-match and program checks —
        // no manual review step in between.
        setState(() {
          _message =
              'ID information extracted. Confirm that the details are correct.';
          _stage = _Stage.review;
        });
        return;
      }

      final result = await const StudentIdVerificationService().scan(
        imageBytes: _image!,
        mimeType: _mimeType,
      );
      if (!mounted) return;
      _institution.text = _psuInstitution;
      _studentName.text = result.fields.studentName;
      _studentNumber.text = result.fields.studentNumber;
      _program.text = result.normalizedProgram ?? result.fields.program;

      // Decision: "ID Information Read Clearly?" — No: stop and ask the
      // student to review the extracted fields or scan the ID again, instead
      // of guessing at a name/program match with incomplete data.
      // Accept both the current `clear` response and the older `accepted`
      // response whenever OCR actually supplied all required identity fields.
      final extractedFieldsAreComplete =
          _studentName.text.trim().isNotEmpty &&
          _studentNumber.text.trim().isNotEmpty &&
          _program.text.trim().isNotEmpty;
      if (!extractedFieldsAreComplete) {
        setState(() {
          _message = result.message;
          _recheckReason = result.reason ?? 'unclear';
          _recheckAttempts++;
          _stage = _Stage.recheck;
        });
        return;
      }

      // Yes: continue straight into the name-match and program checks with
      // the values the server extracted — no manual review step in between.
      setState(() {
        _message =
            'ID information extracted. Confirm that the details are correct.';
        _stage = _Stage.review;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _phase = _ScanPhase.idle;
        });
      }
    }
  }

  StudentIdFields get _fields => StudentIdFields(
    institution: _institution.text,
    studentName: _studentName.text,
    studentNumber: _studentNumber.text,
    program: _program.text,
  );

  // Steps: ID Name Matches Registered Account Name? → Navigate to Student ID
  // Verification Gate → Program Belongs to CCS? → Eligible Program? — all
  // evaluated server-side by the confirm action in one authoritative call.
  //
  // [fromReview] is true only when the student pressed "Verify corrected
  // information" from the editable review screen — a reviewRequired result
  // then stays on that screen with inline guidance. Otherwise (called
  // straight after a clear scan) a reviewRequired result is a fresh failure,
  // so it goes to the recheck screen and asks to review or rescan.
  Future<void> _confirm({bool fromReview = false}) async {
    if (_institution.text.trim().isEmpty ||
        _studentName.text.trim().isEmpty ||
        _studentNumber.text.trim().isEmpty ||
        _program.text.trim().isEmpty) {
      setState(
        () => _message =
            'Complete the institution, student name, student number, and program before verification.',
      );
      return;
    }
    if (_image == null) {
      setState(() => _message = 'The ID photo is missing. Scan the ID again.');
      return;
    }
    setState(() {
      _busy = true;
      _phase = _ScanPhase.verifying;
      _message = null;
    });
    try {
      final result = await const StudentIdVerificationService().confirm(
        fields: _fields,
      );
      if (!mounted) return;

      if (result.approved) {
        // Step: Set Student Account Status to Verified (done server-side).
        // Refresh so AuthProvider.currentUser reflects idVerificationStatus.
        await context.read<AuthProvider>().refreshSession();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.startup,
          (_) => false,
        );
        return;
      }

      if (result.rejected) {
        setState(() {
          _program.text = result.normalizedProgram ?? _program.text;
          _message = result.message;
          _stage = _Stage.rejected;
        });
        return;
      }

      if (fromReview) {
        // Already correcting fields by hand — keep guiding inline rather
        // than bouncing back out to the recheck screen on every attempt.
        setState(() {
          _message = result.message;
          _stage = _Stage.review;
        });
        return;
      }

      // Decision: "ID Name Matches Registered Account Name?" — No (or the
      // program didn't match the account's registered program). Ask the
      // student to review the extracted information or scan the ID again.
      setState(() {
        _program.text = result.normalizedProgram ?? _program.text;
        _message = result.message;
        _recheckReason = result.reason ?? 'unclear';
        _recheckAttempts++;
        _stage = _Stage.recheck;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _phase = _ScanPhase.idle;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _stage = _Stage.capture;
      _image = null;
      _imagePath = null;
      _message = null;
      _recheckReason = null;
      _recheckAttempts = 0;
      _institution.clear();
      _studentName.clear();
      _studentNumber.clear();
      _program.clear();
    });
  }

  // Step: Navigate to Auth Gate → Navigate to Student Dashboard. AppRoutes
  // .dashboard is wrapped by AuthGuard, which re-checks role and
  // requiresIdVerification before rendering DashboardScreen — that is the
  // "Auth Gate" in the flowchart, so no separate route is needed here.
  void _continueToDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (_) => false,
    );
  }

  Future<void> _signOut() => context.read<AuthProvider>().signOut();

  String _phaseLabel(String idleLabel) {
    switch (_phase) {
      case _ScanPhase.reading:
        return 'Reading your ID…';
      case _ScanPhase.verifying:
        return 'Verifying eligibility…';
      case _ScanPhase.idle:
        return idleLabel;
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final viewport = MediaQuery.sizeOf(context);
    final wide = viewport.width >= 920;
    final compact = viewport.width < 600;
    final card = _card(
      name: user?.displayName ?? 'Learner',
      program: user?.program ?? 'Program not set',
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFF), Color(0xFFEEF5FC)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!compact) ...[
              const Positioned(
                top: -150,
                right: -120,
                child: _Orb(size: 300, color: Color(0xFFDDE8FB)),
              ),
              const Positioned(
                bottom: -190,
                left: -150,
                child: _Orb(size: 300, color: Color(0xFFDDF5F4)),
              ),
            ],
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final verticalPadding = wide ? 32.0 : (compact ? 12.0 : 20.0);
                  final minimumContentHeight =
                      constraints.maxHeight > verticalPadding * 2
                      ? constraints.maxHeight - verticalPadding * 2
                      : 0.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 40 : (compact ? 12 : 20),
                      vertical: verticalPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 1180,
                          minHeight: minimumContentHeight,
                        ),
                        child: wide
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: _OverviewPanel(
                                        name: user?.displayName ?? 'Learner',
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 6, child: card),
                                  ],
                                ),
                              )
                            : card,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String name, required String program}) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 420 ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 20 : 28),
        border: Border.all(color: const Color(0xFFD6E2F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0B2854,
            ).withValues(alpha: compact ? 0.06 : 0.08),
            blurRadius: compact ? 16 : 28,
            offset: Offset(0, compact ? 6 : 12),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _content(name: name, program: program),
      ),
    );
  }

  Widget _content({required String name, required String program}) {
    if (_stage == _Stage.approved) {
      return _Outcome(
        key: const ValueKey('approved'),
        icon: Icons.verified_rounded,
        color: const Color(0xFF079669),
        title: 'Student ID Verified',
        message:
            _message ??
            'Student ID verified. The student belongs to the College of Computing Sciences.',
        details: {
          'Name': _studentName.text,
          'Student Number': _studentNumber.text,
          'Program': _program.text,
        },
        primaryLabel: 'Continue',
        onPrimary: _continueToDashboard,
      );
    }

    if (_stage == _Stage.rejected) {
      return _Outcome(
        key: const ValueKey('rejected'),
        icon: Icons.block_rounded,
        color: const Color(0xFFD14343),
        title: 'Student Not Eligible',
        message:
            _message ??
            'This system is intended only for College of Computing Sciences students.',
        details: {
          'Detected Program': _program.text,
          'Eligible Programs': _eligiblePrograms.join('\n'),
        },
        primaryLabel: 'Sign Out',
        onPrimary: _signOut,
      );
    }

    if (_stage == _Stage.recheck) {
      final mismatch = _recheckReason == 'nameMismatch';
      final notOnMasterlist = _recheckReason == 'notOnMasterlist';
      return _Recheck(
        key: const ValueKey('recheck'),
        mismatch: mismatch,
        icon: notOnMasterlist ? Icons.fact_check_outlined : null,
        title: mismatch
            ? 'ID name does not match the registered account'
            : notOnMasterlist
            ? 'Student number not found on the CCS masterlist'
            : "We couldn't read your ID clearly",
        message:
            _message ??
            (mismatch
                ? 'The name on the ID does not clearly match your registered account.'
                : notOnMasterlist
                ? 'This student number was not found in the CCS roster.'
                : 'Some fields could not be read from the photo.'),
        // After a couple of failed attempts, the student is probably not
        // going to fix it by guessing again — surface concrete capture tips
        // and a way out instead of repeating the same two buttons silently.
        showTips: _recheckAttempts >= 2 && !notOnMasterlist,
        onReview: () => setState(() => _stage = _Stage.review),
        onRescan: _reset,
      );
    }

    if (_stage == _Stage.review) {
      return Column(
        key: const ValueKey('review'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading(
            title: 'Review extracted information',
            subtitle: 'Correct any OCR mistakes before verification.',
          ),
          const SizedBox(height: 16),
          const _ProgressSteps(),
          const SizedBox(height: 18),
          if (_image != null) ...[
            _ImageArea(image: _image, busy: _busy, onTap: () {}),
            const SizedBox(height: 14),
          ],
          _field(
            _institution,
            'Institution',
            Icons.account_balance_outlined,
            readOnly: true,
          ),
          _field(_studentName, 'Student Name', Icons.person_outline),
          _field(_studentNumber, 'Student Number', Icons.numbers_rounded),
          _field(_program, 'Program', Icons.school_outlined),
          if (_message != null) _Feedback(message: _message!, rejected: false),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _confirm(fromReview: true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1746A2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(_phaseLabel('Confirm information')),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _reset,
            child: const Text('Scan Again'),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('capture'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(
          title: 'Student ID verification',
          subtitle: 'Secure eligibility check • usually under a minute',
        ),
        const SizedBox(height: 20),
        const _ProgressSteps(),
        const SizedBox(height: 20),
        _LearnerSummary(name: name, program: program),
        const SizedBox(height: 18),
        const Text(
          'Add a clear photo of your ID',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const Text(
          'Use the front of your ID. Keep PSU, your course, and student number visible.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 10),
        _ImageArea(
          image: _image,
          busy: _busy,
          onTap: () => _pick(ImageSource.gallery),
        ),
        const SizedBox(height: 12),
        _PickerButtons(
          busy: _busy,
          onCamera: () => _pick(ImageSource.camera),
          onGallery: () => _pick(ImageSource.gallery),
        ),
        if (_message != null) _Feedback(message: _message!, rejected: false),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _busy ? null : _scan,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1746A2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.document_scanner_outlined),
            label: Text(_phaseLabel('Read my ID')),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          _ScanProgress(phase: _phase),
        ],
        const SizedBox(height: 11),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Your image is used only for this eligibility check.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _busy ? null : _signOut,
          child: const Text('Sign out and use another account'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_busy,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.details,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Map<String, String> details;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF60728E), height: 1.4),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...details.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xFF60728E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
      ],
    );
  }
}

// Flowchart nodes: "Show: ID name does not match the registered account" and
// "Ask Student to Review Information or Scan the ID Again" — both offer the
// same two ways forward, so they share this one screen.
class _Recheck extends StatelessWidget {
  const _Recheck({
    super.key,
    required this.mismatch,
    required this.title,
    required this.message,
    required this.onReview,
    required this.onRescan,
    this.showTips = false,
    this.icon,
  });

  final bool mismatch;
  final String title;
  final String message;
  final VoidCallback onReview;
  final VoidCallback onRescan;
  final bool showTips;
  final IconData? icon;

  static const _tips = [
    'Lay the ID flat on a plain, well-lit surface — avoid glare from lights or windows.',
    'Fill the frame with the ID and keep all four corners visible.',
    'Hold the camera steady and let it focus before capturing.',
  ];

  @override
  Widget build(BuildContext context) {
    final color = mismatch ? const Color(0xFFBE123C) : const Color(0xFFB8790A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          icon ??
              (mismatch ? Icons.badge_outlined : Icons.image_search_rounded),
          size: 44,
          color: color,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF60728E), height: 1.4),
        ),
        if (showTips) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD9E7FB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: Color(0xFF1746A2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'For a cleaner scan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '•  $tip',
                      style: const TextStyle(
                        color: Color(0xFF3A4A63),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Review information'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onRescan,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Scan the ID again'),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF1746A2),
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearnerSummary extends StatelessWidget {
  const _LearnerSummary({required this.name, required this.program});
  final String name;
  final String program;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD9E7FB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFDCE9FF),
            child: Icon(Icons.person_outline, color: Color(0xFF1746A2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  program,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF0B9B78)),
        ],
      ),
    );
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({
    required this.image,
    required this.busy,
    required this.onTap,
  });
  final Uint8List? image;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final previewHeight = image == null
        ? (compact ? 190.0 : 230.0)
        : (compact ? 240.0 : 300.0);
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: previewHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image == null
                ? const Color(0xFFBFD1EA)
                : const Color(0xFF31A98B),
            width: image == null ? 1 : 2,
          ),
        ),
        child: image == null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: _ScannerFrame(color: Color(0xFF9DB6DE)),
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: Color(0xFF1746A2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select your PSU ID',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Align all four corners inside the frame',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(image!, fit: BoxFit.contain),
                  ),
                  const Positioned.fill(
                    child: _ScannerFrame(color: Color(0xFF31A98B)),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF087B61),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Photo ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Viewfinder-style corner brackets over the ID preview, guiding framing the
// way a scanner app would — purely a visual guide, since image_picker hands
// off to the native camera/gallery UI rather than a live preview we control.
class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _CornerFramePainter(color: color)),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  const _CornerFramePainter({required this.color});
  final Color color;

  static const _inset = 14.0;
  static const _arm = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(
      _inset,
      _inset,
      size.width - _inset * 2,
      size.height - _inset * 2,
    );

    void corner(Offset origin, Offset arm1, Offset arm2) {
      canvas.drawLine(origin, origin + arm1, paint);
      canvas.drawLine(origin, origin + arm2, paint);
    }

    corner(rect.topLeft, const Offset(_arm, 0), const Offset(0, _arm));
    corner(rect.topRight, const Offset(-_arm, 0), const Offset(0, _arm));
    corner(rect.bottomLeft, const Offset(_arm, 0), const Offset(0, -_arm));
    corner(rect.bottomRight, const Offset(-_arm, 0), const Offset(0, -_arm));
  }

  @override
  bool shouldRepaint(covariant _CornerFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PickerButtons extends StatelessWidget {
  const _PickerButtons({
    required this.busy,
    required this.onCamera,
    required this.onGallery,
  });
  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    // A LayoutBuilder here would throw once this row sits under the wide
    // layout's IntrinsicHeight (it can't report intrinsic dimensions), so
    // the breakpoint uses the window width instead of the local constraints.
    final camera = OutlinedButton.icon(
      onPressed: busy ? null : onCamera,
      icon: const Icon(Icons.camera_alt_outlined),
      label: const Text('Take a photo'),
    );
    final gallery = OutlinedButton.icon(
      onPressed: busy ? null : onGallery,
      icon: const Icon(Icons.photo_library_outlined),
      label: const Text('Upload from gallery'),
    );
    if (MediaQuery.sizeOf(context).width < 500) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [camera, const SizedBox(height: 8), gallery],
      );
    }
    return Row(
      children: [
        Expanded(child: camera),
        const SizedBox(width: 10),
        Expanded(child: gallery),
      ],
    );
  }
}

// Shows which half of the pipeline is running — on-device OCR, then the
// network eligibility check — instead of one opaque spinner for both.
class _ScanProgress extends StatelessWidget {
  const _ScanProgress({required this.phase});
  final _ScanPhase phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScanProgressStep(
            label: 'Reading ID',
            active: phase == _ScanPhase.reading,
            done: phase == _ScanPhase.verifying,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ScanProgressStep(
            label: 'Checking eligibility',
            active: phase == _ScanPhase.verifying,
            done: false,
          ),
        ),
      ],
    );
  }
}

class _ScanProgressStep extends StatelessWidget {
  const _ScanProgressStep({
    required this.label,
    required this.active,
    required this.done,
  });
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = active || done
        ? const Color(0xFF1746A2)
        : const Color(0xFFC3D2E8);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: done ? 1 : (active ? null : 0),
            backgroundColor: const Color(0xFFE4ECF9),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active || done
                ? const Color(0xFF1746A2)
                : const Color(0xFF8FA1BE),
          ),
        ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.message, required this.rejected});
  final String message;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final color = rejected ? const Color(0xFFBE123C) : const Color(0xFF805000);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: rejected ? const Color(0xFFFFE8EC) : const Color(0xFFFFF6E8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              rejected ? Icons.error_outline : Icons.info_outline,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(message, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2854), Color(0xFF1746A2), Color(0xFF129F9A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B2854),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset('assets/images/cosci.png'),
          ),
          const SizedBox(height: 30),
          const Text(
            'One final step,\nthen you can start learning.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Welcome, $name. Verify your PSU student ID to keep CoSci exclusive to eligible College of Computing Sciences learners.',
            style: const TextStyle(
              color: Color(0xFFD7E5FF),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 32),
          const _OverviewItem(
            icon: Icons.badge_outlined,
            text: 'Confirm your student number',
          ),
          const _OverviewItem(
            icon: Icons.school_outlined,
            text: 'Check your eligible program',
          ),
          const _OverviewItem(
            icon: Icons.lock_outline_rounded,
            text: 'Discard the ID after review',
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF91F2E9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Step(label: 'Account', number: '1', complete: true),
        Expanded(child: Divider(color: Color(0xFF74A3EF), thickness: 2)),
        _Step(label: 'Email', number: '2', complete: true),
        Expanded(child: Divider(color: Color(0xFF74A3EF), thickness: 2)),
        _Step(label: 'Student ID', number: '3', complete: false),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.number,
    required this.complete,
  });
  final String label;
  final String number;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: complete
              ? const Color(0xFF0B9B78)
              : const Color(0xFF1746A2),
          child: complete
              ? const Icon(Icons.check, size: 17, color: Colors.white)
              : Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
