import 'package:moor/moor.dart';

export 'database/shared.dart';

// assuming that your file is called filename.dart. This will give an error at first,
// but it's needed for moor to know about the generated code
part 'chatdb.g.dart';

const String lastUpdateRoom = 'lastUpdateRoom';

const String lastUpdateRoomMessage = 'lastUpdateRoomMessage';
const String historyReadEnd = 'historyReadEnd';

class Rooms extends Table {
  TextColumn get rid => text()();
  TextColumn get sid => text().nullable()();
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

class RoomMessages extends Table {
  TextColumn get rid => text()();
  DateTimeColumn get ts => dateTime()();
  TextColumn get mid => text()();
  TextColumn get info => text()();

  @override
  Set<Column> get primaryKey => {mid};
}

// this annotation tells moor to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
@UseMoor(tables: [Rooms, Subscriptions, KeyValues, RoomMessages])
class ChatDatabase extends _$ChatDatabase {
  // we tell the database where to store the data with this constructor
  //ChatDatabase() : super(_openConnection());
  ChatDatabase(QueryExecutor e) : super(e);
  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        print('migration from=$from, to=$to');
        if (from == 1) {
          await m.alterTable(TableMigration(rooms));
        } else if (from == 8) {
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
            await m.createTable(table);
          }
        }
      }
  );

  Future<List<Room>> get getAllRooms => select(rooms).get();
  Future upsertRoom(Room room) => into(rooms).insertOnConflictUpdate(room);
  Future<Room> getRoom(String _rid) => (select(rooms)..where((t) => t.rid.equals(_rid))).getSingleOrNull();
  Future deleteRoom(String _rid) {
    deleteRoomMessage(_rid);
    deleteByKey(lastUpdateRoomMessage + _rid);
    deleteByKey(historyReadEnd + _rid);
    return (delete(rooms)..where((t) => t.rid.equals(_rid))).go();
  }

  Future<List<Subscription>> get getAllSubscriptions => select(subscriptions).get();
  Future upsertSubscription(Subscription subscription) => into(subscriptions).insertOnConflictUpdate(subscription);
  Future deleteSubscription(String _sid) => (delete(subscriptions)..where((t) => t.sid.equals(_sid))).go();
  Future<Subscription> getSubscription(String _sid) => (select(subscriptions)..where((t) => t.sid.equals(_sid))).getSingleOrNull();

  Future<KeyValue> getValueByKey(String key) => (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull();
  Future upsertKeyValue(KeyValue keyValue) => into(keyValues).insertOnConflictUpdate(keyValue);
  Future deleteByKey(String key) => (delete(keyValues)..where((t) => t.key.equals(key))).go();

  Future<List<RoomMessage>> getRoomMessages(String _rid, int limit, {int offset}) => (select(roomMessages)
    ..where((t) => t.rid.equals(_rid))
    ..limit(limit, offset: offset)
    ..orderBy([(t) => OrderingTerm(expression: t.ts, mode: OrderingMode.desc)])).get();
  Future upsertRoomMessage(RoomMessage roomMessage) => into(roomMessages).insertOnConflictUpdate(roomMessage);
  Future deleteRoomMessage(String _rid) => (delete(roomMessages)..where((t) => t.rid.equals(_rid))).go();
  Future<RoomMessage> getMessage(String _mid) => (select(roomMessages)..where((t) => t.mid.equals(_mid))).getSingleOrNull();
  Future deleteMessage(String _mid) => (delete(roomMessages)..where((t) => t.mid.equals(_mid))).go();

}