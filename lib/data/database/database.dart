import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../functions/getdata.dart';

class Database {
  static final Database _database = Database._internal();
  String username = '';

  factory Database() {
    return _database;
  }

  Database._internal();

  Future<void> setUserName(String username) async {
    this.username = username;
  }

  Future<void> getUserName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      this.username = userDoc['username'];
    }
  }
}