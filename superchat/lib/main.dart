import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBA;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_keyboard/flutter_emoji_keyboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart' as rocket_user;
import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/services/user_service.dart';

import 'package:rocket_chat_connector_flutter/services/push_service.dart';
import 'package:rocket_chat_connector_flutter/models/new/token_new.dart';

import 'chathome.dart';
import 'database/chatdb.dart';

import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';
import 'package:flutter_emoji_keyboard/src/all_emojis.dart';

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

emojiConvert() {
/*
  Map<String, String> unicodeToName = Map<String, String>();
  for (var e in emojis.entries) {
    unicodeToName[e.value] = e.key;
  }

  int count = 0;
  var emojiList2 = <Emoji>[];
  for (var e in emojiListOrg) {
    if (unicodeToName.containsKey(e.text)) {
      //print(unicodeToName[e.text]);
      e.name = unicodeToName[e.text];
      emojiList2.add(e);
      count++;
    } else {
      //print('@@@ not found = ${e.text}');
    }
  }
  print('unicodeToName item count=${unicodeToName.length}, $count');
  emojiList = emojiList2;

  StringBuffer sb = StringBuffer();
  for (var em in emojiList2) {
    var nn = em.name;
    var tt = em.text;
    var and = '[';
    for (var aa in em.limitRangeAndroid) {
      and += "MapEntry('${aa.key}', '${aa.value}'),";
    }
    and += ']';
    var ios = '[';
    for (var aa in em.limitRangeIOS) {
      ios += "MapEntry('${aa.key}', '${aa.value}'),";
    }
    ios += ']';
    var ee = "Emoji('$nn', '$tt', ${em.category}, limitRangeAndroid: $and, limitRangeIOS: $ios),\n";
    sb.write(ee);
  }
  log(sb.toString());

  count = 0;
  for (var cat in emojisByCategory.entries) {
    String catagory = cat.key;
    var names = cat.value;
    for (var name in names) {
      var nn = ':$name:';
      print("Emoji('$nn', '${emojis[nn]}', EmojiCategory.$catagory,null, null),");
      count++;
    }
  }
  print('count=$count');
*/
}

void main() async {
  //emojiConvert();
  print('***** main start');
  await setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  _initNotification();
  runApp(Phoenix(child: SuperChat()));
}

GetIt locator = GetIt.instance;

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

Future<void> _onSelectNotification(String payload) async {
  print("onSelectNotification payload=$payload");
  //navGlobalKey.currentState.push(MaterialPageRoute(builder: (context) => LoginHome()));
  notificationPayload = payload;

  //navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainHome()), (route) => false);
  Phoenix.rebirth(navGlobalKey.currentState.context);
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

class SuperChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'Super Chat';
    print('***** SuperChat start');

    return MaterialApp(
      title: title,
      home: MainHome(),
    );
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
      navigatorKey: navGlobalKey,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          buttonColor: Colors.pink,
          primaryIconTheme: IconThemeData(color: Colors.black)),
      home: LoginHome(title: 'Super Chat'),
    );
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
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

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
      return CircularProgressIndicator(strokeWidth: 5,);
    }

    /*
    authFirebase.authStateChanges().listen((event) {
      if (event == null) {
        //silentLogin(context);
      }
    });
     */

    if (triedSilentLogin && firebaseInitialized && googleSignIn.currentUser != null) {
      print("******************googleid=" + googleSignIn.currentUser.id);
      return FutureBuilder<Authentication>(
          future: getAuthentication(),
          builder: (context, AsyncSnapshot<Authentication> snapshot) {
            if (snapshot.hasData) {
              Authentication auth = snapshot.data;
              String avatarUrl = googleSignIn.currentUser.photoUrl;
              print("avatarUrl=" + avatarUrl);
              UserService(rocketHttpService).setAvatar(avatarUrl, auth);
              user = auth.data.me;

              registerToken(auth);
              var _np = notificationPayload;
              notificationPayload = null;
              return ChatHome(title: 'Super Chat', user: user, authRC: auth, payload: _np,);
              //return Container();
            } else {
              return Center(child: CircularProgressIndicator(strokeWidth: 1,));
            }
          });
    } else
      return buildOAuthLoginPage();
  }

  Scaffold buildOAuthLoginPage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 240.0),
          child: Column(
            children: <Widget>[
              Text(
                'SuperChat',
                style: TextStyle(
                    fontSize: 60.0,
                    fontFamily: "Billabong",
                    color: Colors.black),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 100.0)),
              GestureDetector(
                onTap: login,
                child: Image.asset(
                  "assets/images/google_signin_button.png",
                  width: 225.0,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire().then((_) {
      firebaseInitialized = true;
      print("!!!!!!!!!!!!!!! initializeFlutterFire done");

      if (triedSilentLogin == false) {
        silentLogin(context);
      }
    });
  }
}


