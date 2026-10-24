import 'package:flutter/foundation.dart';
import 'nudge_selection.dart';

/// Keeps the current card intact until a distinct replacement has arrived.
class NudgeAlternativeController extends ChangeNotifier {
  bool loading = false;
  bool canRevisit = false;
  bool hasError = false;
  String? message;
  String? _context;
  bool _reviewing = false;
  bool _disposed = false;
  int _version = 0;
  final Set<String> _visited = {};
  final Set<String> _saved = {};
  bool get hasInteracted => _visited.isNotEmpty;

  void contextChanged(String? value) {
    if (_context == value) return;
    _context = value;
    _version++;
    _visited.clear();
    _saved.clear();
    _reviewing = false;
    loading = false;
    canRevisit = hasError = false;
    message = null;
  }

  Future<void> request<T>({
    required Map<String, dynamic> metadata,
    required Future<void> Function() save,
    required Future<NudgeSelection<T>> Function(
      List<String> excluded,
      String mode,
    )
    fetch,
    required void Function(T item) replace,
    bool reviewEarlier = false,
  }) async {
    if (loading || _disposed) return;
    contextChanged(metadata['context_hash']?.toString());
    final action = metadata['action_id']?.toString();
    final content = metadata['content_id']?.toString();
    if (action == null || content == null) return;
    if (reviewEarlier) {
      _visited.clear();
      _reviewing = true;
    }
    _visited.add(action);
    loading = true;
    hasError = false;
    canRevisit = false;
    message = 'Finding another idea…';
    final version = ++_version;
    notifyListeners();
    try {
      if (!_saved.contains(content)) {
        await save();
        if (_disposed || version != _version) return;
        _saved.add(content);
      }
      if (_disposed || version != _version) return;
      final result = await fetch(
        _visited.toList(),
        _reviewing ? 'revisit' : 'next',
      );
      if (_disposed || version != _version) return;
      if (result.item != null) {
        replace(result.item as T);
        message = null;
      } else {
        canRevisit = result.canRevisit;
        message = canRevisit
            ? 'You’ve explored the ideas that fit right now.'
            : 'You’re up to date. New logs can bring more ideas.';
      }
    } catch (_) {
      if (_disposed || version != _version) return;
      hasError = true;
      message = 'Couldn’t load another idea. Your current one is still here.';
    } finally {
      if (!_disposed && version == _version) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
