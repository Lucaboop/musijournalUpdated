import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:musictherapytracker_windows/profile_setup.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'SignIn.dart';
import 'SignUp.dart';

class SpotifyAuthService {
  // --- SINGLETON MAGIC ---
  // 1. Create a private, hidden instance of the class
  static final SpotifyAuthService _instance = SpotifyAuthService._internal();

  // 2. Use a "factory" to return that exact same instance every time
  factory SpotifyAuthService() {
    return _instance;
  }

  // 3. The actual constructor (hidden from the rest of the app)
  SpotifyAuthService._internal();
  // -----------------------

  // Your token variables
  String? _accessToken;
  DateTime? _tokenExpirationTime;

  // Your method to get the token
  Future<String?> getValidToken() async {
    if (_accessToken != null && _tokenExpirationTime != null) {
      if (DateTime.now().isBefore(_tokenExpirationTime!)) {
        print("here is the token: ${_accessToken}");
        return _accessToken; // Token is good, return it!
      }
    }

    print("Fetching new token...");
    await _fetchNewToken();
    print("here is the token: ${_accessToken}");
    return _accessToken;
  }

  Future<void> _fetchNewToken() async {
    String clientId = '258603d945d84bc0a781454539c4d9f1';
    String clientSecret = 'c8998fe37a4642a88ad9bf89e4f23179';

    final url = Uri.parse('https://accounts.spotify.com/api/token');
    final String credentials = '$clientId:$clientSecret';
    final String encodedCredentials = base64Encode(utf8.encode(credentials));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      print("succesfully created new token");
      final body = jsonDecode(response.body);
      _accessToken = body['access_token'];
      _tokenExpirationTime = DateTime.now().add(const Duration(minutes: 59));
    }
    else{
      print("failed creating new token, ${response.statusCode}");
    }
  }
}

class CreateSpotifyToken extends StatefulWidget {
  const CreateSpotifyToken({super.key});

  @override
  State<CreateSpotifyToken> createState() => _CreateSpotifyTokenState();
}

class _CreateSpotifyTokenState extends State<CreateSpotifyToken> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
