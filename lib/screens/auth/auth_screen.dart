import 'package:flutter/material.dart';
import 'package:taskswap/screens/auth/minimalist_login_screen.dart';
import 'package:taskswap/screens/auth/minimalist_signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLoginScreen = true;

  void _toggleScreen() {
    setState(() {
      _showLoginScreen = !_showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginScreen) {
      return LoginScreen(showSignUpScreen: _toggleScreen);
    } else {
      return SignupScreen(showLoginScreen: _toggleScreen);
    }
  }
}