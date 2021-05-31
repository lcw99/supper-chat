import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:moor/moor.dart' as moor;
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/response/spotlight_response.dart';
import 'package:superchat/flatform_depended/platform_depended.dart';
import 'package:superchat/widgets/user_search_result.dart';
import 'package:universal_io/io.dart';
import 'dart:ui';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'package:rocket_chat_connector_flutter/models/subscription.dart' as RC;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:rocket_chat_connector_flutter/models/constants/message_id.dart';
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
import 'add_user_to_room.dart';
import 'chathome.dart';
import 'chatitemview.dart';
import 'message_search.dart';
import 'room_files.dart';
import 'room_info.dart';
import 'room_members.dart';
import 'edit_room.dart';
import 'image_file_desc.dart';
import 'constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/room.dart' as RC;
import 'package:rocket_chat_connector_flutter/models/sync_messages.dart';
import 'database/chatdb.dart' as db;
import 'utils/utils.dart';

final String gotoBottomKey = ':gotoBottom:';
final String newMessageKey = ':newMessage:';
Message quotedMessage;

class ChatView extends StatefulWidget {
  final StreamController<rocket_notification.Notification> notificationController;
  final Authentication authRC;
  final RC.Room room;
  final User me;
  final dynamic sharedObject;
  final ChatHomeState chatHomeState;

  ChatView({Key key, @required this.chatHomeState, @required this.notificationController, @required this.authRC, @required this.room, @required this.me, this.sharedObject }) : super(key: key);

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatDataStore {
  List<ChatItemData> _chatData = [];

  get length => _chatData.length;

  add(ChatItemData data) {
    _chatData.add(data);
  }

  Message containsMessage(String messageId) {
    var i = _chatData.indexWhere((element) => element.messageId == messageId);
    if (i < 0)
      return null;
    return getMessageAt(i);
  }

  bool tryInsertNew(Message m) {
    if (m.tmid != null) {
      int i = findIndexByMessageId(m.tmid);
      if (i < 0)
        return false;
      _insertAt(i - _chatData[i].replyCount, m);
      _chatData[i].replyCount++;
      return true;
    }
    if (_chatData.length == 0 || m.ts.isAfter(_chatData.first.timeStamp)) {
      _insertAt(0, m);
      return true;
    }
    return false;
  }

  _insertAt(int index, Message m) async {
    String info = jsonEncode(m.toMap());
    RoomMessage roomMessage = RoomMessage(rid: m.rid, mid: m.id, ts: m.ts, info: info);
    await locator<db.ChatDatabase>().upsertRoomMessage(roomMessage);
    _chatData.insert(index, ChatItemData(GlobalKey(), m.id, m.tmid, info, m.ts));
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
    List<ChatItemData> threadMessages = _chatData.where((e) => e.threadId != null).toList();
    _chatData.removeWhere((e) => e.threadId != null);
    for (int i = 0; i < threadMessages.length; i++) {
      int pos = findIndexByMessageId(threadMessages[i].threadId);
      if (pos >= 0) {
        _chatData[pos].replyCount++;
        _chatData.insert(pos, threadMessages[i]);
      }
    }
  }
}

class ChatItemData {
  GlobalKey<ChatItemViewState> key;
  DateTime timeStamp;
  String messageId;
  String threadId;
  String info;
  int replyCount = 0;
  ChatItemData(this.key, this.messageId, this.threadId, this.info, this.timeStamp);
}

class ChatViewState extends State<ChatView> with WidgetsBindingObserver, TickerProviderStateMixin<ChatView>  {
  RC.Room room;
  TaskQueue taskQueueMarkMessageRead;
  TextEditingController _tecMessageInput = TextEditingController();
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

  GlobalKey<UserTypingState> userTypingKey = GlobalKey();
  GlobalKey<ChatViewState> chatViewKey = GlobalKey();

  List<String> permissions;

  DropzoneViewController dropzoneViewController;
  String droppedFile;
  bool announcementExpand = false;
  final ItemScrollController itemScrollController = ItemScrollController();

  GlobalKey<UserSearchResultState> userSearchPopupKey = GlobalKey();
  Message myLastSentMessage;
  Message myLastReceivedMessage;

  var markAsReadJob;

