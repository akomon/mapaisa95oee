import 'workspace_database.dart';

class MemoryWorkspaceDatabase implements WorkspaceDatabase {
  final Map<String, String> values = {};

  int failWrites = 0;

  Object? errorToThrow;

  Future<void> Function()? beforeWrite;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(Map<String, String> entries) async {
    final hook = beforeWrite;
    if (hook != null) {
      await hook();
    }
    if (failWrites > 0) {
      failWrites -= 1;
      throw errorToThrow ?? StateError('write failed');
    }
    values.addAll(entries);
  }
}
