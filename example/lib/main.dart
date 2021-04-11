import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBA;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initNotification();
  runApp(SuperChat());
}

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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  _androidNotification(message);

  print("Handling a background message: ${message.data}");
}

_androidNotification(RemoteMessage message) async {
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
  navGlobalKey.currentState.push(MaterialPageRoute(builder: (context) => LoginHome()));
  notificationPayload = payload;
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
  notificationPayload = null;

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

    return MaterialApp(
      title: title,
      navigatorKey: navGlobalKey,
      home: MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  const MainHome({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MainHome();
  }
}

class _MainHome extends State<MainHome> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Chat',
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

    if (user == null) {
      user = await googleSignIn.signInSilently();
    }

    if (authFirebase.currentUser == null && user != null) {
      final GoogleSignInAccount googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      FBA.GoogleAuthCredential credential = FBA.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await authFirebase.signInWithCredential(credential);

    }
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

      Fluttertoast.showToast(
          msg: message.data['title'],
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

      _androidNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    return app;
  }

  Future<Authentication> getAuthentication() async {
    final AuthenticationService authenticationService = AuthenticationService(rocketHttpService);
    GoogleSignInAuthentication acc = await googleSignIn.currentUser.authentication;
    return await authenticationService.loginGoogle(acc.accessToken, acc.idToken);
    //return await authenticationService.login(username, password);
  }

  registerToken(Authentication _auth) async {
    PushService pushService = PushService(rocketHttpService);
    TokenNew tokenNew = TokenNew(type: "gcm", value: firebaseToken, appName: "co.smallet.superchat");
    String result = await pushService.pushToken(tokenNew, _auth);
    print('push result' + result);
  }


  void login() async {
    await _ensureLoggedIn(context);
    setState(() {
      print("!!!!!!!!!!!!!!! login setstate");
      triedSilentLogin = true;
    });
  }

  void silentLogin(BuildContext context) async {
    await _silentLogin(context);
    setState(() {
      print("!!!!!!!!!!!!!!! silentLogin setstate");
      triedSilentLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    rocket_user.User user;

    if (triedSilentLogin == false) {
      silentLogin(context);
    }

    if (!firebaseInitialized) return CircularProgressIndicator();

    authFirebase.authStateChanges().listen((event) {
      if (event == null) {
        //silentLogin(context);
      }
    });

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
              return Center(child: CircularProgressIndicator());
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
      setState(() {
        print("!!!!!!!!!!!!!!! initializeFlutterFire setstate");
        firebaseInitialized = true;
      });
      debugPrint("inited flutter fire...");
    });
  }

}

