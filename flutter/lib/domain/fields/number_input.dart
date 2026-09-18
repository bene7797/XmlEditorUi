/// Converts German decimal commas to XML/XSD dots, e.g. 1234,56 → 1234.56
class NumberInput {
  static String normalizeDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;

    // 1.234,56 → 1234.56
    final germanThousands = RegExp(r'^-?\d{1,3}(\.\d{3})+,\d+$');
    if (germanThousands.hasMatch(trimmed)) {
      return trimmed.replaceAll('.', '').replaceAll(',', '.');
    }

    // 1234,56 → 1234.56
    final germanDecimal = RegExp(r'^-?\d+,\d+$');
    if (germanDecimal.hasMatch(trimmed)) {
      return trimmed.replaceAll(',', '.');
    }

    return value;
  }
}
