import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/response/find_or_create_invite.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:universal_io/io.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
class UserService {
  HttpService _httpService;

  UserService(this._httpService);

  Future<String> setAvatar(String avatarUrl, Authentication authentication) async {
    Map<String, dynamic> body = {'avatarUrl': avatarUrl};
    http.Response response = await _httpService.post(
      '/api/v1/users.setAvatar',
      jsonEncode(body),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp avatar=" + response.body);
        return response.body;
      } else {
        return "empty";
      }
    }
    throw RocketChatException(response.body);
  }

  Future<Room> useInviteToken(String token, Authentication authentication) async {
    Map<String, dynamic> body = {'token': token};
    http.Response response = await _httpService.post(
      '/api/v1/useInviteToken',
      jsonEncode(body),
      authentication,
    );

    print("resp useInviteToken=" + response.body);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Room.fromMap(jsonDecode(response.body)['room']);
      }
    }
    return Room();
  }

  Future<Room> channelsInvite(String roomId, String userId, Authentication authentication) async {
    Map<String, dynamic> body = {'roomId': roomId, 'userId': userId};
    http.Response response = await _httpService.post(
      '/api/v1/channels.invite',
      jsonEncode(body),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp channelsInvite=" + response.body);
        return Room.fromMap(jsonDecode(response.body)['channel']);
      }
    }
    return Room();
  }

  Future<User> usersUpdate(String userId, Authentication authentication,
    { String? email, String? name, String? password, String? username, bool? active, List<String>? roles,
      bool? joinDefaultChannels, bool? requirePasswordChange, bool? sendWelcomeEmail, bool? verified, Map<String, String>? customFields }) async {
    Map<String, dynamic> payload = {'userId': userId};
    Map<String, dynamic> data = Map<String, dynamic>();
    if (email != null) data['email'] = email;
    if (name != null) data['name'] = name;
    if (password != null) data['password'] = password;
    if (username != null) data['username'] = username;
    if (active != null) data['active'] = active;
    if (roles != null) data['roles'] = roles;
    if (joinDefaultChannels != null) data['joinDefaultChannels'] = joinDefaultChannels;
    if (requirePasswordChange != null) data['requirePasswordChange'] = requirePasswordChange;
    if (sendWelcomeEmail != null) data['sendWelcomeEmail'] = sendWelcomeEmail;
    if (verified != null) data['verified'] = verified;
    if (customFields != null) data['customFields'] = customFields;

    payload['data'] = data;
    http.Response response = await _httpService.post(
      '/api/v1/users.update',
      jsonEncode(payload),
      authentication,
    );

    var respBody = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp usersUpdate=" + respBody);
        return User.fromMap(jsonDecode(respBody)['user']);
      }
    }
    print('usersUpdate error = $respBody');
    return User(success: false, );
  }

  Future<User> updateOwnBasicInfo(Authentication authentication,
      { String? email, String? name, String? currentPassword, String? newPassword, String? username, Map<String, String>? customFields }) async {
    Map<String, dynamic> payload = Map();
    Map<String, dynamic> data = Map();
    if (email != null) data['email'] = email;
    if (name != null) data['name'] = name;
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (newPassword != null) data['newPassword'] = newPassword;
    if (username != null) data['username'] = username;
    payload['data'] = data;
    if (customFields != null) payload['customFields'] = customFields; else payload['customFields'] = Map();

    if (data.isEmpty && customFields!.isEmpty) {
      print('updateOwnBasicInfo nothing to update');
      return User(success: false);
    }
    http.Response response = await _httpService.post(
      '/api/v1/users.updateOwnBasicInfo',
      jsonEncode(payload),
      authentication,
    );

    var respBody = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp updateOwnBasicInfo=" + respBody);
        return User.fromMap(jsonDecode(respBody)['user']);
      }
    }
    print('updateOwnBasicInfo error = $respBody');
    return User(success: false, );
  }


  Future<Message> chatUpdate(String roomId, String msgId, String text, Authentication authentication) async {
    Map<String, dynamic> payload = {'roomId': roomId, 'msgId': msgId, 'text': text};
    http.Response response = await _httpService.post(
      '/api/v1/chat.update',
      jsonEncode(payload),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp useInviteToken=" + response.body);
        return Message.fromMap(jsonDecode(response.body)['channel']);
      }
    }
    return Message();
  }

  Future<FindOrCreateInviteResponse> findOrCreateInvite(String roomId, int days, int maxUses, Authentication authentication) async {
    Map<String, dynamic> payload = {'rid': roomId, 'days': days, 'maxUses': maxUses};
    http.Response response = await _httpService.post(
      '/api/v1/findOrCreateInvite',
      jsonEncode(payload),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp useInviteToken=" + response.body);
        return FindOrCreateInviteResponse.fromMap(jsonDecode(response.body));
      }
    }
    return FindOrCreateInviteResponse();
  }

  Future<Room> channelsJoin(String roomId, Authentication authentication, {String? joinCode}) async {
    Map<String, dynamic> payload;
    if (joinCode == null)
      payload = {'roomId': roomId};
    else
      payload = {'roomId': roomId, 'joinCode': joinCode};
    http.Response response = await _httpService.post(
      '/api/v1/channels.join',
      jsonEncode(payload),
      authentication,
    );

    var body = utf8.decode(response.bodyBytes);
    print("resp channelsJoin=" + body);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return Room.fromMap(jsonDecode(body)['channel']);
      }
    }
    if (response.body.isNotEmpty && jsonDecode(body)['success'] == false) {
      return(Room(error: jsonDecode(body)['error']));
    }
    return Room();
  }


  static int count = 0;
  Future<User> getUserInfo(UserIdFilter userIdFilter, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/users.info',
      userIdFilter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        String res = utf8.decode(response.bodyBytes);
        //log('****http call return getUserInfo=$res');
        var user = User.fromMap(jsonDecode(res)['user']);
        count++;
        return user;
      }
    }
    return User();
  }

  Future<List<User>> usersPresence(DateTime from, Authentication authentication) async {
    http.Response response = await _httpService.getWithQuery(
      '/api/v1/users.presence',
      {'from': from.toIso8601String()},
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        String res = utf8.decode(response.bodyBytes);
        var jsonUsers = jsonDecode(res)['users'];
        log('usersPresence=$res');
        List<dynamic> jsonList = jsonUsers.runtimeType == String //
            ? jsonDecode(jsonUsers)
            : jsonUsers;
        var userList = jsonList
            .where((json) => json != null)
            .map((json) => User.fromMap(json))
            .toList();

        return userList;
      }
    }
    return [];
  }

  Future<User> register(UserNew userNew) async {
    http.Response response = await _httpService.post(
      '/api/v1/users.register',
      jsonEncode(userNew.toMap()),
      null
    );

    var res = utf8.decode(response.bodyBytes);
    print('register resp=$res');
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return User.fromMap(jsonDecode(res)['user']);
      } else {
        return User();
      }
    }
    print(response.body);
    return User();
  }

  Future<dynamic> avatarImageUpload(Authentication? authentication, {File? file, Uint8List? bytes, String? mimeType, String? fileName}) async {
    var uri = _httpService.getUri()!.replace(path: '/api/v1/users.setAvatar');
    if (mimeType == null && fileName!= null && bytes != null) {
      mimeType = lookupMimeType(fileName, headerBytes: bytes);
    }
    var request = http.MultipartRequest('POST', uri)
      ..headers['X-Auth-Token'] = authentication!.data!.authToken!
      ..headers['X-User-Id'] = authentication.data!.userId!
      ..files.add(file != null ? await http.MultipartFile.fromPath(
          'image', file.path,
          contentType: MediaType.parse(lookupMimeType(file.path)!)) :
          http.MultipartFile.fromBytes('image', bytes!.toList(), filename: 'file.name', contentType: MediaType.parse(mimeType != null && mimeType.isNotEmpty ? mimeType : 'application/octet-stream'))
      );

    var response = await request.send();

    if (response.statusCode == 200) {
      var resData = await response.stream.toBytes();
      var res = utf8.decode(resData);
      print('avatarUpload = $res');
      var json = jsonDecode(res);
      return json;
    }
    return null;
  }


}
