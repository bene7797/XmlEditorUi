import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies bundled assets into a writable app-data folder on first run.
class AppDataStore {
  AppDataStore._(this.root);

  final String root;

  String get schemaPath => p.join(root, 'schema.xsd');
  String get templatesRoot => p.join(root, 'templates');
  String get servicesFolder => p.join(templatesRoot, 'services');
  String get profilesFolder => p.join(templatesRoot, 'profiles');
  String get nativeDllFolder => p.join(root, 'native');

  static Future<AppDataStore> ensureInitialized() async {
    final support = await getApplicationSupportDirectory();
    final root = p.join(support.path, 'XmlEditorFlutter');
    final store = AppDataStore._(root);
    await store._seedIfNeeded();
    return store;
  }

  Future<void> _seedIfNeeded() async {
    Directory(servicesFolder).createSync(recursive: true);
    Directory(profilesFolder).createSync(recursive: true);
    Directory(nativeDllFolder).createSync(recursive: true);

    await _copyAsset('assets/schema.xsd', schemaPath);

    const profileAssets = [
      'assets/templates/profiles/locations.xml',
      'assets/templates/profiles/coursetypes.xml',
    ];
    for (final asset in profileAssets) {
      final name = p.basename(asset);
      await _copyAsset(asset, p.join(profilesFolder, name));
    }

    const serviceAssets = [
      'assets/templates/services/Main.xml',
      'assets/templates/services/Main - Externenprüfung.xml',
      'assets/templates/services/Externenprüfung Kassel.xml',
      'assets/templates/services/Kassel - Teilzeit - Extended.xml',
      'assets/templates/services/Kassel - Vollzeit - Extended.xml',
      'assets/templates/services/Leipzig - Teilzeit.xml',
      'assets/templates/services/Leipzig Vollzeit - Extended.xml',
    ];
    for (final asset in serviceAssets) {
      final name = p.basename(asset);
      await _copyAsset(asset, p.join(servicesFolder, name));
    }

    // Prefer project-local native DLL (dev + packaged).
    final dllDest = p.join(nativeDllFolder, 'xsd_validator.dll');
    if (!File(dllDest).existsSync()) {
      final candidates = [
        p.join(Directory.current.path, 'native', 'xsd_validator.dll'),
        p.join(Directory.current.path, 'windows', 'xsd_validator.dll'),
        p.join(
          Directory.current.path,
          '..',
          'native',
          'publish',
          'xsd_validator.dll',
        ),
        p.join(
          p.dirname(Platform.resolvedExecutable),
          'xsd_validator.dll',
        ),
      ];
      for (final candidate in candidates) {
        final normalized = p.normalize(candidate);
        if (File(normalized).existsSync()) {
          await File(normalized).copy(dllDest);
          break;
        }
      }
    }
  }

  Future<void> _copyAsset(String assetPath, String destPath) async {
    final dest = File(destPath);
    if (dest.existsSync()) return;
    try {
      final data = await rootBundle.load(assetPath);
      await dest.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      // Asset may be missing for optional files; ignore.
    }
  }
}
