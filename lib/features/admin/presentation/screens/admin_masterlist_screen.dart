import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_masterlist_entry.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_masterlist_provider.dart';

const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _green = Color(0xFF059669);
const _border = Color(0xFFE2E8F0);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

const _programs = [
  'BS Information Technology',
  'BS Computer Science',
  'BS Mathematics',
];

final _studentNumberPattern = RegExp(r'^\d{2}-[A-Z]{2}-\d{4}$');

String _canonicalStudentNumber(String raw) {
  final compact = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final match = RegExp(r'^(\d{2})([A-Z]{2})(\d{4})$').firstMatch(compact);
  return match == null ? '' : '${match[1]}-${match[2]}-${match[3]}';
}

class AdminMasterlistScreen extends StatefulWidget {
  const AdminMasterlistScreen({super.key});

  @override
  State<AdminMasterlistScreen> createState() => _AdminMasterlistScreenState();
}

class _AdminMasterlistScreenState extends State<AdminMasterlistScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminMasterlistProvider>().loadEntries();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEntryDialog({AdminMasterlistEntry? existing}) async {
    final provider = context.read<AdminMasterlistProvider>();
    final entry = await showDialog<AdminMasterlistEntry>(
      context: context,
      builder: (_) => _EntryDialog(
        existing: existing,
        isDuplicate: (studentNumber) =>
            existing == null && provider.exists(studentNumber),
      ),
    );
    if (entry == null || !mounted) return;
    final ok = existing == null
        ? await provider.createEntry(entry)
        : await provider.updateEntry(entry);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB91C1C),
          content: Text(provider.error ?? 'Could not save this entry.'),
          duration: const Duration(seconds: 3),
        ),
      );
      provider.clearError();
    }
  }

  Future<void> _confirmDelete(AdminMasterlistEntry entry) async {
    final provider = context.read<AdminMasterlistProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: Color(0xFFDC2626),
          size: 34,
        ),
        title: const Text('Remove from masterlist?'),
        content: Text(
          'Remove ${entry.studentNumber} (${entry.name})? Verification will '
          'no longer recognize this student number as CCS-enrolled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await provider.deleteEntry(entry.studentNumber, entry.name);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFB91C1C),
        content: Text(provider.error ?? 'Could not remove this entry.'),
        duration: const Duration(seconds: 3),
      ),
    );
    provider.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'CCS Masterlist',
      currentRoute: AppRoutes.adminMasterlist,
      child: Consumer<AdminMasterlistProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                total: provider.entries.length,
                activeCount: provider.entries.where((e) => e.active).length,
                onRefresh: () => provider.loadEntries(forceRefresh: true),
                onAdd: () => _openEntryDialog(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: provider.setSearch,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by student number, name, or program...',
                  hintStyle: const TextStyle(fontSize: 13, color: _textSub),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: _textSub,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _blue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (provider.isLoading && provider.entries.isEmpty)
                const _LoadingState()
              else if (provider.error != null && provider.entries.isEmpty)
                _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadEntries,
                )
              else if (provider.entries.isEmpty)
                const _EmptyState()
              else
                _MasterlistTable(
                  entries: provider.entries,
                  onEdit: (e) => _openEntryDialog(existing: e),
                  onDelete: _confirmDelete,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.total,
    required this.activeCount,
    required this.onRefresh,
    required this.onAdd,
  });
  final int total;
  final int activeCount;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            Icons.fact_check_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CCS Student Masterlist',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$total student number${total == 1 ? '' : 's'} on file  ·  '
                '$activeCount active',
                style: const TextStyle(fontSize: 13, color: _textSub),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Add student'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _MasterlistTable extends StatelessWidget {
  const _MasterlistTable({
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });
  final List<AdminMasterlistEntry> entries;
  final ValueChanged<AdminMasterlistEntry> onEdit;
  final ValueChanged<AdminMasterlistEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173A67),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFF), Color(0xFFEFF5FF)],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _H('Student Number')),
                Expanded(flex: 4, child: _H('Name')),
                Expanded(flex: 3, child: _H('Program')),
                SizedBox(width: 90, child: _H('Status')),
                SizedBox(width: 96, child: _H('Actions', center: true)),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          ...entries.asMap().entries.map((e) {
            final isLast = e.key == entries.length - 1;
            final entry = e.value;
            return Column(
              children: [
                Container(
                  color: e.key.isEven ? Colors.white : const Color(0xFFFBFDFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.studentNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: Color(0xFF17376B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          entry.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.program,
                          style: const TextStyle(fontSize: 12, color: _textSub),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: _ActiveBadge(active: entry.active),
                      ),
                      SizedBox(
                        width: 96,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEdit(entry),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              onPressed: () => onDelete(entry),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, color: _border),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text, {this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF52627A),
        letterSpacing: 0.7,
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? _green : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? _green : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _navy, strokeWidth: 2.5),
          SizedBox(height: 12),
          Text(
            'Loading the masterlist…',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 30,
              color: _navy,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The masterlist is empty.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add enrolled CCS student numbers so ID verification can find them.',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
        ],
      ),
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({this.existing, required this.isDuplicate});
  final AdminMasterlistEntry? existing;
  final bool Function(String studentNumber) isDuplicate;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _numberCtrl = TextEditingController(
    text: widget.existing?.studentNumber ?? '',
  );
  late final _nameCtrl = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _program = widget.existing?.program ?? _programs.first;
  late bool _active = widget.existing?.active ?? true;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final number = _canonicalStudentNumber(_numberCtrl.text);
    Navigator.pop(
      context,
      AdminMasterlistEntry(
        studentNumber: number,
        name: _nameCtrl.text.trim(),
        program: _program,
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit masterlist entry' : 'Add student'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _numberCtrl,
                enabled: !_isEditing,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Student number',
                  hintText: '22-CS-1234',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
                validator: (value) {
                  final canonical = _canonicalStudentNumber(value ?? '');
                  if (canonical.isEmpty ||
                      !_studentNumberPattern.hasMatch(canonical)) {
                    return 'Enter a valid student number, e.g. 22-CS-1234.';
                  }
                  if (widget.isDuplicate(canonical)) {
                    return 'This student number is already on the masterlist.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter the student\'s full name.'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _program,
                decoration: const InputDecoration(
                  labelText: 'Program',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _programs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _program = value);
                },
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                title: const Text('Active'),
                subtitle: const Text(
                  'Inactive entries are on file but fail verification.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save changes' : 'Add student'),
        ),
      ],
    );
  }
}
