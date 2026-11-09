import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/services/language_tracks.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The programming languages a student chose to study.
///
/// One selection is shared by Lessons, Quizzes, and Puzzles. Several
/// languages can be selected at once; an empty selection means "all
/// languages". The choice is remembered on the device.
class LanguageSelectionProvider extends ChangeNotifier {
  LanguageSelectionProvider() {
    _restore();
  }

  static const _prefsKey = 'selected_language_tracks';

  Set<String> _selected = const {};

  Set<String> get selected => _selected;
  bool get isAll => _selected.isEmpty;

  bool isSelected(String language) =>
      _selected.contains(LanguageTracks.normalize(language));

  bool matches(String? language) => LanguageTracks.matches(_selected, language);

  /// The tracks from [available] to show. Saved selections for languages
  /// that have no content here are ignored, falling back to all of them.
  List<String> visibleTracks(List<String> available) {
    final active = available.where(_selected.contains).toList();
    return active.isEmpty ? available : active;
  }

  void toggle(String language) {
    final track = LanguageTracks.normalize(language);
    final next = {..._selected};
    if (!next.remove(track)) next.add(track);
    _update(next);
  }

  void selectAll() => _update(const {});

  void _update(Set<String> next) {
    _selected = Set.unmodifiable(next);
    notifyListeners();
    _persist();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey);
      if (stored == null || stored.isEmpty) return;
      _selected = Set.unmodifiable(stored.map(LanguageTracks.normalize));
      notifyListeners();
    } catch (_) {
      // Preferences are a convenience only; fall back to "all languages".
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _selected.toList());
    } catch (_) {}
  }
}
