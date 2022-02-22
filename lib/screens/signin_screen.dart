import 'package:flutter/material.dart';
import 'package:flutter_chat_app/services/auth.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messenger'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => AuthMethods().signInWithGoogle(context),
          child: Container(
            padding: EdgeInsets.all(10),
            color: Colors.amber,
            child: Text("Sign in with google!"),
          ),
        ),
      ),
    );
  }
}
