/// Stub implementations for non-web platforms to satisfy conditional import as `html`.
/// These are not executed at runtime because the code paths are gated by `kIsWeb`.
library translation_download_html_stub;

class Blob {
  final List<dynamic> data;
  final String? type;
  Blob(this.data, [this.type]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    throw UnsupportedError('createObjectUrlFromBlob is only available on web (dart:html).');
  }

  static void revokeObjectUrl(String url) {
    // No-op on non-web platforms.
  }
}

class AnchorElement {
  String? href;
  String? download;
  AnchorElement({this.href});
  void click() {
    // No-op on non-web platforms.
  }
}
