import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBA;
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:rocket_chat_connector_flutter/models/user.dart' as rocket_user;
import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/services/user_service.dart';

import 'package:rocket_chat_connector_flutter/services/push_service.dart';
import 'package:rocket_chat_connector_flutter/models/new/token_new.dart';

import 'chathome.dart';
import 'constants/constants.dart';
import 'database/chatdb.dart';

import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';

import 'model/join_info.dart';

final String serverUrl = "https://chat.smallet.co";
final String username = "support@semaphore.kr";
//final String username = "changlee99@gmail.com";
final String password = "enter99!";
final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(Uri.parse(serverUrl));

final authFirebase = FBA.FirebaseAuth.instance;
final googleSignIn = GoogleSignIn(scopes: ['https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/userinfo.profile']);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final navGlobalKey = new GlobalKey<NavigatorState>();
String notificationPayload;

GetIt locator = GetIt.instance;

double textScaleFactor = 1.0;

String version;
String buildNumber;

bool googleSignInMode;

void main() async {
  //emojiConvert();
  print('***** main start');
  setServerUri(serverUri);
  await setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    googleSignInMode = true;
    await _initNotification();
  } else {
    googleSignInMode = false;
  }
  await packageInfo();
  runApp(MainHome());
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

androidNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
      'Super Chat', 'Super Chat', 'Super Chat',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false);
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  String _payload;
  if (message.data['ejson'] != null)
    _payload = message.data['ejson'];
  if (flutterLocalNotificationsPlugin != null)
    await flutterLocalNotificationsPlugin.show(
        0, message.data['title'], message.data['message'], platformChannelSpecifics, payload: _payload);
}

GlobalKey<ChatHomeState> chatHomeStateKey = GlobalKey();
Future<void> _onSelectNotification(String payload) async {
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
        chatHomeStateKey.currentState.notificationController.sink.add(rocket_notification.Notification(msg: 'request_close', collection: _rid));
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

// http://localhost:5000/#/join?invite=5nKTZG&joincode=bbbb
class Routes {
  static String root = "/";
  static String demoSimple = "/join";
  static String demoSimpleFixedTrans = "/demo/fixedtrans";
  static String demoFunc = "/demo/func";
  static String deepLink = "/message";

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
          print("ROUTE WAS NOT FOUND !!!");
          return;
        });
    router.define(root, handler: rootHandler);
    router.define(demoSimple, handler: joinRoomHandler);
    router.define(demoSimpleFixedTrans,
        handler: joinRoomHandler, transitionType: TransitionType.inFromLeft);
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

JoinInfo joinInfo;
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

class _LoginHomeState extends State<LoginHome> {
  bool triedSilentLogin = false;
  bool setupNotifications = false;
  bool firebaseInitialized = false;

  String firebaseToken;

  @override
  void initState() {
    Logger().w('+++++++++++@@@@@@+++++++++LoginHome title=${widget.title}');
    super.initState();
    initializeFlutterFire().then((_) {
      setState(() {
        firebaseInitialized = true;
        print("!!!!!!!!!!!!!!! initializeFlutterFire done");
      });
    });
  }

