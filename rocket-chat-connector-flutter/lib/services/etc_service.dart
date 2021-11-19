import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/response/custom_emoji_response.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class EtcService {
  HttpService _httpService;

  EtcService(this._httpService);

  Future<CustomEmojiResponse> getCustomEmojiList(Authentication authentication, {DateTime? updatedSince}) async {
    String path = '/api/v1/emoji-custom.list';
    var payload;
    if (updatedSince != null)
      payload = {'updatedSince': updatedSince.toIso8601String()};
    http.Response response = await _httpService.getWithQuery(
      path,
      payload,
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("####emoji-custom.list resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return CustomEmojiResponse.fromMap(jsonDecode(resp));
      } else {
        return CustomEmojiResponse();
      }
    }
    throw RocketChatException(response.body);
  }
}