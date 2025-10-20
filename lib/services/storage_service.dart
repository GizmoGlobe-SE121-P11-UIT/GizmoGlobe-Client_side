import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadUserAvatar(File imageFile, String userId) async {
    try {
      // Kiểm tra người dùng đã đăng nhập chưa
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Tạo tên file duy nhất
      String fileName = 'avatars/$userId${path.extension(imageFile.path)}';

      // Upload file lên Firebase Storage
      TaskSnapshot snapshot =
          await _storage.ref().child(fileName).putFile(imageFile);

      // Lấy URL của file đã upload
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      rethrow;
    }
  }

  Future<String> uploadUserAvatarFromWeb(XFile imageFile, String userId) async {
    try {
      // Kiểm tra người dùng đã đăng nhập chưa
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Tạo tên file duy nhất
      String fileName = 'avatars/$userId.jpg'; // Use .jpg as default for web

      // Read the image file as bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Upload file lên Firebase Storage
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putData(
            imageBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );

      // Lấy URL của file đã upload
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image from web: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteUserAvatar(String userId) async {
    try {
      // Kiểm tra người dùng đã đăng nhập chưa
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Lấy danh sách các file trong thư mục avatars của user
      final ListResult result = await _storage.ref().child('avatars').listAll();

      // Tìm và xóa file avatar của user
      for (final Reference ref in result.items) {
        if (ref.name.contains(userId)) {
          await ref.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting avatar: $e');
      }
      rethrow;
    }
  }
}
