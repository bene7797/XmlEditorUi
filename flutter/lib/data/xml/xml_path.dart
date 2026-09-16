import 'package:xml/xml.dart';

/// Path helpers mirroring C# XmlHelper (case-insensitive local names, path@type).
class XmlPath {
  XmlPath._();

  static XmlElement? getNodeByPath(XmlNode startNode, String path) {
    if (path.contains('@')) {
      final parts = path.split('@');
      final elementPath = parts[0].replaceAll(RegExp(r'/+$'), '');
      if (elementPath.isEmpty) {
        return startNode is XmlElement ? startNode : null;
      }
      return getNodeByPath(startNode, elementPath);
    }

    var current = startNode;
    for (final part in path.split('/').where((p) => p.isNotEmpty)) {
      if (current is! XmlElement && current is! XmlDocument) {
        return null;
      }
      final children = current is XmlDocument
          ? current.children.whereType<XmlElement>()
          : (current as XmlElement).childElements;
      final next = children.cast<XmlElement?>().firstWhere(
            (n) => n!.name.local.toLowerCase() == part.toLowerCase(),
            orElse: () => null,
          );
      if (next == null) return null;
      current = next;
    }
    return current is XmlElement ? current : null;
  }

  static String? getTextByPath(XmlNode startNode, String path) {
    if (path.contains('@')) {
      final parts = path.split('@');
      final elementPath = parts[0].replaceAll(RegExp(r'/+$'), '');
      final attributeName = parts[1];
      final element = elementPath.isEmpty
          ? (startNode is XmlElement ? startNode : null)
          : getNodeByPath(startNode, elementPath);
      if (element == null) return null;
      final attr = element.getAttribute(attributeName);
      return attr;
    }
    return getNodeByPath(startNode, path)?.innerText.trim();
  }

  static XmlElement setNodeByPath(XmlNode startNode, String path, String value) {
    if (path.contains('@')) {
      final parts = path.split('@');
      final elementPath = parts[0].replaceAll(RegExp(r'/+$'), '');
      final attributeName = parts[1];
      var current = startNode;

      if (elementPath.isNotEmpty) {
        for (final part in elementPath.split('/').where((p) => p.isNotEmpty)) {
          current = _ensureChild(current, part);
        }
      }

      if (current is! XmlElement) {
        throw StateError('XmlNode kann keine Attribute haben.');
      }
      current.setAttribute(attributeName, value);
      return current;
    }

    var current = startNode;
    for (final part in path.split('/').where((p) => p.isNotEmpty)) {
      current = _ensureChild(current, part);
    }

    final element = current as XmlElement;
    element.children
      ..clear()
      ..add(XmlText(value));
    return element;
  }

  static XmlElement? findChild(XmlNode node, String childName) {
    final children = node is XmlDocument
        ? node.children.whereType<XmlElement>()
        : (node as XmlElement).childElements;
    for (final n in children) {
      if (n.name.local.toLowerCase() == childName.toLowerCase()) return n;
    }
    return null;
  }

  static String? getChildText(XmlNode node, String childName) =>
      findChild(node, childName)?.innerText.trim();

  static XmlElement setChildText(XmlNode node, String childName, String value) {
    var child = findChild(node, childName);
    if (child == null) {
      child = XmlElement(XmlName(childName));
      if (node is XmlDocument) {
        node.children.add(child);
      } else {
        (node as XmlElement).children.add(child);
      }
    }
    child.children
      ..clear()
      ..add(XmlText(value));
    return child;
  }

  static void setAttribute(XmlElement node, String name, String value) {
    node.setAttribute(name, value);
  }

  static void removeAttribute(XmlElement node, String name) {
    node.removeAttribute(name);
  }

  static bool hasElementChildren(XmlElement node) =>
      node.childElements.isNotEmpty;

  static XmlElement _ensureChild(XmlNode parent, String part) {
    final existing = findChild(parent, part);
    if (existing != null) return existing;

    final created = XmlElement(XmlName(part));
    if (parent is XmlDocument) {
      parent.children.add(created);
    } else if (parent is XmlElement) {
      parent.children.add(created);
    } else {
      throw StateError('Ungültiger Parent-Knoten.');
    }
    return created;
  }

  static Iterable<XmlElement> descendantElements(XmlNode root) sync* {
    if (root is XmlElement) {
      yield root;
      for (final child in root.childElements) {
        yield* descendantElements(child);
      }
    } else if (root is XmlDocument) {
      for (final child in root.childElements) {
        yield* descendantElements(child);
      }
    }
  }

  static bool isInsideDelete(XmlNode node) {
    var parent = node.parent;
    while (parent != null) {
      if (parent is XmlElement &&
          parent.name.local.toLowerCase() == 'delete') {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  static bool isServiceNode(XmlNode node) {
    return node is XmlElement &&
        node.name.local.toLowerCase() == 'service' &&
        !isInsideDelete(node);
  }

  /// Deep-copies [source] into [targetDocument] (like ImportNode).
  static XmlElement importElement(
    XmlDocument targetDocument,
    XmlElement source,
  ) {
    return XmlDocument.parse(source.toXmlString()).rootElement.copy();
  }

  static void setRepeatingChildElements(
    XmlElement parent,
    String elementName,
    Iterable<String> values, {
    String? insertAfterLocalName,
    String? insertBeforeLocalName,
  }) {
    final existing = parent.childElements
        .where((n) => n.name.local.toLowerCase() == elementName.toLowerCase())
        .toList();
    for (final node in existing) {
      parent.children.remove(node);
    }

    XmlNode? insertAfter = insertAfterLocalName == null
        ? null
        : parent.childElements
            .where((n) =>
                n.name.local.toLowerCase() ==
                insertAfterLocalName.toLowerCase())
            .lastOrNull;

    final insertBefore = insertBeforeLocalName == null
        ? null
        : parent.childElements.cast<XmlElement?>().firstWhere(
              (n) =>
                  n!.name.local.toLowerCase() ==
                  insertBeforeLocalName.toLowerCase(),
              orElse: () => null,
            );

    for (final value in values) {
      if (value.trim().isEmpty) continue;
      final element = XmlElement(XmlName(elementName), [], [XmlText(value.trim())]);

      if (insertAfter != null) {
        final index = parent.children.indexOf(insertAfter);
        parent.children.insert(index + 1, element);
        insertAfter = element;
      } else if (insertBefore != null) {
        final index = parent.children.indexOf(insertBefore);
        parent.children.insert(index, element);
      } else {
        parent.children.add(element);
      }
    }
  }
}
