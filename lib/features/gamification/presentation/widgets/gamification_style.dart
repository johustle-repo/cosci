import 'package:flutter/material.dart';

class GamificationStyle {
  static const Color panel = Color(0xFF0B1F46);
  static const Color panelSoft = Color(0xFF123A7E);
  static const Color cyan = Color(0xFF56C4FF);
  static const Color teal = Color(0xFF2DE2E6);
  static const Color gold = Color(0xFFF6C66C);

  static Color badgeColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF123D9B;
    return Color(value);
  }

  static IconData badgeIcon(String iconName) {
    switch (iconName) {
      case 'terminal':
        return Icons.terminal_rounded;
      case 'spark':
        return Icons.auto_awesome_rounded;
      case 'puzzle':
        return Icons.extension_rounded;
      case 'target':
        return Icons.track_changes_rounded;
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'seedling':
        return Icons.eco_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }
}
