import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:ss_image_editor/common/image_picker/image_picker.dart';
import 'chathome.dart';
import 'chatitemview.dart';
import 'image_file_desc.dart';
import 'constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;

class ChatView extends StatefulWidget {
  final StreamController<rocket_notification.Notification> notificationController;
  final Authentication authRC;
  final model.Room room;
  final User me;
  final dynamic sharedObject;
  final ChatHomeState chatHomeState;

  ChatView({Key key, @required this.chatHomeState, @required this.notificationController, @required this.authRC, @required this.room, @required this.me, this.sharedObject }) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class ChatDataStore {
  final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
  List<ChatItemData> _chatData = [];
  Map<String, User> _userInfos = Map();

  get length => _chatData.length;

  add(ChatItemData data, Authentication authentication) async {
    _chatData.add(data);

    Message message = data.message;
    await updateUserInfo(message.user.id, authentication);
  }

  updateUserInfo(String userId, Authentication authentication) async {
    if (!_userInfos.containsKey(userId)) {
      User userInfo = await UserService(rocketHttpService).getUserInfo(UserIdFilter(userId), authentication);
      print('@@@@ userInfo=${userInfo.avatarUrl}');
      _userInfos[userId] = userInfo;
    }
  }

  bool containsMessage(String messageId) {
    return _chatData.indexWhere((element) => element.message.id == messageId) >= 0;
  }

  insertAt(int index, ChatItemData data) {
    _chatData.insert(index, data);
  }

  removeAt(int index) {
    _chatData.removeAt(index);
  }

  getMessageAt(int index) {
    return _chatData[index].message;
  }

  replaceMessage(int index, Message message) {
    _chatData[index].message = message;
  }

  int findIndexByMessageId(String messageId) {
    int i = _chatData.indexWhere((element) => element.message.id == messageId);
    return i;
  }

  GlobalKey<ChatItemViewState> getGlobalKey(int index) {
    return _chatData[index].key;
  }

  sortMessagesByTimeStamp() {
    _chatData.sort((b, a) {
      return a.message.ts.compareTo(b.message.ts);
    });
  }
}

class ChatItemData {
  GlobalKey<ChatItemViewState> key;
  Message message;
  ChatItemData(this.key, this.message);
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  TextEditingController _teController = TextEditingController();
  int chatItemOffset = 0;
  final int chatItemCount = 50;

  ChatDataStore chatDataStore = ChatDataStore();
  bool historyEnd = false;
  final picker = ImagePicker();

  final _scrollController = ScrollController();

  bool updateAll = false;
  bool needScrollToBottom = false;
  bool showEmojiKeyboard = false;
  FocusNode myFocusNode;

  GlobalKey<_UserTypingState> userTypingKey = GlobalKey();
  GlobalKey<_ChatViewState> chatViewKey = GlobalKey();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('+++++==== ChatView state=$state');
  }

