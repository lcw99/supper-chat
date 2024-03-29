import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBA;
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart' as RC;
import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/models/notification_payload.dart' as RC;
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as RC;
import 'package:rocket_chat_connector_flutter/services/user_service.dart';

import 'package:rocket_chat_connector_flutter/services/push_service.dart';
import 'package:rocket_chat_connector_flutter/models/new/token_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/custom_emoji_response.dart' as RC;
import 'package:rocket_chat_connector_flutter/models/custom_emoji.dart' as RC;
import 'chathome.dart';
import 'constants/constants.dart';
import 'constants/secrets.dart';
import 'constants/types.dart';
import 'database/chatdb.dart';

import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';

import 'flatform_depended/platform_depended.dart';
import 'model/join_info.dart';
import 'utils/password_generator.dart';
import 'utils/utils.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';


final authFirebase = FBA.FirebaseAuth.instance;
final googleSignIn = GoogleSignIn(scopes: ['https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/userinfo.profile']);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final navGlobalKey = new GlobalKey<NavigatorState>();
String notificationPayload;

GetIt locator = GetIt.instance;

double textScaleFactor = 1.0;

String version;
String buildNumber;

//bool needOAuth;
LoginType loginType;

JoinInfo joinInfo;
//JoinInfo joinInfo = JoinInfo('yzYen4', null);

String authTokenPrevious;
Map<String, String> customEmojis = Map();

void main() async {
  //emojiConvert();
  print('***** main start');
  setServerUri(serverUri);
  await setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    print ('============= in release mode, using custom cache');
    MyWidgetsBinding();
  }
  if (!kIsWeb) {
    await _initNotification();
  } else {
    // if (isLocalhost())
    //   loginType = LoginType.rocketChatUserId;
    if (kIsWeb) {
      // initialize the facebook javascript SDK
      FacebookAuth.i.webInitialize(
        appId: facebookAppId,
        cookie: true,
        xfbml: true,
        version: "v9.0",
      );
    }
  }

  authTokenPrevious = null;
  var keyValue = await locator<ChatDatabase>().getValueByKey('userAuth');
  print ('@#@# prev auth=$keyValue');
  if (keyValue != null) {
    loginType = LoginType.rocketChatToken;
    authTokenPrevious = keyValue.value;
  }

  await packageInfo();
  runApp(MainHome());
}

class MyImageCache extends ImageCache {
  @override
  void clear() {
    print("###################Clearing cache!");
    super.clear();
  }
}

class MyWidgetsBinding extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    MyImageCache myImageCache = MyImageCache();
    myImageCache.maximumSize = 1000;
    myImageCache.maximumSizeBytes = 1024 * 1024 * 1024; // 1 Giga
    return myImageCache;
  }
}

packageInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  version = packageInfo.version;
  buildNumber = packageInfo.buildNumber;
}

Future setupLocator() async {
  //locator.registerSingleton(ChatDatabase());
  locator.registerSingleton(constructDb());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  if (!kIsWeb)
    androidNotification(message);

  print("Handling a background message: ${message.data}");
}

final List<Message> messages = <Message>[];

androidNotification(RemoteMessage message) async {
  String payloadStr;
  if (message.data['ejson'] != null)
    payloadStr = message.data['ejson'];
  RC.NotificationPayload payload = RC.NotificationPayload.fromMap(jsonDecode(payloadStr));

  String messageStr;
  if (payload.message != null)
    messageStr = payload.message.msg;
  if (messageStr == null) {
    if (message.data['message'] != null) {
      String s = message.data['message'];
      var ss = s.split(':');
      if (ss.length > 1)
        messageStr = ss[1];
      else
        messageStr = ss[0];
    }
  }
  if (messageStr == null) {
    messageStr = 'no message';
  }
  final String fromAvatar = await downloadAndSaveImageFile(serverUri.replace(path: '/avatar/${payload.sender.username}', query: 'format=png').toString(), payload.sender.username);
  //final String fromAvatar = await Utils.downloadAndSaveFile('https://via.placeholder.com/48x48', 'largeIcon');

  final Person from = Person(name: payload.sender.name, icon: BitmapFilePathAndroidIcon(fromAvatar));
  messages.add(Message(messageStr, DateTime.now(), from));
  if (messages.length > 5)
    messages.removeAt(0);
  final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
      from,
      groupConversation: true,
      conversationTitle: payload.name,
      htmlFormatContent: true,
      htmlFormatTitle: true,
      messages: messages);
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
      'Super Chat', 'Super Chat', 'Super Chat',
      category: 'msg',
      styleInformation: messagingStyle,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false);
  final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  if (flutterLocalNotificationsPlugin != null)
    await flutterLocalNotificationsPlugin.show(
        0, message.data['title'], message.data['message'], platformChannelSpecifics, payload: payloadStr);
}

