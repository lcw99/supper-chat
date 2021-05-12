import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/channel_counters.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/updatesince_filter.dart';
import 'package:rocket_chat_connector_flutter/models/new/channel_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_list_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_members_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/spotlight_response.dart';
import 'package:rocket_chat_connector_flutter/models/room_update.dart';
import 'package:rocket_chat_connector_flutter/models/subscription_update.dart';
import 'package:rocket_chat_connector_flutter/models/sync_messages.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;

class ChannelService {
  HttpService _httpService;

  ChannelService(this._httpService);

  Future<ChannelNewResponse> create(
      ChannelNew channelNew, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/channels.create',
      jsonEncode(channelNew.toMap()),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelNewResponse.fromMap(jsonDecode(response.body));
      } else {
        return ChannelNewResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelMessages> messages(Channel channel, Authentication authentication) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/channels.messages',
      ChannelFilter(channel),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelMessages.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return ChannelMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<bool> markAsRead(String channelId, Authentication authentication) async {
    Map<String, String?> body = {"rid": channelId};

    http.Response response = await _httpService.post(
      '/api/v1/subscriptions.read',
      jsonEncode(body),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(response.body)).success == true;
      } else {
        return false;
      }
    }
    throw RocketChatException(response.body);
  }

  Future<String> addUsersToRoom(String rid, List<String> users, Authentication authentication) async {
    Map msg = {
      "method": "addUsersToRoom",
      "params": [{
        "rid": rid,
        "users": users
      }]
    };

    Map<String, String?> payload = { "message" : "${jsonEncode(msg)}" };

    http.Response response = await _httpService.post(
      '/api/v1/method.call/addUsersToRoom',
      jsonEncode(payload),
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("^^^^^^^^^^^^^^^^^^^^^addUsersToRoom^^^^^^^^^^^^ resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return resp;
      } else {
        return '';
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelMessages> roomHistory(ChannelHistoryFilter filter, Authentication authentication, String roomType) async {
    String path = '/api/v1/channels.history';
    if (roomType == 'd')
      path = '/api/v1/im.history';
    else if (roomType == 'p')
      path = '/api/v1/groups.history';
    http.Response response = await _httpService.getWithFilter(
      path,
      filter,
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("^^^^^^^^^^^^^^^^^^^^^channels.history^^^^^^^^^^^^ resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelMessages.fromMap(jsonDecode(resp));
      } else {
        return ChannelMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<Response> roomAnnouncement(model.Room? room, String? announcement, Authentication authentication) async {
    String path = '/api/v1/channels.setAnnouncement';
    if (room!.t == 'p')
      path = '/api/v1/groups.setAnnouncement';

    Map<String, String?> body = {"roomId": room.id, "announcement": announcement};

    http.Response response = await _httpService.post(
      path,
      jsonEncode(body),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return Response.fromMap(jsonDecode(response.body));
      }
    }
    return Response(success: false);
  }

  Future<RoomMembersResponse> getRoomMembers(String roomId, String roomType, Authentication authentication, {int? offset, int? count, Map<String, int>? sort}) async {
    String path = '/api/v1/groups.members';
    if (roomType == 'c')
      path = '/api/v1/channels.members';
    Map<String, dynamic> payload = {"roomId": roomId};
    if (offset != null)
      payload["offset"] = offset;
    if (count != null)
      payload["count"] = count;
    if (sort != null)
      payload["sort"] = sort;

    http.Response response = await _httpService.getWithQuery(
      path,
      payload,
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("groups.members resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomMembersResponse.fromMap(jsonDecode(resp));
      } else {
        return RoomMembersResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelMessages> getStarredMessages(String roomId, Authentication authentication) async {
    String path = '/api/v1/chat.getStarredMessages';
    http.Response response = await _httpService.getWithQuery(
      path,
      {'roomId': roomId},
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    //log("chat.getStarredMessages resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelMessages.fromMap(jsonDecode(resp));
      } else {
        return ChannelMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<SpotlightResponse> spotlight(String query, Authentication authentication) async {  // @ user, #channel
    String path = '/api/v1/spotlight';
    http.Response response = await _httpService.getWithQuery(
      path,
      {'query': query},
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("chat.spotlight resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return SpotlightResponse.fromMap(jsonDecode(resp));
      } else {
        return SpotlightResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<model.Room> getRoomInfo(Authentication authentication, {String? roomId, String? roomName}) async {
    String path = '/api/v1/rooms.info';
    var payLoad;
    if (roomId != null)
      payLoad = {'roomId': roomId};
    else if (roomName != null)
      payLoad = {'roomName': roomName};
    if (payLoad == null)
      return model.Room();
    http.Response response = await _httpService.getWithQuery(
      path,
      payLoad,
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("chat.getRoomInfo resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return model.Room.fromMap(jsonDecode(resp)['room']);
      }
    }
    return model.Room();
  }

  Future<SyncMessages> syncMessages(String roomId, DateTime lastUpdate, Authentication authentication) async {
    String path = '/api/v1/chat.syncMessages';
    http.Response response = await _httpService.getWithQuery(
      path,
      { 'roomId': roomId, 'lastUpdate': lastUpdate.toIso8601String() },
      authentication,
    );

    var resp = utf8.decode(response.bodyBytes);
    log("####chat.syncMessages resp=$resp");
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return SyncMessages.fromMap(jsonDecode(resp));
      } else {
        return SyncMessages();
      }
    }
    throw RocketChatException(response.body);
  }


  Future<ChannelCounters> counters(
    ChannelCountersFilter filter,
    Authentication authentication,
  ) async {
    http.Response response = await _httpService.getWithFilter(
      '/api/v1/channels.counters',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return ChannelCounters.fromMap(jsonDecode(response.body));
      } else {
        return ChannelCounters();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<ChannelListResponse> getChannelList(Authentication authentication) async {
    http.Response response = await _httpService.get(
      '/api/v1/channels.list', authentication
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        var resp = utf8.decode(response.bodyBytes);
        log("@@@@@@@ channels.list resp=$resp");
        return ChannelListResponse.fromMap(jsonDecode(resp));
      }
    }
    return ChannelListResponse();
  }

  Future<SubscriptionUpdate> getSubscriptions(Authentication authentication, UpdatedSinceFilter updateSinceFilter) async {
    http.Response response;
    if (updateSinceFilter.updatedSince == null) {
      response = await _httpService.get(
        '/api/v1/subscriptions.get',
        authentication,
      );
    } else {
      response = await _httpService.getWithFilter(
        '/api/v1/subscriptions.get',
        updateSinceFilter,
        authentication,
      );
    }

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        var resp = utf8.decode(response.bodyBytes);
        //log("subscriptions.get resp=$resp");
        return SubscriptionUpdate.fromMap(jsonDecode(resp));
      } else {
        return SubscriptionUpdate();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<RoomUpdate> getRooms(Authentication authentication, UpdatedSinceFilter updateSinceFilter) async {
    http.Response response;
    if (updateSinceFilter.updatedSince == null) {
      response = await _httpService.get(
        '/api/v1/rooms.get',
        authentication,
      );
    } else {
      response = await _httpService.getWithFilter(
        '/api/v1/rooms.get',
        updateSinceFilter,
        authentication,
      );
    }

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        var resp = utf8.decode(response.bodyBytes);
        //log("getRooms resp=$resp");
        return RoomUpdate.fromMap(jsonDecode(resp));
      } else {
        return RoomUpdate();
      }
    }
    throw RocketChatException(response.body);
  }

}

