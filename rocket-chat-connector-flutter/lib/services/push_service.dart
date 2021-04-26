import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/new/token_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class PushService {
  HttpService _httpService;

  PushService(this._httpService);

  Future<String> pushToken(TokenNew tokenNew, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/push.token',
      jsonEncode(tokenNew.toMap()),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return response.body;
      } else {
        return '';
      }
    }
    throw RocketChatException(response.body);
  }
}