GlobalKey<ChatHomeState> chatHomeStateKey = GlobalKey();
Future<void> _onSelectNotification(String payload) async {
  messages.clear();
  print("onSelectNotification payload=$payload");
  notificationPayload = payload;
  if (!navGlobalKey.currentState.mounted)
    navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome(notificationPayloadLocal: payload,)), (route) => false);
  else {
    var json = jsonDecode(payload);
    String _rid = json['rid'];
    if (_rid != null) {
      notificationPayload = null;
      print('**** rid= $_rid');
      if (chatHomeStateKey.currentState != null) {
        chatHomeStateKey.currentState.notificationController.sink.add(RC.Notification(msg: 'request_close', collection: _rid));
        Future.delayed(Duration(seconds: 1), () { chatHomeStateKey.currentState.setChannelById(_rid);} );
      }
    } else {
      navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome()), (route) => false);
    }
  }
}

Future<void> onDidReceiveLocalNotification(int id, String title, String body, String payload) async {
}

_initNotification() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
  final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  final MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: _onSelectNotification);
  //notificationPayload = null;

  final notificationAppLaunchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    if (notificationPayload == null) {
      notificationPayload = notificationAppLaunchDetails.payload;
      print("=============== called from notification = $notificationPayload");
    } else {
      Logger().w('notificationPayload already setted = $notificationPayload');
    }
  }
}

class Application {
  static FluroRouter router;
}

// http://localhost:5000/#/join?invite=T23NSG&joincode=bbbb
class Routes {
  static String root = "/";
  static String joinRoom = "/join";

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
          print("ROUTE WAS NOT FOUND !!!");
          return;
        });
    router.define(root, handler: rootHandler);
    router.define(joinRoom, handler: joinRoomHandler);
  }
}

var rootHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      return LoginHome(title: 'from root');
    });

var joinRoomHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      String invite = params["invite"]?.first;
      String joincode = params["joincode"]?.first;
      //Navigator.of(context).pushNamedAndRemoveUntil(Routes.demoSimple, (Route<dynamic> route) => false);
      //Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome(title: invite +':'+ joincode)), (route) => false);
      return Empty(JoinInfo(invite, joincode));
    });

class MainHome extends StatefulWidget {
  const MainHome({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    print('***** MainHome start');
    return MainHomeState();
  }
}

class MainHomeState extends State<MainHome> {
  MainHomeState() {
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Application.router = router;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Chat',
      debugShowCheckedModeBanner: false,
      navigatorKey: navGlobalKey,
      theme: ThemeData.light(),
      //home: LoginHome(title: 'Super Chat'),
      onGenerateRoute: Application.router.generator,
      //onGenerateRoute: (settings) => NavigatorRoute.route(settings.name),
    );
  }
}

class Empty extends StatefulWidget {
  final JoinInfo joinInfo;
  Empty(this.joinInfo);

  @override
  _EmptyState createState() => _EmptyState();
}

class _EmptyState extends State<Empty> {
  @override
  void initState() {
    joinInfo = widget.joinInfo;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    print('+++++++@@@@@@@@@@@@@++++++++Empty title=${widget.joinInfo}');
    return SizedBox();
  }
}

Future<String> waitMount(String title) {
  return Future.delayed(Duration(seconds: 10), () => title);
}

class LoginHome extends StatefulWidget {
  final String notificationPayloadLocal;
  final String title;

  LoginHome({Key key, this.title, this.notificationPayloadLocal}) : super(key: key);

  @override
  _LoginHomeState createState() {
    //Logger().i('_LoginHomeState createState payload=$notificationPayload, payloadlocal=$notificationPayloadLocal');
    if (notificationPayload == null)
      notificationPayload = notificationPayloadLocal;
    return _LoginHomeState();
  }
}

AccessToken facebookAccessToken;
Map<String, dynamic> facebookUserData;

