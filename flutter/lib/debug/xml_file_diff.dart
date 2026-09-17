import 'package:xml/xml.dart';

import '../data/xml/xml_file_io.dart';

class XmlDiffResult {
  XmlDiffResult({required this.leftPath, required this.rightPath, required this.diffs});

  final String leftPath;
  final String rightPath;
  final List<String> diffs;

  bool get isIdentical => diffs.isEmpty;
}

/// Structural XML comparison that ignores formatting, comments and declarations.
class XmlFileDiff {
  XmlFileDiff._();

  static const maxDiffs = 250;

  static XmlDiffResult compareFiles(String leftPath, String rightPath) {
    final left = XmlFileIo.loadDocument(leftPath);
    final right = XmlFileIo.loadDocument(rightPath);
    final diffs = <String>[];
    _compareNodes(
      left.rootElement,
      right.rootElement,
      '/${left.rootElement.name.local}',
      diffs,
    );
    return XmlDiffResult(leftPath: leftPath, rightPath: rightPath, diffs: diffs);
  }

  static void _compareNodes(
    XmlElement left,
    XmlElement right,
    String path,
    List<String> diffs,
  ) {
    if (diffs.length >= maxDiffs) return;

    if (left.name.local.toLowerCase() != right.name.local.toLowerCase()) {
      diffs.add('$path: Element <${left.name.local}> vs <${right.name.local}>');
      return;
    }

    _compareAttributes(left, right, path, diffs);

    final leftText = _directText(left);
    final rightText = _directText(right);
    if (leftText != rightText && left.childElements.isEmpty && right.childElements.isEmpty) {
      diffs.add('$path: "$leftText" vs "$rightText"');
    } else if (leftText != rightText &&
        left.childElements.isNotEmpty != right.childElements.isNotEmpty) {
      diffs.add('$path (Text): "$leftText" vs "$rightText"');
    } else if (leftText != rightText && left.childElements.isEmpty) {
      diffs.add('$path: "$leftText" vs "$rightText"');
    }

    _compareChildren(left, right, path, diffs);
  }

  /// Match siblings by element name (and occurrence), not by position.
  /// Inserting or removing a neighbour must not shift later fields.
  static void _compareChildren(
    XmlElement left,
    XmlElement right,
    String path,
    List<String> diffs,
  ) {
    final leftGroups = _groupByName(left.childElements);
    final rightGroups = _groupByName(right.childElements);
    final names = <String>[];
    for (final child in left.childElements) {
      final name = child.name.local.toLowerCase();
      if (!names.contains(name)) names.add(name);
    }
    for (final child in right.childElements) {
      final name = child.name.local.toLowerCase();
      if (!names.contains(name)) names.add(name);
    }

    for (final name in names) {
      if (diffs.length >= maxDiffs) return;
      final leftList = leftGroups[name] ?? const <XmlElement>[];
      final rightList = rightGroups[name] ?? const <XmlElement>[];
      final paired = leftList.length < rightList.length
          ? leftList.length
          : rightList.length;
      final numbered = leftList.length > 1 || rightList.length > 1;

      for (var i = 0; i < paired; i++) {
        if (diffs.length >= maxDiffs) return;
        final suffix = numbered ? '[${i + 1}]' : '';
        _compareNodes(
          leftList[i],
          rightList[i],
          '$path/${leftList[i].name.local}$suffix',
          diffs,
        );
      }
      for (var i = paired; i < leftList.length; i++) {
        if (diffs.length >= maxDiffs) return;
        final suffix = numbered ? '[${i + 1}]' : '';
        diffs.add('$path/${leftList[i].name.local}$suffix: nur im Input');
      }
      for (var i = paired; i < rightList.length; i++) {
        if (diffs.length >= maxDiffs) return;
        final suffix = numbered ? '[${i + 1}]' : '';
        diffs.add('$path/${rightList[i].name.local}$suffix: nur im Output');
      }
    }
  }

  static Map<String, List<XmlElement>> _groupByName(
    Iterable<XmlElement> children,
  ) {
    final groups = <String, List<XmlElement>>{};
    for (final child in children) {
      groups
          .putIfAbsent(child.name.local.toLowerCase(), () => <XmlElement>[])
          .add(child);
    }
    return groups;
  }

  static void _compareAttributes(
    XmlElement left,
    XmlElement right,
    String path,
    List<String> diffs,
  ) {
    final leftAttrs = {
      for (final a in left.attributes) a.name.local.toLowerCase(): a.value,
    };
    final rightAttrs = {
      for (final a in right.attributes) a.name.local.toLowerCase(): a.value,
    };

    final names = {...leftAttrs.keys, ...rightAttrs.keys};
    for (final name in names) {
      if (diffs.length >= maxDiffs) return;
      final lv = leftAttrs[name];
      final rv = rightAttrs[name];
      if (lv == null) {
        diffs.add('$path@$name: fehlt im Input, Output="$rv"');
      } else if (rv == null) {
        diffs.add('$path@$name: Input="$lv", fehlt im Output');
      } else if (lv != rv) {
        diffs.add('$path@$name: "$lv" vs "$rv"');
      }
    }
  }

  static String _directText(XmlElement element) {
    final buffer = StringBuffer();
    for (final node in element.children) {
      if (node is XmlText || node is XmlCDATA) {
        buffer.write(node.value);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
