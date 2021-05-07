import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
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
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oktoast/oktoast.dart';
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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:ss_image_editor/common/image_picker/image_picker.dart';
import 'package:superchat/database/chatdb.dart';
import 'package:superchat/main.dart';
import 'chathome.dart';
import 'chatitemview.dart';
import 'room_info.dart';
import 'update_room.dart';
import 'image_file_desc.dart';
import 'constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/sync_messages.dart';
import 'database/chatdb.dart' as db;

class ChatView extends StatefulWidget {
  final StreamController<rocket_notification.Notification> notificationController;
  final Authentication authRC;
  final model.Room room;
  final User me;
  final dynamic sharedObject;
  final ChatHomeState chatHomeState;

  ChatView({Key key, @required this.chatHomeState, @required this.notificationController, @required this.authRC, @required this.room, @required this.me, this.sharedObject }) : super(key: key);

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatDataStore {
  final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
  List<ChatItemData> _chatData = [];

  get length => _chatData.length;

  add(ChatItemData data) {
    _chatData.add(data);
  }

  bool containsMessage(String messageId) {
    return _chatData.indexWhere((element) => element.messageId == messageId) >= 0;
  }

  insertAt(int index, Message m) async {
    String info = jsonEncode(m.toMap());
    RoomMessage roomMessage = RoomMessage(rid: m.rid, mid: m.id, ts: m.ts, info: info);
    await locator<db.ChatDatabase>().upsertRoomMessage(roomMessage);
    _chatData.insert(index, ChatItemData(GlobalKey(), m.id, info, m.ts));
  }

  removeAt(int index) async {
    await locator<db.ChatDatabase>().deleteMessage(_chatData[index].messageId);
    _chatData.removeAt(index);
  }

  String getMessageIdAt(int index) {
    return _chatData[index].messageId;
  }

  Message getMessageAt(int index) {
    //print('=======chatdata $index = ${_chatData[index].info}');
    return Message.fromMap(jsonDecode(_chatData[index].info));
  }

  replaceMessage(int index, Message message) {
    String info = jsonEncode(message.toMap());
    _chatData[index].messageId = message.id;
    _chatData[index].timeStamp = message.ts;
    _chatData[index].info = info;
    RoomMessage rm = RoomMessage(rid: message.rid, ts: message.ts, mid: message.id, info: info);
    locator<db.ChatDatabase>().upsertRoomMessage(rm);
  }

  int findIndexByMessageId(String messageId) {
    int i = _chatData.indexWhere((element) => element.messageId == messageId);
    return i;
  }

  GlobalKey<ChatItemViewState> getGlobalKey(int index) {
    return _chatData[index].key;
  }

  sortMessagesByTimeStamp() {
    _chatData.sort((b, a) {
      return a.timeStamp.compareTo(b.timeStamp);
    });
  }
}

class ChatItemData {
  GlobalKey<ChatItemViewState> key;
  DateTime timeStamp;
  String messageId;
  String info;
  ChatItemData(this.key, this.messageId, this.info, this.timeStamp);
}

class ChatViewState extends State<ChatView> with WidgetsBindingObserver, TickerProviderStateMixin<ChatView>  {
  TextEditingController _teController = TextEditingController();
  int chatItemOffset = 0;
  final int chatItemCount = 50;

  ChatDataStore chatDataStore = ChatDataStore();
  bool historyEnd = false;
  final picker = ImagePicker();

  bool getMoreMessages = false;
  bool needScrollToBottom = false;
  int scrollIndex = -1;
  bool showEmojiKeyboard = false;
  FocusNode myFocusNode;

  GlobalKey<_UserTypingState> userTypingKey = GlobalKey();
  GlobalKey<ChatViewState> chatViewKey = GlobalKey();

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print('+++++==== ChatView state=$state');
    if (state == AppLifecycleState.resumed) {
      await _getChannelMessages(chatItemCount, chatItemOffset, true, syncMessages: true);
      setState(() {
        getMoreMessages = false;  // do not call future build.
      });
    }
  }

  AnimationController _hideFabAnimation;

  Future<void> sendUserTyping() async {
    webSocketService.sendUserTyping(widget.room.id, widget.me.username, true);
  }

