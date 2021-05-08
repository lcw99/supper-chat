import 'dart:convert';
import 'dart:developer';
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

  Future<User> getUserInfo(UserIdFilter userIdFilter, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/users.info',
      userIdFilter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        String res = utf8.decode(response.bodyBytes);
        log('getUserInfo=$res');
        return User.fromMap(jsonDecode(res)['user']);
      } else {
        return User();
      }
    }
    throw RocketChatException(response.body);

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

  Future<dynamic> avatarImageUpload(Authentication? authentication, File? file) async {
    String filename = path.basename(file!.path);

    Map<String, String> headers = {
      'X-Auth-Token': authentication!.data!.authToken!,
      'X-User-Id': authentication.data!.userId!,
    };

    var uri = _httpService.getUri()!.replace(path: '/api/v1/users.setAvatar');
    var request = http.MultipartRequest('POST', uri)
      ..headers['X-Auth-Token'] = authentication.data!.authToken!
      ..headers['X-User-Id'] = authentication.data!.userId!
      ..files.add(await http.MultipartFile.fromPath(
          'image', file.path,
          contentType: MediaType.parse(lookupMimeType(file.path)!)));

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
