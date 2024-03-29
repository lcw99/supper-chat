import 'dart:convert';
import 'dart:developer';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:rocket_chat_connector_flutter/models/attachment_action.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/image_dimensions.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:superchat/create_discussion.dart';
import 'package:superchat/flatform_depended/platform_depended.dart';
import 'package:superchat/utils/dialogs.dart';
import 'package:superchat/widgets/userinfo.dart';
import 'package:universal_io/io.dart' as uio;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:linkable/linkable.dart';
import 'package:linkable/constants.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/emojis.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/models/new/reaction_new.dart';
import 'package:rocket_chat_connector_flutter/models/reaction.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:share/share.dart';
import 'package:superchat/constants/types.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:http_parser/http_parser.dart';

import 'chathome.dart';
import 'chatview.dart';
import 'constants/constants.dart';
import 'main.dart';
import 'utils/utils.dart';
import 'widgets/full_screen_image.dart';
import 'read_receipt.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'database/chatdb.dart' as db;
import 'widgets/video_thumbnail.dart';

class ChatItemView extends StatefulWidget {
  final User me;
  final Authentication authRC;
  final ChatHomeState chatHomeState;
  final bool onTapExit;
  final Message message;
  final int index;
  final Room room;
  final ChatViewState chatViewState;
  final bool hideAvatar;

  ChatItemView({Key key, @required this.chatHomeState, @required this.me, @required this.authRC,
    this.onTapExit = false, this.message, this.index = 0, this.room, this.chatViewState, this.hideAvatar = false,
  }) : super(key: key);

  @override
  ChatItemViewState createState() => ChatItemViewState();
}

class ChatItemViewState extends State<ChatItemView> {
  Message message;
  GlobalKey<_ReactionViewState> keyReactionView = GlobalKey();
  bool myMessageToRight = true;

