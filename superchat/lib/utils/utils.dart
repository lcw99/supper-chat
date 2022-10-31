import 'dart:collection';
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
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:superchat/constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rc;
import 'package:http/http.dart' as http;
import 'package:extended_image/extended_image.dart' as ei;
import 'package:url_launcher/url_launcher.dart';

UserCache userCache = UserCache();
class Utils {
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
  static void clearUserCache() => userCache._clear();
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
    //print('@@ job wait count=$count, username=$userName, userid=$userId');
    return user;
  }

  static String getUserNameByUser(User user) {
    String userName = user.username;
    if (user.name != null)
      userName += '(${user.name})';
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
          //User user = await getUserInfo(authentication, userName: u);
          User user = User(username: u);
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

  static Widget getRoomTitle(context, Room r, User owner) {
    Widget roomType;
    if (r.t == 'c')
      roomType = Icon(Icons.public, color: Colors.white);
    else if (r.t == 'p')
      roomType = Icon(Icons.lock, color: Colors.white);
    else if (r.t == 'd')
      roomType = Icon(Icons.chat, color: Colors.white);
    else
      roomType = Icon(Icons.device_unknown, color: Colors.yellow);

    String roomName = getRoomName(r, owner);

    return Row(children: [
      roomType,
      r.u != null && r.u.id == owner.id ? Icon(Icons.perm_identity, color: Colors.white) : SizedBox(),
      Expanded(child: Text(roomName, overflow: TextOverflow.fade,)),
    ],);
  }

  static String getRoomName(Room r, User owner) {
    String roomName = r.fname;
    if (roomName == null)
      roomName = r.name;
    if (roomName == null && r.t == 'd') {
      r.usernames.remove(owner.username);
      roomName = r.usernames.first;
    }
    return roomName;
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

  static buildUser(user, double size, { Widget userTag, bool compact = false }) {
    List<Widget> title = [
      Text(
        Utils.getUserNameByUser(user) ,
        style: TextStyle(fontSize: size / 2, color: Colors.black),
        textAlign: TextAlign.left,
      )
    ];
    if (userTag != null)
      title.add(userTag);
    return Container(child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Utils.buildUserAvatar(size, user),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Wrap(children: title),
        compact ? SizedBox() : Text(
          user.username ,
          style: TextStyle(fontSize: 12, color: Colors.black54,),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: size / 5,),
      ])),
    ]), decoration: BoxDecoration(border: Border.all(color: Colors.transparent)));
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

  static List<String> getDateString(DateTime ts) {
    List<String> dates = [];
    ts = ts.toLocal();
    String mmdd = '';
    var now = DateTime.now().toLocal();
    if (now.year != ts.year)
      dates.add(DateFormat('yyyy').format(ts));
    if (now.month != ts.month)
      mmdd += DateFormat('MM-').format(ts);
    if (now.day != ts.day) {
      if (now.day - ts.day == 1)
        mmdd += 'YD';
      else
        mmdd += DateFormat('dd').format(ts);
    }
    if (mmdd.isNotEmpty)
      dates.add(mmdd);
    dates.add(DateFormat('jm').format(ts));

    return dates.reversed.toList();
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

      double imageHeightInDevice = imageWidthInDevice;
      if (imageDimensions != null) {
        double r = imageWidthInDevice / imageDimensions.width;
        imageHeightInDevice = imageDimensions.height * r;
      }

      String url = imagePath;
      if (!imagePath.startsWith("http")) {
        var uri = serverUri.replace(path: imagePath, queryParameters: query);
        url = uri.toString();
      }

      var image = ei.ExtendedImage.network(url,
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

  static String _getUserName(Message message) {
    String userName = '';
    if (message.user == null)
      return userName;
    if (message.user.name != null)
      userName += ' ' + message.user.name;
    if (userName == '' && message.user.username != null)
      userName += ' ' + message.user.username;
    return userName;
  }


  static Message toDisplayMessage(Message message) {
    String userName = _getUserName(message);
    var regExp = RegExp(r'\[ \]\(.*\)[\s]*');
    if (message.msg != null && regExp.hasMatch(message.msg)) {
      message.msg = message.msg.replaceAll(regExp, '');
      message.urls = null;
    }
    if (message.mentions != null && message.mentions.length > 0) {
      for (User u in message.mentions) {
        String name = u.name;
        if (name == null)
          name = u.username;
        message.msg = message.msg.replaceAll(RegExp('@' + u.username + '\\b'), '%$name#');
      }
    }

    String newMessage = message.msg;
    switch (message.t) {
      case 'au': newMessage = '$userName added ${message.msg}'; break;
      case 'ru': newMessage = '$userName removed ${message.msg}'; break;
      case 'uj': newMessage = '$userName joined room'; break;
      case 'ul': newMessage = '$userName leave room'; break;
      case 'room_changed_avatar': newMessage = '$userName change room avatar'; break;
      case 'room_changed_description': newMessage = '$userName change room description'; break;
      case 'message_pinned': newMessage = '$userName pinned message'; break;
      case 'discussion-created': newMessage = '$userName created discussion(${message.msg})'; break;
      default: if (message.t != null ) newMessage = '$userName act ${message.t}'; break;
    }
    if (newMessage.contains("\t")) {
      int idx = newMessage.indexOf("\t");
      newMessage = newMessage.substring(0, idx);
    }
    message.displayMessage = newMessage;
    return message;
  }

  static buildPopupMenuItem(IconData icon, String menuText, String value) {
    List<Widget> cc = [];
    if (icon != null) {
      cc.add(Icon(icon, color: Colors.blueAccent,));
      cc.add(SizedBox(width: 5,));
    }
    cc.add(Text(menuText));
    return PopupMenuItem(child: Wrap(children: cc,), value: value);
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
      //print('job code $jobCode is in jobList');
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

  void _clear() {
    userCache.clear();
    userCacheByUserName.clear();
  }
  User getUser({String userName, String userId}) {
    if (userId != null && userCache.containsKey(userId))
      return userCache[userId];
    if (userName != null && userCacheByUserName.containsKey(userName))
      return userCache[userCacheByUserName[userName]];
    print('!!!!!!!!!!!!!!!!!!! no cache for $userName or $userId');
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

typedef void TaskCallback();
class TaskQueue {
  final int delay;

  TaskQueue(this.delay) {
    taskQ = Queue();
  }

  Queue<TaskCallback> taskQ;
  static bool running = false;

  addTask(TaskCallback callback) async {
    taskQ.add(callback);

    if (taskQ.isNotEmpty) {
      while(running) await Future.delayed(Duration(milliseconds: delay));
      running = true;
      await Future.delayed(Duration(milliseconds: delay), () => taskQ.isNotEmpty ? taskQ.removeFirst()() : taskQ.clear());
      running = false;
    }
  }

  clear() {
    taskQ.clear();
    running = false;
  }
}