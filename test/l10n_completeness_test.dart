import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against translation drift: every translated ARB file (fr/ar/it) must
/// contain at least every non-metadata key present in the English source
/// (`app_en.arb`). If a key is added to English but not to a translation, this
/// test fails loudly with the list of missing keys per locale, so the app never
/// silently shows a raw key.
void main() {
  const l10nDir = 'lib/src/l10n';
  const sourceFile = 'app_en.arb';
  const translatedFiles = ['app_fr.arb', 'app_ar.arb', 'app_it.arb'];

  Set<String> nonMetadataKeys(String fileName) {
    final raw = File('$l10nDir/$fileName').readAsStringSync();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.keys
        .where((key) => !key.startsWith('@'))
        .toSet();
  }

  test('translation ARB files are a superset of the English source keys', () {
    final enKeys = nonMetadataKeys(sourceFile);
    expect(enKeys, isNotEmpty, reason: 'Expected $sourceFile to define keys.');

    final missingByLocale = <String, List<String>>{};
    for (final file in translatedFiles) {
      final keys = nonMetadataKeys(file);
      final missing = enKeys.difference(keys).toList()..sort();
      if (missing.isNotEmpty) {
        missingByLocale[file] = missing;
      }
    }

    expect(
      missingByLocale,
      isEmpty,
      reason: 'Translation files are missing keys present in $sourceFile:\n'
          '${missingByLocale.entries.map((e) => '  ${e.key}: ${e.value.join(', ')}').join('\n')}',
    );
  });
}
