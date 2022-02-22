import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_app/helper/sharedpref_helper.dart';

class DatabaseMethods {
  Future addUserInfoToDB(
      String userId, Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getUserByUserName(String userName) async {
    return FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: userName)
        .snapshots();
  }

  Future addMessageInfo(
      String chatRoomId, String messageId, Map messageInfoMap) async {
    return FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('chats')
        .doc(messageId)
        .set(messageInfoMap);
  }

  updateLastMessageSend(
      String chatRoomId, Map<String, dynamic> lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  createChatRoom(String chatRoomId, Map chatRoomInfoMap) async {
    final snapShot = await FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatRoomId)
        .get();
    if (snapShot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('chats')
        .orderBy('ts', descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String myUserName = await SharedPreferenceHelper().getUserName();
    return FirebaseFirestore.instance
        .collection('chatrooms')
        .where('users', arrayContains: myUserName)
        .orderBy('lastMessageSendTs', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String userName) async {
    return FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: userName)
        .get();
  }
}
