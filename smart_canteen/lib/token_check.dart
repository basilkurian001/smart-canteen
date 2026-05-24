import 'package:flutter/material.dart';
import 'package:smart_canteen/auth_service.dart';
import 'signin.dart';
import 'homescreen.dart';

class TokenCheckPage extends StatefulWidget {
  const TokenCheckPage({super.key});

  @override
  State<TokenCheckPage> createState() => _TokenCheckPageState();
}

class _TokenCheckPageState extends State<TokenCheckPage> {
  @override
  void initState() {
    super.initState();
    validateToken();
  }

  Future<void> validateToken() async {
    final auth = AuthService();
    final token = await auth.getToken();

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      return;
    }

    try {
      final me = await auth.me();     // 🔥 Server validates token
      print(me);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(me: me)),
      );
    } catch (e) {
      await auth.clearToken();       // ❌ Token invalid → clear it
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