  bool shiftPressed = false;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print('+++++==== ChatView state=$state');
    if (state == AppLifecycleState.resumed) {
      await _getRoomMessages(chatItemCount, chatItemOffset, true, syncMessages: true);
      setState(() {
        getMoreMessages = false;  // do not call future build.
      });
    }
  }

  AnimationController actionButtonAnimationController;
  StreamSubscription subscription;

  Future<void> sendUserTyping() async {
    webSocketService.sendUserTyping(room.id, widget.me.username, true);
  }

  void popToChatHome(String roomId) {
    Navigator.pop(context, roomId);
  }

  OverlayEntry _oeSearchUser;
  GlobalKey messageInputState = GlobalKey();
  @override
  void initState() {
    room = widget.room;
    taskQueueMarkMessageRead = TaskQueue(1000);

    quotedMessage = null;
    subscribeRoomEvent(room.id);
    markAsReadJob = RepeatedJobWaiter(markAsRead);

    var userTypingJob = RepeatedJobWaiter(sendUserTyping, waitingTime: 5000);
    _tecMessageInput.addListener(() async {
      String msg = _tecMessageInput.text;
      var re = RegExp(r'@\w+');
      if (msg.isNotEmpty) {
        userTypingJob.trigger();
        if (re.hasMatch(msg)) {
          var match = re.allMatches(msg).last;
          if (match.end == msg.length) {
            String text = msg.substring(match.start + 1, match.end);
            if (_oeSearchUser == null) {
              _oeSearchUser = buildMentionPopup(messageInputState.currentContext, (User user) {
                _oeSearchUser.remove();
                _oeSearchUser = null;
                match = re.allMatches(_tecMessageInput.text).last;
                _tecMessageInput.text = _tecMessageInput.text.replaceRange(match.start + 1, match.end, user.username + ' ');
                caretToEnd();
              }, text);
              Overlay.of(context).insert(_oeSearchUser);
            } else
              userSearchPopupKey.currentState.newSearch(text);
          } else {
            if (_oeSearchUser != null) {
              _oeSearchUser.remove();
              _oeSearchUser = null;
            }
          }
        }
      }
      if (_oeSearchUser != null && !msg.contains("@")) {
        _oeSearchUser.remove();
        _oeSearchUser = null;
      }
    });

    actionButtonAnimationController = AnimationController(vsync: this, duration: kThemeAnimationDuration);

    getMoreMessages = false;
    needScrollToBottom = true;
    myFocusNode = FocusNode();
    myFocusNode.onKey = (node, RawKeyEvent event) {
      if (event.isShiftPressed) {
        shiftPressed = true;
      }
      return false;
    };
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus & showEmojiKeyboard) {
        setState(() {
          showEmojiKeyboard = false;
        });
      }
      if (!myFocusNode.hasFocus && _oeSearchUser != null) {
        _oeSearchUser.remove();
        _oeSearchUser = null;
      }
    });

    subscription = widget.notificationController.stream.listen((event) {
      print('chatview event=${event.toMap()}');
      if (event.msg == 'request_close') {
        if (this.mounted)
          Navigator.pop(context, event.collection);
        return;
      } else if (event.msg == 'clipboard_paste') {
        onClipboardImage(event.result);
      }
      if (event.msg == 'changed' && this.mounted) {
        if (event.collection == 'stream-room-messages') {
          if (event.notificationFields.notificationArgs.length > 0) {
            var arg = event.notificationFields.notificationArgs[0];
            Message roomMessage = Message.fromMap(arg);
            log('+++++stream-room-messages:${roomMessage.id}');
            if (roomMessage.rid != room.id) {
              print('not this room message~~~~~!!!');
              return;
            }
            //print(jsonEncode(roomMessage));
            if (roomMessage.t == 'room_changed_announcement') {
              room.announcement = roomMessage.msg;
            }
            int i = chatDataStore.findIndexByMessageId(roomMessage.id);
            if (i >= 0) {
              GlobalKey<ChatItemViewState> keyChatItem = chatDataStore.getGlobalKey(i);
              if (keyChatItem.currentState != null)
                  keyChatItem.currentState.setNewMessage(roomMessage);
              chatDataStore.replaceMessage(i, roomMessage);
            } else {  // new message
              needScrollToBottom = chatDataStore.tryInsertNew(roomMessage);
              print('@@@@ new message inserted=${roomMessage.msg}');
              if (roomMessage.user.id == widget.me.id) {
                myLastReceivedMessage = roomMessage;
                if (myLastSentMessage != null && myLastSentMessage.id == roomMessage.id) {
                  myLastSentMessage.messageReturn = true;
                  print ('my message turn back ok!=${roomMessage.id}');
                }
                if (needScrollToBottom)
                  setState(() {
                    print('!!!new my message inserted');
                  });
              } else {
                if(itemScrollController.scrollController.offset != itemScrollController.scrollController.position.minScrollExtent)
                  userTypingKey.currentState.setTypingUser(newMessageKey, stayTime: -1);
                else
                  if (needScrollToBottom) {
                    markAsReadJob.trigger();
                    setState(() {
                      print('!!!new message inserted');
                    });
                  }
              }
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
            if (eventName == 'updateAvatar' || eventName == 'Users:NameChanged') {
              clearImageCacheAndUpdateAll();
            }
          }
        } else if (event.collection == 'stream-notify-user') {
          if (event.notificationFields.notificationArgs.length > 0) {
            if (event.notificationFields.eventName.endsWith('rooms-changed')) {
              var arg = event.notificationFields.notificationArgs[1];
              RC.Room r = RC.Room.fromMap(arg);
              if (r.id != room.id) {
                print('!!!!!!!!!@@@@ not my room message');
                return;
              }
              var sub = room.subscription;
              room = r;
              room.subscription = sub;
            } else if (event.notificationFields.eventName.endsWith('subscriptions-changed')) {
              var arg = event.notificationFields.notificationArgs[1];
              RC.Subscription sub = RC.Subscription.fromMap(arg);
              if (sub.rid != room.id) {
                print('!!!!!!!!!@@@@ not my room sub message');
                return;
              }
              room.subscription = sub;
              permissions = widget.chatHomeState.getPermissionsForRoles(sub.roles);
              print('!!!!!!!!!@@@@ sub changed ');
/*
              setState(() {
                Utils.userCache.clear();
              });
*/
              print('++@@++permissions=$permissions');
            } else if (event.notificationFields.eventName.endsWith('/userData')) {
              print('!!!!!!!!!@@@@ user data changed');
/*
              setState(() {
                Utils.userCache.clear();
              });
*/
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
          if (mediaFiles.isNotEmpty && !kIsWeb) {
            File f = File(mediaFiles.first.path);
            postFile(file: f);
          }
        }
      }
    });
  }

  final LayerLink _layerLink = LayerLink();
  OverlayEntry buildMentionPopup(context, UserSelectCallback callback, text) {
    RenderBox renderBox = context.findRenderObject();
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    double searchListHeight = 250;
    return OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          width: size.width + 50,
          height: searchListHeight,
          child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          followerAnchor: Alignment.bottomLeft,
          offset: Offset(0.0, -5),
          child: Material(
            elevation: 4.0,
            child: Container(
              alignment: Alignment.topLeft,
              child: UserSearchResult(key: userSearchPopupKey, callback: callback, searchText: text, authRC: widget.authRC,),
              height: searchListHeight,
            ),
          ),
        )); }
    );
  }


  clearImageCacheAndUpdateAll() async {
    print('@@@@@ avatar or username changed, deleting cache');
    print('@@@@@ avatar changed deleting cache done~~~~~');
    setState(() {
      Utils.clearUserCache();
      imageCache.clear();
      imageCache.clearLiveImages();
    });
    chatViewKey.currentContext ?? Phoenix.rebirth(chatViewKey.currentContext);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final show = bottomInset > 0.0;
  }

  @override
  void dispose() {
    unsubscribeRoomEvent(room.id);
    taskQueueMarkMessageRead.clear();
    subscription.cancel();
    _tecMessageInput.dispose();
    actionButtonAnimationController.dispose();
    myFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(onWillPop: () async {
        if (showEmojiKeyboard) {
          setState(() {
            showEmojiKeyboard = false;
          });
          return false;
        }
        return true;
      },
      child: Phoenix(child: Scaffold(
      floatingActionButton: Visibility(
        child: ScaleTransition(
        scale: actionButtonAnimationController,
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(onPressed: (){
          if (userTypingKey.currentState.typing == gotoBottomKey || userTypingKey.currentState.typing == newMessageKey) {
            Future.delayed(Duration.zero, () {
              userTypingKey.currentState.setTypingUser('');
              itemScrollController.jumpTo(index: 0);
            });
          }
        }, backgroundColor: Colors.amber, child: UserTyping(key: userTypingKey, hideFabAnimation: actionButtonAnimationController,)))),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      key: chatViewKey,
      appBar: AppBar(
        leadingWidth: 25,
        title: Utils.getRoomTitle(context, room, widget.me),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.star_border_outlined),
            onPressed: () {
              handleSearchedMessage('Starred Messages', buildTaggedMessage(widget, room,
                  getChannelService().getTaggedMessages('getStarredMessages', room.id, widget.authRC))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              handleSearchedMessage('Search Messages', buildSearchMessage(widget, room));
            },
          ),
          PopupMenuButton(
            onSelected: (value) async {
              if (value == 'room_info')
                roomInformation();
              else if (value == 'pinned_messages') {
                handleSearchedMessage('Pinned Messages', buildTaggedMessage(widget, room,
                    getChannelService().getTaggedMessages('getPinnedMessages', room.id, widget.authRC))
                );
              } else if (value == 'thread_list') {
                handleSearchedMessage('Thread List', buildThreadList(widget, room));
              } else if (value == 'room_files') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RoomFiles(room: room, authRC: widget.authRC,)));
              } else if (value == 'leave_room') {
                var r = await getChannelService().leaveRoom(room, widget.authRC);
                if (r.success)
                  Navigator.pop(context);
                else
                  Utils.showToast(r.body);
              } else if (value == 'room_members')
                Navigator.push(context, MaterialPageRoute(builder: (context) => RoomMembers(room: room, authRC: widget.authRC,)));
              else if (value == 'add_user') {
                if (permissions != null && permissions.contains('add-user-to-joined-room'))
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddUser(room: room, authRC: widget.authRC,)));
                else
                  Utils.showToast('You are not allowed to add members');
              }
            },
            itemBuilder: (context){
              List<PopupMenuEntry<dynamic>> menu = [];
              menu.add(Utils.buildPopupMenuItem(Icons.push_pin_outlined, "Pinned Messages...", 'pinned_messages'));
              menu.add(Utils.buildPopupMenuItem(Icons.forum_outlined, "Thread List...", 'thread_list',));
              menu.add(Utils.buildPopupMenuItem(Icons.file_copy_outlined, "Files...", 'room_files',));
              menu.add(Utils.buildPopupMenuItem(Icons.logout, "Leave Room...", 'leave_room',));
              if (room.t != 'd') {
                menu.add(Utils.buildPopupMenuItem(Icons.people_alt_outlined, 'Room Members...', 'room_members'));
                menu.add(Utils.buildPopupMenuItem(Icons.perm_identity, "Add User...", 'add_user',));
                menu.add(Utils.buildPopupMenuItem(Icons.info_outline, "Room Information...", 'room_info',));
              }
              return menu;
          }),
        ],
      ),
      resizeToAvoidBottomInset: true,
      extendBody: false,
      bottomNavigationBar:
        Container(color: chatBackgroundColor, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            quotedMessage != null ?
            buildQuotedMessage() :
            SizedBox(),
            Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(color: Colors.white, child: _buildInputBox(), )
            ),
            showEmojiKeyboard && MediaQuery.of(context).viewInsets.bottom == 0 ? Container(
            height: 240,
            child:
            epf.EmojiPicker(
              onEmojiSelected: (category, emoji) {
                print(emoji);
                if (emoji.emoji.startsWith('/')) {
                  _postMessage(serverUri.replace(path: '/emoji-custom${emoji.emoji}').toString());
                } else {
                  _tecMessageInput.text += emoji.emoji;
                  caretToEnd();
                }
              },
              config: epf.Config(
                  showCustomsTab: true,
                  customEmojiUrlBase: serverUri.replace(path: '/emoji-custom').toString(),
                  customEmojis: customEmojis,
                  columns: 4,
                  emojiSizeMax: 50.0,
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
          ]
        )),
      body: Column(children: [
        Container(
          child: room.announcement != null && room.announcement.isNotEmpty ?
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(left: 15, top: 5, bottom: 5, right: 20),
            color: Colors.yellow.shade300,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  announcementExpand = !announcementExpand;
                });
              },
              child: AnimatedCrossFade(
                  duration: Duration(milliseconds: 200),
                  crossFadeState: !announcementExpand ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: Text(room.announcement, style: TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.fade,),
                  secondChild: Text(room.announcement, style: TextStyle(fontSize: 12), maxLines: 100, overflow: TextOverflow.fade,),
              )
            )) : SizedBox()
        ),
        Expanded(child:
          !getMoreMessages && (chatDataStore.length > 0) ?
          buildChatList() :
          FutureBuilder(
            future: () {
              print('@@@@@@ call future _getChannelMessages @@@@@@ updateAll=$getMoreMessages');
              var ua = getMoreMessages;
              getMoreMessages = false;
              if (chatDataStore.length == 0)
                ua = true;
              return _getRoomMessages(chatItemCount, chatItemOffset, ua);
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
                if (chatDataStore.length == 0)
                  return SizedBox();
                else
                  return buildChatList();
              }
            }
          )
        )
      ],)
    )));
  }

  caretToEnd() {
    _tecMessageInput.selection = TextSelection.fromPosition(TextPosition(offset: _tecMessageInput.text.length));
  }

  buildQuotedMessage() {
    return Container(constraints: BoxConstraints(maxHeight: 220), margin: EdgeInsets.only(bottom: 3),
    padding: EdgeInsets.only(top: 10,), decoration: BoxDecoration(border: Border.all(color: Colors.purpleAccent, width: 2)),
    clipBehavior: Clip.antiAlias,
    child: Wrap(children: [Row( children: [
      Expanded(child:
        ChatItemView(chatHomeState: widget.chatHomeState, me: widget.me, authRC: widget.authRC, message: quotedMessage, room: room, chatViewState: this,),
      ),
      InkWell(child: Icon(Icons.cancel), onTap: () {
        setState(() {
          quotedMessage = null;
        });
      },),
      SizedBox(width: 15),
    ])]));
  }

  bool onDropFile = false;
  Widget buildChatList() {
    if (scrollIndex >= 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        //itemScrollController.scrollTo(index: scrollIndex, duration: Duration(seconds: 1), curve: Curves.easeInOutCubic);
        print('---------->>> jumpto = $scrollIndex');
        if (scrollIndex > 0)
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

    var listView = ScrollablePositionedList.builder(
      //child: ListView.builder(
        itemScrollController: itemScrollController,
        reverse: true,
        physics: BouncingScrollPhysics(),
        itemCount: chatDataStore.length,
        //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemBuilder: (context, index) {
          Message message = chatDataStore.getMessageAt(index);
          // main list ChatItemView
          return ChatItemView(chatHomeState: widget.chatHomeState, key: chatDataStore.getGlobalKey(index),
            message: message, me: widget.me, authRC: widget.authRC, index: index, room: room, chatViewState: this,);
        }
    );

    final FocusNode _focusNode = FocusNode();

    return NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          print('list drag=${notification.metrics.pixels}');
          if (notification.metrics.pixels > notification.metrics.minScrollExtent + 100)
            userTypingKey.currentState.setTypingUser(gotoBottomKey, stayTime: 0);
          if (notification.metrics.atEdge) {
            print('*****listview Scrollend = ${notification.metrics.pixels}');
            if (!historyEnd && notification.metrics.pixels != notification.metrics.minScrollExtent) { // bottom
              print('!!! scrollview hit top');
              setState(() {
                getMoreMessages = true;
                chatItemOffset += chatItemCount;
              });
            } else if (notification.metrics.pixels == notification.metrics.minScrollExtent) {
              print('on minScrollExtent');
              Future.delayed(Duration(milliseconds: 100), () {actionButtonAnimationController.reverse();});
            }
          }
          return true;
        },
        child:
        Container(
          decoration: BoxDecoration(
            color: chatBackgroundColor,
            border: !onDropFile ? Border.all(width: 0) : Border.all(color: Colors.purpleAccent, width: 8),
          ),
          child: Stack(children: [
            kIsWeb ? DropzoneView(
              operation: DragOperation.copy,
              cursor: CursorType.Default,
              onCreated: (ctrl) {
                dropzoneViewController = ctrl;
              },
              onLoaded: () => print('Zone loaded'),
              onError: (ev) => print('Error: $ev'),
              onHover: () {
                setState(() {
                  onDropFile = true;
                });
              },
              onDrop: (htmlFile) async {
                setState(() {
                    onDropFile = false;
                });
                postHtmlFile(htmlFile);
              },
              onLeave: () {
                setState(() {
                  onDropFile = false;
                });
              },
            ) : SizedBox(),
            RawKeyboardListener(
              onKey: _handleKeyEvent,
              focusNode: _focusNode,
              child: Scrollbar(
                controller: listView.itemScrollController.scrollController,
                thickness: 10,
                showTrackOnHover: true,
                child: listView,
              )
            ),
          ])
        )
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    ScrollController _controller = itemScrollController.scrollController;
    var offset =  _controller.offset;
    print('key = ${event.logicalKey}');
    if (event.logicalKey == LogicalKeyboardKey.arrowDown)
      _controller.animateTo(offset - 200, duration: Duration(milliseconds: 30), curve: Curves.ease);
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp)
      _controller.animateTo(offset + 200, duration: Duration(milliseconds: 30), curve: Curves.ease);
    else if (event.logicalKey == LogicalKeyboardKey.pageDown)
      _controller.animateTo(offset - 1000, duration: Duration(milliseconds: 30), curve: Curves.ease);
    else if (event.logicalKey == LogicalKeyboardKey.pageUp)
      _controller.animateTo(offset + 1000, duration: Duration(milliseconds: 30), curve: Curves.ease);
  }

  handleSearchedMessage(String title, Widget content) async {
    String messageId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            insetPadding: EdgeInsets.all(5),
            contentPadding: EdgeInsets.all(5),
            content: Container(height: MediaQuery.of(context).size.height * .7, width: MediaQuery.of(context).size.width, child:
              content,
            )
          );
        }
    );
    findAndScroll(messageId);
  }

  Future<void> findAndScroll(String messageId) async {
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
      await _getRoomMessages(chatItemCount, chatItemOffset, true, syncMessages: false);
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
/*
    if (scrollIndex >= 0)
      userTypingKey.currentState.setTypingUser(gotoBottomKey, stayTime: 0);
*/
    Future.delayed(Duration(seconds: 1), () { Fluttertoast.cancel(); } );
  }

  _buildInputBox() {
    return Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
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
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextFormField(
                key: messageInputState,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  if (value.endsWith('\n') && !shiftPressed && kIsWeb) {
                    _postMessage(_tecMessageInput.text);
                    _tecMessageInput.clear();
                    myFocusNode.requestFocus();
                  }
                  shiftPressed = false;
                },
                onFieldSubmitted: (value) {
                  _postMessage(_tecMessageInput.text);
                  myFocusNode.requestFocus();
                },
                autofocus: false,
                focusNode: myFocusNode,
                controller: _tecMessageInput,
                minLines: 1,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'New message', border: InputBorder.none, contentPadding: EdgeInsets.only(left: 5)),
              )
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
              else if (value == 'pick_file')
                _pickFile();
            },
            itemBuilder: (context){
              List<PopupMenuEntry<dynamic>> menus = [];
              menus.add(PopupMenuItem(child: Text("Pick File..."), value: 'pick_file',));
              menus.add(PopupMenuItem(child: Text("Pick Image..."), value: 'pick_image',));
              menus.add(PopupMenuItem(child: Text("Take Photo..."), value: 'take_photo'));
              return menus;
            }),
            Container(
              margin: EdgeInsets.only(left: 10),
              child:
              InkWell(
                onTap: () {_postMessage(_tecMessageInput.text);},
                child: Icon(Icons.send, color: Colors.blueAccent, size: 40,),
              )),
        ])
    );
  }

  //message = '[ ](https://chat.smallet.co/channel/pppp_test?msg=NeZ9q4YHzezW8qTAK)  ' + message;
  Future<void> _postMessage(String message) async {
    if (message == null || message.isEmpty)
      return;
    MessageNew msg = MessageNew(roomId: room.id, text: message);
    bool useSendMessage = false;
    if (quotedMessage != null) {
      if (quotedMessage.isReply) {
        msg.tmid = quotedMessage.id;
        msg.msg = message;
        msg.text = null;
        useSendMessage = true;
      } else {
        String url = serverUri.replace(path: '/channel/${room.name}',
            query: 'msg=${quotedMessage.id}').toString();
        message = '[ ]($url)  ' + message;
        msg.text = message;
      }
      quotedMessage = null;
    }
    MessageNewResponse respMsg = await getMessageService().postMessage(msg, widget.authRC, sendMessage: useSendMessage);
    if (respMsg.success) {
      if (myLastReceivedMessage != null && myLastReceivedMessage.id == respMsg.message.id) {  // message already arrived. how fast!
        print('message already arrived!! = ${myLastReceivedMessage.id}');
      } else {
        myLastSentMessage = respMsg.message;
        myLastSentMessage.messageReturn = false;
        print('my message sent! = ${myLastSentMessage.id}');
        Future.delayed(Duration(milliseconds: 800), () {
          if (!myLastSentMessage.messageReturn) {
            widget.chatHomeState.showNetworkAlertDialog();
          }
        });
      }
    }
    _tecMessageInput.text = '';
  }

  void _pickFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();

    if(result != null) {
      if (result.files.single.path != null) {
        File file = File(result.files.single.path);
        Message newMessage = await postFile(file: file);
      } else {
        if (result.files.single.bytes != null) {
          Message newMessage = await postFile(bytes: result.files.single.bytes, fileName: result.files.single.name);
        }
      }
    } else {
      // User canceled the picker
    }
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    Uint8List imageData;
    String fileName;
    if (fromCamera) {
      var pickedFile = await picker.getImage(source: ImageSource.camera);
      imageData = await pickedFile.readAsBytes();
      fileName = pickedFile.path;
    } else {
      FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        fileName = result.files.single.name;
        if (result.files.single.path != null) {
          File file = File(result.files.single.path);
          imageData = file.readAsBytesSync();
        } else {
          if (result.files.single.bytes != null) {
            imageData = result.files.single.bytes;
          }
        }
      }
    }
    if (imageData == null) {
      print('No image selected.');
      return;
    }

    postImageWithEdit(fileName, imageData);
  }

  static bool onProcessing = false;
  postImageWithEdit(String fileName, Uint8List imageData) async {
    if (onProcessing) {
      print('!!!!!!!!!!!!!!!!!!!!!ImageFileDescription already open');
      return;
    }
    onProcessing = true;
    ImageFileData data = await Navigator.push(context, MaterialPageRoute(builder: (context) => ImageFileDescription(imageData: imageData,)));
    onProcessing = false;
    if (data != null) {
      if (data.description != null && data.description == '')
        data.description = null;
      Message newMessage = await postFile(bytes: data.imageData, fileName: fileName, desc: data.description);
    }
  }

  Future<Message> postFile({File file, Uint8List bytes, String fileName, String desc, String mimeType, String tmid}) {
    String tmid;
    if (quotedMessage != null && quotedMessage.isReply)
      tmid = quotedMessage.id;
    return getMessageService().roomImageUpload(room.id, widget.authRC, bytes: bytes, file: file, fileName: fileName, desc: desc, mimeType: mimeType, tmid: tmid);
  }

  Future<void> _takePhoto() async {
    _pickImage(fromCamera: true);
  }

  RoomMessage messageToRoomMessage(Message m) {
    String info = jsonEncode(m.toMap());
    return RoomMessage(rid: m.rid, mid: m.id, ts: m.ts, info: info);
  }

  static int historyCallCount = 0;
  Future<ChannelMessages> _getRoomMessages(int count, int offset, bool _getMoreMessages, { bool syncMessages = true }) async {
    print('!!!!!! get room history _getMoreMessages=$_getMoreMessages, syncMessages=$syncMessages');
    historyEnd = false;
    if (_getMoreMessages) {
      historyCallCount++;
      print('full history call=$historyCallCount');
      var lastUpdate = await locator<db.ChatDatabase>().getValueByKey(db.lastUpdateRoomMessage + room.id);
      var dbHistoryReadEnd = await locator<db.ChatDatabase>().getValueByKey(db.historyReadEnd + room.id);
      DateTime updateSince;
      if (lastUpdate != null)
        updateSince = DateTime.tryParse(lastUpdate.value);
      if (updateSince == null)
        _getMoreMessages = true;
      if (updateSince != null && syncMessages) {
        print('@@@ start syncMessages');
        SyncMessages syncMessages = await getChannelService().syncMessages(room.id, updateSince, widget.authRC);
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
        roomMessages = await locator<db.ChatDatabase>().getRoomMessages(room.id, count, offset: offset);
        print('read database offset=$offset, count=$count, roomMessages.length = ${roomMessages.length}');
        if (roomMessages.length < count)
          fetchFromNetwork = true;
      }
      if (fetchFromNetwork && dbHistoryReadEnd == null) {
        ChannelHistoryFilter filter = ChannelHistoryFilter(roomId: room.id, count: count, offset: offset);
        ChannelMessages channelMessages = await getChannelService().roomHistory(filter, widget.authRC, room.t);
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
        roomMessages = await locator<db.ChatDatabase>().getRoomMessages(room.id, count, offset: offset);
        print('@@@@ roomMessages.length after network fetch = ${roomMessages.length}');
      }
      if (roomMessages.length < count)
        historyEnd = true;

      await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.lastUpdateRoomMessage + room.id, value: DateTime.now().toIso8601String()));
      if (historyEnd)
        await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.historyReadEnd + room.id, value: 'yes'));

      for (var rm in roomMessages) {
        if (chatDataStore.containsMessage(rm.mid) == null) {
          //log('@@@@ add new message=${rm.info}');
          Message m = Message.fromMap(jsonDecode(rm.info));
          Utils.getUserInfo(widget.authRC, userId: m.user.id);
          chatDataStore.add(ChatItemData(GlobalKey(), rm.mid, m.tmid, rm.info, rm.ts));
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
    await getChannelService().markAsRead(room.id, widget.authRC);
    debugPrint("----------- mark channel(${room.id}) as read");
  }

  Future<void> roomInformation() async {
    var ret = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
        RoomInfo(chatHomeState: widget.chatHomeState, user: widget.me, room: room,)));
    if (ret == 'room deleted')
        Navigator.pop(context);
  }

  onClipboardImage(htmlFile) {
    postHtmlFile(htmlFile);
  }

  Future<void> postHtmlFile(htmlFile) async {
    String fileName = htmlFile.name;
    Uint8List bytes = await dropzoneViewController.getFileData(htmlFile);
    String mime = await dropzoneViewController.getFileMIME(htmlFile);
    if (mime.contains('image'))
      postImageWithEdit(fileName, bytes);
    else
      Message newMessage = await postFile(bytes: bytes, fileName: fileName, desc: fileName);
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
  UserTypingState createState() => UserTypingState();
}