class _LoginHomeState extends State<LoginHome> {
  bool triedSilentLogin = false;
  bool setupNotifications = false;
  bool firebaseInitialized = false;

  String firebaseToken;

  @override
  void initState() {
    Logger().w('+++++++++++@@@@@@+++++++++LoginHome title=${widget.title}');
    facebookAccessToken = null;
    super.initState();
    initializeFlutterFire().then((_) {
      setState(() {
        firebaseInitialized = true;
        print("!!!!!!!!!!!!!!! initializeFlutterFire done");
      });
    });
  }

  Future<FirebaseApp> initializeFlutterFire() async {
    debugPrint("start flutter fire...");

    final FirebaseApp app = await Firebase.initializeApp();
    FirebaseMessaging _messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Used to get the current FCM token
    firebaseToken = await _messaging.getToken();
    print('Token: $firebaseToken');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('###!!!@##@@@@ Got a message whilst in the foreground!!!!!!!!!!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
      // todo: need when socket disconnect?
      //androidNotification(message);
      if (chatHomeStateKey.currentState.isWebSocketClosed())
        chatHomeStateKey.currentState.subscribeAndConnect();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    return app;
  }

  Future<Authentication> getAuthentication() async {
    final AuthenticationService authenticationService = getAuthenticationService();
    print('getAuthentication1=$loginType, authTokenPrevious=$authTokenPrevious');
    if (loginType == LoginType.google) {
      final GoogleSignInAccount googleSignInAccount = await googleSignIn.signInSilently();
      print('getAuthentication2');
      GoogleSignInAuthentication acc = await googleSignInAccount.authentication;
      print('getAuthentication3');
      return await authenticationService.loginGoogle(acc.accessToken, acc.idToken);
    } else if (loginType == LoginType.facebook) {
      final AccessToken accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        int expireIn = accessToken.expires.difference(DateTime.now()).inSeconds;
        return await authenticationService.loginFacebook(accessToken.token, facebookAppSecrete, expireIn);
      }
    } else {
      if (authTokenPrevious != null)
        return await authenticationService.login(username, resume: authTokenPrevious);
      return await authenticationService.login(username, password: password);
    }
    return Authentication(status: 'error', data: null);
  }

  registerToken(Authentication _auth) async {
    PushService pushService = PushService(rocketHttpService);
    TokenNew tokenNew = TokenNew(type: "gcm", value: firebaseToken, appName: "co.smallet.superchat");
    String result = await pushService.pushToken(tokenNew, _auth);
    //print('push result' + result);
  }

  void facebookLogin() async {
    loginType = LoginType.facebook;
    print('start facebook login');
    final LoginResult result = await FacebookAuth.instance.login(); // by default we request the email and the public profile
    if (result.status == LoginStatus.success) {
      // you are logged
      facebookAccessToken = result.accessToken;

      facebookUserData = await facebookGetUserData();
      var email = facebookUserData['email'];
      var userName = email.replaceFirst("@", '.');
      UserNew userNew = UserNew(username: userName, name: facebookUserData['name'], email: email, pass: generatePassword(true, true, true, true, 10));
      RC.User userRC = await UserService(rocketHttpService).register(userNew);
      print("user=" + userRC.toString());

      setState(() {
        print("facebook login=$result");
        triedSilentLogin = true;
      });
    }
  }

  Future<void> silentFacebookLogin() async {
    final AccessToken accessToken = await FacebookAuth.instance.accessToken;
    if (accessToken == null) {
      LoginResult r = await FacebookAuth.instance.expressLogin();
      if (r.status != LoginStatus.success)
        await facebookLogin();
    }
  }

  facebookGetUserData() async {
    return await FacebookAuth.instance.getUserData();
  }

  void googleLogin() async {
    loginType = LoginType.google;
    await _ensureGoogleLoggedIn(context);
    setState(() {
      print("!!!!!!!!!!!!!!! login setstate");
      triedSilentLogin = true;
    });
  }

  Future<Null> _ensureGoogleLoggedIn(BuildContext context) async {
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null) {
      user = await googleSignIn.signInSilently();
    }
    if (user == null) {
      user = await googleSignIn.signIn();
    }

    if (authFirebase.currentUser == null) {
      user = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await user.authentication;

      FBA.GoogleAuthCredential credential = FBA.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      var userCredential = await authFirebase.signInWithCredential(credential);
    }

