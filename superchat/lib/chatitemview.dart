import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:superchat/flatform_depended/platform_depended.dart';
import 'package:universal_io/io.dart' as uio;
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart' as ei;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:linkable/linkable.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:http_parser/http_parser.dart';

import 'chathome.dart';
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

  ChatItemView({Key key, @required this.chatHomeState, @required this.me, @required this.authRC,
    this.onTapExit = false, this.message, this.index = 0, this.room,
  }) : super(key: key);

  @override
  ChatItemViewState createState() => ChatItemViewState();
}

class ChatItemViewState extends State<ChatItemView> {
  Message message;
  User messageUser;
  GlobalKey<_ReactionViewState> keyReactionView = GlobalKey();
  @override
  Widget build(BuildContext context) {
    if (message == null)
      message = widget.message;
    messageUser = Utils.getCachedUser(message.user.id);
    if (messageUser != null)
      return _buildChatItem(messageUser, message);
    return FutureBuilder<User>(
        future: Utils.getUserInfo(widget.authRC, userId: message.user.id),
        builder: (context, AsyncSnapshot<User> snapshot) {
          if (snapshot.hasData) {
            messageUser = snapshot.data;
            return _buildChatItem(messageUser, message);
          } else
            return SizedBox();
        });
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
  Widget _buildChatItem(User user, Message message, {String messageText, String avatarPath, String userName}) {
    // if (message.starred != null && message.starred.length > 0)
    //   log('@@@ starred message=' + message.toString());
    // if (message.pinned != null && message.pinned)
    //   log('@@@ pinned message=' + message.toString());

    bool specialMessage = message.t != null;
    if (userName == null)
      userName = Utils.getUserNameByUser(messageUser);
    Color userNameColor = Colors.black;
    if (message.user.id == widget.me.id)
      userNameColor = Colors.green.shade900;
    var usernameFontSize = USERNAME_FONT_SIZE;
    if (messageText != null)
      usernameFontSize *= 0.7;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 9,),
        Utils.buildUserAvatar(specialMessage ? 20 : 40, messageUser),
        SizedBox(width: 5,),
        // user name
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
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
            ]),
            messageText != null
              ? Text(messageText, style: TextStyle(fontSize: MESSAGE_FONT_SIZE * 0.6))
              : _buildMessage(message, userName),
            SizedBox(height: 8,),
          ],)),
        SizedBox(width: 40,),
      ],);
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
  _buildMessage(Message message, String userName) {
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
      GestureDetector (
          onTapDown: (tabDownDetails) { tabPosition = tabDownDetails.globalPosition; },
          onLongPress: () { if (!widget.onTapExit) messagePopupMenu(context, tabPosition, message); },
          child:
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                bAttachments ? Container(child: buildAttachments(message)) : SizedBox(),
                GestureDetector (
                  onTap: () {
                    if (widget.onTapExit)
                      Navigator.pop(context, message.id);
                    else
                      pickReaction(message);
                  },
                  child: buildMessageBody(message),
                ),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: bReactions ?
                      Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width,
                        child: ReactionView(key: keyReactionView, chatItemViewState: this, message: message, reactions: reactions),
                      ) : SizedBox()),
                      Expanded(flex: 1, child: Container(
                          alignment: Alignment.topRight,
                          child: Text(dateStr, style: TextStyle(fontSize: 8, color: Colors.black54),)
                      )),
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
        downloadLink = attachment.imageUrl;
        attachmentBody = Column(children: <Widget>[
          getImage(message, attachment),
          attachment.description != null
              ? Text(attachment.description, style: TextStyle(fontSize: 11),)
              : SizedBox(),
        ]);
      } else {
        //log(message.toString());
        attachmentBody = Expanded(child:
          attachment.authorIcon != null && attachment.text != null
              ? _buildChatItem(messageUser, message, messageText: attachment.text, avatarPath: attachment.authorIcon, userName: attachment.authorName)
              : SizedBox(),
          );
      }
      widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            attachmentBody,
            SizedBox(width: 5,),
            Column(children: [
              downloadLink != null ? InkWell(
                child: Icon(Icons.download_sharp, color: Colors.blueAccent, size: 30),
                onTap: () async { downloadByUrlLaunch(downloadLink); },
              ) : SizedBox(),
            ])
          ]));
    }
    return Column(children: widgets);
  }

  String buildDownloadUrl(String downloadLink) {
    Map<String, String> query = {
      'rc_token': widget.authRC.data.authToken,
      'rc_uid': widget.authRC.data.userId
    };
    var uri = serverUri.replace(path: downloadLink, queryParameters: query);
    return uri.toString();
  }

  void downloadByUrlLaunch(String downloadLink) {
    launch(Uri.encodeFull(buildDownloadUrl(downloadLink)));
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
      case 'message_pinned': newMessage = '$userName pinned message'; break;
      default: if (message.t != null ) newMessage = '$userName act ${message.t}'; break;
    }
    var messageFontSize = MESSAGE_FONT_SIZE * textScaleFactor;
    if (message.t != null)
      messageFontSize = MESSAGE_FONT_SIZE * 0.6;
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
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                Linkable(
                  text: newMessage,
                  style: TextStyle(fontSize: messageFontSize, color: Colors.black54, fontWeight: FontWeight.normal),
                ),
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
                : SizedBox()
        ));
  }

  Widget getImage(Message message, MessageAttachment attachment) {
    String imagePath = attachment.imageUrl;
    Map<String, String> header = {
      'X-Auth-Token': widget.authRC.data.authToken,
      'X-User-Id': widget.authRC.data.userId
    };

    Map<String, String> query = {
      'rc_token': widget.authRC.data.authToken,
      'rc_uid': widget.authRC.data.userId
    };

    var dpr = MediaQuery.of(context).devicePixelRatio;
    var imageWidth = MediaQuery.of(context).size.width - 150;
    var imageWidthInDevice = imageWidth * dpr;

    double r = imageWidthInDevice / attachment.imageDimensions.width;
    double imageHeightInDevice = attachment.imageDimensions.height * r;

    var uri = serverUri.replace(path: imagePath, queryParameters: query);
    //print('@@@ image url=${uri.toString()}');
    //var image = ei.ExtendedImage.network(serverUri.replace(path: imagePath).toString(),
    var image = ei.ExtendedImage.network(uri.toString(),
      width: imageWidthInDevice / dpr,
      height: imageHeightInDevice / dpr,
      cacheWidth: 800,
      fit: BoxFit.contain,
      headers: header,
      cache: true,
      mode: ei.ExtendedImageMode.gesture,
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

    if (widget.onTapExit) {
      return InkWell(
        child: image,
        onTap: () { Navigator.pop(context, message.id); },
      );
    }

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

  pickReaction(Message message) async {
    String emoji = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return
          Dialog(insetPadding: EdgeInsets.all(15),
          child:
          SizedBox(height: 350, width: MediaQuery.of(context).size.width, child:
          epf.EmojiPicker(
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
          )
          ));
        }
    );

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
      if (att.titleLinkDownload)
        downloadPath = message.attachments.first.titleLink;
    }
    List<PopupMenuEntry<String>> items = [];
    items.add(PopupMenuItem(child: Text('Copy...'), value: 'copy'));
    items.add(PopupMenuItem(child: Text('Share...'), value: 'share'));
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
    } else if (value == 'star') {
      getMessageService().starMessage(message.id, widget.authRC);
    } else if (value == 'unstar') {
      getMessageService().unStarMessage(message.id, widget.authRC);
    } else if (value == 'reaction') {
      pickReaction(message);
    } else if (value == 'edit') {
      handleUpdateMessage(message);
    } else if (value == 'download') {
      downloadByUrlLaunch(downloadPath);
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
/*
        DefaultCacheManager manager = new DefaultCacheManager();
        uio.File f = await manager.getSingleFile(serverUri.replace(path: imagePath).toString(), headers: header);
        Share.shareFiles([f.path]);

        http.Response r = await getNetworkImageData(imagePath);
        if (r.statusCode == 200) {
          Uint8List data = r.bodyBytes;
          String contentType = r.headers['content-type'];
          MediaType mt = MediaType.parse(contentType);
          print('---content type=$contentType');
          uio.Directory tempDir = await getTemporaryDirectory();
          tempDir = await tempDir.createTemp();
          uio.File f = uio.File(tempDir.path + '/temp_shared_file.' + mt.subtype);
          print('---shared file=${f.path}');
          f.writeAsBytes(data);
        }
*/
      } else {
        String share = message.msg;
        if (share == null || share.isEmpty)
          share = buildDownloadUrl(getDownloadLink(message));
        if (share != null && share.isNotEmpty)
          Share.share(share);
      }
    }
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

