import 'package:flutter/material.dart';

class AdminPreviewSection {
  const AdminPreviewSection(this.title, this.content, {this.isCode = false});

  final String title;
  final String content;
  final bool isCode;
}

Future<void> showAdminContentPreview(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Map<String, String> metadata,
  required List<AdminPreviewSection> sections,
}) {
  final visibleSections = sections
      .where((section) => section.content.trim().isNotEmpty)
      .toList();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF123B82), Color(0xFF0F9FA5)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ADMIN PREVIEW',
                          style: TextStyle(
                            color: Color(0xFFCCFBF1),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: metadata.entries
                          .where((entry) => entry.value.trim().isNotEmpty)
                          .map(
                            (entry) => Chip(
                              avatar: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                              ),
                              label: Text('${entry.key}: ${entry.value}'),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    if (visibleSections.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No previewable content has been added yet.',
                          ),
                        ),
                      )
                    else
                      ...visibleSections.map(
                        (section) => Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: section.isCode
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: section.isCode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: section.isCode
                                      ? const Color(0xFF5EEAD4)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                section.content,
                                style: TextStyle(
                                  height: 1.5,
                                  fontFamily: section.isCode
                                      ? 'monospace'
                                      : null,
                                  color: section.isCode
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
