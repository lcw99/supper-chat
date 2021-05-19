import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
import 'package:rocket_chat_connector_flutter/models/image_dimensions.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:superchat/constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rc;
import 'package:http/http.dart' as http;
import 'package:extended_image/extended_image.dart' as ei;
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static UserCache userCache = UserCache();
  static String getAvatarUrl(User userInfo) {
    Uri uri = serverUri.replace(path: '/avatar/${userInfo.username}', query: 'format=png');
    if (userInfo.avatarETag != null)
      uri = uri.replace(query: 'avatarETag=${userInfo.avatarETag}');
    else if (userInfo.avatarUrl != null)
      uri = uri.replace(path: Uri.parse(userInfo.avatarUrl).path);
    //print('avatar url=$uri');
    return uri.toString();
  }

  static User getCachedUser({String userId, String userName}) => userCache.getUser(userId: userId, userName: userName);
  static void clearCache() => userCache.clear();
  static void clearUser(String userId) => userCache.clearUser(userId);

  static Future<User> getUserInfo(Authentication authentication, {String userId, String userName, bool forceRefresh = false}) async {
    if (userId == null && userName == null)
      return null;
    User user;
    if (!forceRefresh) {
      user = userCache.getUser(userName: userName, userId: userId);
      if (user != null)
        return user;
    }

    bool working = await userCache.addJob(userId, userName, authentication);
    int count = 0;
    do {
      user = await Future.delayed(Duration(milliseconds: 500), () {
        count ++;
        return userCache.getUser(userName: userName, userId: userId);
      });
    } while(user == null && count < 20);
    print('@@ job wait count=$count, username=$userName, userid=$userId');
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

  static Widget getRoomTitle(context, Room r, String ownerId) {
    Widget roomType;
    if (r.t == 'c')
      roomType = Icon(Icons.public, color: Colors.white);
    else if (r.t == 'p')
      roomType = Icon(Icons.lock, color: Colors.white);
    else if (r.t == 'd')
      roomType = Icon(Icons.chat, color: Colors.white);
    else
      roomType = Icon(Icons.device_unknown, color: Colors.yellow);

    String roomName = r.name;
    if (r.name == null && r.t == 'd') {
      roomName = r.usernames.toString();
    }

    return Row(children: [
      roomType,
      r.u != null && r.u.id == ownerId ? Icon(Icons.perm_identity, color: Colors.white) : SizedBox(),
      Expanded(child: Text(roomName, overflow: TextOverflow.fade,)),
    ],);
  }

  static showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  static buildUser(user, double size) {
    return ListTile(
      dense: true,
      leading: Utils.buildUserAvatar(size, user),
      title: Text(
        Utils.getUserNameByUser(user) ,
        style: TextStyle(fontSize: 15, color: Colors.black),
        textAlign: TextAlign.left,
      ),
      subtitle: Text(
        user.username ,
        style: TextStyle(fontSize: 12, color: Colors.black54),
        textAlign: TextAlign.left,
      ),
    );
  }


  static Widget buildUserAvatar(double size, User user, {String avatarPath}) {
    String url;
    if (avatarPath != null )
      url = serverUri.replace(path: avatarPath, query: 'format=png').toString();
    else
      url = Utils.getAvatarUrl(user);
    return Container(
        padding: EdgeInsets.all(2),
        alignment: Alignment.topLeft,
        width: size ,
        height: size,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(url, key: UniqueKey()))
    );
  }

  static String getDateString(DateTime ts) {
    var now = DateTime.now().toLocal();
    String dateStr = '';
    if (now.year != ts.year)
      dateStr += DateFormat('yyyy-').format(ts);
    if (now.month != ts.month)
      dateStr += DateFormat('MM-').format(ts);
    if (now.day != ts.day) {
      if (now.day - ts.day == 1)
        dateStr += 'yesterday ';
      else
        dateStr += DateFormat('dd ').format(ts);
    }
    dateStr += DateFormat('jm').format(ts);

    return dateStr;
  }

  static buildImageByLayout(Authentication authRC, String imagePath, double imageWidth, ImageDimensions imageDimensions) {
    Map<String, String> query = {
      'rc_token': authRC.data.authToken,
      'rc_uid': authRC.data.userId
    };

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      //print('buildImageByLayout constraints=$constraints');
      var dpr = MediaQuery.of(context).devicePixelRatio;
      var imageWidthInDevice = imageWidth * dpr;

      double r = imageWidthInDevice / imageDimensions.width;
      double imageHeightInDevice = imageDimensions.height * r;

      var uri = serverUri.replace(path: imagePath, queryParameters: query);

      var image = ei.ExtendedImage.network(uri.toString(),
        width: imageWidthInDevice / dpr,
        height: imageHeightInDevice / dpr,
        cacheWidth: 800,
        fit: BoxFit.contain,
        cache: true,
        mode: kIsWeb ? ei.ExtendedImageMode.none : ei.ExtendedImageMode.gesture,
        initGestureConfigHandler: (state) {
          return ei.GestureConfig(
            minScale: 0.9,
            animationMinScale: 0.7,
            maxScale: 3.0,
            animationMaxScale: 3.5,
            speed: 1.0,
            inertialSpeed: 100.0,
            initialScale: 1.0,
            inPageView: false,
            initialAlignment: ei.InitialAlignment.center,
          );
        },
      );
      return image;
    });
  }

  static String buildDownloadUrl(Authentication authRC, String downloadLink) {
    Map<String, String> query = {
      'rc_token': authRC.data.authToken,
      'rc_uid': authRC.data.userId
    };
    var uri = serverUri.replace(path: downloadLink, queryParameters: query);
    return uri.toString();
  }

  static void downloadFile(Authentication authRC, String downloadLink) {
    String downloadUrl = buildDownloadUrl(authRC, downloadLink);
    launch(Uri.encodeFull(downloadUrl));
  }


}

class UserCache {
  static final UserCache _singleton = UserCache._internal();

  UserCache._internal();

  static Map<String, User> userCache = Map<String, User>();
  static Map<String, String> userCacheByUserName = Map<String, String>();
  static List<String> jobList = [];

  factory UserCache() {
    return _singleton;
  }

  Future<bool> addJob(String userId, userName, Authentication authentication) async {
    String jobCode= '$userId+$userName';
    if (jobList.contains(jobCode)) {
      print('job code $jobCode is in jobList');
      return true;
    }
    print('new jobCode=$jobCode');
    jobList.add(jobCode);
    User user = await getUserService().getUserInfo(UserIdFilter(userId: userId, username: userName), authentication);
    print('++++++ get getUserInfo done user=$user');
    addUser(user);
    jobList.remove(jobCode);
    return false;
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
    userCache[user.id] = user;
    userCacheByUserName[user.username] = user.id;
    print('~~~~~~~~~~~~~~~~~~~~~~~~~++++++++++ added user=${user.username}');
  }

  void clearUser(String userId) {
    if (userCache.containsKey(userId)) {
      userCacheByUserName.remove(userCache[userId].username);
      userCache.remove(userId);
    }
  }

}

