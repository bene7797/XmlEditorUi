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
  String get referenceFolder => p.join(root, 'reference');
  String get credentialsPath => p.join(root, 'kursnet_login.json');

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
    Directory(p.join(referenceFolder, 'wertebereiche')).createSync(recursive: true);

    await _copyAsset('assets/openqcat/schema.xsd', schemaPath, overwrite: true);

    const profileAssets = [
      'assets/openqcat/templates/profiles/locations.xml',
      'assets/openqcat/templates/profiles/coursetypes.xml',
    ];
    for (final asset in profileAssets) {
      await _copyAsset(asset, p.join(profilesFolder, p.basename(asset)));
    }

    const serviceAssets = [
      'assets/openqcat/templates/services/Main.xml',
      'assets/openqcat/templates/services/Main - Externenprüfung.xml',
      'assets/openqcat/templates/services/Externenprüfung Kassel.xml',
      'assets/openqcat/templates/services/Kassel - Teilzeit - Extended.xml',
      'assets/openqcat/templates/services/Kassel - Vollzeit - Extended.xml',
      'assets/openqcat/templates/services/Leipzig - Teilzeit.xml',
      'assets/openqcat/templates/services/Leipzig Vollzeit - Extended.xml',
    ];
    for (final asset in serviceAssets) {
      await _copyAsset(asset, p.join(servicesFolder, p.basename(asset)));
    }

    await _repairStaleTemplates(serviceAssets);

    const referenceFiles = [
      'assets/openqcat/reference/Orte.csv',
      'assets/openqcat/reference/Systematik.csv',
      'assets/openqcat/reference/Zertifizierer.csv',
    ];
    for (final asset in referenceFiles) {
      await _copyAsset(
        asset,
        p.join(referenceFolder, p.basename(asset)),
        overwrite: true,
      );
    }

    const wertFiles = [
      'abschlussgrad_studienangebot.dat',
      'akkreditierung.dat',
      'angebotstyp.dat',
      'ansprechpartner.dat',
      'behinderungen.dat',
      'bildungsart.dat',
      'dauerklassen.dat',
      'durchfuehrungsform.dat',
      'foerderartenbund.dat',
      'foerderartenland.dat',
      'landpartnerhochschule.dat',
      'lehramtstyp.dat',
      'mastertyp.dat',
      'schulart.dat',
      'studienform.dat',
      'studieren_ohne_abitur.dat',
      'unterrichtsform.dat',
      'unterrichtssprache.dat',
      'unterrichtszeit.dat',
      'vgstrukturart.dat',
      'zertstatus.dat',
      'zugehoerig.dat',
      'zulassungsmodus.dat',
      'zulassungssemester.dat',
    ];
    for (final name in wertFiles) {
      await _copyAsset(
        'assets/openqcat/reference/wertebereiche/$name',
        p.join(referenceFolder, 'wertebereiche', name),
        overwrite: true,
      );
    }

    final dllDest = p.join(nativeDllFolder, 'xsd_validator.dll');
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
        Directory.current.path,
        '..',
        'native',
        'bin',
        'Release',
        'net10.0',
        'win-x64',
        'native',
        'xsd_validator.dll',
      ),
      p.join(p.dirname(Platform.resolvedExecutable), 'xsd_validator.dll'),
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'native',
        'xsd_validator.dll',
      ),
    ];

    File? bestSource;
    for (final candidate in candidates) {
      final normalized = p.normalize(candidate);
      final file = File(normalized);
      if (!file.existsSync()) continue;
      if (bestSource == null ||
          file.lastModifiedSync().isAfter(bestSource.lastModifiedSync())) {
        bestSource = file;
      }
    }

    if (bestSource != null) {
      final dest = File(dllDest);
      final needsCopy = !dest.existsSync() ||
          bestSource.lastModifiedSync().isAfter(dest.lastModifiedSync()) ||
          await bestSource.length() != await dest.length();
      if (needsCopy) {
        await bestSource.copy(dllDest);
      }
    }
  }

  Future<void> _repairStaleTemplates(List<String> serviceAssets) async {
    final destPath = p.join(servicesFolder, 'Main.xml');
    final dest = File(destPath);
    if (!dest.existsSync()) return;
    try {
      final text = await dest.readAsString();
      final stale = text.contains('deutschland') ||
          text.contains('CONTACT_ROLE type="5"') ||
          !RegExp(
            r'<SUPPLIER[\s\S]*?<EXTENDED_INFO[\s\S]*?</SUPPLIER>',
            caseSensitive: false,
          ).hasMatch(text);
      if (!stale) return;
      for (final asset in serviceAssets) {
        await _copyAsset(
          asset,
          p.join(servicesFolder, p.basename(asset)),
          overwrite: true,
        );
      }
      await _copyAsset(
        'assets/openqcat/templates/profiles/locations.xml',
        p.join(profilesFolder, 'locations.xml'),
        overwrite: true,
      );
    } catch (_) {
      // Keep existing files if repair fails.
    }
  }

  Future<void> _copyAsset(
    String assetPath,
    String destPath, {
    bool overwrite = false,
  }) async {
    final dest = File(destPath);
    if (dest.existsSync() && !overwrite) return;
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
