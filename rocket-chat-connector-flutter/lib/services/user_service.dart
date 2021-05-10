import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:logger/logger.dart';
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

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        print("resp useInviteToken=" + response.body);
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
        print("resp useInviteToken=" + response.body);
        return Room.fromMap(jsonDecode(response.body)['channel']);
      }
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
        var user = User.fromMap(jsonDecode(res)['user']);
        count++;
        log('****http call return getUserInfo=${user.username}, count=${count}');
        return user;
      }
    }
    Logger().e('getUserInfo', response);
    return User();
  }

  Future<User> register(UserNew userNew) async {
    http.Response response = await _httpService.post(
      '/api/v1/users.register',
      jsonEncode(userNew.toMap()),
      null
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        var res = utf8.decode(response.bodyBytes);
        return User.fromMap(jsonDecode(res));
      } else {
        return User();
      }
    }
    print(response.body);
    return User();
  }

  Future<dynamic> avatarImageUpload(Authentication? authentication, {File? file, Uint8List? bytes, String? mimeType}) async {
    var uri = _httpService.getUri()!.replace(path: '/api/v1/users.setAvatar');
    var request = http.MultipartRequest('POST', uri)
      ..headers['X-Auth-Token'] = authentication!.data!.authToken!
      ..headers['X-User-Id'] = authentication.data!.userId!
      ..files.add(file != null ? await http.MultipartFile.fromPath(
          'image', file.path,
          contentType: MediaType.parse(lookupMimeType(file.path)!)) :
          http.MultipartFile.fromBytes('image', bytes!.toList(), filename: 'file.name', contentType: MediaType.parse(mimeType!.isNotEmpty ? mimeType : 'application/octet-stream'))
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
