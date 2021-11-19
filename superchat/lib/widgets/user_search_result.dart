import 'package:flutter/material.dart';
import 'package:image/image.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/response/spotlight_response.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/utils/utils.dart';

typedef void UserSelectCallback(User user);
class UserSearchResult extends StatefulWidget {
  final UserSelectCallback callback;
  final String searchText;
  final Authentication authRC;
  const UserSearchResult({Key key, this.callback, this.searchText, @required this.authRC}) : super(key: key);

  @override
  UserSearchResultState createState() => UserSearchResultState();
}

class UserSearchResultState extends State<UserSearchResult> {
  String searchText;

  @override
  Widget build(BuildContext context) {
    return buildUserSearchPopup(widget.callback);
  }

  void newSearch(String text) {
    setState(() {
      searchText = text;
    });
  }

  Widget buildUserSearchPopup(UserSelectCallback callback) {
    return FutureBuilder<SpotlightResponse>(
        future: searchUser(searchText),
        builder: (context, snapShot) {
          if (snapShot.hasData) {
            List<User> users = snapShot.data.users;
            return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    child: Utils.buildUser(users[i], 30),
                    onTap: () { callback(users[i]); },
                  );
                });
          }
          return Center(child: CircularProgressIndicator());
        }
    );
  }

  Future<SpotlightResponse> searchUser(searchText) {
    String query = '@$searchText';
    return getChannelService().spotlight(query, widget.authRC);
  }

  @override
  void initState() {
    searchText = widget.searchText;
    super.initState();
  }

}