  @override
  void dispose() {
    if (httpClient != null)
      httpClient.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    User messageUser;
    if (message == null || widget.onTapExit)
      message = widget.message;
    messageUser = Utils.getCachedUser(userId: message.user.id);
    bool isAttachmentUserCached = true;
    if (messageHasMessageAttachments(message.attachments)) {
        isAttachmentUserCached = testAttachmentUserIsCached(message.attachments[0]);
        //print('testAttachmentUserIsCached=$isAttachmentUserCached, msg=${message.attachments[0].text}');
    }
    if (messageUser != null && isAttachmentUserCached)
      return buildChatItemMain(message);
    return FutureBuilder<User>(
        future: getUserInfoForMessage(message),
        builder: (context, AsyncSnapshot<User> snapshot) {
          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
            //print('building chatitem=${message.msg}');
            messageUser = snapshot.data;
            return buildChatItemMain(message);
          } else
            return SizedBox();
        });
  }

  Widget buildChatItemMain(Message message) {
/*
    // uncomment this block, to support read count
    if(!message.isAttachment && widget.room.usersCount < 10 && !widget.onTapExit) {
      if (message.reactions == null ||
          !message.reactions.containsKey(readCountEmoji) ||
          !message.reactions[readCountEmoji].usernames.contains(widget.me.username))
        widget.chatViewState.taskQueueMarkMessageRead.addTask(() => getWebsocketService().setReaction(message.id, readCountEmoji, true));
    }
*/

    double leftMargin = 0;
    bool isThreadMessage = message.tmid != null;
    if (isThreadMessage)
      leftMargin = 15;
    Widget m = Container(child: _buildChatItem(message),
      margin: EdgeInsets.only(right: 15, left: leftMargin),
      width: MediaQuery.of(context).size.width - 15,
    );
    if (widget.onTapExit)
      return GestureDetector(onTap: () => Navigator.pop(context, message.id), child: AbsorbPointer(child: m));
    return m;
  }

  bool testAttachmentUserIsCached(MessageAttachment attachment) {
    User attachmentUser = Utils.getCachedUser(userName: attachment.authorName);
    if (attachmentUser == null)
      return false;
    else if (messageHasMessageAttachments(attachment.attachments))
      return testAttachmentUserIsCached(attachment.attachments[0]);
    return true;
  }

  Future<User> getUserInfoForMessage(Message message) async {
    if (messageHasMessageAttachments(message.attachments))
      await getAttachmentUserInfo(message.attachments[0]);
    return await Utils.getUserInfo(widget.authRC, userId: message.user.id);
  }

  Future<void> getAttachmentUserInfo(MessageAttachment attachment) async {
    await Utils.getUserInfo(widget.authRC, userName: attachment.authorName);
    if (messageHasMessageAttachments(attachment.attachments))
      await getAttachmentUserInfo(attachment.attachments[0]);
  }

  Future<Message> getMessage(messageId) async {
    db.RoomMessage rm = await locator<db.ChatDatabase>().getMessage(messageId);
    Message m = Message.fromMap(jsonDecode(rm.info));
    return m;
  }

  @override
  void initState() {
    super.initState();
  }

  setNewMessage(Message newMessage) {
    print('set newMessage=${newMessage.msg}');
    if (message.id == newMessage.id &&
      keyReactionView.currentState != null && newMessage.reactions != null && message.msg == newMessage.msg) {  // reaction case
       keyReactionView.currentState.setNewReaction(newMessage.reactions);
    } else {
      setState(() {
        message = newMessage;
      });
    }
  }

  bool _messageStarred(Message message) {
    return message.starred != null && message.starred.length > 0;
  }


  Widget _buildChatItem(Message message) {
    if (!message.isAttachment && message.msg == "")
      print("empty msg text");
    User user = Utils.getCachedUser(userId: message.user.id);
    bool roomChangedMessage = message.t != null;
    double avatarSize = DEFAULT_AVATAR_SIZE;
    if (roomChangedMessage)
      avatarSize = DEFAULT_AVATAR_SIZE / 2;
    else if (message.tmid != null || message.isAttachment)
      avatarSize = DEFAULT_AVATAR_SIZE * 3 / 4;

    bool myMessage = message.user.id == widget.me.id && !(message.tmid != null || message.isAttachment);
    if (!myMessageToRight)
      myMessage = false;

    if (widget.hideAvatar || myMessage)
      avatarSize = 0;

    return LayoutBuilder(builder: (context, boxConstraint) {
      //print('boxConstraint=$boxConstraint');
      const double avatarLeftPadding = 9;
      const double avatarRightPadding = 5;
      const double messageEndPadding = DEFAULT_AVATAR_SIZE;
      const double attachmentMessageUpArrowSize = 17;
      double messageBodyWidth = boxConstraint.maxWidth -
          (avatarLeftPadding + avatarRightPadding + avatarSize + (message.tmid != null ? 25 : 0) + (message.isAttachment ? attachmentMessageUpArrowSize : 0));
      return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: avatarLeftPadding,),
        widget.hideAvatar || myMessage ? SizedBox() : Row(children: [
          message.tmid == null ? SizedBox() :
          GestureDetector(child: Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.blueAccent,),
            onTap: () => replyMessage(true)
          ),
          message.isAttachment ? Icon(Icons.arrow_upward_sharp, color: Colors.blueAccent, size: attachmentMessageUpArrowSize,) : SizedBox(),
          GestureDetector(child: Utils.buildUserAvatar(avatarSize, user),
            onTap: () async { await userClickAction(user); },
          ),
        ]),
        SizedBox(width: avatarRightPadding,),
        Container(
          width: messageBodyWidth,
          child: Column(
            crossAxisAlignment: myMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4,),
              _buildUserNameLine(user, myMessage),
              Container(child: _buildMessage(message, myMessage), /*decoration: BoxDecoration(border: Border.all()),*/),
              SizedBox(height: 4,),
            ],
          )
        ),
      ],);});
  }

  Widget buildUnreadCount() {
    return SizedBox();    // disable unread count
    var reactions = message.reactions;
    bool bReactions = reactions != null && reactions.length > 0;

    int unreadCount = widget.room.usersCount;
    if (bReactions) {
      if (reactions.containsKey(readCountEmoji)) {
        unreadCount -= reactions[readCountEmoji].usernames.length;
        if (reactions.keys.length == 1)
          bReactions = false;
      }
    }

    return  message.isAttachment || unreadCount <= 0 || widget.room.usersCount >= 10 ? SizedBox() :
      Text('$unreadCount', style: TextStyle(fontSize: 8, color: chatUnreadCountColor));
  }

  Widget buildTimeDisplay() {
    List<String> dateStr = Utils.getDateString(message.ts);
    List<Widget> children = [];
    String date = dateStr.first;
    Color dateColor = chatChatTimeColor;
    if (dateStr.length > 1)
      date = dateStr.reversed.join(' ');
    children.add(Text(date, style: TextStyle(fontSize: 9, color: dateColor, ), maxLines: 1, overflow: TextOverflow.clip,));
    return Column(children: children, crossAxisAlignment: CrossAxisAlignment.start,);
  }

  userClickAction(user) async {
    bool ignoredUser = widget.room.subscription.ignored != null && widget.room.subscription.ignored.contains(user.id);
    var actionChild = Column(children: [
      InkWell(
          onTap: () { Navigator.pop(context, 'im.create'); },
          child: Wrap(children: <Widget>[
            Icon(Icons.chat_outlined, color: Colors.blueAccent),
            Text('Direct Message', style: TextStyle(color: Colors.blueAccent)),
          ],)
      ),
      SizedBox(height: 5,),
      InkWell(
          onTap: () { Navigator.pop(context, 'ignore.user'); },
          child: Wrap(children: <Widget>[
            Icon(Icons.notifications_off_outlined, color: Colors.redAccent,),
            Text(ignoredUser ? 'Un-ignore User' : 'Ignore User', style: TextStyle(color: Colors.blueAccent)),
          ],)
      ),
    ]);
    String ret = await showDialogWithWidget(context, UserInfoWithAction(userInfo: user, actionChild: actionChild,), MediaQuery.of(context).size.height - 200);
    if (ret == 'im.create') {
      var resp = await getChannelService().createDirectMessage(user.username, widget.authRC);
      Future.delayed(Duration(seconds: 2), () => widget.chatViewState.popToChatHome(resp.room.rid));
    } else if (ret == 'ignore.user') {
      bool setIgnore = true;
      if (ignoredUser)
        setIgnore = false;
      var resp = await getChannelService().ignoreUser(widget.room.id, user.id, setIgnore, widget.authRC);
      Utils.showToast(resp.success ? (setIgnore ? 'User ignored' : 'User Un-ignored') : 'error');
    }
  }

  Widget _buildUserNameLine(User user, bool myMessage) {
    Color userNameColor = Colors.black;
    if (message.user.id == widget.me.id)
      userNameColor = Colors.green.shade900;
    var usernameFontSize = USERNAME_FONT_SIZE;
    List<TextSpan> userNameLine = [];
    userNameLine.add(TextSpan(text: user.username,
      style: TextStyle(fontSize: usernameFontSize, color: userNameColor)));
    if (user.name != null && user.name.isNotEmpty)
      userNameLine.add(TextSpan(text: ' ' + user.name,
          style: TextStyle(fontSize: usernameFontSize * 0.8, color: displayNameColor)));
    return Row(mainAxisSize: MainAxisSize.min, children: [
      myMessage ? SizedBox() : Expanded(child: Text.rich(
        TextSpan(children: userNameLine),
        textAlign: TextAlign.left,
        maxLines: 1, overflow: TextOverflow.clip,
      )),
      _messageStarred(message) ?
        Icon(Icons.star_border_outlined, size: 14, color: Colors.redAccent,)
        : SizedBox(),
      message.pinnedBy != null ? Wrap(children: [
        SizedBox(width: 4,),
        rotatedPin,
        SizedBox(width: 1,),
        //Text(message.pinnedBy.username, style: TextStyle(fontSize: usernameFontSize), overflow: TextOverflow.clip, maxLines: 1,)
      ]) : SizedBox(),
    ]);
  }

  Offset tabPosition;
  Widget _buildMessage(Message message, bool myMessage) {
    var attachments = message.attachments;
    bool bAttachments = attachments != null && attachments.length > 0;
    bool bMessageAttachment = bAttachments && attachments.first.imageUrl == null && attachments.first.messageLink != null;
    var reactions = message.reactions;
    bool bReactions = reactions != null && reactions.length > 0;

    final double endPaddingForDate = widget.hideAvatar ? 0 : 80;

    if (bReactions) {
      if (reactions.containsKey(readCountEmoji)) {
        if (reactions.keys.length == 1)
          bReactions = false;
      }
    }
    return GestureDetector (
      onTapDown: (tabDownDetails) { tabPosition = tabDownDetails.globalPosition; },
      onLongPress: () { messagePopupMenu(context, tabPosition, message); },
      child:
      Column(
        crossAxisAlignment: myMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: myMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector (
            onTap: () {
              if (message.t == 'discussion-created')
                Navigator.pop(context, message.drid);
              else if (!message.isAttachment)
                pickReaction(message);
              else
                widget.chatViewState.findAndScroll(message.id);
            },
            child: LayoutBuilder(builder: (context, boxConstraint) {
              List<Widget> children = [];
              children.add(Container(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                    Container(constraints: BoxConstraints(maxWidth: boxConstraint.maxWidth - (!bMessageAttachment ? 0 : endPaddingForDate)),
                      child: buildMessageBody(message, boxConstraint),
                    ),
                    !bMessageAttachment ? SizedBox() : buildTimeAndUnreadCount(myMessage),
                  ],),
                  !bAttachments ? SizedBox() :
                  LayoutBuilder(builder: (context, boxConstraint){
                    return buildAttachments(message);
                  }),
                ]),
                constraints: BoxConstraints(maxWidth: boxConstraint.maxWidth - (bMessageAttachment ? 0 : endPaddingForDate)),),);
              if (!bMessageAttachment)
                children.add(buildTimeAndUnreadCount(myMessage));
              if (myMessage)
                children = children.reversed.toList();
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: children);
            }),
          ),
          !bReactions ? SizedBox() :
          Container(
            height: 30,
            child: ReactionView(key: keyReactionView, chatItemViewState: this, message: message, reactions: reactions),
          )
      ]));
  }

  Widget buildTimeAndUnreadCount(myMessage) {
    return Container(
      padding: EdgeInsets.only(left: 4),
      child: Column(children: [
      buildUnreadCount(),
      buildTimeDisplay(),
    ], crossAxisAlignment: myMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,));
  }

  String getDownloadLink(Message message) {
    var downloadLink;
    var attachments = message.attachments;
    for (MessageAttachment attachment in attachments) {
      if (attachment.type == 'file' && attachment.imageUrl == null) {
        downloadLink = attachment.titleLink;
      } else {
        if (attachment.titleLink == null)
          downloadLink = attachment.imageUrl;
        else
          downloadLink = attachment.titleLink;
      }
    }
    return downloadLink;
  }

  double downloadPercent = 0;
  buildAttachments(Message message) {
    var attachments = message.attachments;
    List<Widget> widgets = [];
    for (MessageAttachment attachment in attachments) {
      var attachmentBody;
      var downloadLink;
      //log(attachment.toString());
      if (attachment.type == 'file' && attachment.imageUrl == null) {
        downloadLink = attachment.titleLink;
        attachmentBody = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          attachment.videoUrl != null && !kIsWeb ?
            LayoutBuilder(builder: (context, bc) {
              return GestureDetector(
                onTap: () async {
                  String filePath = await fileExists(attachment.title);
                  if (filePath != null)
                    OpenFile.open(filePath);
                },
                child: VideoThumbnailView(videoFileName: attachment.title, width: bc.maxWidth.toInt(),)
              );
            }) : SizedBox(),
          attachment.description != null
            ? Text(attachment.description, style: TextStyle(fontSize: MESSAGE_FONT_SIZE), maxLines: 3, overflow: TextOverflow.fade,)
            : Text(attachment.title, style: TextStyle(fontSize: MESSAGE_FONT_SIZE), maxLines: 1, overflow: TextOverflow.clip, softWrap: false,),
          LinearPercentIndicator(percent: downloadPercent, backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero, progressColor: Colors.green,
          ),
        ],);
      } else if (attachment.imageUrl != null) {
        //downloadLink = attachment.imageUrl;
        attachmentBody = LayoutBuilder(builder: (context, bc) {
          //print('Column bc=$bc');
          return Column(children: <Widget>[
          LayoutBuilder(builder: (context, bc) {
            //print('getimage bc=$bc');
            return getImage(message, attachment);
          },),
          attachment.description != null
              ? Text(attachment.description, style: TextStyle(fontSize: 11),)
              : SizedBox(),
        ]);});
      } else if (attachment.messageLink != null) {
        String attachmentMessageId = attachment.messageLink.split("msg=")[1];
        User attachmentAuthor = Utils.getCachedUser(userName: attachment.authorName);
        if (attachmentAuthor == null)
          print('############ attachment.authorName = ${attachment.authorName}');
        String attachmentText = attachment.text;

        Message attachmentMessage;
        if (widget.chatViewState != null)
          if (widget.chatViewState.chatDataStore.containsMessage(attachmentMessageId) != null)
            attachmentMessage = Message.fromMap(widget.chatViewState.chatDataStore.containsMessage(attachmentMessageId).toMap());
        if (attachmentMessage == null) {
          attachmentMessage = Message(
            id: attachmentMessageId,
            rid: widget.room.id,
            msg: attachmentText,
            user: attachmentAuthor,
            updatedAt: attachment.ts,
            attachments: attachment.attachments,
            ts: attachment.ts,
            isAttachment: true,
          );
        }
        attachmentMessage.isAttachment = true;
        attachmentBody = _buildChatItem(attachmentMessage);
      } else if (message.t == 'message_pinned') {
        attachmentBody = SizedBox();
      } else if (attachment.actions != null) {
        attachmentBody = LayoutBuilder(builder: (context, bc) {
          List<Widget> buttons = [];
          attachment.actions.forEach((AttachmentAction attachmentAction) {
            Widget w = LayoutBuilder(builder: (context, bc) {
              String buttonText = attachmentAction.type == "button" ? attachmentAction.text : "unknown";
              return Align(alignment: Alignment.centerLeft, child:
                TextButton(
                  child: Text(buttonText),
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.black26),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              //side: BorderSide(color: Colors.red)
                          )
                      )
                  ),
                  onPressed: () {
                    widget.chatViewState.postMessage(attachmentAction.text + "\t" + attachmentAction.msg);
                  },
              ));
            });
            buttons.add(w);
          });
          return Column(children: buttons);
        });
      }
      else {
        log('unknown attachment type=$message');
      }
      widgets.add(LayoutBuilder(builder: (context, bc) {
        //print('return Row bc=$bc');
        attachment.renderWidth = bc.maxWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(child: attachmentBody, width: bc.maxWidth - (downloadLink != null ? 30 : 0)),
            //SizedBox(width: 5,),
            downloadLink != null ? InkWell(
              child: Icon(Icons.download_sharp, color: Colors.blueAccent, size: 30),
              onTap: () async {
                downloadAttachmentFile(downloadLink, attachment.title);
              },
            ) : SizedBox(),
          ]);}));
    }
    return LayoutBuilder(builder: (context, bc) {
      //print('return Column bc=$bc');
      return Container(child: Column(children: widgets), width: bc.maxWidth,);});
  }

  Future<void> downloadAttachmentFile(String downloadLink, String fileName) async {
    if (kIsWeb)
      Utils.downloadFile(widget.authRC, downloadLink);
    else {
      String filePath = await fileExists(fileName);
      if (filePath != null) {
        showSimpleAlertDialog(context, 'File warning', 'File already exists, overwrite?', () {
          Navigator.pop(context);
          downloadAttachmentFileProgress(downloadLink, fileName, forceDownload: true);
        }, onCancel: () {
          Navigator.pop(context);
          OpenFile.open(filePath);
        }, yesNo: true);
      } else {
        downloadAttachmentFileProgress(downloadLink, fileName);
      }
    }
  }

  http.Client httpClient;
  Future<void> downloadAttachmentFileProgress(String downloadLink, String fileName, {bool forceDownload = false}) async {
    httpClient = await downloadFile(Utils.buildDownloadUrl(widget.authRC, downloadLink), fileName, (String filePath) {
      httpClient = null;
      OpenFile.open(filePath);
    }, forceDownload: forceDownload,
    onProgress: (percent) {
      setState(() {
        downloadPercent = percent;
      });
    });
  }

  bool messageHasMessageAttachments(List<MessageAttachment> attachments) {
    bool haveIt = attachments != null && attachments.length > 0 && attachments[0].messageLink != null;
    // if (haveIt)
    //   log('messageHasAttachments=${message.attachments[0]}');
    return haveIt;
  }

  Widget buildMessageBody(Message message, BoxConstraints boxConstraints) {
    message = Utils.toDisplayMessage(message);
    String newMessage = message.displayMessage;
    var messageFontSize = MESSAGE_FONT_SIZE * textScaleFactor;
    if (message.t != null)
      messageFontSize = MESSAGE_FONT_SIZE * 0.9;
    else if (message.tmid != null || message.isAttachment)
      messageFontSize = MESSAGE_FONT_SIZE * 0.8;
    var messageBackgroundColor = Colors.white;
    if (message.user.id == widget.me.id)
      messageBackgroundColor = chatMyMessageColor;

    bool imageUrlBody = false;
    if (message.urls != null && message.urls.length == 1 && message.urls.single.headers != null &&
        message.urls.single.headers['contentType'] != null &&
        message.urls.single.headers['contentType'].contains('image') &&
        message.msg == message.urls.single.url ||
        message.urls != null && message.urls.length == 1 &&
        message.msg == message.urls.single.url &&
        message.id == widget.room.lastMessage.id &&
        message.msg.startsWith(serverUri.replace(path: '/emoji-custom').toString())) {
      imageUrlBody = true;
      message.imageUrlBody = true;
      newMessage = null;
    }

    if (message.urls != null && message.urls.length == 1 && message.msg == message.urls.single.url)
      newMessage = null;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        newMessage == null || newMessage.isEmpty ? SizedBox() :
        SizedBox(child: Container(
          padding: EdgeInsets.only(left:10, right: 10, top:3, bottom: 3),
          decoration: BoxDecoration(
            color: messageBackgroundColor,
            //border: Border.all(color: Colors.blueAccent, width: messageBorderWidth),
            borderRadius: BorderRadius.all(
                Radius.circular(10.0) //                 <--- border radius here
            ),
          ),
          //width: MediaQuery.of(context).size.width,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
            MouseRegion(
            cursor: SystemMouseCursors.text,
            child: Linkable(
              text: newMessage,
              style: TextStyle(fontSize: messageFontSize, color: Colors.black54, fontWeight: FontWeight.normal),
              linkClickCallback: (String text, String type) {
                _launch(_getUrl(message, text, type));
              },
            )),
            message.editedBy != null ?
              Text('(${message.editedBy.username} edited)', style: TextStyle(fontSize: 9, color: Colors.purple),) :
              SizedBox(),
              message.t == 'discussion-created' ? Icon(Icons.double_arrow_sharp, color: Colors.blueAccent,) : SizedBox(),
          ])
        )),
        !imageUrlBody ? SizedBox() :
        Container(width: boxConstraints.maxWidth, alignment: Alignment.topLeft,
          child: FullScreenWidget(
          child: Hero(
            tag: message.urls.single.url + message.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5), child:
              Image.network(message.urls.single.url, width: boxConstraints.maxWidth, fit: BoxFit.contain, cacheWidth: 500,)
            )
          )),
        ),
        message.urls != null && message.urls.length > 0 && !imageUrlBody
            ? buildUrls(message)
            : SizedBox(),
      ]), /*decoration: BoxDecoration(border: Border.all())*/);
  }

  _launch(String url) async {
    if (url == null)
      return;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _getUrl(Message message, String text, String type) {
    switch (type) {
      case "http":
        return text.substring(0, 4) == 'http' ? text : 'http://$text';
      case "email":
        return text.substring(0, 7) == 'mailto:' ? text : 'mailto:$text';
      case "tel":
        return text.substring(0, 4) == 'tel:' ? text : 'tel:$text';
      case "mention":
        userClickAction(message.mentions.where((e) => e.name == text).single);
        return null;
      default:
        return text;
    }
  }

  Widget buildUrls(Message message) {
    UrlInMessage urlInMessage = message.urls.first;
    return GestureDetector(
        onTap: () async {
          await canLaunch(urlInMessage.url) ? launch(urlInMessage.url) : print('url launch failed${urlInMessage.url}');
        },
        child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: urlInMessage.meta != null && urlInMessage.meta['ogImage'] != null
                ? Column (crossAxisAlignment: CrossAxisAlignment.start, children: <Widget> [
                  urlInMessage.meta['ogImage'] != null ? Image.network(urlInMessage.meta['ogImage'], cacheWidth: 500,) : SizedBox(),
                  urlInMessage.meta['ogTitle'] != null ? Text(urlInMessage.meta['ogTitle'], style: TextStyle(fontWeight: FontWeight.bold),  maxLines: 3, overflow: TextOverflow.fade,) : SizedBox(),
                  urlInMessage.meta['ogDescription'] != null ? Text(urlInMessage.meta['ogDescription'], style: TextStyle(fontSize: 11, color: Colors.blue), maxLines: 3, overflow: TextOverflow.fade,) : SizedBox(),
                ])
                : urlInMessage.meta != null && urlInMessage.meta['oembedThumbnailUrl'] != null
                ? Column (crossAxisAlignment: CrossAxisAlignment.start, children: <Widget> [
                  urlInMessage.meta['oembedThumbnailUrl'] != null ? Image.network(urlInMessage.meta['oembedThumbnailUrl'], cacheWidth: 500) : SizedBox(),
                  urlInMessage.meta['oembedTitle'] != null ? Text(urlInMessage.meta['oembedTitle'], maxLines: 3, overflow: TextOverflow.fade,) : SizedBox(),
                ])
                : urlInMessage.meta != null && urlInMessage.meta['pageTitle'] != null
                ? Column (crossAxisAlignment: CrossAxisAlignment.start, children: <Widget> [
                  urlInMessage.meta['pageTitle'] != null ? Text(urlInMessage.meta['pageTitle'], style: TextStyle(fontWeight: FontWeight.bold),) : SizedBox(),
                  urlInMessage.meta['description'] != null ? Text(urlInMessage.meta['description'], style: TextStyle(fontSize: 13), maxLines: 3, overflow: TextOverflow.fade,) : SizedBox(),
                ])
                : Linkable(text: urlInMessage.url, ),
        ));
  }

  Widget getImage(Message message, MessageAttachment attachment) {
    if (message.isAttachment) {
      return InkWell(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Utils.buildImageByLayout(widget.authRC, attachment.titleLink, attachment.renderWidth, attachment.imageDimensions)),
        onTap: () {
          widget.chatViewState.findAndScroll(message.id);
        },
      );
    }

    String imageUrl = attachment.titleLink;
    if (imageUrl == null)
      imageUrl = attachment.imageUrl;

    return FullScreenWidget(
      child: Hero(
        tag: attachment.imageUrl + message.id + message.isAttachment.toString() + widget.hashCode.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Utils.buildImageByLayout(widget.authRC, imageUrl, attachment.renderWidth, attachment.imageDimensions),
        ),
      ),
    );
  }

  pickReaction(Message message) async {
    var emojiPicker = epf.EmojiPicker(
      onEmojiSelected: (category, emoji) {
        print('@@@ selected emoji=${emoji.name}');
        Navigator.pop(context, emoji.name);
      },
      config: epf.Config(
          showCustomsTab: true,
          customEmojiUrlBase: serverUri.replace(path: '/emoji-custom').toString(),
          customEmojis: customEmojis,
          columns: 6,
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
    );

    String emoji = await showDialogWithWidget(context, emojiPicker, 350, alertDialog: false);

    if (emoji == null)
      return;

    sendReaction(message, emoji, true);
  }

  sendReaction(message, emoji, bool shouldReact) {
    MessageService messageService = getMessageService();
    String em = emoji;
    print('!!!!!emoji=$em');
    ReactionNew reaction = ReactionNew(emoji: em, messageId: message.id, shouldReact: shouldReact);
    messageService.postReaction(reaction, widget.authRC);
  }
  onReactionTouch(message, emoji, Reaction reaction) {
    if (reaction.usernames.contains(widget.me.username))
      sendReaction(message, emoji, false);
    else
      sendReaction(message, emoji, true);
  }

  Future<void> messagePopupMenu(context, Offset tabPosition, Message message) async {
    String imagePath;
    String downloadPath;
    MessageAttachment att;
    if (message.attachments != null && message.attachments.length > 0) {
      att = message.attachments.first;
      imagePath = att.imageUrl;
      if (att.titleLinkDownload != null && att.titleLinkDownload) {
        downloadPath = message.attachments.first.titleLink;
        imagePath = downloadPath;
      }
    } else if (message.imageUrlBody) {
      imagePath = Uri.parse(message.urls.single.url).path;
    }
    List<PopupMenuEntry<String>> items = [];
    items.add(Utils.buildPopupMenuItem(Icons.copy_outlined, 'Copy...', 'copy'));
    items.add(Utils.buildPopupMenuItem(Icons.share_outlined, 'Share...', 'share'));
    items.add(Utils.buildPopupMenuItem(Icons.format_quote_outlined, 'Quote...', 'quote'));
    items.add(Utils.buildPopupMenuItem(Icons.reply_outlined, 'Reply...', 'reply'));
    items.add(Utils.buildPopupMenuItem(Icons.add_comment_outlined, 'Create Discussion...', 'create_discussion'));
    if (_messageStarred(message))
      items.add(Utils.buildPopupMenuItem(Icons.remove_circle_outlined, 'UnStar...', 'unstar'));
    else
      items.add(Utils.buildPopupMenuItem(Icons.star_border_outlined, 'Star...', 'star'));
    if (message.pinned)
      items.add(Utils.buildPopupMenuItem(Icons.remove_circle_outlined, 'UnPin...', 'unpin'));
    else
      items.add(Utils.buildPopupMenuItem(Icons.push_pin_outlined, 'Pinn...', 'pin'));
    items.add(Utils.buildPopupMenuItem(Icons.add_reaction_outlined, 'Reaction...', 'reaction'));
    if (downloadPath != null)
      items.add(Utils.buildPopupMenuItem(Icons.download_outlined, 'Download...', 'download'));
    if (imagePath != null && !kIsWeb)
      items.add(Utils.buildPopupMenuItem(Icons.person_outline, 'Set as Profile...', 'set_profile'));
    if (message.user.id == widget.me.id) {
      items.add(Utils.buildPopupMenuItem(Icons.delete_outline, 'Delete...', 'delete'));
      items.add(Utils.buildPopupMenuItem(Icons.edit_outlined, 'Edit...', 'edit'));
    }
    if (widget.room.t != 'd')
      items.add(Utils.buildPopupMenuItem(Icons.receipt_long_outlined, 'Read receipts...', 'read_receipts'));

    var pos = RelativeRect.fromLTRB(0,0,0,0);
    if (tabPosition != null)
      pos = RelativeRect.fromLTRB(0, tabPosition.dy - 100, 0, tabPosition.dy + 100);
    String value = await showMenu(context: context,
      position: pos,
      items: items,
    );
    if (value == 'delete') {
      widget.chatHomeState.deleteMessage(message.id);
    } else if (value == 'create_discussion') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateDiscussion(parentRoomId: widget.room.id, parentMessageId: message.id, authRC: widget.authRC,)));
    } else if (value == 'copy') {
      Clipboard.setData(ClipboardData(text: message.msg));
    } else if (value == 'quote') {
      replyMessage(false);
    } else if (value == 'reply') {
      replyMessage(true);
    } else if (value == 'star') {
      getMessageService().starMessage(message.id, widget.authRC);
    } else if (value == 'unstar') {
      getMessageService().unStarMessage(message.id, widget.authRC);
    } else if (value == 'pin') {
      var resp = await getMessageService().pinMessage(message.id, widget.authRC);
      if (!resp.success)
        Utils.showToast('You are not allowed to pin message.');
    } else if (value == 'unpin') {
      getMessageService().unPinMessage(message.id, widget.authRC);
    } else if (value == 'reaction') {
      pickReaction(message);
    } else if (value == 'edit') {
      handleUpdateMessage(message);
    } else if (value == 'download') {
      downloadAttachmentFile(downloadPath, att.title);
    } else if (value == 'set_profile') {
      setProfilePicture(imagePath);
    } else if (value == 'read_receipts') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ReadReceipt(room: widget.room, messageId: message.id, authRC: widget.authRC,)));
    } else if (value == 'share') {
      if (imagePath != null) {
        Map<String, String> header = {
          'X-Auth-Token': widget.authRC.data.authToken,
          'X-User-Id': widget.authRC.data.userId
        };
        // Web support problem
        shareFile(serverUri.replace(path: imagePath).toString(), header);
      } else {
        String share = message.msg;
        if (share == null || share.isEmpty)
          share = Utils.buildDownloadUrl(widget.authRC, getDownloadLink(message));
        if (share != null && share.isNotEmpty)
          Share.share(share);
      }
    }
  }

  void replyMessage(bool reply) {
    widget.chatViewState.setState(() {
      quotedMessage = message;
      quotedMessage.isReply = reply;
    });
  }

  handleUpdateMessage(Message message) {
    TextEditingController _teController = TextEditingController();

    showDialog<void>(context: context, builder: (BuildContext context) {
      _teController.text = message.msg;
      return AlertDialog(
        title: Text('Edit Message'),
        content: Container(height: 200, child:
        Material(child:
        Column(children: [
          Form(
            child: TextFormField(
              autofocus: true,
              controller: _teController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5)),
            ),
          ),
          InkWell(
            onTap: () {
              widget.chatHomeState.editMessage(widget.room.id, message.id, _teController.text);
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(12.0),
              child: Text('Update'),
            ),
          ),
        ]),
      )));
    });
  }

  void setProfilePicture(String imagePath) {
    Utils.setAvatarImage(imagePath, widget.authRC);
  }
}

