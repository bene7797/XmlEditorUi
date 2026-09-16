enum ServiceState {
  unchanged,
  neu,
  updated,
}

class DeletedServiceInfo {
  DeletedServiceInfo(this.productId, this.title);

  final String productId;
  final String title;
}

class QuickFieldDefinition {
  const QuickFieldDefinition(this.label, this.path);

  final String label;
  final String path;
}

class TemplateFieldDefinition {
  const TemplateFieldDefinition(this.label, this.path);

  final String label;
  final String path;
}

class LocationProfile {
  LocationProfile({required this.name, Map<String, String>? values})
      : values = values ?? {};

  String name;
  Map<String, String> values;
}

class CourseTypeProfile {
  CourseTypeProfile({
    required this.name,
    Map<String, String>? values,
    Map<String, String>? attributes,
  })  : values = values ?? {},
        attributes = attributes ?? {};

  String name;
  Map<String, String> values;
  Map<String, String> attributes;
}
