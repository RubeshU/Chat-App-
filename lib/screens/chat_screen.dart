import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/helper/sharedpref_helper.dart';
import 'package:flutter_chat_app/services/database.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatWithUserName, name;
  ChatScreen(this.chatWithUserName, this.name);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatRoomId, messageId = '';
  String myName, myProfilePic, myUserName, myEmail;
  Stream messageStream;
  TextEditingController messageTextEditingController = TextEditingController();

  getInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
    chatRoomId = getChatRoomIdByUserNames(myUserName, widget.chatWithUserName);
  }

  getChatRoomIdByUserNames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  Widget chatMessageTile(
      BuildContext context, String message, bool isSentByMe) {
    return Row(
      mainAxisAlignment:
          isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomRight:
                      isSentByMe ? Radius.circular(0) : Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft:
                      isSentByMe ? Radius.circular(24) : Radius.circular(0)),
              color: Colors.blue),
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget chatMessages(BuildContext context) {
    return StreamBuilder(
        stream: messageStream,
        builder: (ctx, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: EdgeInsets.only(bottom: 70, top: 60),
                  reverse: true,
                  itemBuilder: (ctx, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return chatMessageTile(
                        context, ds['message'], myUserName == ds['sendBy']);
                  },
                  itemCount: snapshot.data.docs.length,
                )
              : Center(child: CircularProgressIndicator());
        });
  }

  getAndSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getInfoFromSharedPreferences();
    getAndSetMessages();
  }

  addMessage(bool sendClicked) {
    if (messageTextEditingController.text != '') {
      String message = messageTextEditingController.text;
      var lastMessageTs = DateTime.now();
      Map<String, dynamic> messageInfoMap = {
        'message': message,
        'sendBy': myUserName,
        'ts': lastMessageTs,
        'imgUrl': myProfilePic,
      };
      print(chatRoomId);

      print(messageInfoMap);
      if (messageId == '') {
        messageId = randomAlphaNumeric(12);
      }
      print('message id $messageId');
      DatabaseMethods()
          .addMessageInfo(chatRoomId, messageId, messageInfoMap)
          .then((_) {
        Map<String, dynamic> lastMessageInfoMap = {
          'lastMessage': message,
          'lastMessageSendTs': lastMessageTs,
          'lastMessageSendBy': myUserName,
        };
        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);
        if (sendClicked) {
          messageTextEditingController.text = '';
          messageId = '';
        }
      });
    }
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        child: Stack(
          children: [
            chatMessages(context),
            Container(
              child: Container(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type the message',
                            contentPadding: EdgeInsets.all(8)),
                        onChanged: (_) {
                          addMessage(false);
                        },
                        controller: messageTextEditingController,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          addMessage(true);
                        },
                        icon: Icon(Icons.send))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
