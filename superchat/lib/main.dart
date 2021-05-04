import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBA;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info/package_info.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart' as rocket_user;
import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/services/user_service.dart';

import 'package:rocket_chat_connector_flutter/services/push_service.dart';
import 'package:rocket_chat_connector_flutter/models/new/token_new.dart';

import 'chathome.dart';
import 'chathome.dart';
import 'database/chatdb.dart';

import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;

final String serverUrl = "https://chat.smallet.co";
final String username = "support@semaphore.kr";
//final String username = "changlee99@gmail.com";
final String password = "enter99!";
final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(Uri.parse(serverUrl));

final authFirebase = FBA.FirebaseAuth.instance;
final googleSignIn = GoogleSignIn();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final navGlobalKey = new GlobalKey<NavigatorState>();
String notificationPayload;

GetIt locator = GetIt.instance;

String version;
String buildNumber;

void main() async {
  //emojiConvert();
  print('***** main start');
  await setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotification();
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
  locator.registerSingleton(ChatDatabase());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

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
  await flutterLocalNotificationsPlugin.show(
      0, message.data['title'], message.data['message'], platformChannelSpecifics, payload: _payload);
}

GlobalKey<ChatHomeState> chatHomeStateKey = GlobalKey();
Future<void> _onSelectNotification(String payload) async {
  print("onSelectNotification payload=$payload");
  notificationPayload = payload;
  if (!navGlobalKey.currentState.mounted)
    navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome()), (route) => false);
  else {
    var json = jsonDecode(payload);
    String _rid = json['rid'];
    if (_rid != null) {
      notificationPayload = null;
      print('**** rid= $_rid');
      if (chatHomeStateKey.currentState != null) {
        chatHomeStateKey.currentState.notificationController.sink.add(rocket_notification.Notification(msg: 'request_close'));
        chatHomeStateKey.currentState.setChannelById(_rid);
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
    notificationPayload = notificationAppLaunchDetails.payload;
    print("=============== called from notification = $notificationPayload");
  }
}

class MainHome extends StatefulWidget {
  const MainHome({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    print('***** MainHome start');
    return _MainHome();
  }
}

class _MainHome extends State<MainHome> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Chat',
      debugShowCheckedModeBanner: false,
      navigatorKey: navGlobalKey,
      theme: ThemeData.light(),
      home: LoginHome(title: 'Super Chat'),
      //home: Empty(),
    );
  }
}

class Empty extends StatefulWidget {
  @override
  _EmptyState createState() => _EmptyState();
}

class _EmptyState extends State<Empty> {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white,);
  }
}


class LoginHome extends StatefulWidget {
  LoginHome({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginHomeState createState() {
    print('_LoginHomeState createState payload=$notificationPayload');
    return _LoginHomeState();
  }
}

class _LoginHomeState extends State<LoginHome> {
  bool triedSilentLogin = false;
  bool setupNotifications = false;
  bool firebaseInitialized = false;

  String firebaseToken;

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
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    return app;
  }

  Future<Authentication> getAuthentication() async {
    final AuthenticationService authenticationService = AuthenticationService(rocketHttpService);
    print('getAuthentication1');
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signInSilently();
    print('getAuthentication2');
    GoogleSignInAuthentication acc = await googleSignInAccount.authentication;
    print('getAuthentication3');
    return await authenticationService.loginGoogle(acc.accessToken, acc.idToken);
    //return await authenticationService.login(username, password);
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

  @override
  Widget build(BuildContext context) {
    rocket_user.User user;

    if (!firebaseInitialized) {
      print('!firebaseInitialized----------------------');
      return Container(color: Colors.white);
    }

    if (triedSilentLogin == false) {
      silentLogin(context);
    }

    authFirebase.authStateChanges().listen((event) {
      if (event == null) {
        print('****authFirebase.authStateChanges****');
        //silentLogin(context);
      }
    });

    if (triedSilentLogin && firebaseInitialized && googleSignIn.currentUser != null) {
      print("******************googleid=" + googleSignIn.currentUser.id);
      return Scaffold(body:
        FutureBuilder<Authentication>(
          future: getAuthentication(),
          builder: (context, AsyncSnapshot<Authentication> snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              Authentication auth = snapshot.data;
              String avatarUrl = googleSignIn.currentUser.photoUrl;
              print("avatarUrl=" + avatarUrl);
              UserService(rocketHttpService).setAvatar(avatarUrl, auth);
              user = auth.data.me;

              registerToken(auth);
              var _np = notificationPayload;
              notificationPayload = null;
              return ChatHome(key: chatHomeStateKey, title: 'Super Chat', user: user, authRC: auth, payload: _np,);
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
        Text('SuperChat $version($buildNumber)', style: TextStyle(fontSize: 10, color: Colors.blueAccent),)
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
          ),
        )
      ])]))));
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire().then((_) {
      setState(() {
        firebaseInitialized = true;
        print("!!!!!!!!!!!!!!! initializeFlutterFire done");
      });
    });
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