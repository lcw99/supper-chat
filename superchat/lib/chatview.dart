import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/new/reaction_new.dart';
import 'package:rocket_chat_connector_flutter/models/reaction.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:superchat/input_file_desc.dart';
import 'package:flutter_emoji_keyboard/flutter_emoji_keyboard.dart';
import 'constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';


class ChatView extends StatefulWidget {
  final Stream<rocket_notification.Notification> notificationStream;
  final Authentication authRC;
  final model.Room room;
  final User me;

  ChatView({Key key, @required this.notificationStream, @required this.authRC, @required this.room, @required this.me}) : super(key: key);

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

  bool needScrollToBottom = false;
  bool bUpdateAll = false;
  bool showEmojiKeyboard = false;
  FocusNode myFocusNode;

  @override
  void initState() {
    bUpdateAll = true;
    needScrollToBottom = true;
    myFocusNode = FocusNode();
    widget.notificationStream.listen((event) {
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
                needScrollToBottom = true;
                chatData[i] = roomMessage;
              });
            } else {  // new message
              setState(() {
                print('!!!new message');
                needScrollToBottom = true;
                chatData.add(roomMessage);
              });
            }
          }
        } else if (event.collection == 'stream-notify-user')
          if (event.notificationFields.notificationArgs.length > 0) {
            var arg = event.notificationFields.notificationArgs[0];
            print('+++++stream-notify-user:' + jsonEncode(arg));
/*
            setState(() {
              chatItemOffset = 0;
              needScrollToBottom = true;
            });
*/
          }
      }
    });
    super.initState();
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
        future: _getChannelMessages(chatItemCount, chatItemOffset, bUpdateAll),
        builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
          if (snapshot.hasData) {
            List<Message> channelMessages = snapshot.data.messages;
            if (snapshot.data.count == -1) {  // updated
              print('!!!!partial update case');
              markAsReadScheduler();
            } else {
              bUpdateAll = false;
              if (channelMessages.length > 0) {
                for (Message m in channelMessages)
                  if (!chatData.contains(m))
                    chatData.add(m);
                chatData.sort((a, b) {
                  return a.ts.compareTo(b.ts);
                });
                debugPrint("msg count=" + channelMessages.length.toString());
                debugPrint("total msg count=" + chatData.length.toString());

                markAsReadScheduler();
              } else {
                historyEnd = true;
              }
            }
            return NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                if (notification.metrics.atEdge) {
                  print("listview Scrollend" + notification.metrics.pixels.toString());
                  if (!historyEnd && notification.metrics.pixels == 0.0) { // bottom
                    setState(() {
                      bUpdateAll = true;
                      chatItemOffset += chatItemCount;
                    });
                  }
                }
                return true;
              },
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                SliverAppBar(
                  title: Text(title),
                  expandedHeight: 100.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    background: Image.network(serverUri.replace(path: '/avatar/room/${widget.room.id}', query: 'format=png').toString(),
                      fit: BoxFit.cover,
                    )),
                ),
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
                SliverToBoxAdapter(
                  child: _buildInputBox()
                )
            ]));
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
          InkWell(
            onTap: _pickImage,
            child: Icon(Icons.image, color: Colors.blueAccent, size: 40,),
          ),
          Container(
              margin: EdgeInsets.only(left: 10),
              child:
              InkWell(
                onTap: _postMessage,
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
    String newMessage = message.msg;
    switch (message.t) {
      case 'au': newMessage = '$userName added ${message.msg}'; break;
      case 'uj': newMessage = '$userName joined'; break;
      case 'room_changed_avatar': newMessage = '$userName change room avatar'; break;
      case 'room_changed_description': newMessage = '$userName change room description'; break;
      default: if (message.t != null ) newMessage = '$userName act ${message.t}'; break;
    }
    Color userNameColor = Colors.brown;
    if (message.user.id == widget.me.id)
      userNameColor = Colors.green.shade900;
    return ListTile(
      dense: true,
      leading: Container(
          alignment: Alignment.centerLeft,
          width: specialMessage ? 20 : 40,
          height: specialMessage ? 20 : 40,
          child: Image.network(url)
      ),
      title: Text(
        userName + '(' + index.toString() +')',
        style: TextStyle(fontSize: 10, color: userNameColor),
        textAlign: TextAlign.left,
      ),
      subtitle: _buildMessage(message, userName, newMessage),
    );
  }
  _getUserName(Message message) {
    String userName = '';
    if (message.user.username != null)
      userName += ' ' + message.user.username;
    if (message.user.name != null)
      userName += ' ' + message.user.name;
    return userName;
  }

  _buildMessage(Message message, String userName, String newMessage) {
    var attachments = message.attachments;
    bool bAttachments = attachments != null && attachments.length > 0;
    var reactions = message.reactions;
    bool bReactions = reactions != null && reactions.length > 0;
    var now = DateTime.now().toLocal();
    var ts = message.ts.toLocal();
    String dateStr;
    if (now.year == ts.year && now.month == ts.month && now.day == ts.day)
      dateStr = DateFormat('kk:mm:ss').format(ts);
    else
      dateStr = DateFormat('yyyy-MM-dd kk:mm:ss').format(ts);

    return
      Column(children: <Widget>[
        Container(alignment: Alignment.centerLeft,
          child: Text(dateStr, style: TextStyle(fontSize: 10, color: Colors.blue),)
        ),
        GestureDetector (
          onTap: () { pickReaction(message); },
          child:
          Container(
            width: MediaQuery.of(context).size.width,
            child: Text(
            newMessage,
            style: TextStyle(fontSize: 14, color: Colors.blueAccent),
          ))
        ),
        bReactions ?
          Container(
            height: 20,
            width: MediaQuery.of(context).size.width,
            child: _buildReactions(message, reactions),
          ) : Container(height: 1, width: 1,),
        bAttachments ? Container(
        height: 150,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemExtent: 200,
            itemBuilder: (context, index) {
              var attachment = attachments[index];
              return Column(children: <Widget>[
                getImage(attachment.imageUrl),
                attachment.description != null ? Text(attachment.description) : Container(),
              ]);
            }
          )
        ) : Container(height: 1, width: 1,)
      ]);
  }

  Widget getImage(String imagePath) {
    Map<String, String> header = {
      'X-Auth-Token': widget.authRC.data.authToken,
      'X-User-Id': widget.authRC.data.userId
    };

    var image = Image.network(serverUri.replace(path: imagePath).toString(), headers: header, fit: BoxFit.fitHeight, height: 130,);

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

  Future<void> _postMessage() async {
    if (_teController.text.isNotEmpty) {
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(roomId: widget.room.id, text: _teController.text);
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

  Future<void> _pickImage() async {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    MessageService messageService = MessageService(rocketHttpService);

    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String desc = await Navigator.push(context, MaterialPageRoute(builder: (context) => InputFileDescription(file: file)));
      Message newMessage = await messageService.roomImageUpload(widget.room.id, widget.authRC, file, desc: desc);
      // setState(() {
      //   chatData.add(newMessage);
      // });
    } else {
      print('No image selected.');
    }
  }

  static int historyCallCount = 0;
  Future<ChannelMessages> _getChannelMessages(int count, int offset, bool _updatAll) {
    print('!!!!!! get room history bUpdateAll=$_updatAll');
    if (_updatAll) {
      historyCallCount++;
      print('full history call=$historyCallCount');
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      ChannelService channelService = ChannelService(rocketHttpService);
      ChannelHistoryFilter filter = ChannelHistoryFilter(roomId: widget.room.id, count: count, offset: offset);
      Future<ChannelMessages> messages = channelService.roomHistory(filter, widget.authRC, widget.room.t);
      return messages;
    } else {
      Future<ChannelMessages> messages = (() async { return ChannelMessages(success: true, count: -1); }());
      return messages;
    }
  }

  scrollToBottom(BuildContext context) {
    if (_scrollController.hasClients && needScrollToBottom) {
      needScrollToBottom = false;
      print('scroll to bottom!!!');
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Queue<String> taskQ = Queue<String>();
  markAsReadScheduler() {
    Future.delayed(const Duration(milliseconds: 300), () => scrollToBottom(context));
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
}

