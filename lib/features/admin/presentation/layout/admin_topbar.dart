import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key, required this.pageTitle, this.onMenuPressed});

  final String pageTitle;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE6F4))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0F2A55),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              tooltip: 'Open navigation',
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            pageTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF102449),
              letterSpacing: -.25,
            ),
          ),
          const Spacer(),
          // Admin info badge
          if (MediaQuery.sizeOf(context).width >= 560)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFE9FBF8)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD6E2F2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 16,
                    color: Color(0xFF0E3A8A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user?.displayName ?? user?.email ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0E3A8A),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
