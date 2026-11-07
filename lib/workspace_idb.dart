import 'package:idb_shim/idb_client.dart';

import 'workspace_database.dart';

class IdbWorkspaceDatabase implements WorkspaceDatabase {
  IdbWorkspaceDatabase(this.factory, {this.name = workspaceDatabaseName});

  final IdbFactory factory;
  final String name;
  Database? _database;

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final opened = await factory.open(
      name,
      version: workspaceDatabaseVersion,
      onUpgradeNeeded: (event) {
        if (event.oldVersion < 1) {
          event.database.createObjectStore(workspaceStoreName);
        }
      },
    );
    _database = opened;
    return opened;
  }

  @override
  Future<String?> read(String key) async {
    final database = await _open();
    final transaction = database.transaction(
      workspaceStoreName,
      idbModeReadOnly,
    );
    final value = await transaction
        .objectStore(workspaceStoreName)
        .getObject(key);
    await transaction.completed;
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw StateError('Valor inesperat a IndexedDB.');
  }

  @override
  Future<void> write(Map<String, String> entries) async {
    final database = await _open();
    final transaction = database.transaction(
      workspaceStoreName,
      idbModeReadWrite,
    );
    final store = transaction.objectStore(workspaceStoreName);
    for (final entry in entries.entries) {
      await store.put(entry.value, entry.key);
    }
    await transaction.completed;
  }
}
