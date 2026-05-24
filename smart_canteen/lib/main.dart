import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/auth_service.dart';
import 'package:smart_canteen/homescreen.dart';
import 'package:smart_canteen/signin.dart';
import 'package:smart_canteen/token_check.dart';

/* =========================
   SERVER CHECK FUNCTION
========================= */
Future<bool> checkServerStatus() async {
  try {
    final response = await http
        .get(Uri.parse("http://10.125.22.31:3000/health"))
        .timeout(const Duration(seconds: 10));

    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/* =========================
   ENTRY POINT
========================= */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/* =========================
   ROOT APP
========================= */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Canteen',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const ServerCheckPage(), // ✅ FIRST PAGE
    );
  }
}

/* =========================
   SERVER CHECK PAGE
========================= */
class ServerCheckPage extends StatefulWidget {
  const ServerCheckPage({super.key});

  @override
  State<ServerCheckPage> createState() => _ServerCheckPageState();
}

class _ServerCheckPageState extends State<ServerCheckPage> {
  bool? serverOnline;

  @override
  void initState() {
    super.initState();
    _verifyServer();
  }

  Future<void> _verifyServer() async {
    final result = await checkServerStatus();
    setState(() => serverOnline = result);

    // ✅ If server is live → go to token check
    if (result && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TokenCheckPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Checking server
    if (serverOnline == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ Server offline
    if (serverOnline == false) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Server is offline.\nCheck your connection.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() => serverOnline = null);
                  _verifyServer();
                },
                child: const Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    // ✔️ Server online (navigation already triggered)
    return const SizedBox();
  }
}