  @override
  void initState() {
    subscribeRoomEvent(widget.room.id);

    updateAll = true;
    myFocusNode = FocusNode();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus & showEmojiKeyboard) {
        setState(() {
          showEmojiKeyboard = false;
        });
      }
    });

    widget.notificationController.stream.listen((event) {
      if (event.msg == 'request_close') {
        if (this.mounted)
          Navigator.pop(context, null);
        return;
      }
      if (event.msg == 'changed' && this.mounted) {
        if (event.collection == 'stream-room-messages') {
          if (event.notificationFields.notificationArgs.length > 0) {
            var arg = event.notificationFields.notificationArgs[0];
            print('+++++stream-room-messages:' + jsonEncode(arg));
            Message roomMessage = Message.fromMap(arg);
            //print(jsonEncode(roomMessage));
            int i = chatDataStore.findIndexByMessageId(roomMessage.id);
            if (i >= 0) {
              GlobalKey<ChatItemViewState> keyChatItem = chatDataStore.getGlobalKey(i);
              keyChatItem.currentState.setNewMessage(roomMessage);
              chatDataStore.replaceMessage(i, roomMessage);
              userTypingKey.currentState.setTypingUser('');
            } else {  // new message
              setState(() {
                print('!!!new message');
                needScrollToBottom = true;
                chatDataStore.insertAt(0, ChatItemData(GlobalKey(), roomMessage));
              });
              userTypingKey.currentState.setTypingUser('');
            }
          }
        } else if (event.collection == 'stream-notify-room') {
          if (event.notificationFields != null && event.notificationFields.eventName.endsWith('deleteMessage')) {
            if (event.notificationFields.notificationArgs.length > 0) {
              var arg = event.notificationFields.notificationArgs[0];
              Message roomMessage = Message.fromMap(arg);
              int i = chatDataStore.findIndexByMessageId(roomMessage.id);
              if (i >= 0) {
                print('---deleted message=${roomMessage.id}, index=$i');
                chatDataStore.removeAt(i);
                setState(() {
                  needScrollToBottom = false;
                });
              }
            }
          } else if (event.notificationFields != null && event.notificationFields.eventName.endsWith('typing')) {
            if (event.notificationFields.notificationArgs.length > 0) {
              var arg = event.notificationFields.notificationArgs[0];
              userTypingKey.currentState.setTypingUser(arg);
            }
          }
        } else if (event.collection == 'stream-notify-logged') {
          if (event.notificationFields.notificationArgs.length > 0) {
            var eventName = event.notificationFields.eventName;
            print('+++++stream-notify-logged:' + eventName);
            if (eventName == 'updateAvatar') {
              clearImageCacheAndUpdateAll();
            }
          }
        } else if (event.collection == 'stream-notify-user') {
          if (event.notificationFields.notificationArgs.length > 0) {
            var arg = event.notificationFields.notificationArgs[0];
            print('+++++stream-notify-user:' + jsonEncode(arg));
            if (event.notificationFields.eventName.endsWith('rooms-changed')) {
            }
          }
        }
      }
    });

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sharedObject != null) {
        if (widget.sharedObject is String)
          _postMessage(widget.sharedObject);
        else if (widget.sharedObject is List<SharedMediaFile>) {
          List<SharedMediaFile> mediaFiles = widget.sharedObject;
          if (mediaFiles.isNotEmpty) {
            File f = File(mediaFiles.first.path);
            postImage(f, null);
          }
        }
      }
    });
  }

  clearImageCacheAndUpdateAll() async {
    print('@@@@@ avatar changed deleteing cache');
    imageCache.clear();
    imageCache.clearLiveImages();
    print('@@@@@ avatar changed deleteing cache done~~~~~');
    //setState(() {});
    chatViewKey.currentContext ?? Phoenix.rebirth(chatViewKey.currentContext);
  }

  @override
  void dispose() {
    unsubscribeRoomEvent(widget.room.id);
    _teController.dispose();
    _scrollController.dispose();
    myFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.room.id;
    if (widget.room.name != null)
      title = widget.room.name;
    else if (widget.room.usernames != null)
      title = widget.room.usernames.toString();

    print('~~~ chatview building=$title');

    return Phoenix(child: Scaffold(
      key: chatViewKey,
      resizeToAvoidBottomInset: true,
      extendBody: false,
      bottomNavigationBar:
        Container(color: Colors.blue.shade100, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
          UserTyping(key: userTypingKey),
          Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(height: 50, color: Colors.white, child: _buildInputBox())
          ),
          showEmojiKeyboard && MediaQuery.of(context).viewInsets.bottom == 0 ? Container(
          height: 240,
          child:
          epf.EmojiPicker(
            onEmojiSelected: (category, emoji) {
              print(emoji);
              _teController.text += emoji.emoji;
              _teController.selection = TextSelection.fromPosition(TextPosition(offset: _teController.text.length));
            },
            config: epf.Config(
                columns: 7,
                emojiSizeMax: 26.0,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: epf.Category.RECENT,
                bgColor: Color(0xFFF2F2F2),
                indicatorColor: Colors.blue,
                iconColor: Colors.grey,
                iconColorSelected: Colors.blue,
                progressIndicatorColor: Colors.blue,
                showRecentsTab: true,
                recentsLimit: 28,
                noRecentsText: "No Recents",
                noRecentsStyle: const TextStyle(fontSize: 20, color: Colors.black26),
                categoryIcons: const epf.CategoryIcons(),
                buttonMode: epf.ButtonMode.MATERIAL
            ),
          )
          )
          : SizedBox(height: 0,),
        ])),
      body:
        FutureBuilder(
        future: () {
          print('@@@@@@ call future _getChannelMessages @@@@@@');
          return _getChannelMessages(chatItemCount, chatItemOffset, updateAll, needScrollToBottom);
        } (),
        builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
          print('~~~~~~~~ builder update=${snapshot.hasData}');
          print('~~~~~~~~ builder chatDataStore.length=${chatDataStore.length}');
          if (snapshot.connectionState == ConnectionState.done) {
            print('~~~~~~~~ builder connectionState.done');
            markAsReadScheduler();
            if (needScrollToBottom) {
              Future.delayed(const Duration(milliseconds: 300), () {
                scrollToBottom();
              });
            }
            updateAll = false;
            needScrollToBottom = false;
          }
          if (snapshot.hasData) {
            return NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                if (notification.metrics.atEdge) {
                  print("listview Scrollend" + notification.metrics.pixels.toString());
                  if (!historyEnd && notification.metrics.pixels != 0.0) { // bottom
                    setState(() {
                      updateAll = true;
                      chatItemOffset += chatItemCount;
                    });
                  }
                }
                return true;
              },
              child: Container(color: Colors.blue.shade100,
                child: CustomScrollView(
                controller: _scrollController,
                reverse: true,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                      Message message = chatDataStore.getMessageAt(index);
                      return Container(
                        //child: _buildChatItem(message, index),
                        child: ChatItemView(chatHomeState: widget.chatHomeState, key: chatDataStore.getGlobalKey(index), message: message, index: index, me: widget.me, authRC: widget.authRC, ),
                      );
                    },
                    childCount: chatDataStore.length,
                  )
                ),
                SliverAppBar(
                  title: Text(title),
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      background: ExtendedImage.network(serverUri.replace(path: '/avatar/room/${widget.room.id}', query: 'format=png').toString(),
                        fit: BoxFit.cover,
                      )),
                ),
            ])));
          } else
            return SizedBox();
        }
      )
    ));
  }

  _buildInputBox() {
    return Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        child:
        Row(children: <Widget>[
          InkWell(
            onTap: () {
              setState(() {
                showEmojiKeyboard = !showEmojiKeyboard;
              });
              if (showEmojiKeyboard)
                SystemChannels.textInput.invokeMethod('TextInput.hide');
              else {
                myFocusNode.requestFocus();
                SystemChannels.textInput.invokeMethod('TextInput.show');
              }
            },
            child: showEmojiKeyboard ?
            Icon(Icons.keyboard, color: Colors.blueAccent, size: 40,) :
            Icon(Icons.face_rounded, color: Colors.blueAccent, size: 40,),
          ),
          Expanded(child:
          Form(
            child: TextFormField(
              autofocus: false,
              focusNode: myFocusNode,
              controller: _teController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(hintText: 'New message', border: InputBorder.none, contentPadding: EdgeInsets.only(left: 5)),
            ),
          )),
          PopupMenuButton(
            offset: const Offset(0, -160),
            child: Icon(Icons.add, color: Colors.blueAccent, size: 40),
            onSelected: (value) {
              if (value == 'pick_image')
                _pickImage();
              else if (value == 'take_photo')
                _takePhoto();
            },
            itemBuilder: (context){
              return [
                PopupMenuItem(child: Text("Pick Image..."), value: 'pick_image',),
                PopupMenuItem(child: Text("Take Photo..."), value: 'take_photo',),
              ];
          }),
          Container(
              margin: EdgeInsets.only(left: 10),
              child:
              InkWell(
                onTap: () {_postMessage(_teController.text);},
                child: Icon(Icons.send, color: Colors.blueAccent, size: 40,),
              )),
        ])
    );
  }


  Future<void> _postMessage(String message) async {
    if (message != null && message.isNotEmpty) {
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(roomId: widget.room.id, text: message);
      MessageNewResponse respMsg = await messageService.postMessage(msg, widget.authRC);
      _teController.text = '';
    }
  }

  Future<void> _pickImage({imageSource}) async {
    var pickedFile;
    if (imageSource != null)
      pickedFile = await picker.getImage(source: imageSource);
    else
      pickedFile = await pickImage(context, fileResult: true);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      ImageFileData data = await Navigator.push(context, MaterialPageRoute(builder: (context) => ImageFileDescription(file: file)));
      if (data != null) {
        if (data.description != null && data.description == '')
          data.description = null;
        file = File(data.filePath);
        Message newMessage = await postImage(file, data.description);
      }
    } else {
      print('No image selected.');
    }
  }

  Future<Message> postImage(File file, String desc) {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    MessageService messageService = MessageService(rocketHttpService);
    return messageService.roomImageUpload(widget.room.id, widget.authRC, file, desc: desc);
  }

  Future<void> _takePhoto() async {
    _pickImage(imageSource: ImageSource.camera);
  }

  static int historyCallCount = 0;
  Future<ChannelMessages> _getChannelMessages(int count, int offset, bool _updateAll, bool _scrollToBottom) async {
    print('!!!!!! get room history bUpdateAll=$_updateAll');
    if (_updateAll) {
      historyCallCount++;
      print('full history call=$historyCallCount');
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      ChannelService channelService = ChannelService(rocketHttpService);
      ChannelHistoryFilter filter = ChannelHistoryFilter(roomId: widget.room.id, count: count, offset: offset);
      ChannelMessages channelMessages = await channelService.roomHistory(filter, widget.authRC, widget.room.t);
      print('_getChannelMessages return1 _updateAll=$_updateAll');
      if (channelMessages.messages.length <= 0)
        historyEnd = true;
      else {
        for (Message m in channelMessages.messages)
          if (!chatDataStore.containsMessage(m.id))
            await chatDataStore.add(ChatItemData(GlobalKey(), m), widget.authRC);
        chatDataStore.sortMessagesByTimeStamp();
      }
      return ChannelMessages(success: true);
    } else {
      print('_getChannelMessages return2 _updateAll=$_updateAll');
      return ChannelMessages(success: true);
    }
  }

  scrollToBottom() {
    if (_scrollController.hasClients) {
      print('scroll to bottom!!!');
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Queue<String> taskQ = Queue<String>();
  markAsReadScheduler() {
    if (taskQ.isNotEmpty)
      return;
    taskQ.add('job');
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (taskQ.isNotEmpty) {
        await markAsRead();
        taskQ.removeFirst();
      }
    });
  }

  Future<void> markAsRead() async {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    ChannelService channelService = ChannelService(rocketHttpService);
    await channelService.markAsRead(widget.room.id, widget.authRC);
    debugPrint("----------- mark channel(${widget.room.id}) as read");
  }
}

