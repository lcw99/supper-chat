import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/response/sync_threads_list.dart';
import 'chatitemview.dart';

Widget buildTaggedMessage(widget, room, Future<ChannelMessages> future) {
  return FutureBuilder(
      future: future,
      builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
        if(snapshot.hasData) {
          return ListView.builder(
              itemCount: snapshot.data.messages.length,
              itemBuilder: (BuildContext c, int index) {
                var message = snapshot.data.messages[index];
                return ChatItemView(chatHomeState: widget.chatHomeState, message: message, me: widget.me, authRC: widget.authRC, onTapExit: true, room: room,);
              });
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
  );
}

Widget buildThreadList(widget, room) {
  return FutureBuilder(
      future: getChannelService().syncThreadsList(room.id, widget.authRC),
      builder: (context, AsyncSnapshot<SyncThreadListResponse> snapshot) {
        if(snapshot.hasData) {
          List<Message> messages = snapshot.data.threads.update;
          return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (BuildContext c, int index) {
                var message = messages[index];
                return ChatItemView(chatHomeState: widget.chatHomeState, message: message, me: widget.me, authRC: widget.authRC, onTapExit: true, room: room,);
              });
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
  );
}

String searchText;
Widget buildSearchMessage(widget, room) {
  return StatefulBuilder(builder: (context, setState) {
    return Column(children: [
      Container(child: TextFormField(
        autofocus: true,
        keyboardType: TextInputType.text,
        maxLines: 1,
        decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),),
        onChanged: (text) {
          if (text == null || text.isEmpty)
            return;
          fromCancelable(getTranslation(text)).then((value) {
            print("Then called: $value");
            setState(() { searchText = text; });
          });
        },
      ), margin: EdgeInsets.only(left: 15, top:10, bottom: 0, right: 15),),
      FutureBuilder(
          future: _getSearchedMessages(widget, room, searchText),
          builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
            if(snapshot.hasData && snapshot.data.messages != null) {
              return Expanded(child: Column(children: [
                Container(child: Text('count = ${snapshot.data.messages.length}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  alignment: Alignment.centerLeft, margin: EdgeInsets.only(left: 15, bottom: 10),),
                Expanded(child: ListView.builder(
                    itemCount: snapshot.data.messages.length,
                    itemBuilder: (BuildContext c, int index) {
                      var message = snapshot.data.messages[index];
                      return ChatItemView(chatHomeState: widget.chatHomeState, message: message, me: widget.me, authRC: widget.authRC, onTapExit: true, room: room,);
                    }))
              ],));
            } else {
              return Text('no result\nregular expression possible, like /.*text.*/', style: TextStyle(fontSize: 12,), );
            }
          }
      ),
    ],);
  });
}

Future<ChannelMessages> _getSearchedMessages(widget, room, String text) {
  if (text == null || text.isEmpty)
    return Future.value(ChannelMessages());
  bool isRegular = text.startsWith('/') && (text.endsWith('/') || text.endsWith('/i'));
  if (!isRegular || text.length < 3) {
    text = text.replaceAll('/', '\x2f');
    text = '/.*$text.*/';
  }
  return getChannelService().chatSearch(room.id, text, 100, widget.authRC);
}

CancelableOperation<void> cancellableOperation;
Future<dynamic> fromCancelable(Future<dynamic> future) async {
  cancellableOperation?.cancel();
  cancellableOperation = CancelableOperation.fromFuture(future, onCancel: () {
    print('Operation Cancelled');
    cancellableOperation = null;
  });
  return cancellableOperation.value;
}

Future<dynamic> getTranslation(String text) async {
  return Future.delayed(const Duration(milliseconds: 1000), () {
    return text;
  });
}



