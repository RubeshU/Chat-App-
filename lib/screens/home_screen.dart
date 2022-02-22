import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/helper/sharedpref_helper.dart';
import 'package:flutter_chat_app/screens/chat_screen.dart';
import 'package:flutter_chat_app/screens/signin_screen.dart';
import 'package:flutter_chat_app/services/auth.dart';
import 'package:flutter_chat_app/services/database.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String myName, myProfilePic, myUserName, myEmail;
  bool isSearching = false;
  TextEditingController searchUserNameController = TextEditingController();
  Stream usersStream;
  Stream chatRoomStream;

  getInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
  }

  onScreenLoades() async {
    await getInfoFromSharedPreferences();
    getChatRooms();
  }

  @override
  void initState() {
    onScreenLoades();
    super.initState();
  }

  onSearhcBtnClicked() async {
    setState(() {
      isSearching = true;
    });

    usersStream = await DatabaseMethods()
        .getUserByUserName(searchUserNameController.text);
  }

  getChatRoomIdByUserNames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  getChatRooms() async {
    chatRoomStream = await DatabaseMethods().getChatRooms();
  }

  Widget chatRoomsList(BuildContext context) {
    return StreamBuilder(
        stream: chatRoomStream,
        builder: (ctx, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemBuilder: (ctx, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return ChatRoomListTile(
                        ds['lastMessage'], ds.id, myUserName);
                  },
                  shrinkWrap: true,
                  itemCount: snapshot.data.docs.length,
                )
              : CircularProgressIndicator();
        });
  }

  Widget searchUserListTile(context, userData) {
    return GestureDetector(
      onTap: () {
        var chatRoomId =
            getChatRoomIdByUserNames(myUserName, userData['username']);
        Map<String, dynamic> chatRoomInfoMap = {
          'users': [myUserName, userData['username']],
        };
        DatabaseMethods().createChatRoom(chatRoomId, chatRoomInfoMap);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatScreen(userData['username'], userData['name']),
            ));
      },
      child: ListTile(
        leading:
            CircleAvatar(backgroundImage: NetworkImage(userData['imgUrl'])),
        title: Text(userData['username']),
        subtitle: Text(userData['email']),
      ),
    );
  }

  Widget searchUsersList(BuildContext context) {
    return StreamBuilder(
        stream: usersStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return searchUserListTile(context, ds);
                  },
                  itemCount: snapshot.data.docs.length,
                  shrinkWrap: true,
                )
              : Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                AuthMethods().signOut().then((_) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => SignInScreen(),
                  ));
                });
              },
              icon: Icon(Icons.exit_to_app))
        ],
        title: Text('Messenger'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                isSearching
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              searchUserNameController.text = '';
                              isSearching = false;
                            });
                          },
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    margin: EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      children: [
                        Expanded(
                            child: TextField(
                          controller: searchUserNameController,
                          decoration: InputDecoration(
                              border: InputBorder.none, hintText: 'username'),
                        )),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.search,
                            ),
                            onPressed: () {
                              if (searchUserNameController.text != '') {
                                onSearhcBtnClicked();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isSearching ? searchUsersList(context) : chatRoomsList(context),
          ],
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  String lastMessage, chatRoomId, myUserName;
  ChatRoomListTile(this.lastMessage, this.chatRoomId, this.myUserName);
  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = '', name = '', username = '';
  getThisUserInfo() async {
    username =
        widget.chatRoomId.replaceAll(widget.myUserName, '').replaceAll('_', '');

    QuerySnapshot query = await DatabaseMethods().getUserInfo(username);
    name = await query.docs[0]['name'];
    profilePicUrl = '${query.docs[0]['imgUrl']}';
    setState(() {});
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return profilePicUrl != ''
        ? GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatScreen(username, name)));
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(profilePicUrl),
              ),
              title: Text(name),
              subtitle: Text(widget.lastMessage),
            ),
          )
        : Container();
  }
}
