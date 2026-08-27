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
  }

  Future<void> _submit() async {
    final number = _studentNumber.text.trim().toUpperCase();
    if (!RegExp(r'^\d{2}-[A-Z]{2}-\d{4}$').hasMatch(number)) {
      setState(
        () => _message =
            'Enter the student number shown on the ID, for example 23-LN-5223.',
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
    final rejected = _resultStatus == 'rejected';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD5E1F1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 44,
                  color: Color(0xFF1746A2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verify your PSU student ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'CoSci is available to eligible CCS learners. We check the ID program and student number, then discard the uploaded image.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${user?.displayName ?? 'Learner'} • ${user?.program ?? 'Program not set'}\nUse a clear, uncropped image with the PSU name, student number, and course visible.',
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _studentNumber,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Student number',
                    hintText: '23-LN-5223',
                    prefixIcon: Icon(Icons.numbers_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                if (_image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _image!,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD5E1F1)),
                    ),
                    child: const Center(child: Text('No ID image selected')),
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
                      onPressed: _busy
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload from gallery'),
                    ),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: rejected
                          ? const Color(0xFFFFE4E6)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: rejected
                            ? const Color(0xFFBE123C)
                            : const Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(_busy ? 'Analyzing ID…' : 'Verify student ID'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.read<AuthProvider>().signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
