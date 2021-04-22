import 'package:moor/moor.dart';

import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

// assuming that your file is called filename.dart. This will give an error at first,
// but it's needed for moor to know about the generated code
part 'chatdb.g.dart';

const String lastUpdate = 'lastUpdate';

class Rooms extends Table {
  TextColumn get rid => text()();
  TextColumn get sid => text()();
  TextColumn get info => text()();

  @override
  Set<Column> get primaryKey => {rid};
}

class Subscriptions extends Table {
  TextColumn get sid => text()();
  TextColumn get info => text()();

  @override
  Set<Column> get primaryKey => {sid};
}

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

// this annotation tells moor to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
@UseMoor(tables: [Rooms, Subscriptions, KeyValues])
class ChatDatabase extends _$ChatDatabase {
  // we tell the database where to store the data with this constructor
  ChatDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        print('migration from=$from, to=$to');
        if (from == 1) {
          await m.alterTable(TableMigration(rooms));
        } else if (from == 6) {
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
            await m.createTable(table);
          }
        }
      }
  );

  Future<List<Room>> get getAllRooms => select(rooms).get();
  Future upsertRoom(Room room) => into(rooms).insertOnConflictUpdate(room);
  Future deleteRoom(String _rid) => (delete(rooms)..where((t) => t.rid.equals(_rid))).go();
  Future<Room> getRoom(String _rid) => (select(rooms)..where((t) => t.rid.equals(_rid))).getSingleOrNull();

  Future<List<Subscription>> get getAllSubscriptions => select(subscriptions).get();
  Future upsertSubscription(Subscription subscription) => into(subscriptions).insertOnConflictUpdate(subscription);
  Future deleteSubscription(String _sid) => (delete(subscriptions)..where((t) => t.sid.equals(_sid))).go();
  Future<Subscription> getSubscription(String _sid) => (select(subscriptions)..where((t) => t.sid.equals(_sid))).getSingleOrNull();
  
  Future<KeyValue> getValueByKey(String key) {
    return (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull();
  }
  Future upsertKeyValue(KeyValue keyValue) => into(keyValues).insertOnConflictUpdate(keyValue);
}