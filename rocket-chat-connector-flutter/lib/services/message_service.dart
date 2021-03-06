import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:universal_io/io.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/new/reaction_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/receipt_response.dart';

import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class MessageService {
  rocket_http_service.HttpService _httpService;

  MessageService(this._httpService);

  Future<MessageNewResponse> postMessage(MessageNew message, Authentication authentication, {bool sendMessage = false}) async {
    String api = '/api/v1/chat.postMessage';
    var payload = message.toMap();
    if (sendMessage) {
      api = '/api/v1/chat.sendMessage';
      payload = { "message" : message.toMap() };
    }
    http.Response response = await _httpService.post(
      api,
      jsonEncode(payload),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return MessageNewResponse.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return MessageNewResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<MessageNewResponse> postReaction(ReactionNew reaction, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/chat.react',
      jsonEncode(reaction.toMap()),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return MessageNewResponse.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return MessageNewResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<Response> starMessage(String messageId, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/chat.starMessage',
      jsonEncode({ 'messageId': messageId }),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return Response();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<Response> unStarMessage(String messageId, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/chat.unStarMessage',
      jsonEncode({ 'messageId': messageId }),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return Response();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<Response> pinMessage(String messageId, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/chat.pinMessage',
      jsonEncode({ 'messageId': messageId }),
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(resp));
      }
    }
    return Response(success: false, body: resp);
  }

  Future<Response> unPinMessage(String messageId, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/chat.unPinMessage',
      jsonEncode({ 'messageId': messageId }),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return Response();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ReceiptResponse> getMessageReadReceipts(String messageId, Authentication authentication) async {
    String path = '/api/v1/chat.getMessageReadReceipts';
    http.Response response = await _httpService.getWithQuery(
      path,
      {'messageId': messageId},
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("chat.getMessageReadReceipts resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ReceiptResponse.fromMap(jsonDecode(resp));
      } else {
        return ReceiptResponse(success: false);
      }
    }
    throw RocketChatException(response.body);
  }


  Future<Message> roomImageUpload(String? roomId, Authentication? authentication,
        {File? file, Uint8List? bytes, String? desc, String? mimeType, String? fileName, String? tmid}) async {
    var uri = _httpService.getUri()!.replace(path: '/api/v1/rooms.upload/$roomId');
    if (mimeType == null && fileName!= null && bytes != null) {
      mimeType = lookupMimeType(fileName, headerBytes: bytes);
    }
    var request = http.MultipartRequest('POST', uri)
      ..headers['X-Auth-Token'] = authentication!.data!.authToken!
      ..headers['X-User-Id'] = authentication.data!.userId!
      ..files.add(file != null ? await http.MultipartFile.fromPath(
          'file', file.path,
          contentType: MediaType.parse(lookupMimeType(file.path)!)) :
          http.MultipartFile.fromBytes('file', bytes!.toList(), filename: fileName!,
              contentType: MediaType.parse(mimeType != null && mimeType.isNotEmpty ? mimeType : 'application/octet-stream'))
      );

    if (desc != null && desc.isNotEmpty)
      request.fields["description"] = desc;
    if (tmid != null && tmid.isNotEmpty)
      request.fields["tmid"] = tmid;

    var response = await request.send();

    if (response.statusCode == 200) {
      var resData = await response.stream.toBytes();
      var json = jsonDecode(utf8.decode(resData));
      if (json['message'] != null)
        return Message.fromMap(json['message']);
    }
    return Message();
  }
}
