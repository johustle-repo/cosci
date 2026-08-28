import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/services/student_id_verification_service.dart';

class StudentIdVerificationScreen extends StatefulWidget {
  const StudentIdVerificationScreen({super.key});

  @override
  State<StudentIdVerificationScreen> createState() =>
      _StudentIdVerificationScreenState();
}

class _StudentIdVerificationScreenState
    extends State<StudentIdVerificationScreen> {
  final _studentNumber = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _image;
  String _mimeType = 'image/jpeg';
  String? _message;
  String? _resultStatus;
  bool _busy = false;

  @override
  void dispose() {
    _studentNumber.dispose();
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
      setState(() {
        _image = bytes;
        _mimeType =
            file.mimeType ??
            (file.name.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg');
        _message = null;
        _resultStatus = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = source == ImageSource.camera
            ? 'Camera access was denied or unavailable. Allow camera access in your device settings, or upload from your gallery.'
            : 'Photo access was denied or unavailable. Allow photo access in your device settings and try again.';
        _resultStatus = null;
      });
    }
  }

  Future<void> _submit() async {
    final number = _studentNumber.text.trim().toUpperCase();
    if (number.isNotEmpty &&
        !RegExp(r'^\d{2}\s*-?\s*[A-Z]{2}\s*-?\s*\d{4}$').hasMatch(number)) {
      setState(
        () => _message =
            'Check the student number, or leave it blank so CoSci can read it from the ID.',
      );
      return;
    }
    if (_image == null) {
      setState(
        () => _message =
            'Take or upload a clear photo of the front of your PSU ID.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await const StudentIdVerificationService().verify(
        imageBytes: _image!,
        mimeType: _mimeType,
        studentNumber: number,
      );
      if (!mounted) return;
      setState(() {
        _resultStatus = result.status;
        _message = result.message;
      });
      if (result.approved) {
        await context.read<AuthProvider>().refreshSession();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final form = _VerificationCard(
      name: user?.displayName ?? 'Learner',
      program: user?.program ?? 'Program not set',
      studentNumber: _studentNumber,
      image: _image,
      busy: _busy,
      message: _message,
      rejected: _resultStatus == 'rejected',
      onCamera: () => _pick(ImageSource.camera),
      onGallery: () => _pick(ImageSource.gallery),
      onSubmit: _submit,
      onSignOut: () => context.read<AuthProvider>().signOut(),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      body: Stack(
        children: [
          const Positioned(
            top: -130,
            right: -90,
            child: _Orb(size: 330, color: Color(0xFFDDE8FB)),
          ),
          const Positioned(
            bottom: -150,
            left: -100,
            child: _Orb(size: 310, color: Color(0xFFDDF5F4)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 16,
                vertical: wide ? 32 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _OverviewPanel(
                                  name: user?.displayName ?? 'Learner',
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(flex: 6, child: form),
                            ],
                          ),
                        )
                      : form,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.name,
    required this.program,
    required this.studentNumber,
    required this.image,
    required this.busy,
    required this.message,
    required this.rejected,
    required this.onCamera,
    required this.onGallery,
    required this.onSubmit,
    required this.onSignOut,
  });

  final String name;
  final String program;
  final TextEditingController studentNumber;
  final Uint8List? image;
  final bool busy;
  final String? message;
  final bool rejected;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onSubmit;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 420 ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD6E2F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B2854),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading(),
          const SizedBox(height: 20),
          const _ProgressSteps(),
          const SizedBox(height: 20),
          _LearnerSummary(name: name, program: program),
          const SizedBox(height: 18),
          const Text(
            '1. Student number (optional)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: studentNumber,
            enabled: !busy,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'We can read this from your ID',
              prefixIcon: const Icon(Icons.numbers_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD6E2F2)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '2. Add a clear photo of your ID',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text(
            'Use the front of your ID. Keep PSU, your course, and student number visible.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 10),
          _ImageArea(image: image, busy: busy, onTap: onGallery),
          const SizedBox(height: 12),
          _PickerButtons(busy: busy, onCamera: onCamera, onGallery: onGallery),
          if (message != null) ...[
            const SizedBox(height: 14),
            _Feedback(message: message!, rejected: rejected),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: busy ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1746A2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(busy ? 'Reading your ID…' : 'Verify my ID'),
            ),
          ),
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
            onPressed: busy ? null : onSignOut,
            child: const Text('Sign out and use another account'),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student ID verification',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'Secure eligibility check • usually under a minute',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: image == null ? 150 : 230,
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
            ? const Column(
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
                    'JPG or PNG • maximum 5 MB',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
    return LayoutBuilder(
      builder: (context, constraints) {
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
        if (constraints.maxWidth < 470) {
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
      },
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
    return Container(
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
