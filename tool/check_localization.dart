import 'dart:io';

const _sourceRoots = ['lib/app', 'lib/features', 'lib/shared'];

const _excludedFiles = {'lib/l10n/localized_text.dart'};

final _rawTextPattern = RegExp(r'(?<![A-Za-z0-9_.])Text\s*\(');
final _rawRichTextPattern = RegExp(r'(?<![A-Za-z0-9_.])RichText\s*\(');
final _literalAccessibilityPattern = RegExp(
  r'''\b(tooltip|semanticLabel|labelText|hintText|helperText|counterText)\s*:\s*(['"])''',
);

void main() {
  final violations = <String>[];

  for (final rootPath in _sourceRoots) {
    final root = Directory(rootPath);
    if (!root.existsSync()) continue;

    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (_excludedFiles.contains(path)) continue;
      if (path.contains('/data/') || path.contains('/services/')) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (_rawTextPattern.hasMatch(line)) {
          violations.add(
            '$path:${index + 1}: use LocalizedText for app-owned copy',
          );
        }
        if (_rawRichTextPattern.hasMatch(line)) {
          violations.add(
            '$path:${index + 1}: use LocalizedRichText for app-owned copy',
          );
        }
        if (_literalAccessibilityPattern.hasMatch(line) &&
            !RegExp(r'''\:\s*(['"])\1\s*[,)]''').hasMatch(line) &&
            !line.contains('.localizedCopy(') &&
            !_nearbyLocalization(lines, index)) {
          violations.add(
            '$path:${index + 1}: localize tooltip/input/accessibility copy',
          );
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Localization audit found ${violations.length} issue(s):');
    for (final violation in violations) {
      stderr.writeln('  $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Localization audit passed.');
}

bool _nearbyLocalization(List<String> lines, int index) {
  final end = (index + 4).clamp(0, lines.length);
  return lines.sublist(index, end).join(' ').contains('.localizedCopy(');
}
