import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../enums/processing/dialog_name_enum.dart';
import '../generated/l10n.dart';
import '../services/storage_service.dart';
import 'dialog/information_dialog.dart';

class AvatarPicker extends StatefulWidget {
  final String userId;
  final String? currentAvatarUrl;
  final Function(String) onAvatarChanged;
  final bool isGuest;

  const AvatarPicker({
    super.key,
    required this.userId,
    this.currentAvatarUrl,
    required this.onAvatarChanged,
    this.isGuest = false,
  });

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
      // On web, permissions are handled by the browser
      // For camera access, the browser will prompt the user
      // For gallery access, no special permissions are needed
      if (kIsWeb) {
        return true;
      }

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
      if (kDebugMode) {
        print('Error checking permission: $e');
      }
      return false;
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (kIsWeb) {
      // On web, directly open file picker for gallery
      final hasPermission = await _checkAndRequestPermission(Permission.photos);
      if (hasPermission) {
        _pickImage(ImageSource.gallery);
      }
    } else {
      // On mobile, show dialog with options
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).pickAvatar),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(S.of(context).chooseFromGallery),
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
                title: Text(S.of(context).takeAPicture),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
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
      if (kDebugMode) {
        print('Attempting to pick image from source: $source');
        if (kIsWeb) {
          print('Running on web platform');
        }
      }

      final XFile? image = await _picker
          .pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (kDebugMode) {
            print('Image picker timed out - possible permission issue');
          }
          throw Exception(
              'Camera access timed out. Please check browser permissions.');
        },
      );

      if (kDebugMode) {
        print(
            'Image picker result: ${image != null ? "Success" : "Cancelled/Error"}');
      }

      if (image != null) {
        setState(() => _isUploading = true);

        try {
          // Upload ảnh lên Firebase Storage
          String downloadUrl;
          if (kIsWeb) {
            // On web, we need to handle the file differently
            downloadUrl = await _storageService.uploadUserAvatarFromWeb(
              image,
              widget.userId,
            );
          } else {
            // On mobile platforms, use the File class
            downloadUrl = await _storageService.uploadUserAvatar(
              File(image.path),
              widget.userId,
            );
          }

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
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => InformationDialog(
                title: S.of(context).error,
                content: errorMessage,
                dialogName: DialogName.failure,
                buttonText: S.of(context).ok,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            );
          }
        }
      }
    } catch (e) {
      String errorMessage = 'Error picking image: $e';

      // Handle specific camera access errors on web
      if (kIsWeb && source == ImageSource.camera) {
        if (e.toString().contains('Permission denied') ||
            e.toString().contains('NotAllowedError') ||
            e.toString().contains('timed out')) {
          errorMessage = 'Camera access denied or timed out. Please:\n'
              '1. Allow camera access in your browser settings\n'
              '2. Make sure you\'re using HTTPS\n'
              '3. Check if another app is using your camera';
        } else if (e.toString().contains('NotFoundError')) {
          errorMessage =
              'No camera found. Please connect a camera to your device.';
        } else if (e.toString().contains('NotReadableError')) {
          errorMessage =
              'Camera is being used by another application. Please close other camera apps.';
        } else {
          errorMessage = 'Camera access failed. Please check:\n'
              '1. Browser camera permissions\n'
              '2. HTTPS connection\n'
              '3. Camera availability';
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => InformationDialog(
            title: S.of(context).error,
            content: errorMessage,
            dialogName: DialogName.failure,
            buttonText: S.of(context).ok,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
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
                  color: Colors.black.withValues(alpha: 0.5),
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
