import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:linkable/linkable.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/reaction_new.dart';
import 'package:rocket_chat_connector_flutter/models/reaction.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:ss_image_editor/common/image_picker/image_picker.dart';
import 'package:superchat/image_file_desc.dart';
import 'package:flutter_emoji_keyboard/flutter_emoji_keyboard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chathome.dart';
import 'constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';
import 'wigets/full_screen_image.dart';
import 'package:ss_image_editor/ss_image_editor.dart';

class ChatView extends StatefulWidget {
  final Stream<rocket_notification.Notification> notificationStream;
  final Authentication authRC;
  final model.Room room;
  final User me;
  final dynamic sharedObject;
  final Function(String messageId) onDeleteMessage;

  ChatView({Key key, @required this.notificationStream, @required this.authRC, @required this.room, @required this.me, this.sharedObject, this.onDeleteMessage}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TextEditingController _teController = TextEditingController();
  int chatItemOffset = 0;
  final int chatItemCount = 20;

  List<Message> chatData = [];
  bool historyEnd = false;
  final picker = ImagePicker();

  final _scrollController = ScrollController();

  bool updateAll = false;
  bool needScrollToBottom = false;
  bool showEmojiKeyboard = false;
  FocusNode myFocusNode;

  static const SCROLL_TO_BOTTOM = 1;

  @override
  void initState() {
    updateAll = true;
    myFocusNode = FocusNode();
    widget.notificationStream.listen((event) {
      if (event.msg == 'request_close') {
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
            int i = chatData.indexWhere((element) => element.id == roomMessage.id);
            if (i >= 0) {
              setState(() {
                needScrollToBottom = false;
                chatData[i] = roomMessage;
              });
            } else {  // new message
              setState(() {
                print('!!!new message');
                needScrollToBottom = true;
                chatData.insert(0, roomMessage);
              });
            }
          }
        } else if (event.collection == 'stream-notify-user')
          if (event.notificationFields.notificationArgs.length > 0) {
            var arg = event.notificationFields.notificationArgs[0];
            print('+++++stream-notify-user:' + jsonEncode(arg));
            if (event.notificationFields.eventName.endsWith('rooms-changed')) {
/*
              setState(() {
                chatData.clear();
                updateAll = true;
              });
*/
            }
          }
      }
    });