    if (user != null) {
      var userName = user.email.replaceFirst("@", '.');
      UserNew userNew = UserNew(username: userName, name: user.displayName, email: user.email, pass: generatePassword(true, true, true, true, 10));
      RC.User userRC = await UserService(rocketHttpService).register(userNew);
      print("user=" + userRC.toString());
    }
  }

  void silentGoogleLogin(BuildContext context) async {
    print('!!!!!silentLogin1');
    GoogleSignInAccount user = googleSignIn.currentUser;

    print('!!!!_silent login1=${user==null}');
    if (user == null)
      user = await googleSignIn.signInSilently();
    print('!!!!_silent login2=${user==null}, ${authFirebase.currentUser==null}');

    setState(() {
      print("!!!!!!!!!!!!!!! silentLogin setstate");
      triedSilentLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    RC.User user;

    textScaleFactor = MediaQuery.of(context).textScaleFactor;
    print('===text scale factor = $textScaleFactor');

    if (!firebaseInitialized) {
      print('!firebaseInitialized----------------------');
      return Scaffold(body: buildShowVersion('login initializing'));
    }

    if (triedSilentLogin == false) {
      if (loginType == LoginType.google)
        silentGoogleLogin(context);
      else if (loginType == LoginType.facebook)
        silentFacebookLogin();
    }

    authFirebase.authStateChanges().listen((event) {
      if (event == null) {
        print('****authFirebase.authStateChanges****');
        //silentLogin(context);
      }
    });

    bool needOAuth = loginType == null || loginType == LoginType.google || loginType == LoginType.facebook;
    bool oAuthLoggedIn = loginType == LoginType.google && googleSignIn.currentUser != null ||
        loginType == LoginType.facebook && facebookAccessToken != null;

    if (firebaseInitialized && (!needOAuth || (triedSilentLogin && oAuthLoggedIn))) {
      return Scaffold(body:
      FutureBuilder<Authentication>(
          future: getAuthentication(),
          builder: (context, AsyncSnapshot<Authentication> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return buildShowVersion('login progress');
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              Authentication auth = snapshot.data;
              if (auth.status == 'error') {
                logout(null);
                return SizedBox();
              }
              KeyValue authKeyValue = KeyValue(key: 'userAuth', value: auth.data.authToken);
              locator<ChatDatabase>().upsertKeyValue(authKeyValue);
              user = auth.data.me;
              if (needOAuth) {
                if (user.avatarETag == null) {
                  String avatarUrl;
                  if (loginType == LoginType.google)
                    avatarUrl = googleSignIn.currentUser.photoUrl;
                  else if (loginType == LoginType.facebook)
                    avatarUrl = facebookUserData['picture']['data']['url'];
                  getUserService().setAvatar(avatarUrl, auth);
                }
                if (user.username == null || user.username.isEmpty) { // some case username == null, and it's problem.
                  getUserService().usersUpdate(user.id, auth, username: user.id);
                }
              }

              loadCustomEmojis(auth);

              registerToken(auth);
              var _np = notificationPayload;
              notificationPayload = null;
              Future.delayed(Duration.zero, () {
                if (chatHomeStateKey.currentState != null && chatHomeStateKey.currentState.mounted)
                  return SizedBox();
                var ji = joinInfo;
                joinInfo = null;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
                    ChatHome(key: chatHomeStateKey, joinInfo: ji, user: user, authRC: auth, payload: _np,)));
              });
              return buildShowVersion('login completed');
            } else {
              return buildShowVersion('connecting');
            }
          }));
    } else
      return Scaffold(body: FutureBuilder<String>(
          future: Future.delayed(Duration(seconds: 5), () {
            return '';
          }),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.done)
              return buildOAuthLoginPage();
            else
              return buildShowVersion('login started');
          }));
  }

  buildShowVersion(String status) {
    return Container(color: Colors.white, child:
    Center(child: Wrap(children: [Column(children: [
      Image.asset('assets/images/logo.png', height: 150, fit: BoxFit.fitHeight,),
      SizedBox(height: 50,),
      SizedBox(height: 50, child: Column(children: [
        Text('SuperChat $version($buildNumber)' + (kDebugMode ? ' - debug' : ''), style: TextStyle(fontSize: 10, color: Colors.blueAccent),),
        Text('$status', style: TextStyle(fontSize: 8, color: Colors.deepOrange)),
      ])),
    ])])));
  }

  Scaffold buildOAuthLoginPage() {
    return Scaffold(
        body:
        Container(color: Colors.white, child:
        Center(child: Wrap(children: [Column(children: [
          Image.asset('assets/images/logo.png', height: 150, fit: BoxFit.fitHeight,),
          SizedBox(height: 50,),
          GestureDetector(
            onTap: googleLogin,
            child: Image.asset(
              "assets/images/google_signin_button.png",
              width: 225.0,
              height: 50,
              fit: BoxFit.fitWidth,
            ),
          ),
          SizedBox(height: 15,),
          GestureDetector(
            onTap: facebookLogin,
            child: Image.asset(
              "assets/images/facebook_signin_button.png",
              width: 225.0,
              height: 50,
              fit: BoxFit.fitWidth,
            ),
          )
        ])]))));
  }

  Future<void> loadCustomEmojis(Authentication authRC) async {
    var lastUpdate = await locator<ChatDatabase>().getValueByKey(lastUpdateCustomEmoji);
    DateTime updateSince;
    if (lastUpdate != null)
      updateSince = DateTime.tryParse(lastUpdate.value);
    RC.CustomEmojiResponse r = await getEtcService().getCustomEmojiList(authRC, updatedSince: updateSince);
    if (!r.success)
      return;
    List<RC.CustomEmoji> update = r.emojis.update;
    List<RC.CustomEmoji> remove = r.emojis.remove;

    for (var e in update)
      await locator<ChatDatabase>().upsertCustomEmoji(CustomEmoji(id: e.id, info: jsonEncode(e.toMap())));
    for (var e in remove)
      await locator<ChatDatabase>().deleteCustomEmoji(e.id);
    if (update.length > 0 || remove.length > 0)
      await locator<ChatDatabase>().upsertKeyValue(KeyValue(key: lastUpdateCustomEmoji, value: DateTime.now().toIso8601String()));

    List<CustomEmoji> dbCustomEmojis = await locator<ChatDatabase>().getAllCustomEmojis;

    //Logger().e('update=${update.length}, remove=${remove.length}, db=${dbCustomEmojis.length}');

    for (var e in dbCustomEmojis) {
      RC.CustomEmoji r = RC.CustomEmoji.fromMap(jsonDecode(e.info));
      customEmojis[':${r.name}:'] = '/${r.name}.${r.extension}';
    }
  }

}

