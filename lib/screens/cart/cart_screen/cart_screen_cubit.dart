import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/database/database.dart';
import '../../../data/firebase/firebase.dart';
import '../../../objects/product_related/product.dart';
import 'cart_screen_state.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../services/local_guest_service.dart';

class CartScreenCubit extends Cubit<CartScreenState> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();

  CartScreenCubit() : super(const CartScreenState()) {
    // Load cart items when cubit is created
    loadCartItems();
  }

  Future<bool> _isGuestUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Check if we have a local guest user
      return await _localGuestService.isCurrentUserGuest();
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && (userDoc.data()?['isGuest'] ?? false);
  }

  Future<void> loadCartItems() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode){
          print('User not logged in');
        }
        emit(state.copyWith(
            processState: ProcessState.failure,
            error: 'User not logged in'
        ));
        return;
      }

      final items = await _firebase.getCartItems(user.uid);

      // Tính subtotal cho mỗi item
      final updatedItems = items.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
        final price = (product['sellingPrice'] as num?)?.toDouble() ?? 0;
        final discount = (product['discount'] as num?)?.toDouble() ?? 0;

        // Tính giá sau giảm giá
        final discountedPrice = price * (1 - discount / 100);
        final subtotal = discountedPrice * quantity;

        return {
          ...item,
          'subtotal': subtotal,
        };
      }).toList();

      emit(state.copyWith(
        items: updatedItems,
        processState: ProcessState.success,
      ));
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> updateQuantity(String productID, int newQuantity) async {
    try {
      // Optimistically update the state
      final updatedItems = state.items.map((item) {
        if (item['productID'] == productID) {
          final product = item['product'] as Map<String, dynamic>;
          final price = (product['sellingPrice'] as num?)?.toDouble() ?? 0;
          final discount = (product['discount'] as num?)?.toDouble() ?? 0;
          final discountedPrice = price * (1 - discount / 100);
          final subtotal = discountedPrice * newQuantity;

          return {
            ...item,
            'quantity': newQuantity,
            'subtotal': subtotal,
          };
        }
        return item;
      }).toList();

      emit(state.copyWith(items: updatedItems));

      // Make the actual update call
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.updateCartItemQuantity(user.uid, productID, newQuantity);
    } catch (e) {
      // Revert the state if the update call fails
      await loadCartItems();
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> removeFromCart(String productID) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.removeFromCart(user.uid, productID);
      await loadCartItems();
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  void toggleItemSelection(String productID) {
    final currentSelected = Set<String>.from(state.selectedItems);
    if (currentSelected.contains(productID)) {
      currentSelected.remove(productID);
    } else {
      currentSelected.add(productID);
    }
    emit(state.copyWith(selectedItems: currentSelected));
  }

  void toggleSelectAll() {
    if (state.isAllSelected) {
      emit(state.copyWith(selectedItems: {}));
    } else {
      final allProductIds =
          state.items.map((item) => item['productID'] as String).toSet();
      emit(state.copyWith(selectedItems: allProductIds));
    }
  }

  Future<void> clearCart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.clearCart(user.uid);
      await loadCartItems();
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> addToCart(String productID, int quantity) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        emit(state.copyWith(
            processState: ProcessState.failure, error: 'User not logged in.'));
        return;
      }

      await _firebase.addToCart(user.uid, productID, quantity);
      await loadCartItems();
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  List<Map<Product, int>> convertItemsToProductQuantityList() {
    final result = <Map<Product, int>>[];

    for (var item in state.items) {
      final productID = item['productID'] as String;
      final quantity = item['quantity'] as int;

      if (state.selectedItems.contains(productID)) {
        final product = Database()
            .productList
            .firstWhere((product) => product.productID == productID);
        result.add({product: quantity});
      }
    }
    return result;
  }
}