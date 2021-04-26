class MessageUser {
  MessageUser({
    this.id,
    this.username,
    this.name,
  });

  String? id;
  String? username;
  String? name;

  factory MessageUser.fromMap(Map<String, dynamic> json) => MessageUser(
    id: json["_id"] == null ? null : json["_id"],
    username: json["username"] == null ? null : json["username"],
    name: json["name"] == null ? null : json["name"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "username": username == null ? null : username,
    "name": name == null ? null : name,
  };
}
