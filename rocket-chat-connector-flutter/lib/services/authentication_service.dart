import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class AuthenticationService {
  HttpService _httpService;

  AuthenticationService(this._httpService);

  Future<Authentication> login(String user, String password) async {
    Map<String, String> body = {'user': user, 'password': password};
    http.Response response = await _httpService.post(
      '/api/v1/login',
      jsonEncode(body),
      null,
    );

    if (response.statusCode == 200 && response.body.isNotEmpty == true) {
      var s = utf8.decode(response.bodyBytes);
      log('authentication = $s');
      var json = jsonDecode(s);
      return Authentication.fromMap(json);
    }
    throw RocketChatException(response.body);
  }

  Future<Authentication> loginGoogle(String accessToken, String idToken) async {
    print("google login=" + accessToken);
    Map<String, dynamic> body = {'serviceName': 'google', 'accessToken': accessToken, 'idToken': idToken, 'expiresIn': 200, 'scope': 'email'};
    http.Response response = await _httpService.post(
      '/api/v1/login',
      jsonEncode(body),
      null,
    );

    print("google login resp=${response.statusCode}");

    if (response.statusCode == 200 && response.body.isNotEmpty == true) {
      var s = utf8.decode(response.bodyBytes);
      log('authentication = $s');
      var json = jsonDecode(s);
      var auth = Authentication.fromMap(json);
      // var u = await getUserService().getUserInfo(UserIdFilter(userId: auth.data!.me!.id), auth);
      // auth.data!.me = u;
      return auth;
    }
    throw RocketChatException(response.body);
  }

  Future<User> me(Authentication authentication) async {
    http.Response response = await _httpService.get(
      '/api/v1/me',
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        return User();
      }
    }
    throw RocketChatException(response.body);
  }
}
