import 'package:firebase_auth/firebase_auth.dart';

class GetData{
  static String getUID() {
    return FirebaseAuth.instance.currentUser?.uid ?? "";
  }
}