  Future<Null> _ensureLoggedIn(BuildContext context) async {
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
      var ss = user.email.split("@");
      UserNew userNew = UserNew(username: ss[0], name: user.displayName, email: user.email, pass: user.id);
      rocket_user.User userRC = await UserService(rocketHttpService).register(userNew);
      print("user=" + userRC.toString());
    }
  }

  Future<Null> _silentLogin(BuildContext context) async {
    GoogleSignInAccount user = googleSignIn.currentUser;

    print('!!!!_silent login1=${user==null}');
    if (user == null)
      user = await googleSignIn.signInSilently();
    print('!!!!_silent login2=${user==null}, ${authFirebase.currentUser==null}');

    /*
    if (authFirebase.currentUser == null && user != null) {
      print('!!!!try silent login');
      final GoogleSignInAccount googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      FBA.GoogleAuthCredential credential = FBA.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await authFirebase.signInWithCredential(credential);
    } else {
      print('!!!!_silent login4=${user==null}, ${authFirebase.currentUser==null}');
    }
    */
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
    final AuthenticationService authenticationService = AuthenticationService(rocketHttpService);
    print('getAuthentication1');
    if (googleSignInMode) {
      final GoogleSignInAccount googleSignInAccount = await googleSignIn.signInSilently();
      print('getAuthentication2');
      GoogleSignInAuthentication acc = await googleSignInAccount.authentication;
      print('getAuthentication3');
      return await authenticationService.loginGoogle(acc.accessToken, acc.idToken);
    } else {
      return await authenticationService.login(username, password);
    }
  }

  registerToken(Authentication _auth) async {
    PushService pushService = PushService(rocketHttpService);
    TokenNew tokenNew = TokenNew(type: "gcm", value: firebaseToken, appName: "co.smallet.superchat");
    String result = await pushService.pushToken(tokenNew, _auth);
    //print('push result' + result);
  }


  void login() async {
    await _ensureLoggedIn(context);
    setState(() {
      print("!!!!!!!!!!!!!!! login setstate");
      triedSilentLogin = true;
    });
  }

  void silentLogin(BuildContext context) async {
    print('!!!!!silentLogin1');
    await _silentLogin(context);
    setState(() {
      print("!!!!!!!!!!!!!!! silentLogin setstate");
      triedSilentLogin = true;
    });
  }

  String loginStatus = '...';
  GlobalKey loginStatusKey = GlobalKey();
  void showLoginStatus(String s) {
/*
    if (loginStatusKey.currentState == null)
      return;
    loginStatusKey.currentState.setState(() {
      loginStatus = s;
    });
*/
  }


  @override
  Widget build(BuildContext context) {
    rocket_user.User user;

    textScaleFactor = MediaQuery.of(context).textScaleFactor;
    print('===text scale factor = $textScaleFactor');

    if (!firebaseInitialized) {
      print('!firebaseInitialized----------------------');
      return Container(color: Colors.white);
    }

    if (googleSignInMode && triedSilentLogin == false) {
      silentLogin(context);
    }

    authFirebase.authStateChanges().listen((event) {
      if (event == null) {
        print('****authFirebase.authStateChanges****');
        //silentLogin(context);
      }
    });

    if (firebaseInitialized && (!googleSignInMode || (triedSilentLogin && googleSignIn.currentUser != null))) {
      if (googleSignInMode)
        print("******************googleid=" + googleSignIn.currentUser.id);
      showLoginStatus('google login complete');
      return Scaffold(body:
        FutureBuilder<Authentication>(
          future: getAuthentication(),
          builder: (context, AsyncSnapshot<Authentication> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              showLoginStatus('waiting chat server login');
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              Authentication auth = snapshot.data;
              user = auth.data.me;
              if (googleSignInMode) {
                if (user.avatarETag == null) {
                  String avatarUrl = googleSignIn.currentUser.photoUrl;
                  UserService(rocketHttpService).setAvatar(avatarUrl, auth);
                }
              }

              registerToken(auth);
              var _np = notificationPayload;
              notificationPayload = null;
              Future.delayed(Duration.zero, () {
                if (chatHomeStateKey.currentState != null && chatHomeStateKey.currentState.mounted)
                  return SizedBox();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
                    ChatHome(key: chatHomeStateKey, joinInfo: joinInfo, user: user, authRC: auth, payload: _np,)));
              });
              return SizedBox();
            } else {
              return buildShowVersion();
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
            return buildShowVersion();
        }));
  }

  buildShowVersion() {
    return Container(color: Colors.white, child:
      Center(child: Wrap(children: [Column(children: [
        Image.asset('assets/images/logo.png', height: 150, fit: BoxFit.fitHeight,),
        SizedBox(height: 50,),
        SizedBox(height: 50, child: Column(children: [
          Text('SuperChat $version($buildNumber)', style: TextStyle(fontSize: 10, color: Colors.blueAccent),),
          Text('$loginStatus', key: loginStatusKey),
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
          onTap: login,
          child: Image.asset(
            "assets/images/google_signin_button.png",
            width: 225.0,
            height: 50,
            fit: BoxFit.contain,
          ),
        )
      ])]))));
  }

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