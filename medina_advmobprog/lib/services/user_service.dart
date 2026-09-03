import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/user.dart';

class UserService {
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 30,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Sign in failed');
  }

  Future<User> getUserById(int userId) async {
    final response = await http.get(Uri.parse('$host/users/$userId'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load user information');
  }
}
