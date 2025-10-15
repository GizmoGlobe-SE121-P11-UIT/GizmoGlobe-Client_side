import 'package:flutter/foundation.dart';
import 'local_guest_service.dart';

class WebGuestService {
  final LocalGuestService _localGuestService = LocalGuestService();

  /// Check if a guest user is already stored in localStorage
  Future<bool> hasGuestUser() async {
    if (!kIsWeb) return false;
    return await _localGuestService.hasGuestUser();
  }

  /// Get stored guest user ID from localStorage
  Future<String?> getStoredGuestUserId() async {
    if (!kIsWeb) return null;
    return await _localGuestService.getStoredGuestUserId();
  }

  /// Create or retrieve guest user for web
  Future<Map<String, dynamic>?> createOrGetGuestUser() async {
    if (!kIsWeb) return null;
    return await _localGuestService.createOrGetGuestUser();
  }

  /// Check if current user is a guest
  Future<bool> isCurrentUserGuest() async {
    if (!kIsWeb) return false;
    return await _localGuestService.isCurrentUserGuest();
  }

  /// Clear guest user data from localStorage
  Future<void> clearGuestUser() async {
    if (!kIsWeb) return;
    await _localGuestService.clearGuestUser();
  }

  /// Get stored guest user data
  Future<Map<String, dynamic>?> getStoredGuestUserData() async {
    if (!kIsWeb) return null;
    return await _localGuestService.getStoredGuestUserData();
  }

  /// Get stored guest customer data
  Future<Map<String, dynamic>?> getStoredGuestCustomerData() async {
    if (!kIsWeb) return null;
    return await _localGuestService.getStoredGuestCustomerData();
  }

  /// Store guest cart data
  Future<void> storeGuestCart(List<Map<String, dynamic>> cartItems) async {
    if (!kIsWeb) return;
    await _localGuestService.storeGuestCart(cartItems);
  }

  /// Get guest cart data
  Future<List<Map<String, dynamic>>> getGuestCart() async {
    if (!kIsWeb) return [];
    return await _localGuestService.getGuestCart();
  }

  /// Store guest favorites data
  Future<void> storeGuestFavorites(List<String> favoriteIds) async {
    if (!kIsWeb) return;
    await _localGuestService.storeGuestFavorites(favoriteIds);
  }

  /// Get guest favorites data
  Future<List<String>> getGuestFavorites() async {
    if (!kIsWeb) return [];
    return await _localGuestService.getGuestFavorites();
  }

  /// Update guest user profile data
  Future<void> updateGuestUserData(Map<String, dynamic> updatedData) async {
    if (!kIsWeb) return;
    await _localGuestService.updateGuestUserData(updatedData);
  }

  /// Update guest customer data
  Future<void> updateGuestCustomerData(Map<String, dynamic> updatedData) async {
    if (!kIsWeb) return;
    await _localGuestService.updateGuestCustomerData(updatedData);
  }
}