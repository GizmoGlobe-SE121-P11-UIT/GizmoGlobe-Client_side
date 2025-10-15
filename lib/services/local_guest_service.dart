import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html show window;

class LocalGuestService {
  static const String _guestUserKey = 'gizmoglobe_guest_user';
  static const String _guestUserIdKey = 'gizmoglobe_guest_user_id';
  static const String _guestUserDataKey = 'gizmoglobe_guest_user_data';
  static const String _guestCustomerDataKey = 'gizmoglobe_guest_customer_data';
  static const String _guestCartKey = 'gizmoglobe_guest_cart';
  static const String _guestFavoritesKey = 'gizmoglobe_guest_favorites';

  /// Check if a guest user is already stored locally
  Future<bool> hasGuestUser() async {
    try {
      if (kIsWeb) {
        final guestUserId = html.window.localStorage[_guestUserIdKey];
        return guestUserId != null && guestUserId.isNotEmpty;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final guestUserId = prefs.getString(_guestUserIdKey);
        return guestUserId != null && guestUserId.isNotEmpty;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking guest user: $e');
      }
      return false;
    }
  }

  /// Get stored guest user ID from local storage
  Future<String?> getStoredGuestUserId() async {
    try {
      if (kIsWeb) {
        return html.window.localStorage[_guestUserIdKey];
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_guestUserIdKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored guest user ID: $e');
      }
      return null;
    }
  }

  /// Get stored guest user data from local storage
  Future<Map<String, dynamic>?> getStoredGuestUserData() async {
    try {
      String? userDataJson;
      if (kIsWeb) {
        userDataJson = html.window.localStorage[_guestUserDataKey];
      } else {
        final prefs = await SharedPreferences.getInstance();
        userDataJson = prefs.getString(_guestUserDataKey);
      }
      
      if (userDataJson != null) {
        return Map<String, dynamic>.from(json.decode(userDataJson));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored guest user data: $e');
      }
      return null;
    }
  }

  /// Get stored guest customer data from local storage
  Future<Map<String, dynamic>?> getStoredGuestCustomerData() async {
    try {
      String? customerDataJson;
      if (kIsWeb) {
        customerDataJson = html.window.localStorage[_guestCustomerDataKey];
      } else {
        final prefs = await SharedPreferences.getInstance();
        customerDataJson = prefs.getString(_guestCustomerDataKey);
      }
      
      if (customerDataJson != null) {
        return Map<String, dynamic>.from(json.decode(customerDataJson));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored guest customer data: $e');
      }
      return null;
    }
  }

