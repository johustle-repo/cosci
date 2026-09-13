import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pseudocode_apk/services/student_id_models.dart';
import 'package:pseudocode_apk/services/student_id_verification_service.dart';

class StudentIdScannerScreen extends StatefulWidget {
  const StudentIdScannerScreen({super.key});

  @override
  State<StudentIdScannerScreen> createState() => _StudentIdScannerScreenState();
}

class _StudentIdScannerScreenState extends State<StudentIdScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  final StudentIdVerificationService _verificationService =
      const StudentIdVerificationService();

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  bool _scanning = false;
  bool _showReview = false;

  final _institutionController = TextEditingController();

  final _studentNameController = TextEditingController();

  final _studentNumberController = TextEditingController();

  final _programController = TextEditingController();

  @override
  void dispose() {
    _institutionController.dispose();
    _studentNameController.dispose();
    _studentNumberController.dispose();
    _programController.dispose();

    super.dispose();
  }

  Future<void> _takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );

    if (image == null) {
      return;
    }

    await _setImage(image);
  }

  Future<void> _chooseFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (image == null) {
      return;
    }

    await _setImage(image);
  }

  Future<void> _setImage(XFile image) async {
    final bytes = await image.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;
      _imageBytes = bytes;
      _showReview = false;

      _institutionController.clear();
      _studentNameController.clear();
      _studentNumberController.clear();
      _programController.clear();
    });
  }

  Future<void> _scanId() async {
    if (_imageBytes == null) {
      _showMessage('Please take or select a student ID first.');

      return;
    }

    setState(() {
      _scanning = true;
    });

    final mimeType = _mimeTypeFromPath(_selectedImage?.path ?? '');

    final result = await _verificationService.scan(
      imageBytes: _imageBytes!,
      mimeType: mimeType,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _scanning = false;
    });

    if (result.rejected) {
      _showRejectedDialog(result);
      return;
    }

    _institutionController.text = result.fields.institution;

    _studentNameController.text = result.fields.studentName;

    _studentNumberController.text = result.fields.studentNumber;

    _programController.text = result.fields.program;

    setState(() {
      _showReview = true;
    });

    _showMessage(result.message);

    debugPrint('RAW OCR TEXT:\n${result.rawText}');
  }

  Future<void> _confirm() async {
    final fields = StudentIdExtractedFields(
      institution: _institutionController.text,
      studentName: _studentNameController.text,
      studentNumber: _studentNumberController.text,
      program: _programController.text,
    );

    final result = await _verificationService.confirm(fields: fields);

    if (!mounted) {
      return;
    }

    if (result.accepted) {
      await _showAcceptedDialog(result);

      return;
    }

    if (result.rejected) {
      await _showRejectedDialog(result);

      return;
    }

    _showMessage(result.message);
  }

  Future<void> _showAcceptedDialog(StudentIdVerificationResult result) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified),
              SizedBox(width: 8),
              Expanded(child: Text('Student ID Accepted')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 16),
              Text('Name: ${result.fields.studentName}'),
              Text('Student Number: ${result.fields.studentNumber}'),
              Text(
                'Program: ${result.normalizedProgram ?? result.fields.program}',
              ),
              const Text('College: College of Computing Sciences'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRejectedDialog(StudentIdVerificationResult result) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined),
              SizedBox(width: 8),
              Expanded(child: Text('Student Not Eligible')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 16),
              const Text(
                'Eligible programs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• BS Information Technology'),
              const Text('• BS Computer Science'),
              const Text('• BS Mathematics'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _selectedImage = null;
                  _imageBytes = null;
                  _showReview = false;

                  _institutionController.clear();

                  _studentNameController.clear();

                  _studentNumberController.clear();

                  _programController.clear();
                });
              },
              child: const Text('Scan Another ID'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student ID Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 72),
                      SizedBox(height: 12),
                      Text('No student ID selected'),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _scanning ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanning ? null : _chooseFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: _selectedImage == null || _scanning ? null : _scanId,
                icon: _scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(_scanning ? 'Analyzing ID...' : 'Scan Student ID'),
              ),

              if (_showReview) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Review Extracted Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _institutionController,
                  decoration: const InputDecoration(
                    labelText: 'Institution',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _studentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Student Number',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _programController,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                    helperText: 'Accepted: BSIT, BSCS, or BS Mathematics',
                  ),
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.verified),
                  label: const Text('Confirm Information'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
