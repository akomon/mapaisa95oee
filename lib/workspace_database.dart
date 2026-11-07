const String workspaceDatabaseName = 'mapaisa95oee';

const int workspaceDatabaseVersion = 1;

const String workspaceStoreName = 'kv';

const String workspaceDocumentKey = 'workspace';

const String migrationStateKey = 'migrationState';

const String priorBackupKey = 'priorBackup';

/// Magatzem clau-valor. Una crida a [write] és una sola transacció.
abstract class WorkspaceDatabase {
  Future<String?> read(String key);

  Future<void> write(Map<String, String> entries);
}
