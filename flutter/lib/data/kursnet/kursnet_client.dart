import 'dart:convert';
import 'dart:io';

class KursnetClient {
  KursnetClient({
    this.endpoint =
        'https://www.kursnet-online.arbeitsagentur.de/onlinekurs/ws-kursnet/UploadOpenq',
  });

  final String endpoint;

  /// [action] 1 = prüfen, 2 = prüfen und speichern.
  Future<String> upload({
    required List<int> xmlBytes,
    required String user,
    required String password,
    required int action,
  }) async {
    final envelope = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://ws.apache.org/axis2/xsd">
  <soapenv:Header/>
  <soapenv:Body>
    <xsd:upload>
      <xsd:openqData>${base64.encode(xmlBytes)}</xsd:openqData>
      <xsd:userLogin>${_xmlEscape(user)}</xsd:userLogin>
      <xsd:userPassword>${_xmlEscape(password)}</xsd:userPassword>
      <xsd:action>$action</xsd:action>
    </xsd:upload>
  </soapenv:Body>
</soapenv:Envelope>''';

    return _postSoap(soapAction: 'urn:upload', body: envelope);
  }

  Future<String> testAccess() {
    const envelope = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Header/>
  <soapenv:Body>
    <testAccess xmlns="http://ws.apache.org/axis2/xsd"/>
  </soapenv:Body>
</soapenv:Envelope>''';
    return _postSoap(soapAction: 'urn:testAccess', body: envelope);
  }

  Future<String> _postSoap({
    required String soapAction,
    required String body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType =
          ContentType('text', 'xml', charset: 'utf-8');
      request.headers.set('SOAPAction', soapAction);
      request.add(utf8.encode(body));
      final response = await request.close().timeout(const Duration(seconds: 90));
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('KURSNET HTTP ${response.statusCode}: $text');
      }
      return _extractReturn(text) ?? text;
    } finally {
      client.close(force: true);
    }
  }

  static String? _extractReturn(String soap) {
    final match = RegExp(
      r'<return[^>]*>([\s\S]*?)</return>',
      caseSensitive: false,
    ).firstMatch(soap);
    if (match == null) return null;
    return _xmlUnescape(match.group(1) ?? '').trim();
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static String _xmlUnescape(String value) => value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
