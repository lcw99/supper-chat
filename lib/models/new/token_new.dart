class TokenNew {
  String? id;
  String? type;
  String? value;
  String? appName;

  TokenNew({
    this.id,
    this.type,
    this.value,
    this.appName,
  });

  TokenNew.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      id = json['id'];
      type = json['type'];
      value = json['value'];
      appName = json['appName'];
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};

    if (id != null) {
      map['id'] = id;
    }
    if (type != null) {
      map['type'] = type;
    }
    if (value != null) {
      map['value'] = value;
    }
    if (appName != null) {
      map['appName'] = appName;
    }

    return map;
  }

  @override
  String toString() {
    return 'UserNew{id: $id, type: $type, value: $value, appName: $appName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TokenNew &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              type == other.type &&
              value == other.value &&
              appName == other.appName;

  @override
  int get hashCode =>
      id.hashCode ^ type.hashCode ^ value.hashCode ^ appName.hashCode;
}