  /// Generate a unique guest user ID
  String _generateGuestUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999).toString().padLeft(6, '0');
    return 'guest_${timestamp}_$randomSuffix';
  }

  /// Create or retrieve guest user data locally
  Future<Map<String, dynamic>?> createOrGetGuestUser() async {
    try {
      // Check if we already have a stored guest user
      final storedUserId = await getStoredGuestUserId();
      
      if (storedUserId != null) {
        // Try to get existing guest data
        final userData = await getStoredGuestUserData();
        if (userData != null) {
          if (kDebugMode) {
            print('Retrieved existing guest user: $storedUserId');
          }
          return userData;
        }
      }

      // Create new guest user
      final guestUserId = _generateGuestUserId();
      final guestData = await _createGuestUserData(guestUserId);
      
      // Store the guest data locally
      await _storeGuestData(guestUserId, guestData['userData'], guestData['customerData']);
      
      if (kDebugMode) {
        print('Created new guest user: $guestUserId');
      }
      
      return guestData['userData'];
    } catch (e) {
      if (kDebugMode) {
        print('Error creating/retrieving guest user: $e');
      }
      return null;
    }
  }

  /// Create guest user data
  Future<Map<String, dynamic>> _createGuestUserData(String guestUserId) async {
    // Generate guest data
    final String guestId = guestUserId.substring(guestUserId.length - 6);
    final String guestName = 'Guest_$guestId';
    final String guestEmail = 'guest.$guestId@gizmoglobe.com';
    final String guestPhone = '+0000$guestId';
    final DateTime now = DateTime.now();

    // Prepare user data
    final Map<String, dynamic> userData = {
      'username': guestName,
      'email': guestEmail,
      'userid': guestUserId,
      'role': 'customer',
      'isGuest': true,
      'createdAt': now.toIso8601String(),
    };

    // Prepare customer data
    final Map<String, dynamic> customerData = {
      'customerID': guestUserId,
      'customerName': guestName,
      'email': guestEmail,
      'phoneNumber': guestPhone,
      'isGuest': true,
      'createdAt': now.toIso8601String(),
    };

    return {
      'userData': userData,
      'customerData': customerData,
    };
  }

  /// Store guest data locally
  Future<void> _storeGuestData(
    String userId,
    Map<String, dynamic> userData,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final userDataJson = json.encode(userData);
      final customerDataJson = json.encode(customerData);

      if (kIsWeb) {
        html.window.localStorage[_guestUserIdKey] = userId;
        html.window.localStorage[_guestUserKey] = 'true';
        html.window.localStorage[_guestUserDataKey] = userDataJson;
        html.window.localStorage[_guestCustomerDataKey] = customerDataJson;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_guestUserIdKey, userId);
        await prefs.setBool(_guestUserKey, true);
        await prefs.setString(_guestUserDataKey, userDataJson);
        await prefs.setString(_guestCustomerDataKey, customerDataJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing guest data: $e');
      }
      throw Exception('Failed to store guest data: $e');
    }
  }

  /// Store guest cart data
  Future<void> storeGuestCart(List<Map<String, dynamic>> cartItems) async {
    try {
      final cartJson = json.encode(cartItems);
      
      if (kIsWeb) {
        html.window.localStorage[_guestCartKey] = cartJson;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_guestCartKey, cartJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing guest cart: $e');
      }
    }
  }

  /// Get guest cart data
  Future<List<Map<String, dynamic>>> getGuestCart() async {
    try {
      String? cartJson;
      
      if (kIsWeb) {
        cartJson = html.window.localStorage[_guestCartKey];
      } else {
        final prefs = await SharedPreferences.getInstance();
        cartJson = prefs.getString(_guestCartKey);
      }
      
      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        return cartList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting guest cart: $e');
      }
      return [];
    }
  }

  /// Store guest favorites data
  Future<void> storeGuestFavorites(List<String> favoriteIds) async {
    try {
      final favoritesJson = json.encode(favoriteIds);
      
      if (kIsWeb) {
        html.window.localStorage[_guestFavoritesKey] = favoritesJson;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_guestFavoritesKey, favoritesJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing guest favorites: $e');
      }
    }
  }

  /// Get guest favorites data
  Future<List<String>> getGuestFavorites() async {
    try {
      String? favoritesJson;
      
      if (kIsWeb) {
        favoritesJson = html.window.localStorage[_guestFavoritesKey];
      } else {
        final prefs = await SharedPreferences.getInstance();
        favoritesJson = prefs.getString(_guestFavoritesKey);
      }
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        return favoritesList.map((item) => item.toString()).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting guest favorites: $e');
      }
      return [];
    }
  }

  /// Check if current stored user is a guest
  Future<bool> isCurrentUserGuest() async {
    try {
      final userData = await getStoredGuestUserData();
      return userData != null && (userData['isGuest'] ?? false);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is guest: $e');
      }
      return false;
    }
  }

  /// Clear all guest user data from local storage
  Future<void> clearGuestUser() async {
    try {
      if (kIsWeb) {
        html.window.localStorage.remove(_guestUserIdKey);
        html.window.localStorage.remove(_guestUserKey);
        html.window.localStorage.remove(_guestUserDataKey);
        html.window.localStorage.remove(_guestCustomerDataKey);
        html.window.localStorage.remove(_guestCartKey);
        html.window.localStorage.remove(_guestFavoritesKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_guestUserIdKey);
        await prefs.remove(_guestUserKey);
        await prefs.remove(_guestUserDataKey);
        await prefs.remove(_guestCustomerDataKey);
        await prefs.remove(_guestCartKey);
        await prefs.remove(_guestFavoritesKey);
      }
      
      if (kDebugMode) {
        print('Guest user data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing guest user data: $e');
      }
    }
  }

  /// Update guest user profile data
  Future<void> updateGuestUserData(Map<String, dynamic> updatedData) async {
    try {
      final currentData = await getStoredGuestUserData();
      if (currentData != null) {
        // Merge the updated data with existing data
        final mergedData = {...currentData, ...updatedData};
        mergedData['isGuest'] = true; // Ensure isGuest flag is maintained
        
        final userDataJson = json.encode(mergedData);
        
        if (kIsWeb) {
          html.window.localStorage[_guestUserDataKey] = userDataJson;
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_guestUserDataKey, userDataJson);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating guest user data: $e');
      }
    }
  }

  /// Update guest customer data
  Future<void> updateGuestCustomerData(Map<String, dynamic> updatedData) async {
    try {
      final currentData = await getStoredGuestCustomerData();
      if (currentData != null) {
        // Merge the updated data with existing data
        final mergedData = {...currentData, ...updatedData};
        mergedData['isGuest'] = true; // Ensure isGuest flag is maintained
        
        final customerDataJson = json.encode(mergedData);
        
        if (kIsWeb) {
          html.window.localStorage[_guestCustomerDataKey] = customerDataJson;
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_guestCustomerDataKey, customerDataJson);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating guest customer data: $e');
      }
    }
  }
}
