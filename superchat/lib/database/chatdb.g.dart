// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatdb.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Room extends DataClass implements Insertable<Room> {
  final String rid;
  final String sid;
  final String info;
  Room({@required this.rid, this.sid, @required this.info});
  factory Room.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    return Room(
      rid: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}rid']),
      sid: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}sid']),
      info: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}info']),
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
  int get hashCode => Object.hash(rid, sid, info);
  @override
  bool operator ==(Object other) =>
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
  @override
  final GeneratedDatabase attachedDatabase;
  final String _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _ridMeta = const VerificationMeta('rid');
  GeneratedColumn<String> _rid;
  @override
  GeneratedColumn<String> get rid =>
      _rid ??= GeneratedColumn<String>('rid', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _sidMeta = const VerificationMeta('sid');
  GeneratedColumn<String> _sid;
  @override
  GeneratedColumn<String> get sid =>
      _sid ??= GeneratedColumn<String>('sid', aliasedName, true,
          type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedColumn<String> _info;
  @override
  GeneratedColumn<String> get info =>
      _info ??= GeneratedColumn<String>('info', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [rid, sid, info];
  @override
  String get aliasedName => _alias ?? 'rooms';
  @override
  String get actualTableName => 'rooms';
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
    return Room.fromData(data, attachedDatabase,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String sid;
  final String info;
  Subscription({@required this.sid, @required this.info});
  factory Subscription.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    return Subscription(
      sid: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}sid']),
      info: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}info']),
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
  int get hashCode => Object.hash(sid, info);
  @override
  bool operator ==(Object other) =>
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
  @override
  final GeneratedDatabase attachedDatabase;
  final String _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _sidMeta = const VerificationMeta('sid');
  GeneratedColumn<String> _sid;
  @override
  GeneratedColumn<String> get sid =>
      _sid ??= GeneratedColumn<String>('sid', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedColumn<String> _info;
  @override
  GeneratedColumn<String> get info =>
      _info ??= GeneratedColumn<String>('info', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [sid, info];
  @override
  String get aliasedName => _alias ?? 'subscriptions';
  @override
  String get actualTableName => 'subscriptions';
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
    return Subscription.fromData(data, attachedDatabase,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  KeyValue({@required this.key, @required this.value});
  factory KeyValue.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    return KeyValue(
      key: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}key']),
      value: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}value']),
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
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
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
  @override
  final GeneratedDatabase attachedDatabase;
  final String _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _keyMeta = const VerificationMeta('key');
  GeneratedColumn<String> _key;
  @override
  GeneratedColumn<String> get key =>
      _key ??= GeneratedColumn<String>('key', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _valueMeta = const VerificationMeta('value');
  GeneratedColumn<String> _value;
  @override
  GeneratedColumn<String> get value =>
      _value ??= GeneratedColumn<String>('value', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? 'key_values';
  @override
  String get actualTableName => 'key_values';
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
    return KeyValue.fromData(data, attachedDatabase,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
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
    return RoomMessage(
      rid: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}rid']),
      ts: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}ts']),
      mid: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}mid']),
      info: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}info']),
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
  int get hashCode => Object.hash(rid, ts, mid, info);
  @override
  bool operator ==(Object other) =>
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
  @override
  final GeneratedDatabase attachedDatabase;
  final String _alias;
  $RoomMessagesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _ridMeta = const VerificationMeta('rid');
  GeneratedColumn<String> _rid;
  @override
  GeneratedColumn<String> get rid =>
      _rid ??= GeneratedColumn<String>('rid', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _tsMeta = const VerificationMeta('ts');
  GeneratedColumn<DateTime> _ts;
  @override
  GeneratedColumn<DateTime> get ts =>
      _ts ??= GeneratedColumn<DateTime>('ts', aliasedName, false,
          type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _midMeta = const VerificationMeta('mid');
  GeneratedColumn<String> _mid;
  @override
  GeneratedColumn<String> get mid =>
      _mid ??= GeneratedColumn<String>('mid', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedColumn<String> _info;
  @override
  GeneratedColumn<String> get info =>
      _info ??= GeneratedColumn<String>('info', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [rid, ts, mid, info];
  @override
  String get aliasedName => _alias ?? 'room_messages';
  @override
  String get actualTableName => 'room_messages';
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
    return RoomMessage.fromData(data, attachedDatabase,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $RoomMessagesTable createAlias(String alias) {
    return $RoomMessagesTable(attachedDatabase, alias);
  }
}

class CustomEmoji extends DataClass implements Insertable<CustomEmoji> {
  final String id;
  final String info;
  CustomEmoji({@required this.id, @required this.info});
  factory CustomEmoji.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    return CustomEmoji(
      id: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id']),
      info: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}info']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    if (!nullToAbsent || info != null) {
      map['info'] = Variable<String>(info);
    }
    return map;
  }

  CustomEmojisCompanion toCompanion(bool nullToAbsent) {
    return CustomEmojisCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      info: info == null && nullToAbsent ? const Value.absent() : Value(info),
    );
  }

  factory CustomEmoji.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return CustomEmoji(
      id: serializer.fromJson<String>(json['id']),
      info: serializer.fromJson<String>(json['info']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'info': serializer.toJson<String>(info),
    };
  }

  CustomEmoji copyWith({String id, String info}) => CustomEmoji(
        id: id ?? this.id,
        info: info ?? this.info,
      );
  @override
  String toString() {
    return (StringBuffer('CustomEmoji(')
          ..write('id: $id, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, info);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomEmoji && other.id == this.id && other.info == this.info);
}

class CustomEmojisCompanion extends UpdateCompanion<CustomEmoji> {
  final Value<String> id;
  final Value<String> info;
  const CustomEmojisCompanion({
    this.id = const Value.absent(),
    this.info = const Value.absent(),
  });
  CustomEmojisCompanion.insert({
    @required String id,
    @required String info,
  })  : id = Value(id),
        info = Value(info);
  static Insertable<CustomEmoji> custom({
    Expression<String> id,
    Expression<String> info,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (info != null) 'info': info,
    });
  }

  CustomEmojisCompanion copyWith({Value<String> id, Value<String> info}) {
    return CustomEmojisCompanion(
      id: id ?? this.id,
      info: info ?? this.info,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (info.present) {
      map['info'] = Variable<String>(info.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomEmojisCompanion(')
          ..write('id: $id, ')
          ..write('info: $info')
          ..write(')'))
        .toString();
  }
}

class $CustomEmojisTable extends CustomEmojis
    with TableInfo<$CustomEmojisTable, CustomEmoji> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String _alias;
  $CustomEmojisTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedColumn<String> _id;
  @override
  GeneratedColumn<String> get id =>
      _id ??= GeneratedColumn<String>('id', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _infoMeta = const VerificationMeta('info');
  GeneratedColumn<String> _info;
  @override
  GeneratedColumn<String> get info =>
      _info ??= GeneratedColumn<String>('info', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, info];
  @override
  String get aliasedName => _alias ?? 'custom_emojis';
  @override
  String get actualTableName => 'custom_emojis';
  @override
  VerificationContext validateIntegrity(Insertable<CustomEmoji> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id'], _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomEmoji map(Map<String, dynamic> data, {String tablePrefix}) {
    return CustomEmoji.fromData(data, attachedDatabase,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $CustomEmojisTable createAlias(String alias) {
    return $CustomEmojisTable(attachedDatabase, alias);
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
  $CustomEmojisTable _customEmojis;
  $CustomEmojisTable get customEmojis =>
      _customEmojis ??= $CustomEmojisTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rooms, subscriptions, keyValues, roomMessages, customEmojis];
}
