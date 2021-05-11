// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatdb.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Room extends DataClass implements Insertable<Room> {
  final String rid;
  final String sid;
  final String info;
  Room({@required this.rid, this.sid, @required this.info});
  factory Room.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Room(
      rid: stringType.mapFromDatabaseResponse(data['${effectivePrefix}rid']),
      sid: stringType.mapFromDatabaseResponse(data['${effectivePrefix}sid']),
      info: stringType.mapFromDatabaseResponse(data['${effectivePrefix}info']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || rid != null) {
      map['rid'] = Variable<String>(rid);
    }
    if (!nullToAbsent || sid != null) {
      map['sid'] = Variable<String>(sid);
    }
    if (!nullToAbsent || info != null) {
      map['info'] = Variable<String>(info);
    }
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      rid: rid == null && nullToAbsent ? const Value.absent() : Value(rid),
      sid: sid == null && nullToAbsent ? const Value.absent() : Value(sid),
      info: info == null && nullToAbsent ? const Value.absent() : Value(info),
    );
  }

  factory Room.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Room(
      rid: serializer.fromJson<String>(json['rid']),
      sid: serializer.fromJson<String>(json['sid']),
      info: serializer.fromJson<String>(json['info']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rid': serializer.toJson<String>(rid),
      'sid': serializer.toJson<String>(sid),
      'info': serializer.toJson<String>(info),
    };
  }

  Room copyWith({String rid, String sid, String info}) => Room(
        rid: rid ?? this.rid,
        sid: sid ?? this.sid,
        info: info ?? this.info,
      );
  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('rid: $rid, ')
          ..write('sid: $sid, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(rid.hashCode, $mrjc(sid.hashCode, info.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Room &&
          other.rid == this.rid &&
          other.sid == this.sid &&
          other.info == this.info);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<String> rid;
  final Value<String> sid;
  final Value<String> info;
  const RoomsCompanion({
    this.rid = const Value.absent(),
    this.sid = const Value.absent(),
    this.info = const Value.absent(),
  });
  RoomsCompanion.insert({
    @required String rid,
    this.sid = const Value.absent(),
    @required String info,
  })  : rid = Value(rid),
        info = Value(info);
  static Insertable<Room> custom({
    Expression<String> rid,
    Expression<String> sid,
    Expression<String> info,
  }) {
    return RawValuesInsertable({
      if (rid != null) 'rid': rid,
      if (sid != null) 'sid': sid,
      if (info != null) 'info': info,
    });
  }

  RoomsCompanion copyWith(
      {Value<String> rid, Value<String> sid, Value<String> info}) {
    return RoomsCompanion(
      rid: rid ?? this.rid,
      sid: sid ?? this.sid,
      info: info ?? this.info,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rid.present) {
      map['rid'] = Variable<String>(rid.value);
    }
    if (sid.present) {
      map['sid'] = Variable<String>(sid.value);
    }
    if (info.present) {
      map['info'] = Variable<String>(info.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('rid: $rid, ')
          ..write('sid: $sid, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  final GeneratedDatabase _db;
  final String _alias;
  $RoomsTable(this._db, [this._alias]);
  final VerificationMeta _ridMeta = const VerificationMeta('rid');
  GeneratedTextColumn _rid;
  @override
  GeneratedTextColumn get rid => _rid ??= _constructRid();
  GeneratedTextColumn _constructRid() {
    return GeneratedTextColumn(
      'rid',
      $tableName,
      false,
    );
  }

  final VerificationMeta _sidMeta = const VerificationMeta('sid');
  GeneratedTextColumn _sid;
  @override
  GeneratedTextColumn get sid => _sid ??= _constructSid();
  GeneratedTextColumn _constructSid() {
    return GeneratedTextColumn(
      'sid',
      $tableName,
      true,
    );
  }

  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedTextColumn _info;
  @override
  GeneratedTextColumn get info => _info ??= _constructInfo();
  GeneratedTextColumn _constructInfo() {
    return GeneratedTextColumn(
      'info',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [rid, sid, info];
  @override
  $RoomsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'rooms';
  @override
  final String actualTableName = 'rooms';
  @override
  VerificationContext validateIntegrity(Insertable<Room> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rid')) {
      context.handle(
          _ridMeta, rid.isAcceptableOrUnknown(data['rid'], _ridMeta));
    } else if (isInserting) {
      context.missing(_ridMeta);
    }
    if (data.containsKey('sid')) {
      context.handle(
          _sidMeta, sid.isAcceptableOrUnknown(data['sid'], _sidMeta));
    }
    if (data.containsKey('info')) {
      context.handle(
          _infoMeta, info.isAcceptableOrUnknown(data['info'], _infoMeta));
    } else if (isInserting) {
      context.missing(_infoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rid};
  @override
  Room map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Room.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(_db, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String sid;
  final String info;
  Subscription({@required this.sid, @required this.info});
  factory Subscription.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return Subscription(
      sid: stringType.mapFromDatabaseResponse(data['${effectivePrefix}sid']),
      info: stringType.mapFromDatabaseResponse(data['${effectivePrefix}info']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || sid != null) {
      map['sid'] = Variable<String>(sid);
    }
    if (!nullToAbsent || info != null) {
      map['info'] = Variable<String>(info);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      sid: sid == null && nullToAbsent ? const Value.absent() : Value(sid),
      info: info == null && nullToAbsent ? const Value.absent() : Value(info),
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Subscription(
      sid: serializer.fromJson<String>(json['sid']),
      info: serializer.fromJson<String>(json['info']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sid': serializer.toJson<String>(sid),
      'info': serializer.toJson<String>(info),
    };
  }

  Subscription copyWith({String sid, String info}) => Subscription(
        sid: sid ?? this.sid,
        info: info ?? this.info,
      );
  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('sid: $sid, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(sid.hashCode, info.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.sid == this.sid &&
          other.info == this.info);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<String> sid;
  final Value<String> info;
  const SubscriptionsCompanion({
    this.sid = const Value.absent(),
    this.info = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    @required String sid,
    @required String info,
  })  : sid = Value(sid),
        info = Value(info);
  static Insertable<Subscription> custom({
    Expression<String> sid,
    Expression<String> info,
  }) {
    return RawValuesInsertable({
      if (sid != null) 'sid': sid,
      if (info != null) 'info': info,
    });
  }

  SubscriptionsCompanion copyWith({Value<String> sid, Value<String> info}) {
    return SubscriptionsCompanion(
      sid: sid ?? this.sid,
      info: info ?? this.info,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sid.present) {
      map['sid'] = Variable<String>(sid.value);
    }
    if (info.present) {
      map['info'] = Variable<String>(info.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('sid: $sid, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  final GeneratedDatabase _db;
  final String _alias;
  $SubscriptionsTable(this._db, [this._alias]);
  final VerificationMeta _sidMeta = const VerificationMeta('sid');
  GeneratedTextColumn _sid;
  @override
  GeneratedTextColumn get sid => _sid ??= _constructSid();
  GeneratedTextColumn _constructSid() {
    return GeneratedTextColumn(
      'sid',
      $tableName,
      false,
    );
  }

  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedTextColumn _info;
  @override
  GeneratedTextColumn get info => _info ??= _constructInfo();
  GeneratedTextColumn _constructInfo() {
    return GeneratedTextColumn(
      'info',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [sid, info];
  @override
  $SubscriptionsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'subscriptions';
  @override
  final String actualTableName = 'subscriptions';
  @override
  VerificationContext validateIntegrity(Insertable<Subscription> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sid')) {
      context.handle(
          _sidMeta, sid.isAcceptableOrUnknown(data['sid'], _sidMeta));
    } else if (isInserting) {
      context.missing(_sidMeta);
    }
    if (data.containsKey('info')) {
      context.handle(
          _infoMeta, info.isAcceptableOrUnknown(data['info'], _infoMeta));
    } else if (isInserting) {
      context.missing(_infoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sid};
  @override
  Subscription map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Subscription.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(_db, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  KeyValue({@required this.key, @required this.value});
  factory KeyValue.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return KeyValue(
      key: stringType.mapFromDatabaseResponse(data['${effectivePrefix}key']),
      value:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}value']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory KeyValue.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String key, String value}) => KeyValue(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(key.hashCode, value.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    @required String key,
    @required String value,
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String> key,
    Expression<String> value,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  KeyValuesCompanion copyWith({Value<String> key, Value<String> value}) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  final GeneratedDatabase _db;
  final String _alias;
  $KeyValuesTable(this._db, [this._alias]);
  final VerificationMeta _keyMeta = const VerificationMeta('key');
  GeneratedTextColumn _key;
  @override
  GeneratedTextColumn get key => _key ??= _constructKey();
  GeneratedTextColumn _constructKey() {
    return GeneratedTextColumn(
      'key',
      $tableName,
      false,
    );
  }

  final VerificationMeta _valueMeta = const VerificationMeta('value');
  GeneratedTextColumn _value;
  @override
  GeneratedTextColumn get value => _value ??= _constructValue();
  GeneratedTextColumn _constructValue() {
    return GeneratedTextColumn(
      'value',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  $KeyValuesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'key_values';
  @override
  final String actualTableName = 'key_values';
  @override
  VerificationContext validateIntegrity(Insertable<KeyValue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key'], _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value'], _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return KeyValue.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(_db, alias);
  }
}

class RoomMessage extends DataClass implements Insertable<RoomMessage> {
  final String rid;
  final DateTime ts;
  final String mid;
  final String info;
  RoomMessage(
      {@required this.rid,
      @required this.ts,
      @required this.mid,
      @required this.info});
  factory RoomMessage.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return RoomMessage(
      rid: stringType.mapFromDatabaseResponse(data['${effectivePrefix}rid']),
      ts: dateTimeType.mapFromDatabaseResponse(data['${effectivePrefix}ts']),
      mid: stringType.mapFromDatabaseResponse(data['${effectivePrefix}mid']),
      info: stringType.mapFromDatabaseResponse(data['${effectivePrefix}info']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || rid != null) {
      map['rid'] = Variable<String>(rid);
    }
    if (!nullToAbsent || ts != null) {
      map['ts'] = Variable<DateTime>(ts);
    }
    if (!nullToAbsent || mid != null) {
      map['mid'] = Variable<String>(mid);
    }
    if (!nullToAbsent || info != null) {
      map['info'] = Variable<String>(info);
    }
    return map;
  }

  RoomMessagesCompanion toCompanion(bool nullToAbsent) {
    return RoomMessagesCompanion(
      rid: rid == null && nullToAbsent ? const Value.absent() : Value(rid),
      ts: ts == null && nullToAbsent ? const Value.absent() : Value(ts),
      mid: mid == null && nullToAbsent ? const Value.absent() : Value(mid),
      info: info == null && nullToAbsent ? const Value.absent() : Value(info),
    );
  }

  factory RoomMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return RoomMessage(
      rid: serializer.fromJson<String>(json['rid']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      mid: serializer.fromJson<String>(json['mid']),
      info: serializer.fromJson<String>(json['info']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rid': serializer.toJson<String>(rid),
      'ts': serializer.toJson<DateTime>(ts),
      'mid': serializer.toJson<String>(mid),
      'info': serializer.toJson<String>(info),
    };
  }

  RoomMessage copyWith({String rid, DateTime ts, String mid, String info}) =>
      RoomMessage(
        rid: rid ?? this.rid,
        ts: ts ?? this.ts,
        mid: mid ?? this.mid,
        info: info ?? this.info,
      );
  @override
  String toString() {
    return (StringBuffer('RoomMessage(')
          ..write('rid: $rid, ')
          ..write('ts: $ts, ')
          ..write('mid: $mid, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      rid.hashCode, $mrjc(ts.hashCode, $mrjc(mid.hashCode, info.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is RoomMessage &&
          other.rid == this.rid &&
          other.ts == this.ts &&
          other.mid == this.mid &&
          other.info == this.info);
}

class RoomMessagesCompanion extends UpdateCompanion<RoomMessage> {
  final Value<String> rid;
  final Value<DateTime> ts;
  final Value<String> mid;
  final Value<String> info;
  const RoomMessagesCompanion({
    this.rid = const Value.absent(),
    this.ts = const Value.absent(),
    this.mid = const Value.absent(),
    this.info = const Value.absent(),
  });
  RoomMessagesCompanion.insert({
    @required String rid,
    @required DateTime ts,
    @required String mid,
    @required String info,
  })  : rid = Value(rid),
        ts = Value(ts),
        mid = Value(mid),
        info = Value(info);
  static Insertable<RoomMessage> custom({
    Expression<String> rid,
    Expression<DateTime> ts,
    Expression<String> mid,
    Expression<String> info,
  }) {
    return RawValuesInsertable({
      if (rid != null) 'rid': rid,
      if (ts != null) 'ts': ts,
      if (mid != null) 'mid': mid,
      if (info != null) 'info': info,
    });
  }

  RoomMessagesCompanion copyWith(
      {Value<String> rid,
      Value<DateTime> ts,
      Value<String> mid,
      Value<String> info}) {
    return RoomMessagesCompanion(
      rid: rid ?? this.rid,
      ts: ts ?? this.ts,
      mid: mid ?? this.mid,
      info: info ?? this.info,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rid.present) {
      map['rid'] = Variable<String>(rid.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (mid.present) {
      map['mid'] = Variable<String>(mid.value);
    }
    if (info.present) {
      map['info'] = Variable<String>(info.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomMessagesCompanion(')
          ..write('rid: $rid, ')
          ..write('ts: $ts, ')
          ..write('mid: $mid, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }
}

class $RoomMessagesTable extends RoomMessages
    with TableInfo<$RoomMessagesTable, RoomMessage> {
  final GeneratedDatabase _db;
  final String _alias;
  $RoomMessagesTable(this._db, [this._alias]);
  final VerificationMeta _ridMeta = const VerificationMeta('rid');
  GeneratedTextColumn _rid;
  @override
  GeneratedTextColumn get rid => _rid ??= _constructRid();
  GeneratedTextColumn _constructRid() {
    return GeneratedTextColumn(
      'rid',
      $tableName,
      false,
    );
  }

  final VerificationMeta _tsMeta = const VerificationMeta('ts');
  GeneratedDateTimeColumn _ts;
  @override
  GeneratedDateTimeColumn get ts => _ts ??= _constructTs();
  GeneratedDateTimeColumn _constructTs() {
    return GeneratedDateTimeColumn(
      'ts',
      $tableName,
      false,
    );
  }

  final VerificationMeta _midMeta = const VerificationMeta('mid');
  GeneratedTextColumn _mid;
  @override
  GeneratedTextColumn get mid => _mid ??= _constructMid();
  GeneratedTextColumn _constructMid() {
    return GeneratedTextColumn(
      'mid',
      $tableName,
      false,
    );
  }

  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedTextColumn _info;
  @override
  GeneratedTextColumn get info => _info ??= _constructInfo();
  GeneratedTextColumn _constructInfo() {
    return GeneratedTextColumn(
      'info',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [rid, ts, mid, info];
  @override
  $RoomMessagesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'room_messages';
  @override
  final String actualTableName = 'room_messages';
  @override
  VerificationContext validateIntegrity(Insertable<RoomMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rid')) {
      context.handle(
          _ridMeta, rid.isAcceptableOrUnknown(data['rid'], _ridMeta));
    } else if (isInserting) {
      context.missing(_ridMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts'], _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('mid')) {
      context.handle(
          _midMeta, mid.isAcceptableOrUnknown(data['mid'], _midMeta));
    } else if (isInserting) {
      context.missing(_midMeta);
    }
    if (data.containsKey('info')) {
      context.handle(
          _infoMeta, info.isAcceptableOrUnknown(data['info'], _infoMeta));
    } else if (isInserting) {
      context.missing(_infoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mid};
  @override
  RoomMessage map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return RoomMessage.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $RoomMessagesTable createAlias(String alias) {
    return $RoomMessagesTable(_db, alias);
  }
}

class ChatUser extends DataClass implements Insertable<ChatUser> {
  final String uid;
  final String uname;
  ChatUser({@required this.uid, @required this.uname});
  factory ChatUser.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return ChatUser(
      uid: stringType.mapFromDatabaseResponse(data['${effectivePrefix}uid']),
      uname:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}uname']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<String>(uid);
    }
    if (!nullToAbsent || uname != null) {
      map['uname'] = Variable<String>(uname);
    }
    return map;
  }

  ChatUsersCompanion toCompanion(bool nullToAbsent) {
    return ChatUsersCompanion(
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
      uname:
          uname == null && nullToAbsent ? const Value.absent() : Value(uname),
    );
  }

  factory ChatUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return ChatUser(
      uid: serializer.fromJson<String>(json['uid']),
      uname: serializer.fromJson<String>(json['uname']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'uname': serializer.toJson<String>(uname),
    };
  }

  ChatUser copyWith({String uid, String uname}) => ChatUser(
        uid: uid ?? this.uid,
        uname: uname ?? this.uname,
      );
  @override
  String toString() {
    return (StringBuffer('ChatUser(')
          ..write('uid: $uid, ')
          ..write('uname: $uname')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(uid.hashCode, uname.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is ChatUser && other.uid == this.uid && other.uname == this.uname);
}

class ChatUsersCompanion extends UpdateCompanion<ChatUser> {
  final Value<String> uid;
  final Value<String> uname;
  const ChatUsersCompanion({
    this.uid = const Value.absent(),
    this.uname = const Value.absent(),
  });
  ChatUsersCompanion.insert({
    @required String uid,
    @required String uname,
  })  : uid = Value(uid),
        uname = Value(uname);
  static Insertable<ChatUser> custom({
    Expression<String> uid,
    Expression<String> uname,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (uname != null) 'uname': uname,
    });
  }

  ChatUsersCompanion copyWith({Value<String> uid, Value<String> uname}) {
    return ChatUsersCompanion(
      uid: uid ?? this.uid,
      uname: uname ?? this.uname,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (uname.present) {
      map['uname'] = Variable<String>(uname.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatUsersCompanion(')
          ..write('uid: $uid, ')
          ..write('uname: $uname')
          ..write(')'))
        .toString();
  }
}

class $ChatUsersTable extends ChatUsers
    with TableInfo<$ChatUsersTable, ChatUser> {
  final GeneratedDatabase _db;
  final String _alias;
  $ChatUsersTable(this._db, [this._alias]);
  final VerificationMeta _uidMeta = const VerificationMeta('uid');
  GeneratedTextColumn _uid;
  @override
  GeneratedTextColumn get uid => _uid ??= _constructUid();
  GeneratedTextColumn _constructUid() {
    return GeneratedTextColumn(
      'uid',
      $tableName,
      false,
    );
  }

  final VerificationMeta _unameMeta = const VerificationMeta('uname');
  GeneratedTextColumn _uname;
  @override
  GeneratedTextColumn get uname => _uname ??= _constructUname();
  GeneratedTextColumn _constructUname() {
    return GeneratedTextColumn(
      'uname',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [uid, uname];
  @override
  $ChatUsersTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'chat_users';
  @override
  final String actualTableName = 'chat_users';
  @override
  VerificationContext validateIntegrity(Insertable<ChatUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid'], _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('uname')) {
      context.handle(
          _unameMeta, uname.isAcceptableOrUnknown(data['uname'], _unameMeta));
    } else if (isInserting) {
      context.missing(_unameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  ChatUser map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return ChatUser.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $ChatUsersTable createAlias(String alias) {
    return $ChatUsersTable(_db, alias);
  }
}

abstract class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  $RoomsTable _rooms;
  $RoomsTable get rooms => _rooms ??= $RoomsTable(this);
  $SubscriptionsTable _subscriptions;
  $SubscriptionsTable get subscriptions =>
      _subscriptions ??= $SubscriptionsTable(this);
  $KeyValuesTable _keyValues;
  $KeyValuesTable get keyValues => _keyValues ??= $KeyValuesTable(this);
  $RoomMessagesTable _roomMessages;
  $RoomMessagesTable get roomMessages =>
      _roomMessages ??= $RoomMessagesTable(this);
  $ChatUsersTable _chatUsers;
  $ChatUsersTable get chatUsers => _chatUsers ??= $ChatUsersTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rooms, subscriptions, keyValues, roomMessages, chatUsers];
}
