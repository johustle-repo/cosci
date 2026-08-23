import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_syllabus_provider.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _blueLight = Color(0xFFEFF6FF);
const _border = Color(0xFFE2E8F0);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminSyllabusScreen extends StatefulWidget {
  const AdminSyllabusScreen({super.key});

  @override
  State<AdminSyllabusScreen> createState() => _AdminSyllabusScreenState();
}

class _AdminSyllabusScreenState extends State<AdminSyllabusScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSyllabusProvider>().loadSyllabi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Syllabi',
      currentRoute: AppRoutes.adminSyllabus,
      child: Consumer<AdminSyllabusProvider>(
        builder: (context, provider, _) {
          final syllabi = provider.syllabi
              .where(
                (s) =>
                    _searchQuery.isEmpty ||
                    s.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    s.courseCode.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    s.courseName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ──────────────────────────────────────────────
              _PageHeader(
                totalCount: provider.syllabi.length,
                analyzedCount: provider.syllabi
                    .where((s) => s.isAnalyzed)
                    .length,
                onUpload: () => _showUploadDialog(context, provider),
              ),
              const SizedBox(height: 24),

              // ── Search + table ───────────────────────────────────────────
              _SearchBar(
                value: _searchQuery,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 16),

              if (provider.isLoading)
                const _LoadingTable()
              else if (provider.error != null && provider.syllabi.isEmpty)
                _ErrorBanner(
                  message: provider.error!,
                  onRetry: provider.loadSyllabi,
                )
              else if (syllabi.isEmpty)
                _EmptyState(
                  hasQuery: _searchQuery.isNotEmpty,
                  onUpload: () => _showUploadDialog(context, provider),
                )
              else
                _SyllabiTable(
                  syllabi: syllabi,
                  onDelete: (s) async {
                    final ok = await showAdminConfirmDialog(
                      context,
                      title: 'Delete Syllabus',
                      message:
                          'Delete "${s.title}"? All linked analysis data will also be removed.',
                    );
                    if (ok && context.mounted) {
                      await provider.deleteSyllabus(s.id, s.title);
                    }
                  },
                  onView: (s) => Navigator.pushNamed(
                    context,
                    AppRoutes.adminSyllabusDetail,
                    arguments: s.id,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showUploadDialog(BuildContext ctx, AdminSyllabusProvider provider) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _UploadSyllabusDialog(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER WITH STAT CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.totalCount,
    required this.analyzedCount,
    required this.onUpload,
  });
  final int totalCount;
  final int analyzedCount;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_navy, _blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Syllabus Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _textMain,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Upload syllabi and generate AI-powered course content',
                            style: TextStyle(fontSize: 13, color: _textSub),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _UploadButton(onPressed: onUpload),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatTile(
              label: 'Total Syllabi',
              value: '$totalCount',
              icon: Icons.description_rounded,
              color: _blue,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Analysed',
              value: '$analyzedCount',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF059669),
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Pending',
              value: '${totalCount - analyzedCount}',
              icon: Icons.pending_rounded,
              color: const Color(0xFFD97706),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: _textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file_rounded, size: 18),
      label: const Text('Upload Syllabus'),
      style: FilledButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by title, code or name…',
          hintStyle: const TextStyle(fontSize: 13, color: _textSub),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: _textSub,
          ),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _textSub,
                  ),
                  onPressed: () => onChanged(''),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _blue, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM DATA TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _SyllabiTable extends StatelessWidget {
  const _SyllabiTable({
    required this.syllabi,
    required this.onView,
    required this.onDelete,
  });

  final List<dynamic> syllabi;
  final void Function(dynamic s) onView;
  final void Function(dynamic s) onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1180,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFF)),
        headingRowHeight: 48,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 72,
        horizontalMargin: 20,
        columnSpacing: 24,
        dividerThickness: 1,
        columns: const [
          DataColumn(label: _ColHeader('Syllabus Title')),
          DataColumn(label: _ColHeader('Course')),
          DataColumn(label: _ColHeader('Language')),
          DataColumn(label: _ColHeader('File')),
          DataColumn(label: _ColHeader('Analysis')),
          DataColumn(label: _ColHeader('Uploaded')),
          DataColumn(label: _ColHeader('Actions')),
        ],
        rows: syllabi.map((s) {
          return DataRow(
            cells: [
              // Title
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _textMain,
                        ),
                      ),
                      if (s.uploadedByEmail.isNotEmpty)
                        Text(
                          s.uploadedByEmail,
                          style: const TextStyle(fontSize: 11, color: _textSub),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // Course
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.courseCode.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.courseCode,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _textSub,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        s.courseName.isNotEmpty ? s.courseName : '—',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: _textMain),
                      ),
                    ),
                  ],
                ),
              ),
              // Language
              DataCell(_LangBadge(label: s.programmingLanguage)),
              // File
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _fileIcon(s.fileType),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.fileType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _textMain,
                          ),
                        ),
                        Text(
                          s.displayFileSize,
                          style: const TextStyle(fontSize: 11, color: _textSub),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Analysis status
              DataCell(_AnalysisBadge(status: s.analysisStatus)),
              // Date
              DataCell(
                Text(
                  s.createdAt != null
                      ? DateFormat('MMM d, yyyy').format(s.createdAt!)
                      : '—',
                  style: const TextStyle(fontSize: 12, color: _textSub),
                ),
              ),
              // Actions
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionBtn(
                      icon: Icons.open_in_new_rounded,
                      label: 'Open',
                      color: _blue,
                      onTap: () => onView(s),
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: const Color(0xFFDC2626),
                      onTap: () => onDelete(s),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _fileIcon(String type) {
    final (icon, color) = switch (type.toLowerCase()) {
      'pdf' => (Icons.picture_as_pdf_rounded, const Color(0xFFDC2626)),
      'docx' => (Icons.description_rounded, const Color(0xFF1D4ED8)),
      _ => (Icons.text_snippet_rounded, const Color(0xFF059669)),
    };
    return Icon(icon, size: 20, color: color);
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const Text('—', style: TextStyle(color: _textSub));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _blue,
        ),
      ),
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  const _AnalysisBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      'analyzed' => (
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
        Icons.check_circle_rounded,
        'Analyzed',
      ),
      'analyzing' => (
        const Color(0xFFDBEAFE),
        _blue,
        Icons.sync_rounded,
        'Analyzing…',
      ),
      'failed' => (
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
        Icons.error_rounded,
        'Failed',
      ),
      _ => (
        const Color(0xFFF1F5F9),
        _textSub,
        Icons.schedule_rounded,
        'Pending',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingTable extends StatelessWidget {
  const _LoadingTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              'Loading syllabi…',
              style: TextStyle(fontSize: 13, color: _textSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onUpload});
  final bool hasQuery;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _blueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_rounded,
                size: 36,
                color: _blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No results found' : 'No syllabi uploaded yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different search term.'
                  : 'Upload your first syllabus to start generating\nAI-powered course content.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textSub),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Upload Syllabus'),
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPLOAD DIALOG — PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _UploadSyllabusDialog extends StatefulWidget {
  const _UploadSyllabusDialog();

  @override
  State<_UploadSyllabusDialog> createState() => _UploadSyllabusDialogState();
}

class _UploadSyllabusDialogState extends State<_UploadSyllabusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _termCtrl = TextEditingController();

  String _language = 'C++';
  String _yearLevel = '1st Year';
  PlatformFile? _pickedFile;
  String? _pickError;

  static const _languages = ['C++', 'Java', 'JavaScript'];
  static const _yearLevels = ['1st Year', '2nd Year'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _pickError = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _pickError = 'Could not read file bytes. Try again.');
      return;
    }
    const maxBytes = 10 * 1024 * 1024;
    if (file.size > maxBytes) {
      setState(() => _pickError = 'File too large (max 10 MB).');
      return;
    }
    setState(() => _pickedFile = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      setState(() => _pickError = 'Please select a file.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final provider = context.read<AdminSyllabusProvider>();
    final id = await provider.uploadAndCreate(
      fileBytes: _pickedFile!.bytes!,
      fileName: _pickedFile!.name,
      fileType: _pickedFile!.extension ?? 'txt',
      title: _titleCtrl.text.trim(),
      courseCode: _codeCtrl.text.trim(),
      courseName: _nameCtrl.text.trim(),
      programmingLanguage: _language,
      yearLevel: _yearLevel,
      term: _termCtrl.text.trim(),
      uploadedBy: auth.currentUser?.uid ?? '',
      uploadedByEmail: auth.currentUser?.email ?? '',
    );
    if (!mounted) return;
    if (id != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Syllabus uploaded. Open it to run analysis.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSyllabusProvider>();
    final isBusy = provider.isUploading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _blue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Upload Syllabus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: isBusy ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.uploadError != null)
                        _DialogErrorBanner(message: provider.uploadError!),

                      _field(
                        child: TextFormField(
                          controller: _titleCtrl,
                          decoration: _dec(
                            'Syllabus Title *',
                            Icons.title_rounded,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _field(
                              child: TextFormField(
                                controller: _codeCtrl,
                                decoration: _dec(
                                  'Course Code',
                                  Icons.tag_rounded,
                                  hint: 'CS101',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: _field(
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: _dec(
                                  'Course Name',
                                  Icons.school_rounded,
                                  hint: 'Intro to Programming',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              child: DropdownButtonFormField<String>(
                                initialValue: _language,
                                decoration: _dec(
                                  'Language *',
                                  Icons.code_rounded,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: _languages
                                    .map(
                                      (l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _language = v!),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              child: DropdownButtonFormField<String>(
                                initialValue: _yearLevel,
                                decoration: _dec(
                                  'Year Level',
                                  Icons.grade_rounded,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: _yearLevels
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _yearLevel = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _termCtrl,
                          decoration: _dec(
                            'Academic Term',
                            Icons.calendar_month_rounded,
                            hint: '1st Semester AY 2025-2026',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // File picker area
                      _FileDropZone(
                        file: _pickedFile,
                        error: _pickError,
                        onPick: isBusy ? null : _pickFile,
                      ),

                      if (isBusy) ...[
                        const SizedBox(height: 16),
                        _ProgressBar(progress: provider.uploadProgress),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isBusy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: isBusy ? null : _submit,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: Text(isBusy ? 'Uploading…' : 'Upload'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required Widget child}) => child;

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: _textSub),
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }
}

class _FileDropZone extends StatelessWidget {
  const _FileDropZone({
    required this.file,
    required this.error,
    required this.onPick,
  });
  final PlatformFile? file;
  final String? error;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: file != null
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: error != null
                ? const Color(0xFFDC2626)
                : file != null
                ? const Color(0xFF059669)
                : const Color(0xFFBFDBFE),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              file != null
                  ? Icons.check_circle_rounded
                  : Icons.upload_file_rounded,
              size: 32,
              color: file != null ? const Color(0xFF059669) : _blue,
            ),
            const SizedBox(height: 8),
            if (file != null) ...[
              Text(
                file!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF166534),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                _fmt(file!.size),
                style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
              ),
            ] else ...[
              const Text(
                'Click to select a file',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'PDF, TXT or DOCX — max 10 MB',
                style: TextStyle(fontSize: 12, color: _textSub),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                error!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Uploading to Cloudinary…',
              style: TextStyle(fontSize: 12, color: _textSub),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(_blue),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}

class _DialogErrorBanner extends StatelessWidget {
  const _DialogErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}
