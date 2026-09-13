import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pseudocode_apk/features/auth/presentation/utils/role_redirect.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/services/college_eligibility_service.dart';
import 'package:pseudocode_apk/services/student_id_models.dart';
import 'package:pseudocode_apk/services/student_id_verification_service.dart';

enum _Stage { capture, review, accepted, rejected, reviewRequired }

class StudentIdVerificationScreen extends StatefulWidget {
  const StudentIdVerificationScreen({super.key});

  @override
  State<StudentIdVerificationScreen> createState() =>
      _StudentIdVerificationScreenState();
}

class _StudentIdVerificationScreenState
    extends State<StudentIdVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _institution = TextEditingController();

  final TextEditingController _name = TextEditingController();

  final TextEditingController _number = TextEditingController();

  final TextEditingController _program = TextEditingController();

  Uint8List? _image;

  String _mimeType = 'image/jpeg';

  String? _message;

  String? _normalizedProgram;

  bool _busy = false;

  _Stage _stage = _Stage.capture;

  @override
  void dispose() {
    _institution.dispose();
    _name.dispose();
    _number.dispose();
    _program.dispose();

    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2000,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) {
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        setState(() {
          _message = 'Please select an image smaller than 10 MB.';
        });

        return;
      }

      final name = file.name.toLowerCase();

      setState(() {
        _image = bytes;

        _mimeType =
            file.mimeType ??
            (name.endsWith('.png') ? 'image/png' : 'image/jpeg');

        _message = null;

        _normalizedProgram = null;

        _stage = _Stage.capture;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Camera or photo access is unavailable. Please allow permission and try again.';
      });
    }
  }

  Future<void> _scan() async {
    if (_image == null) {
      setState(() {
        _message =
            'Take or upload a clear photo of the front of your PSU student ID.';
      });

      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final result = await const StudentIdVerificationService().scan(
        imageBytes: _image!,
        mimeType: _mimeType,
      );

      if (!mounted) {
        return;
      }

      _institution.text = result.fields.institution;

      _name.text = result.fields.studentName;

      _number.text = result.fields.studentNumber;

      _program.text = result.normalizedProgram ?? result.fields.program;

      setState(() {
        _message = result.message;

        _normalizedProgram = result.normalizedProgram;

        _stage = _Stage.review;
      });

      debugPrint('=========== RAW OCR ===========');

      debugPrint(result.rawText);

      debugPrint('===============================');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  StudentIdExtractedFields get _fields => StudentIdExtractedFields(
    institution: _institution.text,
    studentName: _name.text,
    studentNumber: _number.text,
    program: _program.text,
  );

  Future<void> _confirm() async {
    if (_institution.text.trim().isEmpty ||
        _name.text.trim().isEmpty ||
        _number.text.trim().isEmpty ||
        _program.text.trim().isEmpty) {
      setState(() {
        _stage = _Stage.reviewRequired;

        _message =
            'Complete the institution, student name, student number, and program before verification.';
      });

      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      // IMPORTANT:
      //
      // confirm() receives ONLY fields.
      //
      // Do NOT send imageBytes or mimeType here.
      final result = await const StudentIdVerificationService().confirm(
        fields: _fields,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = result.message;

        _normalizedProgram = result.normalizedProgram;

        _stage = switch (result.status) {
          EligibilityStatus.accepted => _Stage.accepted,

          EligibilityStatus.rejected => _Stage.rejected,

          EligibilityStatus.reviewRequired => _Stage.reviewRequired,
        };
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _stage = _Stage.capture;

      _image = null;

      _message = null;

      _normalizedProgram = null;

      _institution.clear();
      _name.clear();
      _number.clear();
      _program.clear();
    });
  }

  Future<void> _continue() async {
    final program = _normalizedProgram?.trim() ?? '';
    if (program.isEmpty) {
      setState(() {
        _message =
            'The verified program is missing. Review the ID information and try again.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final auth = context.read<AuthProvider>();
    final saved = await auth.completeStudentIdVerification(
      institution: _institution.text,
      studentName: _name.text,
      studentNumber: _number.text,
      normalizedProgram: program,
    );

    if (!mounted) {
      return;
    }

    if (!saved) {
      setState(() {
        _busy = false;
        _message =
            auth.errorMessage ??
            'The verified student ID could not be saved. Please try again.';
      });
      return;
    }

    final destination = RoleRedirect.homeRoute(auth.currentUser);
    Navigator.pushNamedAndRemoveUntil(context, destination, (_) => false);
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
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 32 : 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: _Intro()),
                        const SizedBox(width: 24),
                        Expanded(child: _card()),
                      ],
                    )
                  : _card(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFD4E1F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    if (_stage == _Stage.accepted) {
      return _Outcome(
        key: const ValueKey('accepted'),
        icon: Icons.verified_rounded,
        color: const Color(0xFF079669),
        title: 'Student ID Verified',
        message: _message ?? CollegeEligibilityService.acceptedMessage,
        details: {
          'Name': _name.text,
          'Student Number': _number.text,
          'Program': _normalizedProgram ?? _program.text,
          'College': CollegeEligibilityService.collegeName,
        },
        primaryLabel: 'Continue',
        onPrimary: _continue,
        busy: _busy,
      );
    }

    if (_stage == _Stage.rejected) {
      return _Outcome(
        key: const ValueKey('rejected'),
        icon: Icons.block_rounded,
        color: const Color(0xFFD14343),
        title: 'Student Not Eligible',
        message: _message ?? CollegeEligibilityService.rejectedMessage,
        details: {
          'Detected Program': _normalizedProgram ?? _program.text,
          'Eligible Programs':
              'BS Information Technology\n'
              'BS Computer Science\n'
              'BS Mathematics',
        },
        primaryLabel: 'Scan Another ID',
        onPrimary: _reset,
      );
    }

    if (_stage == _Stage.reviewRequired) {
      return _Outcome(
        key: const ValueKey('reviewRequired'),
        icon: Icons.manage_search_rounded,
        color: const Color(0xFFD97706),
        title: 'Program Could Not Be Verified',
        message: _message ?? CollegeEligibilityService.reviewMessage,
        details: const {},
        primaryLabel: 'Review Information',
        onPrimary: () {
          setState(() {
            _stage = _Stage.review;
          });
        },
        secondaryLabel: 'Scan Again',
        onSecondary: _reset,
      );
    }

    if (_stage == _Stage.review) {
      return Column(
        key: const ValueKey('review'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading(
            icon: Icons.fact_check_outlined,
            title: 'Review extracted information',
            subtitle: 'Correct any OCR mistakes before verification.',
          ),
          const SizedBox(height: 20),
          _field(_institution, 'Institution', Icons.account_balance_outlined),
          _field(_name, 'Student Name', Icons.person_outline),
          _field(_number, 'Student Number', Icons.tag),
          _field(_program, 'Program', Icons.school_outlined),
          if (_message != null) _notice(_message!),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _confirm,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: const Text('Verify corrected information'),
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
          icon: Icons.badge_outlined,
          title: 'Verify your PSU student ID',
          subtitle:
              'Take or upload the front of your ID. You can review every extracted field before verification.',
        ),
        const SizedBox(height: 20),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD4E1F3)),
          ),
          child: _image == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 42,
                        color: Color(0xFF17499E),
                      ),
                      SizedBox(height: 10),
                      Text('No ID image selected'),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.memory(_image!, fit: BoxFit.contain),
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take a photo'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Upload from gallery'),
            ),
          ],
        ),
        if (_message != null) _notice(_message!),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _busy ? null : _scan,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner_outlined),
          label: Text(_busy ? 'Reading ID...' : 'Read student ID'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => context.read<AuthProvider>().signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _notice(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2551), Color(0xFF17499E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Colors.white, size: 42),
          SizedBox(height: 22),
          Text(
            'CCS learner verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'A simple three-step check protects the CoSci learning workspace.',
            style: TextStyle(color: Color(0xFFDCE8FF), height: 1.5),
          ),
          SizedBox(height: 28),
          _Step('1', 'Capture or upload your PSU ID'),
          _Step('2', 'Review the extracted details'),
          _Step('3', 'Confirm your eligible CCS program'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF2DD4BF),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF0B2551),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF17499E), size: 38),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF60728E), height: 1.4),
        ),
      ],
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
    this.secondaryLabel,
    this.onSecondary,
    this.busy = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Map<String, String> details;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool busy;

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
        FilledButton(
          onPressed: busy ? null : onPrimary,
          child: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(primaryLabel),
        ),
        if (secondaryLabel != null)
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
      ],
    );
  }
}