class ReactionView extends StatefulWidget {
  final ChatItemViewState chatItemViewState;
  final Message message;
  final Map<String, Reaction> reactions;

  ReactionView({Key key, this.chatItemViewState, this.message, this.reactions}) : super(key: key);

  @override
  _ReactionViewState createState() => _ReactionViewState();
}

class _ReactionViewState extends State<ReactionView> {
  Map<String, Reaction> reactions;
  @override
  void initState() {
    reactions = widget.reactions;
    super.initState();
  }

  setNewReaction(Map<String, Reaction> newReactions) {
    setState(() {
      reactions = newReactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: reactions.keys.length,
      itemBuilder: (context, index) {
        var emoji = reactions.keys.elementAt(index);
        if (emoji == readCountEmoji)
          return SizedBox();
        Reaction r = reactions[emoji];
        return GestureDetector (
            onTap: () { widget.chatItemViewState.onReactionTouch(widget.message, emoji, r); },
            child:Container(
                child: Row(children: <Widget>[
                  emojis[emoji] == null && customEmojis[emoji] != null
                  ? Image.network(serverUri.replace(path: '/emoji-custom${customEmojis[emoji]}').toString())
                  : Text(emojis[emoji], style: TextStyle(fontSize: 17)),
                  Text(r.usernames.length.toString(), style: TextStyle(fontSize: 10)),
                ])
            ));
      },
    );
  }

}

