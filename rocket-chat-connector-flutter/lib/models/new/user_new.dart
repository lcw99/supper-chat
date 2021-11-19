import 'dart:convert';

class UserNew {
  String? username;
  String? email;
  String? pass;
  String? name;

  UserNew({
    this.username,
    this.email,
    this.pass,
    this.name,
  });

  UserNew.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      name = json['name'];
      email = json['email'];
      pass = json['pass'];
      username = json['username'];
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};

    if (name != null) {
      map['name'] = name;
    }
    if (email != null) {
      map['email'] = email;
    }
    if (pass != null) {
      map['pass'] = pass;
    }
    if (username != null) {
      map['username'] = username;
    }

    return map;
  }

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserNew &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          pass == other.pass &&
          username == other.username;

  @override
  int get hashCode =>
      name.hashCode ^ email.hashCode ^ pass.hashCode ^ username.hashCode;
}
