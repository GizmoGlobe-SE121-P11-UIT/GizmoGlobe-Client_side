import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../data/database/database.dart';
import '../../../data/firebase/firebase.dart';
import '../../../objects/product_related/product.dart';
import 'cart_screen_state.dart';
import '../../../enums/processing/process_state_enum.dart';

class CartScreenCubit extends Cubit<CartScreenState> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CartScreenCubit() : super(const CartScreenState()) {
    // Load cart items when cubit is created
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    try {
      if (isClosed) return;
      emit(state.copyWith(processState: ProcessState.loading));

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        if (isClosed) return;
        emit(state.copyWith(
            processState: ProcessState.failure, error: 'User not logged in'));
        return;
      }

      final items = await _firebase.getCartItems(user.uid);

      if (isClosed) return;

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

      if (isClosed) return;
      emit(state.copyWith(
        items: updatedItems,
        processState: ProcessState.success,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> updateQuantity(String productID, int newQuantity) async {
    try {
      if (isClosed) return;

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

      if (isClosed) return;
      emit(state.copyWith(items: updatedItems));

      // Make the actual update call
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.updateCartItemQuantity(user.uid, productID, newQuantity);
    } catch (e) {
      if (isClosed) return;
      // Revert the state if the update call fails
      await loadCartItems();
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> removeFromCart(String productID) async {
    try {
      if (isClosed) return;
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.removeFromCart(user.uid, productID);
      await loadCartItems();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  void toggleItemSelection(String productID) {
    if (isClosed) return;
    final currentSelected = Set<String>.from(state.selectedItems);
    if (currentSelected.contains(productID)) {
      currentSelected.remove(productID);
    } else {
      currentSelected.add(productID);
    }
    emit(state.copyWith(selectedItems: currentSelected));
  }

  void toggleSelectAll() {
    if (isClosed) return;
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
      if (isClosed) return;
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.clearCart(user.uid);
      await loadCartItems();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> addToCart(String productID, int quantity) async {
    try {
      if (isClosed) return;
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        if (isClosed) return;
        emit(state.copyWith(
            processState: ProcessState.failure, error: 'User not logged in.'));
        return;
      }

      await _firebase.addToCart(user.uid, productID, quantity);
      await loadCartItems();
    } catch (e) {
      if (isClosed) return;
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
