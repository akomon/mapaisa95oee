import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

Future<void> downloadJsonFile(String filename, String content) async {
  final bytes = utf8.encode(content);
  final data = bytes.jsify()!;
  final blob = Blob([data].toJS, BlobPropertyBag(type: 'application/json'));
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}

Future<String?> pickJsonFile() async {
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = 'application/json,.json';
  document.body!.append(input);

  try {
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.length == 0) {
      return null;
    }
    final file = files.item(0);
    if (file == null) {
      return null;
    }
    final jsString = await file.text().toDart;
    return jsString.toDart;
  } finally {
    input.remove();
  }
}