  @override
  void initState() {
    subscribeRoomEvent(widget.room.id);

    var userTypingJob = RepeatedJobWaiter(sendUserTyping, waitingTime: 5000);
    _teController.addListener(() {
      if (_teController.text.isNotEmpty)
        userTypingJob.trigger();
    });

    _hideFabAnimation = AnimationController(vsync: this, duration: kThemeAnimationDuration);

    getMoreMessages = false;
    needScrollToBottom = true;
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
          Navigator.pop(context, event.collection);
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
              if (keyChatItem.currentState != null)
                  keyChatItem.currentState.setNewMessage(roomMessage);
              chatDataStore.replaceMessage(i, roomMessage);
              userTypingKey.currentState.setTypingUser('');
            } else {  // new message
              setState(() {
                print('!!!new message');
                needScrollToBottom = true;
                chatDataStore.insertAt(0, roomMessage);
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
              if (arg != widget.me.username)
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
    setState(() {});
    chatViewKey.currentContext ?? Phoenix.rebirth(chatViewKey.currentContext);
  }

  @override
  void dispose() {
    unsubscribeRoomEvent(widget.room.id);
    _teController.dispose();
    _hideFabAnimation.dispose();
    myFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var markAsReadJob = RepeatedJobWaiter(markAsRead);

    String title = widget.room.id;
    if (widget.room.name != null)
      title = widget.room.name;
    else if (widget.room.usernames != null)
      title = widget.room.usernames.toString();

    print('~~~ chatview building=$title');
    return Phoenix(child: Scaffold(
      floatingActionButton: Visibility(
        child: ScaleTransition(
        scale: _hideFabAnimation,
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(onPressed: (){}, backgroundColor: Colors.amber, child: UserTyping(key: userTypingKey, hideFabAnimation: _hideFabAnimation,)))),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      key: chatViewKey,
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.star_border_outlined),
            onPressed: () {
              _handleStarredMessage();
            },
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'room_info')
                roomInformation();
              else if (value == 'pin_message') {}
            },
            itemBuilder: (context){
              return [
                PopupMenuItem(child: Text("Pin Message..."), value: 'pin_message',),
                PopupMenuItem(child: Text("Room Information..."), value: 'room_info',),
              ];
              }),
        ],
      ),
      resizeToAvoidBottomInset: true,
      extendBody: false,
      bottomNavigationBar:
        Container(color: Colors.blue.shade100, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
          //UserTyping(key: userTypingKey),
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
        !getMoreMessages && (chatDataStore.length > 0) ? buildChatList() :
        FutureBuilder(
        future: () {
          print('@@@@@@ call future _getChannelMessages @@@@@@ updateAll=$getMoreMessages');
          var ua = getMoreMessages;
          getMoreMessages = false;
          if (chatDataStore.length == 0)
            ua = true;
          return _getChannelMessages(chatItemCount, chatItemOffset, ua);
        } (),
        builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
          print('~~~~~~~~ builder update=${snapshot.hasData}, con state=${snapshot.connectionState}');
          print('~~~~~~~~ builder chatDataStore.length=${chatDataStore.length}');
          if (snapshot.connectionState == ConnectionState.done) {
            print('------- builder connectionState.done needScrollToBottom=$needScrollToBottom');
            markAsReadJob.trigger();
            getMoreMessages = false;
            needScrollToBottom = false;
          }
          if (snapshot.hasData) {
            return buildChatList();
          } else {
            print('***** builder has no data');
            return SizedBox();
          }
        }
      )
    ));
  }

  Widget buildChatList() {
    if (scrollIndex >= 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        //itemScrollController.scrollTo(index: scrollIndex, duration: Duration(seconds: 1), curve: Curves.easeInOutCubic);
        print('---------->>> jumpto = $scrollIndex');
        itemScrollController.jumpTo(index: scrollIndex, alignment: 0);
        scrollIndex = -1;
      });
    }

    if (needScrollToBottom) {
      needScrollToBottom = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollToBottom();
      });
    }

    return NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if (notification.metrics.atEdge) {
            print('*****listview Scrollend = ${notification.metrics.pixels}');
            if (!historyEnd && notification.metrics.pixels != notification.metrics.minScrollExtent) { // bottom
              print('!!! scrollview hit top');
              setState(() {
                getMoreMessages = true;
                chatItemOffset += chatItemCount;
              });
            }
          }
          return true;
        },
        child: Container(color: Colors.blue.shade100,
          child:ScrollablePositionedList.builder(
          //child: ListView.builder(
            itemScrollController: itemScrollController,
            reverse: true,
            itemCount: chatDataStore.length,
            //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemBuilder: (context, index) {
              Message message = chatDataStore.getMessageAt(index);
              // return ChatItemView(chatHomeState: widget.chatHomeState, key: chatDataStore.getGlobalKey(index),
              // messageId: messageId, me: widget.me, authRC: widget.authRC, );
              return ChatItemView(chatHomeState: widget.chatHomeState, key: chatDataStore.getGlobalKey(index),
                message: message, me: widget.me, authRC: widget.authRC, index: index,);
            },
          ),
        ));
  }

  final ItemScrollController itemScrollController = ItemScrollController();
  _handleStarredMessage() async {
    String messageId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Starred Messages'),
            insetPadding: EdgeInsets.all(5),
            contentPadding: EdgeInsets.all(5),
            content: Container(height: MediaQuery.of(context).size.height * .7, width: MediaQuery.of(context).size.width, child:
              _buildStarredMessage(),
            )
          );
        }
    );
    if (messageId == null)
      return;
    print('@@@ selected message=$messageId');
    int index  = -1;
    int count = 0;

    Fluttertoast.showToast(
        msg: "Searching...",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );

    do {
      index = chatDataStore.findIndexByMessageId(messageId);
      print('@@@ selected message=$messageId, index=$index');
      chatItemOffset += chatItemCount;
      await _getChannelMessages(chatItemCount, chatItemOffset, true, syncMessages: false);
      count++;
      //await Future.delayed(Duration(seconds: 1), () {});
    } while(index < 0 && count < 100);
    if (count >= 100) {
      print('!!!!!!!!!!!!!!! not found for 100 pages');
    }
    setState(() {
      needScrollToBottom = false;
      scrollIndex = index;
    });
    Future.delayed(Duration(seconds: 1), () { Fluttertoast.cancel(); } );
  }

  _buildStarredMessage() {
    return FutureBuilder(
      future: _getStarredMessages(),
      builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
        if(snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.messages.length,
            itemBuilder: (BuildContext c, int index) {
              var message = snapshot.data.messages[index];
              return ChatItemView(chatHomeState: widget.chatHomeState, message: message, me: widget.me, authRC: widget.authRC, onTapExit: true,);
            });
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  }

  Future<ChannelMessages> _getStarredMessages() {
    return getChannelService().getStarredMessages(widget.room.id, widget.authRC);
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

  ChannelService getChannelService() {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    return ChannelService(rocketHttpService);
  }

  RoomMessage messageToRoomMessage(Message m) {
    String info = jsonEncode(m.toMap());
    return RoomMessage(rid: m.rid, mid: m.id, ts: m.ts, info: info);
  }

  static int historyCallCount = 0;
  Future<ChannelMessages> _getChannelMessages(int count, int offset, bool _getMoreMessages, { bool syncMessages = true }) async {
    print('!!!!!! get room history _getMoreMessages=$_getMoreMessages, syncMessages=$syncMessages');
    historyEnd = false;
    if (_getMoreMessages) {
      historyCallCount++;
      print('full history call=$historyCallCount');
      var lastUpdate = await locator<db.ChatDatabase>().getValueByKey(db.lastUpdateRoomMessage + widget.room.id);
      var dbHistoryReadEnd = await locator<db.ChatDatabase>().getValueByKey(db.historyReadEnd + widget.room.id);
      DateTime updateSince;
      if (lastUpdate != null)
        updateSince = DateTime.tryParse(lastUpdate.value);
      if (updateSince == null)
        _getMoreMessages = true;
      if (updateSince != null && syncMessages) {
        print('@@@ start syncMessages');
        SyncMessages syncMessages = await getChannelService().syncMessages(widget.room.id, updateSince, widget.authRC);
        if (syncMessages.success) {
          for (Message m in syncMessages.result.updated) {
            print('updated message=${m.msg}');
            locator<db.ChatDatabase>().upsertRoomMessage(messageToRoomMessage(m));
          }
          for (Message m in syncMessages.result.deleted) {
            print('deleted message=${m.msg}');
            locator<db.ChatDatabase>().deleteMessage(m.id);
          }
        }
      }
      List<RoomMessage> roomMessages;
      bool fetchFromNetwork = false;
      if (_getMoreMessages) {
        roomMessages = await locator<db.ChatDatabase>().getRoomMessages(widget.room.id, count, offset: offset);
        print('read database offset=$offset, count=$count, roomMessages.length = ${roomMessages.length}');
        if (roomMessages.length < count)
          fetchFromNetwork = true;
      }
      if (fetchFromNetwork && dbHistoryReadEnd == null) {
        ChannelHistoryFilter filter = ChannelHistoryFilter(roomId: widget.room.id, count: count, offset: offset);
        ChannelMessages channelMessages = await getChannelService().roomHistory(filter, widget.authRC, widget.room.t);
        print('@@@ fetch from network, channelMessages.messages.length = ${channelMessages.messages.length}');
        if (channelMessages.messages.length < count) {
          print('!!!!!!!!!!!!history end!!!!!!!!!!!!!! roomMessages.length = ${channelMessages.messages.length}');
          historyEnd = true;
        }
        for (Message m in channelMessages.messages) {
          var rm = messageToRoomMessage(m);
          //log('rm.info = ${rm.info}');
          locator<db.ChatDatabase>().upsertRoomMessage(rm);
        }
      }
      if (fetchFromNetwork) {
        roomMessages = await locator<db.ChatDatabase>().getRoomMessages(widget.room.id, count, offset: offset);
        print('@@@@ roomMessages.length after network fetch = ${roomMessages.length}');
      }
      if (roomMessages.length < count)
        historyEnd = true;

      await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.lastUpdateRoomMessage + widget.room.id, value: DateTime.now().toIso8601String()));
      if (historyEnd)
        await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.historyReadEnd + widget.room.id, value: 'yes'));

      for (var rm in roomMessages) {
        if (!chatDataStore.containsMessage(rm.mid)) {
          print('@@@@ add new message=${rm.info}');
          chatDataStore.add(ChatItemData(GlobalKey(), rm.mid, rm.info, rm.ts));
        }
      }
      chatDataStore.sortMessagesByTimeStamp();

      return ChannelMessages(success: true);
    } else {
      print('_getChannelMessages return2 _getMoreMessages=$_getMoreMessages');
      return ChannelMessages(success: true);
    }
  }

  scrollToBottom() {
    print('@@@@*** scroll to bottom called');
    if (itemScrollController != null)
      itemScrollController.jumpTo(index: 0);
/*
    if (_scrollController.hasClients) {
      print('scroll to bottom!!!');
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
      );
    }
*/
  }

  Future<void> markAsRead() async {
    await getChannelService().markAsRead(widget.room.id, widget.authRC);
    debugPrint("----------- mark channel(${widget.room.id}) as read");
  }

  Future<void> roomInformation() async {
    var ret = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
        RoomInfo(chatHomeState: widget.chatHomeState, user: widget.me, roomId: widget.room.id,)));
    if (ret == 'room deleted')
        Navigator.pop(context);
  }

}

class RepeatedJobWaiter {
  Future Function() callBack;
  int waitingTime;
  RepeatedJobWaiter(this.callBack, {this.waitingTime = 2000});

  Queue<String> taskQ = Queue<String>();
  trigger() {
    if (taskQ.isNotEmpty)
      return;
    print('^^^^^^^^^^^^Job Schedule call= $callBack');
    callBack();
    taskQ.add('job');
    Future.delayed(Duration(milliseconds: waitingTime), () async {
      taskQ.clear();
    });
  }
}

class UserTyping extends StatefulWidget {
  final AnimationController hideFabAnimation;
  UserTyping({Key key, @required this.hideFabAnimation}) : super(key: key);

  @override
  _UserTypingState createState() => _UserTypingState();
}

class _UserTypingState extends State<UserTyping> {
  String typing = '';
  Timer t;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    String avatarPath = '/avatar/$typing';
    String url = serverUri.replace(path: avatarPath, query: 'format=png').toString();
    if (typing == '') {
      widget.hideFabAnimation.reverse();
      return SizedBox();
    } else {
      widget.hideFabAnimation.forward();
      return CircleAvatar(radius: 20, backgroundImage: NetworkImage(url));
    }
  }

}


