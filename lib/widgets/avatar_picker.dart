import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../services/storage_service.dart';

class AvatarPicker extends StatefulWidget {
  final String userId;
  final String? currentAvatarUrl;
  final Function(String) onAvatarChanged;
  final bool isGuest;

  const AvatarPicker({
    Key? key,
    required this.userId,
    this.currentAvatarUrl,
    required this.onAvatarChanged,
    this.isGuest = false,
  }) : super(key: key);

  @override
  _AvatarPickerState createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _isUploading = false;

  Future<bool> _checkAndRequestPermission(Permission permission) async {
    try {
      if (Platform.isAndroid) {
        // Kiểm tra phiên bản Android
        final androidInfo = await _deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13 trở lên
          if (permission == Permission.photos) {
            permission = Permission.photos;
          }
        } else {
          // Android 12 trở xuống
          if (permission == Permission.photos) {
            permission = Permission.storage;
          }
        }
      }

      final status = await permission.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await permission.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(
            permission == Permission.camera ? 'camera' : 'thư viện ảnh');
        return false;
      }

      return false;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick An Avatar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'), // 'Chọn từ thư viện'
              onTap: () async {
                Navigator.pop(context);
                final hasPermission =
                    await _checkAndRequestPermission(Permission.photos);
                if (hasPermission) {
                  _pickImage(ImageSource.gallery);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Picture'), // 'Chụp ảnh mới'
              onTap: () async {
                Navigator.pop(context);
                final hasPermission =
                    await _checkAndRequestPermission(Permission.camera);
                if (hasPermission) {
                  _pickImage(ImageSource.camera);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text(
            'You need to grant $feature access to use this feature.'), // 'Bạn cần cấp quyền $feature để sử dụng tính năng này.'
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'), // Đóng
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'), // 'Mở Cài đặt'
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);

        try {
          // Upload ảnh lên Firebase Storage
          String downloadUrl = await _storageService.uploadUserAvatar(
            File(image.path),
            widget.userId,
          );

          // Gọi callback để cập nhật avatar mới
          widget.onAvatarChanged(downloadUrl);
        } catch (e) {
          String errorMessage =
              'Error uploading image'; // 'Lỗi khi tải ảnh lên'
          if (e.toString().contains('unauthorized')) {
            errorMessage =
                'You need to log in to configure avatar.'; // Bạn cần đăng nhập để thay đổi ảnh đại diện
          } else if (e.toString().contains('User not found')) {
            errorMessage =
                'You need to log in to configure avatar.'; // 'Bạn cần đăng nhập để thay đổi ảnh đại diện'
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error picking image: $e')), // 'Lỗi khi chọn ảnh: $e'
        );
      }
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading || widget.isGuest ? null : _showImageSourceDialog,
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: widget.currentAvatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.currentAvatarUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 75,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 75,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          if (!widget.isGuest)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _isUploading ? null : _showImageSourceDialog,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
