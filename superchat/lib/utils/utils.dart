import 'dart:typed_data';

import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:superchat/constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rc;
import 'package:http/http.dart' as http;

class Utils {
  static UserCache userCache = UserCache();
  static String getAvatarUrl(User userInfo) {
    Uri uri = serverUri.replace(path: '/avatar/${userInfo.username}', query: 'format=png');
    if (userInfo.avatarUrl != null)
      uri = uri.replace(path: Uri.parse(userInfo.avatarUrl).path);
    else if (userInfo.avatarETag != null)
      uri = uri.replace(query: 'avatarETag=${userInfo.avatarETag}');
    //print('avatar url=$uri');
    return uri.toString();
  }

  static User getCachedUser(String userId) => userCache.getUser(userId: userId);
  static void clearCache() => userCache.clear();
  static void clearUser(String userId) => userCache.clearUser(userId);

  static Future<User> getUserInfo(Authentication authentication, {String userId, String userName, bool foreRefresh = false}) async {
    User user;
    if (!foreRefresh) {
      user = userCache.getUser(userName: userName, userId: userId);
      if (user != null)
        return user;
    }
    print('++++++ call getUserInfo=$userId, $userName');
    user = await getUserService().getUserInfo(UserIdFilter(userId: userId, username: userName), authentication);
    userCache.addUser(user);
    return user;
  }

  static String getUserNameByUser(User user) {
    String userName = '';
    if (user.name != null)
      userName += ' ' + user.name;
    if (userName == '' && user.username != null)
      userName += ' ' + user.username;
    return userName;
  }

  static Future<String> getUserName(String userId, Authentication authentication) async {
    User user = await getUserInfo(authentication, userId: userId);
    return getUserNameByUser(user);
  }

  static Future<String> getRoomAvatarUrl(Room room, Authentication authentication) async {
    if (room.t == 'd') {
      for (String u in room.usernames) {
        if (u != authentication.data.me.username) {
          User user = await getUserInfo(authentication, userName: u);
          return getAvatarUrl(user);
        }
      }
    }

    String query = 'format=png';
    if (room.avatarETag != null)
      query += "&avatarETag=${room.avatarETag}";
    return serverUri.replace(path: '/avatar/room/${room.id}', query: query).toString();
  }

  static Future<dynamic> setAvatarImage(String imagePath, Authentication auth) async {
    Map<String, String> query = {
      'rc_token': auth.data.authToken,
      'rc_uid': auth.data.userId
    };
    var r = await http.get(serverUri.replace(path: imagePath, queryParameters: query));

    if (r.statusCode == 200) {
      Uint8List data = r.bodyBytes;
      String contentType = r.headers['content-type'];
      await getUserService().avatarImageUpload(auth, bytes: data, mimeType: contentType);
      clearUser(auth.data.me.id);
    } else {
      return null;
    }
  }

}

class UserCache {
  static final UserCache _singleton = UserCache._internal();

  UserCache._internal();

  static Map<String, User> userCache = Map<String, User>();
  static Map<String, String> userCacheByUserName = Map<String, String>();

  factory UserCache() {
    return _singleton;
  }

  void clear() {
    userCache.clear();
    userCacheByUserName.clear();
  }
  User getUser({String userName, String userId}) {
    if (userId != null && userCache.containsKey(userId))
      return userCache[userId];
    if (userName != null && userCacheByUserName.containsKey(userName))
      return userCache[userCacheByUserName[userName]];
    return null;
  }

  void addUser(User user) {
    print('~~~~~~~~~~~~~~~~~~~~~~~~~++++++++++ adduser=${user.username}');
    userCache[user.id] = user;
    userCacheByUserName[user.username] = user.id;
  }

  void clearUser(String userId) {
    if (userCache.containsKey(userId)) {
      userCacheByUserName.remove(userCache[userId].username);
      userCache.remove(userId);
    }
  }
}

