// lib/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class AuthService {
  static String baseUrl = dotenv.get('API_URL'); // emulator -> node on host

  // single key for SharedPreferences
  static const String _tokenKey = "jwt_token";

  // -- Signup: returns response map or throws --
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/signup");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    final body = _safeDecode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      if (body["token"] != null) {
        await saveToken(body["token"]);
      }
      return body;
    } else {
      throw Exception(body["message"] ?? body["error"] ?? "Signup failed");
    }
  }

  // -- Login: returns response map or throws --
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    print("============== LOGIN RESPONSE ==============");
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");
    print("============================================");

    final body = _safeDecode(res);

    if (res.statusCode == 200) {
      if (body["token"] != null) {
        await saveToken(body["token"]);
      }
      return body;
    } else {
      throw Exception(body["message"] ?? body["error"] ?? "Login failed (${res.statusCode})");
    }
  }

  // -- Save token (SharedPreferences) --
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print("AuthService: token saved");
  }

  // -- Read token --
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_tokenKey);
    // debug print to help you during testing (remove in production)
    // ignore: avoid_print
    print("AuthService: getToken -> ${t != null ? 'FOUND' : 'NULL'}");
    return t;
  }

  // -- Remove token (logout local) --
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print("AuthService: token cleared from local storage");
  }

  // -- Headers helper (includes Authorization when token present) --
  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // -- Example protected request (GET /auth/me) --
  Future<Map<String, dynamic>> me() async {
    final url = Uri.parse("$baseUrl/auth/me");
    final headers = await authHeaders();
    final res = await http.get(url, headers: headers);

    final body = _safeDecode(res);
    if (res.statusCode == 200) return body;
    throw Exception(body["message"] ?? body["error"] ?? "Failed to fetch user");
  }

  // -- Logout: call server then clear local token --
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        final url = Uri.parse("$baseUrl/auth/logout");
        final res = await http.post(url, headers: {"Authorization": "Bearer $token"});
        print("AuthService.logout: server responded ${res.statusCode} ${res.body}");
      } catch (e) {
        // network error — still clear local token
        print("AuthService.logout: network error calling server logout -> $e");
      }
    } else {
      print("AuthService.logout: no token to send to server");
    }

    // always clear local token
    await clearToken();
  }

  // -- Optional helper: check if logged in locally --
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // -- Private: safe JSON decoding with fallback for non-json responses --
  Map<String, dynamic> _safeDecode(http.Response res) {
    try {
      if (res.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"data": decoded};
    } catch (e) {
      print("AuthService: JSON parse error -> $e");
      return {"raw": res.body};
    }
  }

  Future<void> uploadAvatar(File image) async {
      final token = await getToken();
      if (token == null) {
        throw Exception("Not authenticated");
      }

      final uri = Uri.parse("$baseUrl/profile/avatar");
      final request = http.MultipartRequest("POST", uri);

      request.headers["Authorization"] = "Bearer $token";

      request.files.add(
        await http.MultipartFile.fromPath(
          "avatar", // MUST match upload.single("avatar")
          image.path,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception("Avatar upload failed: $body");
      }
  }


  Future<void> changeUsername(String name) async {
      final token = await getToken();

      final response = await http.post(
        Uri.parse("$baseUrl/profile/change-username"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name}),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)["message"]);
      }
    }

    Future<void> changePassword({
        required String oldPassword,
        required String newPassword,
      }) async {
        final token = await getToken();

        final response = await http.post(
          Uri.parse("$baseUrl/profile/change-password"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "oldPassword": oldPassword,
            "newPassword": newPassword,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception(jsonDecode(response.body)["message"]);
        }
      }
}
