import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_syllabus_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_generation_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_settings_provider.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class AdminLessonGeneratorScreen extends StatefulWidget {
  const AdminLessonGeneratorScreen({super.key});

  @override
  State<AdminLessonGeneratorScreen> createState() => _State();
}

class _State extends State<AdminLessonGeneratorScreen> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final code = TextEditingController();
  final course = TextEditingController();
  final term = TextEditingController(text: 'First Semester');
  final syllabusText = TextEditingController();
  String language = 'C++';
  String year = '1st Year';
  PlatformFile? file;
  String? fileError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => configureServices());
  }

  Future<void> configureServices() async {
    final settings = context.read<AdminSettingsProvider>();
    await settings.loadSettings();
    if (!mounted) return;
    final key = settings.settings.groqApiKey;
    context.read<AdminSyllabusProvider>().configureApiKey(key);
    context.read<AdminGenerationProvider>().configureApiKey(key);
  }

  @override
  void dispose() {
    title.dispose();
    code.dispose();
    course.dispose();
    term.dispose();
    syllabusText.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'txt'],
      withData: true,
    );
    if (result == null) return;
    final selected = result.files.first;
    if (selected.bytes == null || selected.size > 10 * 1024 * 1024) {
      setState(
        () => fileError = selected.bytes == null
            ? 'The selected file could not be read.'
            : 'Maximum file size is 10 MB.',
      );
      return;
    }
    setState(() {
      file = selected;
      fileError = null;
      if (title.text.trim().isEmpty) {
        title.text = selected.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (file == null) {
      setState(() => fileError = 'Select a syllabus file first.');
      return;
    }
    final auth = context.read<AuthProvider>().currentUser;
    final settings = context.read<AdminSettingsProvider>();
    if (settings.settings.groqApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Configure the content-generation key in Settings first.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AdminSyllabusProvider>().configureApiKey(
      settings.settings.groqApiKey,
    );
    context.read<AdminGenerationProvider>().configureApiKey(
      settings.settings.groqApiKey,
    );
    final provider = context.read<AdminSyllabusProvider>();
    final generation = context.read<AdminGenerationProvider>();
    final id = await provider.uploadAndCreate(
      fileBytes: file!.bytes!,
      fileName: file!.name,
      fileType: file!.extension ?? 'txt',
      title: title.text,
      courseCode: code.text,
      courseName: course.text,
      programmingLanguage: language,
      yearLevel: year,
      term: term.text,
      uploadedBy: auth?.uid ?? '',
      uploadedByEmail: auth?.email ?? '',
    );
    if (!mounted) return;
    if (id == null) {
      _showFailure(
        provider.uploadError ?? 'The syllabus could not be uploaded.',
      );
      return;
    }
    await provider.loadSyllabusDetail(id);
    if (!mounted) return;
    final analyzed = await provider.analyzeSyllabus(
      textContent: syllabusText.text.trim(),
    );
    if (!mounted) return;
    if (!analyzed || provider.currentAnalysis == null) {
      _showFailure(
        provider.analysisError ??
            'The syllabus could not be analyzed. Check its pasted text.',
      );
      return;
    }
    final generated = await generation.generateContent(
      analysis: provider.currentAnalysis!,
      contentType: 'lesson',
    );
    if (!mounted) return;
    if (!generated) {
      _showFailure(
        generation.generationError ??
            'No lesson drafts were generated. Please try again.',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${generation.countFor('lessons')} lesson drafts created.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.adminLessons,
      (route) => route.isFirst,
    );
  }

  void _showFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSyllabusProvider>();
    final generation = context.watch<AdminGenerationProvider>();
    final form = _UploadForm(
      formKey: formKey,
      title: title,
      code: code,
      course: course,
      term: term,
      syllabusText: syllabusText,
      language: language,
      year: year,
      file: file,
      error:
          fileError ??
          provider.uploadError ??
          provider.analysisError ??
          generation.generationError,
      busy:
          provider.isUploading ||
          provider.isAnalyzing ||
          generation.isGenerating,
      progress: provider.isUploading
          ? provider.uploadProgress
          : generation.isGenerating
          ? generation.generationProgress
          : 0,
      stage: provider.isUploading
          ? 'Uploading syllabus…'
          : provider.isAnalyzing
          ? 'Reading syllabus content…'
          : generation.isGenerating
          ? 'Creating lesson drafts…'
          : null,
      onLanguage: (v) => setState(() => language = v),
      onYear: (v) => setState(() => year = v),
      onPick: pickFile,
      onSubmit: submit,
    );
    return AdminShell(
      pageTitle: 'Lesson Generator',
      currentRoute: AppRoutes.adminLessons,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.adminLessons),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to lessons'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create lessons from a syllabus',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102449),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload the course syllabus and confirm the learner scope. Structured lesson drafts will be prepared for review.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 920) {
                return Column(
                  children: [form, const SizedBox(height: 18), const _Guide()],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: form),
                  const SizedBox(width: 20),
                  const Expanded(flex: 2, child: _Guide()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UploadForm extends StatelessWidget {
  const _UploadForm({
    required this.formKey,
    required this.title,
    required this.code,
    required this.course,
    required this.term,
    required this.syllabusText,
    required this.language,
    required this.year,
    required this.file,
    required this.error,
    required this.busy,
    required this.progress,
    required this.stage,
    required this.onLanguage,
    required this.onYear,
    required this.onPick,
    required this.onSubmit,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController title, code, course, term, syllabusText;
  final String language, year;
  final PlatformFile? file;
  final String? error;
  final bool busy;
  final double progress;
  final String? stage;
  final ValueChanged<String> onLanguage, onYear;
  final VoidCallback onPick, onSubmit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Syllabus details',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Syllabus title *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: required,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: code,
                    decoration: const InputDecoration(
                      labelText: 'Course code',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  width: 330,
                  child: TextFormField(
                    controller: course,
                    decoration: const InputDecoration(
                      labelText: 'Course name *',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    validator: required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: const InputDecoration(
                      labelText: 'Programming language',
                    ),
                    items: const ['C++', 'Java', 'JavaScript']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onLanguage(v);
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'Year level'),
                    items: const ['1st Year', '2nd Year']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onYear(v);
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    initialValue: term.text,
                    decoration: const InputDecoration(
                      labelText: 'Academic term',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    items: const ['First Semester', 'Second Semester']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) term.text = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: syllabusText,
              minLines: 7,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Syllabus content *',
                alignLabelWithHint: true,
                hintText: 'Paste course topics, outcomes, and weekly coverage.',
              ),
              validator: (value) => value == null || value.trim().length < 100
                  ? 'Paste at least 100 characters of syllabus content.'
                  : null,
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: busy ? null : onPick,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: error == null
                        ? const Color(0xFFD8E3F2)
                        : const Color(0xFFDC2626),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFF2563EB),
                      size: 30,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        file?.name ?? 'Choose PDF, DOCX, or TXT syllabus',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Text(
                      'Browse',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ),
            if (busy) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress > 0 ? progress : null),
              const SizedBox(height: 8),
              Text(
                stage ?? 'Preparing lessons…',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onSubmit,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  busy
                      ? (stage ?? 'Preparing lessons…')
                      : 'Generate lesson drafts',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}

class _Guide extends StatelessWidget {
  const _Guide();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'What happens next',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 18),
          _Step(
            '1',
            'Read the syllabus',
            'Extract outcomes, topics, and sequence.',
          ),
          _Step(
            '2',
            'Build the lesson plan',
            'Organize topics for the language and year level.',
          ),
          _Step(
            '3',
            'Prepare lesson drafts',
            'Create objectives, algorithms, examples, and practice.',
          ),
          _Step(
            '4',
            'Review before publishing',
            'Every generated lesson remains a draft until approved.',
          ),
        ],
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.title, this.text);
  final String number, title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF0E3A8A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
