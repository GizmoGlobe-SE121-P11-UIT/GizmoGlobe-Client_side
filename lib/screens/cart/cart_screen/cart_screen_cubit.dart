import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/objects/cart_item.dart';
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

      await Database().getCartItems();

      final items = Database().cartItems;

      if (isClosed) return;

      if (isClosed) return;
      emit(state.copyWith(
        items: items,
        processState: ProcessState.success,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }


  Future<void> updateQuantity(CartItem cartItem, int newQuantity) async {
    try {
      if (isClosed) return;

      final updatedItems = state.items.map((item) {
        if (item == cartItem) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList();

      if (isClosed) return;
      emit(state.copyWith(items: updatedItems));

      // Make the actual update call
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.updateCartItemQuantity(user.uid, cartItem.product.productID!, newQuantity);
    } catch (e) {
      if (isClosed) return;
      // Revert the state if the update call fails
      await loadCartItems();
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> removeFromCart(CartItem item) async {
    try {
      if (isClosed) return;
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.removeFromCart(user.uid, item.product.productID!);
      await loadCartItems();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
    }
  }

  void toggleItemSelection(CartItem item) {
    if (isClosed) return;
    final currentSelected = List<CartItem>.from(state.selectedItems);
    if (currentSelected.contains(item)) {
      currentSelected.remove(item);
    } else {
      currentSelected.add(item);
    }
    emit(state.copyWith(selectedItems: currentSelected));
  }

  void toggleSelectAll() {
    if (isClosed) return;
    if (state.isAllSelected) {
      emit(state.copyWith(selectedItems: []));
    } else {
      final allProductIds =
          state.items.map((item) => item.product.productID as String).toList();
      emit(state.copyWith(selectedItems: state.items));
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
      final productID = item.product.productID;

      if (state.selectedItems.contains(productID)) {
        final product = Database()
            .productList
            .firstWhere((product) => product.productID == productID);
        result.add({product: item.quantity});
      }
    }
    return result;
  }
}
