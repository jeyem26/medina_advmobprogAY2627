import 'package:flutter_dotenv/flutter_dotenv.dart';

const String defaultHost = 'https://dummyjson.com';

String get host => dotenv.env['HOST'] ?? defaultHost;

const String isLoggedInKey = 'isLoggedIn';
const String userIdKey = 'userId';
const String accessTokenKey = 'accessToken';
const String usernameKey = 'username';
const String emailKey = 'email';
