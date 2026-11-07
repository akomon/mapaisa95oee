/// IO per a tests (VM): sense fitxers del navegador.
Future<void> downloadJsonFile(String filename, String content) async {
  lastDownloadedFilename = filename;
  lastDownloadedContent = content;
}

Future<String?> pickJsonFile() async => null;

String? lastDownloadedFilename;
String? lastDownloadedContent;
