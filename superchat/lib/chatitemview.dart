import 'dart:convert';
import 'dart:developer';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:superchat/flatform_depended/platform_depended.dart';
import 'package:superchat/utils/dialogs.dart';
import 'package:superchat/wigets/userinfo.dart';
import 'package:universal_io/io.dart' as uio;
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart' as ei;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:linkable/linkable.dart';
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
import 'wigets/full_screen_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'database/chatdb.dart' as db;

class ChatItemView extends StatefulWidget {
  final User me;
  final Authentication authRC;
  final ChatHomeState chatHomeState;
  final bool onTapExit;
  final Message message;
  final int index;
  final Room room;
  final ChatViewState chatViewState;

  ChatItemView({Key key, @required this.chatHomeState, @required this.me, @required this.authRC,
    this.onTapExit = false, this.message, this.index = 0, this.room, this.chatViewState,
  }) : super(key: key);

  @override
  ChatItemViewState createState() => ChatItemViewState();
}

class ChatItemViewState extends State<ChatItemView> {
  Message message;
  GlobalKey<_ReactionViewState> keyReactionView = GlobalKey();
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
    double leftMargin = 0;
    if (message.tmid != null)
      leftMargin = 40;
    return Container(child: _buildChatItem(message),
      margin: EdgeInsets.only(right: 15, left: leftMargin),
      width: MediaQuery.of(context).size.width - 15,);
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
    if (keyReactionView.currentState != null && newMessage.reactions != null && message.msg == newMessage.msg) {  // reaction case
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
    User user = Utils.getCachedUser(userId: message.user.id);
    bool roomChangedMessage = message.t != null;
    double avatarSize = 40;
    if (roomChangedMessage)
      avatarSize = 20;
    else if (message.tmid != null || message.isAttachment)
      avatarSize = 30;
    return LayoutBuilder(builder: (context, boxConstraint) {
      //print('boxConstraint=$boxConstraint');
      return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 9,),
        GestureDetector(child: Utils.buildUserAvatar(avatarSize, user),
          onTap: () async {
            String ret = await showDialogWithWidget(context, UserInfo(userInfo: user), MediaQuery.of(context).size.height - 200);
            if (ret != 'im.create')
              return;
            var resp = await getChannelService().createDirectMessage(user.username, widget.authRC);
            Future.delayed(Duration(seconds: 2), () => widget.chatViewState.popToChatHome(resp.room.rid));
        },),
        SizedBox(width: 5,),
        Container(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserNameLine(user),
            _buildMessage(message),
            SizedBox(height: 8,),
          ],), width: boxConstraint.maxWidth - (9 + 5 + avatarSize),),
        //SizedBox(width: 40,),
      ],);});
  }

  Widget _buildUserNameLine(user) {
    var now = DateTime.now().toLocal();
    var ts = message.ts.toLocal();
    String dateStr = '';
    if (now.year != ts.year)
      dateStr += DateFormat('yyyy-').format(ts);
    if (now.month != ts.month)
      dateStr += DateFormat('MM-').format(ts);
    if (now.day != ts.day) {
      if (now.day - ts.day == 1)
        dateStr += 'yesterday ';
      else
        dateStr += DateFormat('dd ').format(ts);
    }
    dateStr += DateFormat('jm').format(ts);

    String userName = Utils.getUserNameByUser(user);
    Color userNameColor = Colors.black;
    if (message.user.id == widget.me.id)
      userNameColor = Colors.green.shade900;
    var usernameFontSize = USERNAME_FONT_SIZE;
    return Row(children: [
      Text(
        userName  + '(${widget.index.toString()})' ,
        style: TextStyle(fontSize: usernameFontSize, color: userNameColor),
        textAlign: TextAlign.left,
      ),
      Wrap(alignment: WrapAlignment.end,
          children: [
            _messageStarred(message) ? Wrap(children: [
              SizedBox(width: 2,),
              Icon(Icons.star_border_outlined, size: 14, color: Colors.redAccent,),
            ]) : SizedBox(),
            message.pinnedBy != null ? Wrap(children: [
              SizedBox(width: 4,),
              Transform.rotate(child: Icon(Icons.push_pin_outlined, size: 12,), angle: 45 * 3.14 / 180,),
              SizedBox(width: 1,),
              Text(message.pinnedBy.username, style: TextStyle(fontSize: usernameFontSize),)
            ])  : SizedBox(),
          ]),
      Expanded(child: Container(child:
      Text(dateStr, style: TextStyle(fontSize: usernameFontSize, color: Colors.blueGrey, fontStyle: FontStyle.italic),),
        alignment: Alignment.centerRight,
      )),
    ]);
  }

  _getUserName(Message message) {
    String userName = '';
    if (message.user.name != null)
      userName += ' ' + message.user.name;
    if (userName == '' && message.user.username != null)
      userName += ' ' + message.user.username;
    return userName;
  }

  Offset tabPosition;
  Widget _buildMessage(Message message) {
    var attachments = message.attachments;
    bool bAttachments = attachments != null && attachments.length > 0;
    bool hasReplies = message.replies != null && message.replies.length > 0;
    var reactions = message.reactions;
    bool bReactions = reactions != null && reactions.length > 0;
    return GestureDetector (
      onTapDown: (tabDownDetails) { tabPosition = tabDownDetails.globalPosition; },
      onLongPress: () { if (!widget.onTapExit) messagePopupMenu(context, tabPosition, message); },
      child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector (
            onTap: () {
              if (widget.onTapExit)
                Navigator.pop(context, message.id);
              else if (!message.isAttachment)
                pickReaction(message);
              else
                widget.chatViewState.findAndScroll(message.id);
            },
            child: buildMessageBody(message),
          ),
          bAttachments ?
            LayoutBuilder(builder: (context, boxConstraint){
              //print('bAttachments boxConstraint=$boxConstraint');
              return Container(child: buildAttachments(message), width: boxConstraint.maxWidth,);
            })
            : SizedBox(),
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hasReplies ?
                  GestureDetector(child:
                    Container(child: Icon(Icons.add_comment_outlined, color: Colors.blueAccent), height: 30,
                      padding: EdgeInsets.only(right: 10),
                    ),
                    onTap: () => replyMessage(),
                  )
                  : SizedBox(),
                Expanded(flex: 1, child: bReactions ?
                Container(
                  height: 30,
                  width: MediaQuery.of(context).size.width,
                  child: ReactionView(key: keyReactionView, chatItemViewState: this, message: message, reactions: reactions),
                ) : SizedBox()),
              ]),
        ]));
  }

  String getDownloadLink(Message message) {
    var downloadLink;
    var attachments = message.attachments;
    for (MessageAttachment attachment in attachments) {
      if (attachment.type == 'file' && attachment.imageUrl == null) {
        downloadLink = attachment.titleLink;
      } else {
        downloadLink = attachment.imageUrl;
      }
    }
    return downloadLink;
  }

  buildAttachments(Message message) {
    var attachments = message.attachments;
    List<Widget> widgets = [];
    for (MessageAttachment attachment in attachments) {
      var attachmentBody;
      var downloadLink;
      //log(attachment.toString());
      if (attachment.type == 'file' && attachment.imageUrl == null) {
        downloadLink = attachment.titleLink;
        attachmentBody = attachment.description != null
            ? Text(attachment.description, style: TextStyle(fontSize: 10),)
            : Text(attachment.title, style: TextStyle(fontSize: 10),);
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

        Message attachmentMessage = Message(
          id: attachmentMessageId,
          rid: widget.room.id,
          msg: attachmentText,
          user: attachmentAuthor,
          updatedAt: attachment.ts,
          attachments: attachment.attachments,
          ts: attachment.ts,
          isAttachment: true,
        );
        attachmentBody = Expanded(child: _buildChatItem(attachmentMessage));
      } else {
        log('unknown attachment type=$message');
      }
      widgets.add(LayoutBuilder(builder: (context, bc) {
        //print('return Row bc=$bc');
        attachment.renderWidth = bc.maxWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            attachmentBody,
            //SizedBox(width: 5,),
            downloadLink != null ? InkWell(
              child: Icon(Icons.download_sharp, color: Colors.blueAccent, size: 30),
              onTap: () async { downloadFile(downloadLink); },
            ) : SizedBox(),
          ]);}));
    }
    return LayoutBuilder(builder: (context, bc) {
      //print('return Column bc=$bc');
      return Container(child: Column(children: widgets), width: bc.maxWidth,);});
  }

  String buildDownloadUrl(String downloadLink) {
    Map<String, String> query = {
      'rc_token': widget.authRC.data.authToken,
      'rc_uid': widget.authRC.data.userId
    };
    var uri = serverUri.replace(path: downloadLink, queryParameters: query);
    return uri.toString();
  }

  void downloadFile(String downloadLink) {
    String downloadUrl = buildDownloadUrl(downloadLink);
    downloadByUrlLaunch(downloadUrl);
  }

  void downloadByUrlLaunch(String downloadUrl) {
    launch(Uri.encodeFull(downloadUrl));
  }

  bool messageHasMessageAttachments(List<MessageAttachment> attachments) {
    bool haveIt = attachments != null && attachments.length > 0 && attachments[0].messageLink != null;
    // if (haveIt)
    //   log('messageHasAttachments=${message.attachments[0]}');
    return haveIt;
  }

  Widget buildMessageBody(Message message) {
    String userName = _getUserName(message);
    message.msg = message.msg.replaceAll(RegExp(r'\[ \]\(.*\)[\s]*'), '');
    message.urls = null;
    String newMessage = message.msg;
    switch (message.t) {
      case 'au': newMessage = '$userName added ${message.msg}'; break;
      case 'ru': newMessage = '$userName removed ${message.msg}'; break;
      case 'uj': newMessage = '$userName joined'; break;
      case 'room_changed_avatar': newMessage = '$userName change room avatar'; break;
      case 'room_changed_description': newMessage = '$userName change room description'; break;
      case 'message_pinned': newMessage = '$userName pinned message'; break;
      default: if (message.t != null ) newMessage = '$userName act ${message.t}'; break;
    }
    var messageFontSize = MESSAGE_FONT_SIZE * textScaleFactor;
    if (message.t != null)
      messageFontSize = MESSAGE_FONT_SIZE * 0.6;
    else if (message.tmid != null || message.isAttachment)
      messageFontSize = MESSAGE_FONT_SIZE * 0.8;
    var messageBackgroundColor = Colors.white;
    if (message.user.id == widget.me.id)
      messageBackgroundColor = Colors.amber.shade100;

    double messageBorderWidth = 0;
    if (message.isAttachment)
      messageBorderWidth = 1;
    return Container(
        child: Column(children: <Widget>[
          newMessage == null || newMessage.isEmpty ? SizedBox() : Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: messageBackgroundColor,
                border: Border.all(color: Colors.blueAccent, width: messageBorderWidth),
                borderRadius: BorderRadius.all(
                    Radius.circular(2.0) //                 <--- border radius here
                ),
              ),
              width: MediaQuery.of(context).size.width,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                MouseRegion(
                cursor: SystemMouseCursors.text,
                child: kIsWeb && !widget.onTapExit ? SelectableText(
                  newMessage,
                  style: TextStyle(fontSize: messageFontSize, color: Colors.black, fontWeight: FontWeight.normal),
                ) : Linkable(
                  text: newMessage,
                  style: TextStyle(fontSize: messageFontSize, color: Colors.black54, fontWeight: FontWeight.normal),
                )),
                message.editedBy != null ?
                  Text('(${message.editedBy.username} edited)', style: TextStyle(fontSize: 9, color: Colors.purple),) :
                  SizedBox(),
              ])
          ),
          message.urls != null && message.urls.length > 0
              ? buildUrls(message)
              : SizedBox(),
        ]));
  }

  Widget buildUrls(Message message) {
    UrlInMessage urlInMessage = message.urls.first;
    return GestureDetector(
        onTap: () async {
          if (widget.onTapExit)
            Navigator.pop(context, message.id);
          else
            await canLaunch(urlInMessage.url) ? launch(urlInMessage.url) : print('url launch failed${urlInMessage.url}');
        },
        child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: urlInMessage.meta != null && urlInMessage.meta['ogImage'] != null
                ? Column (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget> [
                  urlInMessage.meta['ogImage'] != null ? Image.network(urlInMessage.meta['ogImage'], cacheWidth: 500,) : SizedBox(),
                  urlInMessage.meta['ogTitle'] != null ? Text(urlInMessage.meta['ogTitle'], style: TextStyle(fontWeight: FontWeight.bold)) : SizedBox(),
                  urlInMessage.meta['ogDescription'] != null ? Text(urlInMessage.meta['ogDescription'], style: TextStyle(fontSize: 11, color: Colors.blue)) : SizedBox(),
                ])
                : urlInMessage.meta != null && urlInMessage.meta['oembedThumbnailUrl'] != null
                ? Column (children: <Widget> [
                  urlInMessage.meta['oembedThumbnailUrl'] != null ? Image.network(urlInMessage.meta['oembedThumbnailUrl'], cacheWidth: 500) : SizedBox(),
                  urlInMessage.meta['oembedTitle'] != null ? Text(urlInMessage.meta['oembedTitle']) : SizedBox(),
                ])
                : Linkable(text: urlInMessage.url),
        ));
  }

  Widget getImage(Message message, MessageAttachment attachment) {
    if (widget.onTapExit || message.isAttachment) {
      return InkWell(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: buildImageByLayout(message, attachment)),
        onTap: () {
          if (widget.onTapExit)
            Navigator.pop(context, message.id);
          else
            widget.chatViewState.findAndScroll(message.id);
        },
      );
    }

    return FullScreenWidget(
      child: Hero(
        tag: attachment.imageUrl + message.id + message.isAttachment.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: buildImageByLayout(message, attachment),
        ),
      ),
    );
  }

  buildImageByLayout(Message message, MessageAttachment attachment) {
    String imagePath = attachment.imageUrl;
    Map<String, String> header = {
      'X-Auth-Token': widget.authRC.data.authToken,
      'X-User-Id': widget.authRC.data.userId
    };

    Map<String, String> query = {
      'rc_token': widget.authRC.data.authToken,
      'rc_uid': widget.authRC.data.userId
    };

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      //print('buildImageByLayout constraints=$constraints');
      var dpr = MediaQuery.of(context).devicePixelRatio;
      var imageWidth = attachment.renderWidth;
      var imageWidthInDevice = imageWidth * dpr;

      double r = imageWidthInDevice / attachment.imageDimensions.width;
      double imageHeightInDevice = attachment.imageDimensions.height * r;

      var uri = serverUri.replace(path: imagePath, queryParameters: query);

      var image = ei.ExtendedImage.network(uri.toString(),
        width: imageWidthInDevice / dpr,
        height: imageHeightInDevice / dpr,
        cacheWidth: 800,
        fit: BoxFit.contain,
        headers: header,
        cache: true,
        mode: kIsWeb ? ei.ExtendedImageMode.none : ei.ExtendedImageMode.gesture,
        initGestureConfigHandler: (state) {
          return ei.GestureConfig(
            minScale: 0.9,
            animationMinScale: 0.7,
            maxScale: 3.0,
            animationMaxScale: 3.5,
            speed: 1.0,
            inertialSpeed: 100.0,
            initialScale: 1.0,
            inPageView: false,
            initialAlignment: ei.InitialAlignment.center,
          );
        },
      );
      return image;
    });
  }

  pickReaction(Message message) async {
    var emojiPicker = epf.EmojiPicker(
      onEmojiSelected: (category, emoji) {
        print('@@@ selected emoji=${emoji.name}');
        Navigator.pop(context, emoji.name);
      },
      config: epf.Config(
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

  MessageService getMessageService() {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    return MessageService(rocketHttpService);
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
    if (message.attachments != null && message.attachments.length > 0) {
      var att = message.attachments.first;
      imagePath = att.imageUrl;
      if (att.titleLinkDownload != null && att.titleLinkDownload)
        downloadPath = message.attachments.first.titleLink;
    }
    List<PopupMenuEntry<String>> items = [];
    items.add(PopupMenuItem(child: Text('Copy...'), value: 'copy'));
    items.add(PopupMenuItem(child: Text('Share...'), value: 'share'));
    items.add(PopupMenuItem(child: Text('Quote...'), value: 'quote'));
    if (message.tmid == null)
      items.add(PopupMenuItem(child: Text('Reply...'), value: 'reply'));
    if (_messageStarred(message))
      items.add(PopupMenuItem(child: Text('UnStar...'), value: 'unstar'));
    else
      items.add(PopupMenuItem(child: Text('Star...'), value: 'star'));
    items.add(PopupMenuItem(child: Text('Reaction...'), value: 'reaction'));
    if (downloadPath != null)
      items.add(PopupMenuItem(child: Text('Download...'), value: 'download'));
    if (imagePath != null && !kIsWeb)
      items.add(PopupMenuItem(child: Text('Set as Profile...'), value: 'set_profile'));
    if (message.user.id == widget.me.id) {
      items.add(PopupMenuItem(child: Text('Delete...'), value: 'delete'));
      items.add(PopupMenuItem(child: Text('Edit...'), value: 'edit'));
    }

    var pos = RelativeRect.fromLTRB(0,0,0,0);
    if (tabPosition != null)
      pos = RelativeRect.fromLTRB(0, tabPosition.dy - 100, 0, tabPosition.dy + 100);
    String value = await showMenu(context: context,
      position: pos,
      items: items,
    );
    if (value == 'delete') {
      widget.chatHomeState.deleteMessage(message.id);
    } else if (value == 'copy') {
      Clipboard.setData(ClipboardData(text: message.msg));
    } else if (value == 'quote') {
      replyMessage();
    } else if (value == 'reply') {
      replyMessage();
    } else if (value == 'star') {
      getMessageService().starMessage(message.id, widget.authRC);
    } else if (value == 'unstar') {
      getMessageService().unStarMessage(message.id, widget.authRC);
    } else if (value == 'reaction') {
      pickReaction(message);
    } else if (value == 'edit') {
      handleUpdateMessage(message);
    } else if (value == 'download') {
      downloadFile(downloadPath);
    } else if (value == 'set_profile') {
      setProfilePicture(imagePath);
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
          share = buildDownloadUrl(getDownloadLink(message));
        if (share != null && share.isNotEmpty)
          Share.share(share);
      }
    }
  }

  void replyMessage() {
    widget.chatViewState.setState(() {
      quotedMessage = message;
      quotedMessage.isReply = true;
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
      scrollDirection: Axis.horizontal,
      itemCount: reactions.keys.length,
      itemBuilder: (context, index) {
        var emoji = reactions.keys.elementAt(index);
        Reaction r = reactions[emoji];
        return GestureDetector (
            onTap: () { widget.chatItemViewState.onReactionTouch(widget.message, emoji, r); },
            child:Container(
                child: Row(children: <Widget>[
                  Text(emojis[emoji], style: TextStyle(fontSize: 17)),
                  Text(r.usernames.length.toString(), style: TextStyle(fontSize: 10)),
                ])
            ));
      },
    );
  }

}

