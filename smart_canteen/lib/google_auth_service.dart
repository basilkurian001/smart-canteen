// lib/google_auth_service.dart
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  // 🔴 IMPORTANT: USE WEB CLIENT ID (NOT Android)
  static const String _webClientId = 'enter your google client id'; //important for google authentication

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _webClientId, // ⭐ THIS ENABLES idToken
  );

  /// Sign in with Google and authenticate with backend
  Future<Map<String, dynamic>> signInWithGoogle({
    required String backendUrl,
  }) async {
    // 1️⃣ Start Google sign-in
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }

    // 2️⃣ Get authentication tokens
    final GoogleSignInAuthentication auth =
        await account.authentication;

    final String? idToken = auth.idToken;
    final String? accessToken = auth.accessToken;

    // DEBUG (remove later)
    print('GOOGLE ACCESS TOKEN: $accessToken');
    print('GOOGLE ID TOKEN: $idToken');

    if (idToken == null) {
      throw Exception(
        'Google ID token is null. Check serverClientId (WEB CLIENT ID).',
      );
    }

    // 3️⃣ Send ID TOKEN to backend (AS "token")
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': idToken, // ✅ BACKEND EXPECTS THIS
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend signin failed: ${response.statusCode} ${response.body}',
      );
    }

    // 4️⃣ Backend returns { success, token, user }
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['token'] == null || data['user'] == null) {
      throw Exception('Invalid backend response');
    }

    return {
      'token': data['token'], // your app JWT
      'user': data['user'],   // user object from backend
    };
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    print('Google signed out');
  }
}