class UserTyping extends StatefulWidget {
  UserTyping({Key key}) : super(key: key);

  @override
  _UserTypingState createState() => _UserTypingState();
}

class _UserTypingState extends State<UserTyping> {
  String typing = '';
  Timer t;

  double _width = 200;
  Color _color = Colors.white;

  @override
  void initState() {
    super.initState();
  }

  setTypingUser(String userName) {
    print('---typing user=$userName');
    setState(() {
      if (t != null) {
        t.cancel();
        t = null;
      }
      typing = userName;
    });
    if (userName != '') {
      t = Timer(Duration(seconds: 7), () {
        setState(() {
          typing = '';
        });
      });
      Timer(Duration(seconds: 1), () {
        setState(() {
          _width = _width == 200 ? 150 : 200;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return typing != '' ?
        AnimatedContainer(
          alignment: Alignment.center,
          margin: EdgeInsets.only(bottom: 5),
          curve: Curves.fastOutSlowIn,
          duration: Duration(seconds: 1),
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _color,
            border: Border.all(color: Colors.blueAccent, width: 0),
            borderRadius: BorderRadius.all(
                Radius.circular(2.0) //                 <--- border radius here
            ),
          ),
          width: _width,
          child:Text('$typing typing...', style: TextStyle(fontSize: 10),)
        )
        : SizedBox();
  }
}


