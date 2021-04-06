import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBA;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart'
    as rocket_http_service;
import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart'
    as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_list_response.dart';

import 'package:rocket_chat_connector_flutter/services/push_service.dart';
import 'package:rocket_chat_connector_flutter/models/new/token_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SuperChat());
}

final String serverUrl = "https://chat.smallet.co";
final String webSocketUrl = "wss://chat.smallet.co/websocket";
final String username = "support@semaphore.kr";
//final String username = "changlee99@gmail.com";
final String password = "enter99!";
final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(Uri.parse(serverUrl));

final authFirebase = FBA.FirebaseAuth.instance;
final googleSignIn = GoogleSignIn();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.data}");
}

class SuperChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'Super Chat';

    return MaterialApp(
      title: title,
      home: MainHome(),
    );
  }
}

class MainHome extends StatelessWidget {
  // Define an async function to initialize FlutterFire

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttergram',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
          primarySwatch: Colors.blue,
          buttonColor: Colors.pink,
          primaryIconTheme: IconThemeData(color: Colors.black)),
      home: LoginHome(title: 'Super Chat'),
    );
  }
}

class LoginHome extends StatefulWidget {
  final String title;

  LoginHome({Key key, @required this.title}) : super(key: key);

  @override
  _LoginHomeState createState() => _LoginHomeState();
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

      await authFirebase.signInWithCredential(credential);
    }

    if (user != null) {
      var ss = user.email.split("@");
      UserNew userNew = UserNew(username: ss[0], name: user.displayName, email: user.email, pass: user.id);
      User userRC = await UserService(rocketHttpService).register(userNew);
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    WebSocketChannel webSocketChannel;
    WebSocketService webSocketService = WebSocketService();
    User user;

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
              webSocketChannel = webSocketService.connectToWebSocket(webSocketUrl, snapshot.data);
              webSocketService.streamNotifyUserSubscribe(webSocketChannel, user);

              registerToken(auth);
              return ChatHome(title: 'Super Chat', webSocketChannel: webSocketChannel, webSocketService: webSocketService, user: user, authRC: auth);
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

class ChatHome extends StatefulWidget {
  final String title;
  final WebSocketChannel webSocketChannel;
  final WebSocketService webSocketService;
  final User user;
  final Authentication authRC;

  ChatHome({Key key, @required this.title, @required this.webSocketChannel, @required this.webSocketService, @required this.user, @required this.authRC}) : super(key: key);

  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  TextEditingController _controller = TextEditingController();
  int _selectedPage = 0;

  Channel channel = Channel(id: "myChannelId");
  Room room = Room(id: "myRoomId");

  bool firebaseInitialized = false;

  int chattingCount = 20;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
            StreamBuilder(
              stream: widget.webSocketChannel.stream,
              builder: (context, snapshot) {
                print(snapshot.data);
                rocket_notification.Notification notification = snapshot.hasData
                    ? rocket_notification.Notification.fromMap(
                        jsonDecode(snapshot.data))
                    : null;
                print(notification);
                widget.webSocketService.streamNotifyUserSubscribe(widget.webSocketChannel, widget.user);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  child: Text(
                      notification != null ? '${notification.toString()}' : ''),
                );
              },
            ),
            _buildPage(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _postMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Rooms',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatting',
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: _selectedPage,
        selectedItemColor: Colors.amber[800],
        onTap: _onBottomNaviTapped,
      ),
    );
  }

  _buildPage() {
    debugPrint("_buildPage=" + _selectedPage.toString());
    switch(_selectedPage) {
      case 0:
        return FutureBuilder<ChannelListResponse>(
          future: _getChannelList(),
          builder: (context, AsyncSnapshot<ChannelListResponse> snapshot) {
          if (snapshot.hasData) {
            ChannelListResponse r = snapshot.data;
            return Expanded(    // images
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: r.channelList.length,
                itemBuilder: (context, index)  {
                  return ListTile(
                    onTap: () { _setChannel(index, r.channelList[index]); },
                    title: Text(r.channelList[index].name, style: TextStyle(color: Colors.black45)),
                    subtitle: Text(r.channelList[index].id, style: TextStyle(color: Colors.blue)),
                    leading: const Icon(Icons.group),
                    dense: true,
                    selected: channel.id == r.channelList[index].id,
                  );
                },
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
        break;
      case 1:
        return FutureBuilder(
            future: _getChannelMessages(),
            builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
              if (snapshot.hasData) {
                List<Message> channelMessages = snapshot.data.messages;
                //channelMessages.sort((a, b) { return a.ts.compareTo(b.ts); });
                debugPrint("msg count=" + channelMessages.length.toString());
                return Expanded(
                  child: NotificationListener<ScrollEndNotification>(
                    child: ListView.builder(
                    padding: EdgeInsets.all(0.0),
                    itemExtent: 40,
                    scrollDirection: Axis.vertical,
                    itemCount: channelMessages.length,
                    reverse: true,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      Message message = channelMessages[index];
                      bool joinMessage = message.t != null && message.t == 'uj';
                      //debugPrint("msg=" + index.toString() + message.toString());
                      return Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.red)),
                      child:
                        Column(children: [
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.yellow)),
                          alignment: Alignment.centerLeft,
                          child:
                          Text(
                            message.user.username + '(' + index.toString() +')',
                            style: TextStyle(fontSize: 10, color: Colors.brown),
                            textAlign: TextAlign.left,
                          )),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.yellow)),
                          alignment: Alignment.centerLeft,
                          child:
                          Text(
                            joinMessage ? message.user.username + ' joined' : message.msg,
                            style: TextStyle(fontSize: 10, color: Colors.blueAccent),
                          ))
                        ])
                      );
                    }
                  ),
                    onNotification: (notification) {
                      print("listview Scrollend" + notification.metrics.pixels.toString());
                      if (notification.metrics.pixels != 0.0) { // bottom
                        setState(() {
                          chattingCount += 20;
                        });
                      }
                      return true;
                    },
                  ),
                );
              } else
                return Container();
            }
        );
        break;
    }
  }

  void _onBottomNaviTapped(int index) {
    debugPrint("_onBottomNaviTapped =" + index.toString());
    setState(() {
      _selectedPage = index;
    });
  }

  _setChannel(int _index, Channel _channel) {
    setState(() {
      channel = _channel;
      _selectedPage = 1;
    });
    debugPrint("channel name=" + channel.name);
  }

  _getChannelMessages() {
    ChannelService channelService = ChannelService(rocketHttpService);
    ChannelHistoryFilter filter = ChannelHistoryFilter(channel, count: chattingCount);
    Future<ChannelMessages> messages = channelService.history(filter, widget.authRC);
    return messages;
  }

  _getChannelList() {
    ChannelService channelService = ChannelService(rocketHttpService);
    Future<ChannelListResponse> respChannelList = channelService.list(widget.authRC);
    return respChannelList;
  }

  void _postMessage() {
    if (_controller.text.isNotEmpty) {
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(channel: channel.id, roomId: channel.name, text: _controller.text);
      messageService.postMessage(msg, widget.authRC);
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      widget.webSocketService.sendMessageOnChannel(_controller.text, widget.webSocketChannel, channel);
      widget.webSocketService.sendMessageOnRoom(_controller.text, widget.webSocketChannel, room);
    }
  }

  @override
  void dispose() {
    widget.webSocketChannel.sink.close();
    super.dispose();
  }
}
