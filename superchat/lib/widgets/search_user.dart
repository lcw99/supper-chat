import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/response/spotlight_response.dart';
import 'package:superchat/chathome.dart';
import 'package:superchat/utils/dialogs.dart';

import '../utils/utils.dart';
import 'userinfo.dart';

typedef void SelectUserCallback(User user);

class SearchUser extends StatefulWidget {
  final Authentication authRC;
  final SelectUserCallback onUserSelected;
  const SearchUser({Key key, this.onUserSelected, this.authRC}) : super(key: key);

  @override
  SearchUserState createState() => SearchUserState();
}

class SearchUserState extends State<SearchUser> {
  DateTime from;
  List<User> users;
  TextEditingController _tecSearch = TextEditingController();
  String searchTitle = 'Online Recently';

  @override
  void initState() {
    from = DateTime.now().subtract(Duration(days: 30));
    super.initState();

    _tecSearch.addListener(() async {
      if (_tecSearch.text.isEmpty)
        return;
      String query = '@${_tecSearch.text}';
      SpotlightResponse s = await getChannelService().spotlight(query, widget.authRC);
      if (s.success == null || !s.success)
        return;
      setState(() {
        searchTitle = 'Search results';
        users.clear();
        users.addAll(s.users);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return
      Column(children: [
        Container(child: TextFormField(
          autofocus: true,
          readOnly: false,
          controller: _tecSearch,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
            helperText: 'Search user',),
        ), margin: EdgeInsets.all(15),),
        SizedBox(height: 10,),
        Container(child: Text(searchTitle), width: double.infinity,
          margin: EdgeInsets.only(left: 10),
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
          decoration: BoxDecoration(border: Border(left: BorderSide(width: 3, color: Colors.blueAccent))),),
        Expanded(flex: 5, child:
        FutureBuilder<List<User>>(
            future: getUsersPresence(),
            builder: (context, AsyncSnapshot snapshot){
              if (snapshot.hasData) {
                users = snapshot.data;
                return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      User user = users[index];
                      return GestureDetector(
                        onTap: () async {
                          var actionChild = InkWell(
                              onTap: () { Navigator.pop(context, 'im.create'); },
                              child: Wrap(children: <Widget>[
                                Icon(Icons.chat_outlined),
                                Text('Direct Message'),
                              ],)
                          );
                          String ret = await showDialogWithWidget(context, UserInfoWithAction(userInfo: user, actionChild: actionChild,), MediaQuery.of(context).size.height - 200);
                          if (ret != 'im.create')
                            return;
                          widget.onUserSelected(user);
                        },
                        child: Utils.buildUser(user, 40)
                      );
                    }
                );
              } else {
                return Center(child: CircularProgressIndicator(),);
              }
            })),
      ]);
  }

  Future<List<User>> getUsersPresence() async {
    if (users != null)
      return Future.value(users);
    return getUserService().usersPresence(from, widget.authRC);
  }
}