    super.initState();

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
  @override
  void dispose() {
    _teController.dispose();
    _scrollController.dispose();
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.room.id;
    if (widget.room.name != null)
      title = widget.room.name;
    else if (widget.room.usernames != null)
      title = widget.room.usernames.toString();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false,
      bottomNavigationBar:
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
        Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(height: 50, child: _buildInputBox())
        ),
        showEmojiKeyboard ? Container(child:
        EmojiKeyboard(
          height: 250,
          onEmojiSelected: (Emoji emoji){
            _teController.text += emoji.text;
            _teController.selection = TextSelection.fromPosition(TextPosition(offset: _teController.text.length));
          },
        )) : SizedBox(height: 0,),
      ]),
      body:
        FutureBuilder(
        future: _getChannelMessages(chatItemCount, chatItemOffset, updateAll, needScrollToBottom),
        builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
          if (snapshot.hasData) {
            List<Message> channelMessages = snapshot.data.messages;
            if (snapshot.data.count != null && snapshot.data.count < 0) {  // updated
              print('!!!!partial update case=${snapshot.data.offset}');
              markAsReadScheduler();
              if (snapshot.data.offset == SCROLL_TO_BOTTOM)
                Future.delayed(const Duration(milliseconds: 300), () {
                  scrollToBottom();
                });
            } else {
              updateAll = false;
              if (channelMessages.length > 0) {
                for (Message m in channelMessages)
                  if (!chatData.contains(m))
                    chatData.add(m);
                chatData.sort((b, a) {
                  return a.ts.compareTo(b.ts);
                });
                debugPrint("msg count=" + channelMessages.length.toString());
                debugPrint("total msg count=" + chatData.length.toString());
                debugPrint("chatItemOffset=$chatItemOffset");

                markAsReadScheduler();
                if (chatItemOffset == 0)
                  Future.delayed(const Duration(milliseconds: 300), () {
                    scrollToBottom();
                  });
              } else {
                historyEnd = true;
              }
            }
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
                      Message message = chatData[index];
                      return Container(
                        //decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                        child: _buildChatItem(message, index),
                      );
                    },
                    childCount: chatData.length,
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
            return Container();
        }
      )
    );
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

  _buildChatItem(Message message, int index) {
    //log("msg=" + index.toString() + message.toString());
    bool specialMessage = message.t != null;
    String url = message.user.avatarUrl == null ?
                    serverUri.replace(path: '/avatar/${message.user.username}', query: 'format=png').toString() :
                    message.user.avatarUrl;
    String userName = _getUserName(message);
    Color userNameColor = Colors.black;
    if (message.user.id == widget.me.id)
      userNameColor = Colors.green.shade900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      SizedBox(width: 9,),
      // avatar
      Container(
          padding: EdgeInsets.all(2),
          alignment: Alignment.topLeft,
          width: specialMessage ? 20 : 40,
          height: specialMessage ? 20 : 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: ExtendedImage.network(url))
      ),
      SizedBox(width: 5,),
      // user name
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          userName /* + '(${index.toString()})' */,
          style: TextStyle(fontSize: 10, color: userNameColor),
          textAlign: TextAlign.left,
        ),
        _buildMessage(message, userName),
        SizedBox(height: 8,),
      ],)),
      SizedBox(width: 40,),
    ],);
  }
  _getUserName(Message message) {
    String userName = '';
    if (message.user.username != null)
      userName += ' ' + message.user.username;
    if (message.user.name != null)
      userName += ' ' + message.user.name;
    return userName;
  }

  _buildMessage(Message message, String userName) {
    Offset tabPosition;
    var attachments = message.attachments;
    bool bAttachments = attachments != null && attachments.length > 0;
    var reactions = message.reactions;
    bool bReactions = reactions != null && reactions.length > 0;
    var now = DateTime.now().toLocal();
    var ts = message.ts.toLocal();
    String dateStr = '';
    if (now.year != ts.year)
      dateStr += DateFormat('yyyy-').format(ts);
    if (now.month != ts.month)
      dateStr += DateFormat('MM-').format(ts);
    if (now.day != ts.day)
      dateStr += DateFormat('dd ').format(ts);
    dateStr += DateFormat('kk:mm:ss').format(ts);

    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        bAttachments ? Container(child: buildAttachments(attachments, message)) : SizedBox(),
        GestureDetector (
          onTap: () { pickReaction(message); },
          onTapDown: (tabDownDetails) { tabPosition = tabDownDetails.globalPosition; },
          onLongPress: () { messagePopupMenu(context, tabPosition, message); },
          child: buildMessageBody(message),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(flex: 1, child: bReactions ?
          Container(
            height: 20,
            width: MediaQuery.of(context).size.width,
            child: _buildReactions(message, reactions),
          ) : SizedBox()),
          Expanded(flex: 1, child: Container(
            alignment: Alignment.topRight,
            child: Text(dateStr, style: TextStyle(fontSize: 8, color: Colors.black54),)
          )),
        ]),
      ]);
  }

  buildAttachments(attachments, message) {
    List<Widget> widgets = [];
    for (MessageAttachment attachment in attachments) {
      var attachmentBody;
      var downloadLink;
      if (attachment.type == 'file' && attachment.imageUrl == null) {
        downloadLink = attachment.titleLink;
        attachmentBody = attachment.description != null
            ? Text(attachment.description, style: TextStyle(fontSize: 10),)
            : Text(attachment.title, style: TextStyle(fontSize: 10),);
      } else {
        downloadLink = attachment.imageUrl;
        attachmentBody = Column(children: <Widget>[
          getImage(message, attachment.imageUrl),
          attachment.description != null
              ? Text(attachment.description, style: TextStyle(fontSize: 11),)
              : SizedBox(),
        ]);
      }
      widgets.add(Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
        attachmentBody,
        SizedBox(width: 5,),
        Column(children: [
          InkWell(
            child: Icon(Icons.thumb_up_alt_outlined, color: Colors.blueAccent, size: 30),
            onTap: () { pickReaction(message); },
          ),
          SizedBox(height: 5,),
          InkWell(
            child: Icon(Icons.download_sharp, color: Colors.blueAccent, size: 30),
            onTap: () async {
              Map<String, String> query = {
                'rc_token': widget.authRC.data.authToken,
                'rc_uid': widget.authRC.data.userId
              };
              var uri = serverUri.replace(path: downloadLink, queryParameters: query);
              launch(Uri.encodeFull(uri.toString()));
            },
          ),
        ])
      ]));
    }
    return Column(children: widgets);
  }

  Widget buildMessageBody(Message message) {
    String userName = _getUserName(message);
    String newMessage = message.msg;
    switch (message.t) {
      case 'au': newMessage = '$userName added ${message.msg}'; break;
      case 'ru': newMessage = '$userName removed ${message.msg}'; break;
      case 'uj': newMessage = '$userName joined'; break;
      case 'room_changed_avatar': newMessage = '$userName change room avatar'; break;
      case 'room_changed_description': newMessage = '$userName change room description'; break;
      default: if (message.t != null ) newMessage = '$userName act ${message.t}'; break;
    }
    var messageBackgroundColor = Colors.white;
    if (message.user.id == widget.me.id)
      messageBackgroundColor = Colors.amber.shade100;
    return Container(
    child: Column(children: <Widget>[
      newMessage == '' ? SizedBox() : Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: messageBackgroundColor,
            border: Border.all(color: Colors.blueAccent, width: 0),
            borderRadius: BorderRadius.all(
                Radius.circular(2.0) //                 <--- border radius here
            ),
          ),
        width: MediaQuery.of(context).size.width,
        child: Linkable(
          text: newMessage,
          style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
        )
      ),
      message.urls != null && message.urls.length > 0
          ? buildUrls(message)
          : SizedBox(),
    ]));
  }

  Widget buildUrls(Message message) {
    UrlInMessage urlInMessage = message.urls.first;
    return GestureDetector(
      onTap: () async { await canLaunch(urlInMessage.url) ? launch(urlInMessage.url) : print('url launch failed${urlInMessage.url}'); },
      child: Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: urlInMessage.meta != null && urlInMessage.meta['ogImage'] != null
        ? Column (
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget> [
          urlInMessage.meta['ogImage'] != null ? ExtendedImage.network(urlInMessage.meta['ogImage']) : SizedBox(),
          urlInMessage.meta['ogTitle'] != null ? Text(urlInMessage.meta['ogTitle'], style: TextStyle(fontWeight: FontWeight.bold)) : SizedBox(),
          urlInMessage.meta['ogDescription'] != null ? Text(urlInMessage.meta['ogDescription'], style: TextStyle(fontSize: 11, color: Colors.blue)) : SizedBox(),
        ])
        : urlInMessage.meta != null && urlInMessage.meta['oembedThumbnailUrl'] != null
          ? Column (children: <Widget> [
            urlInMessage.meta['oembedThumbnailUrl'] != null ? ExtendedImage.network(urlInMessage.meta['oembedThumbnailUrl']) : SizedBox(),
            urlInMessage.meta['oembedTitle'] != null ? Text(urlInMessage.meta['oembedTitle']) : SizedBox(),
          ])
          : SizedBox()
    ));
  }

  Widget getImage(Message message, String imagePath) {
    Map<String, String> header = {
      'X-Auth-Token': widget.authRC.data.authToken,
      'X-User-Id': widget.authRC.data.userId
    };

    var image = ExtendedImage.network(serverUri.replace(path: imagePath).toString(),
      width: MediaQuery.of(context).size.width - 150,
      fit: BoxFit.contain,
      headers: header,
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        return GestureConfig(
          minScale: 0.9,
          animationMinScale: 0.7,
          maxScale: 3.0,
          animationMaxScale: 3.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0,
          inPageView: false,
          initialAlignment: InitialAlignment.center,
        );
      },
    );

    return FullScreenWidget(
      child: Hero(
        tag: imagePath,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: image,
        ),
      ),
    );
  }

  Future<void> _postMessage(String message) async {
    if (message != null && message.isNotEmpty) {
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(roomId: widget.room.id, text: message);
      MessageNewResponse respMsg = await messageService.postMessage(msg, widget.authRC);
      _teController.text = '';
/*
      setState(() {
        needScrollToBottom = true;
        chatData.add(respMsg.message);
      });
*/
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
  Future<ChannelMessages> _getChannelMessages(int count, int offset, bool _updateAll, bool _scrollToBottom) {
    print('!!!!!! get room history bUpdateAll=$_updateAll');
    if (_updateAll) {
      historyCallCount++;
      print('full history call=$historyCallCount');
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      ChannelService channelService = ChannelService(rocketHttpService);
      ChannelHistoryFilter filter = ChannelHistoryFilter(roomId: widget.room.id, count: count, offset: offset);
      Future<ChannelMessages> messages = channelService.roomHistory(filter, widget.authRC, widget.room.t);
      return messages;
    } else {
      int offset = 0;
      if (_scrollToBottom)
        offset = SCROLL_TO_BOTTOM;
      Future<ChannelMessages> messages = (() async { return ChannelMessages(success: true, count: -1, offset: offset); }());
      return messages;
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
/*
      Future.delayed(const Duration(milliseconds: 300), () {
        print('scroll not enough!!!');
        if(_scrollController.offset != _scrollController.position.maxScrollExtent)
          scrollToBottom();
      });
*/
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

  _buildReactions(message, Map<String, Reaction> reactions) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: reactions.keys.length,
      itemBuilder: (context, index) {
        var emoji = reactions.keys.elementAt(index);
        Reaction r = reactions[emoji];
        return GestureDetector (
          onTap: () { onReactionTouch(message, emoji, r); },
          child:Container(
            child: Row(children: <Widget>[
              Text(emojis[emoji], style: TextStyle(fontSize: 12)),
              Text(r.usernames.length.toString(), style: TextStyle(fontSize: 10)),
            ])
          ));
      },
    );
  }

  void onReactionTouch(message, emoji, Reaction reaction) {
    if (reaction.usernames.contains(widget.me.username))
      _sendReaction(message, emoji, false);
    else
      _sendReaction(message, emoji, true);
  }

  pickReaction(Message message) async {
    String emoji = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(child:
          Container(
            child: EmojiKeyboard(
              height: 300,
              onEmojiSelected: (Emoji emoji){
                Navigator.pop(context, emoji.name);
              },
            )
          )
        );
      }
    );

    if (emoji == null)
      return;

    _sendReaction(message, emoji, true);
  }

  _sendReaction(message, emoji, bool shouldReact) {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    MessageService messageService = MessageService(rocketHttpService);
    String em = ':$emoji:';
    print('!!!!!emoji=$em');
    ReactionNew reaction = ReactionNew(emoji: em, messageId: message.id, shouldReact: shouldReact);
    messageService.postReaction(reaction, widget.authRC);
  }

  Future<void> messagePopupMenu(context, Offset tabPosition, Message message) async {
    String value = await showMenu(context: context,
      position: RelativeRect.fromLTRB(tabPosition.dx + 50, tabPosition.dy - 100, tabPosition.dx + 100, tabPosition.dy + 100),
      items: [
        PopupMenuItem(child: Text('Share...'), value: 'share',),
        PopupMenuItem(child: Text('Delete...'), value: 'delete'),
      ],
    );
    if (value == 'delete') {
      widget.onDeleteMessage(message.id);
    }
  }

}

