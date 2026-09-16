class MainTemplateVariants {
  static const standard = 'Standard (Umschulung)';
  static const externenpruefung = 'Externenprüfung';

  static const standardFileName = 'Main.xml';
  static const externFileName = 'Main - Externenprüfung.xml';

  static const List<String> all = [standard, externenpruefung];

  static String getFileName(String variant) =>
      isExternenpruefung(variant) ? externFileName : standardFileName;

  static bool isExternenpruefung(String? variant) =>
      variant != null &&
      variant.toLowerCase() == externenpruefung.toLowerCase();
}
