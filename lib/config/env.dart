import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseClientId => dotenv.env['FIREBASE_CLIENT_ID'] ?? '';
  static String get firebaseCertificateHash =>
      dotenv.env['FIREBASE_CERTIFICATE_HASH'] ?? '';
}
