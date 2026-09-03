import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

// Temporary fallback until authentication provides the logged-in user's ID.
const int defaultUserId = 1;
