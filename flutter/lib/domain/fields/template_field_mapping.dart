class TemplateFieldMapping {
  static const Map<String, String> locationFieldPaths = {
    'NAME':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME',
    'NAME2':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME2',
    'STREET':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STREET',
    'ZIP':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIP',
    'ZIPBOX':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIPBOX',
    'CITY':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
    'STATE':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STATE',
    'COUNTRY':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/COUNTRY',
    'PHONE':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/PHONE',
    'MOBILE':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/MOBILE',
    'EMAIL':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/EMAILS/EMAIL',
    'URL':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/URL',
    'ADDRESS_REMARKS':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS',
    'FAX':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/FAX',
    'BARRIER_FREE_LOCATION':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/BARRIER_FREE_LOCATION',
  };

  static const Map<String, String> courseTypeFieldPaths = {
    'COURSE_TYPE': 'COURSE_TYPE',
    'INSTRUCTION_TIME':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME',
    'DURATION':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION',
    'INSTRUCTION_REMARKS':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS',
    'EDUCATION_TYPE':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE',
    'INSTRUCTION_FORM':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_FORM',
    'FLEXIBLE_START':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/FLEXIBLE_START',
    'MIN_PARTICIPANTS':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/MIN_PARTICIPANTS',
    'MAX_PARTICIPANTS':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/MAX_PARTICIPANTS',
  };

  static const Map<String, String> courseTypeFieldAttributes = {
    'INSTRUCTION_TIME@type':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type',
    'DURATION@type':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type',
    'EDUCATION_TYPE@type':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE@type',
    'INSTRUCTION_FORM@type':
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_FORM@type',
  };

  static const locationRoot =
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION';
  static const extendedInfoRoot =
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO';
  static const moduleCourseRoot =
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE';

  static String? pathForLocationKey(String key) {
    for (final entry in locationFieldPaths.entries) {
      if (_canonicalKey(entry.key) == _canonicalKey(key)) return entry.value;
    }
    return '$locationRoot/${_xmlName(key)}';
  }

  static String? pathForCourseTypeKey(String key) {
    for (final entry in courseTypeFieldPaths.entries) {
      if (_canonicalKey(entry.key) == _canonicalKey(key)) return entry.value;
    }
    final name = _xmlName(key);
    if (name == 'COURSE_TYPE') return 'COURSE_TYPE';
    if (name == 'DURATION' ||
        name == 'INSTRUCTION_REMARKS' ||
        name == 'FLEXIBLE_START' ||
        name.contains('PARTICIPANT')) {
      return '$moduleCourseRoot/$name';
    }
    return '$extendedInfoRoot/$name';
  }

  static String _xmlName(String key) =>
      key.trim().replaceAll(' ', '_').toUpperCase();

  /// German UI labels and spelling variants that may appear in profiles.
  static const Map<String, String> fieldKeyAliases = {
    'ADRESS BEMERKUNGEN': 'ADDRESS_REMARKS',
    'ADRESSBEMERKUNGEN': 'ADDRESS_REMARKS',
    'ADRESSBEMERKUNG': 'ADDRESS_REMARKS',
    'ADDRESS_REMARK': 'ADDRESS_REMARKS',
    'STRASSE': 'STREET',
    'STRAßE': 'STREET',
    'STADT': 'CITY',
    'BUNDESLAND': 'STATE',
    'TELEFON': 'PHONE',
    'HANDY': 'MOBILE',
    'MOBIL': 'MOBILE',
    'PLZ POSTFACH': 'ZIPBOX',
    'PLZ_POSTFACH': 'ZIPBOX',
    'LAND': 'COUNTRY',
    'E-MAIL': 'EMAIL',
    'MAIL': 'EMAIL',
    'BESCHÄFTIGUNGSART': 'INSTRUCTION_TIME',
    'BESCHAEFTIGUNGSART': 'INSTRUCTION_TIME',
    'UNTERRICHTSZEIT': 'INSTRUCTION_TIME',
    'DAUER': 'DURATION',
    'UNTERRICHTS BEMERKUNGEN': 'INSTRUCTION_REMARKS',
    'UNTERRICHTSBEMERKUNGEN': 'INSTRUCTION_REMARKS',
    'BILDUNGSART': 'EDUCATION_TYPE',
  };

  static String? lookupValue(Map<String, String> values, String canonicalKey) {
    final wanted = _compactKey(canonicalKey);
    for (final entry in values.entries) {
      if (_canonicalKey(entry.key) == wanted) return entry.value;
    }
    return null;
  }

  static String _canonicalKey(String raw) {
    final upper = raw.trim().toUpperCase();
    return _compactKey(fieldKeyAliases[upper] ?? upper);
  }

  static String _compactKey(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[\s_]+'), '');
}