Future<void> logout(Authentication authRC) async {
  if (loginType == LoginType.google) {
    if (await googleSignIn.isSignedIn()) {
      print('sign out!');
      try {
        await googleSignIn.signOut();
        await authFirebase.signOut();
        await googleSignIn.disconnect();
      } catch (e) {
        print("signout error=$e");
      }
    }
  } else if (loginType == LoginType.facebook) {
    await FacebookAuth.instance.logOut();
    facebookAccessToken = null;
  }

  loginType = null;
  authTokenPrevious = null;
  if (authRC != null)
    await getAuthenticationService().logout(authRC);
  await locator<ChatDatabase>().deleteAllTables();
  Future.delayed(Duration.zero, () => navGlobalKey.currentState.pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false));
  //navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome()), (route) => false);
}



/*
categoryConvert(unicodeToName, Map<String, String> cat, String name) {
  int count = 0;
  String names = 'final Map<String, String> $name = Map.fromIterables([';
  String codes = '[';
  for (String unicode in cat.values) {
    if (unicodeToName.containsKey(unicode)) {
      //print(unicode + ' ' + unicodeToName[unicode]);
      names += "'${unicodeToName[unicode]}',";
      codes += "'$unicode',";
      count++;
    }
  }
  names += ']';
  codes += ']);';
  log('$names, $codes');
}

emojiConvert() {
  Map<String, String> unicodeToName = Map<String, String>();
  for (var e in emojis.entries) {
    unicodeToName[e.value] = e.key;
  }

  categoryConvert(unicodeToName, epf.smileys, 'smileys');
  categoryConvert(unicodeToName, epf.activities, 'activities');
  categoryConvert(unicodeToName, epf.animals, 'animals');
  categoryConvert(unicodeToName, epf.flags, 'flags');
  categoryConvert(unicodeToName, epf.foods, 'foods');
  categoryConvert(unicodeToName, epf.objects, 'objects');
  categoryConvert(unicodeToName, epf.symbols, 'symbols');
  categoryConvert(unicodeToName, epf.travel, 'travel');
}
*/