class UserTypingState extends State<UserTyping> {
  String typing = '';
  Timer t;

  @override
  void initState() {
    super.initState();
  }

  setTypingUser(String userName, {int stayTime = 7}) {
    print('---typing user=$userName');
    setState(() {
      if (t != null) {
        t.cancel();
        t = null;
      }
      typing = userName;
    });
    if (userName != '') {
      if (stayTime > 0) {
        t = Timer(Duration(seconds: stayTime), () {
          if (mounted)
            setState(() {
              typing = '';
            });
        });
      } else {
        t = null;
      }
    } else {
      widget.hideFabAnimation.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget actionButton;
    if (typing == gotoBottomKey)
      actionButton = CircleAvatar(radius: 20, child: Icon(Icons.arrow_downward));
    else if (typing == newMessageKey)
      actionButton = CircleAvatar(radius: 20, child: Icon(Icons.message_outlined));
    else {
      String avatarPath = '/avatar/$typing';
      String url = serverUri.replace(path: avatarPath, query: 'format=png').toString();
      actionButton = CircleAvatar(radius: 20, backgroundImage: NetworkImage(url));
    }
    if (typing == '') {
      widget.hideFabAnimation.reverse();
      return SizedBox();
    } else {
      widget.hideFabAnimation.forward();
      return actionButton;
    }
  }

}


