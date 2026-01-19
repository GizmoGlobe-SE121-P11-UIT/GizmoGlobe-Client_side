import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        if (isClosed) return;
        emit(state.copyWith(
            processState: ProcessState.failure, error: 'User not logged in'));
        return;
      }

      await Database().getCartItems();

      final items = Database().cartItems;

      // Filter out products with stock == 0 to hide out-of-stock items
      final inStockItems =
          items.where((item) => item.product.stock > 0).toList();

      if (isClosed) return;

      if (isClosed) return;
      emit(state.copyWith(
        items: inStockItems,
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

      // Clamp the quantity to not exceed available stock
      final maxStock = cartItem.product.stock;
      final clampedQuantity = newQuantity > maxStock ? maxStock : newQuantity;
      if (clampedQuantity < 1) return; // Ensure at least 1

      final productID = cartItem.product.productID;
      final updatedItems = state.items.map((item) {
        if (item.product.productID == productID) {
          return item.copyWith(quantity: clampedQuantity);
        }
        return item;
      }).toList();

      // Also update selectedItems if this item is selected
      final updatedSelectedItems = state.selectedItems.map((item) {
        if (item.product.productID == productID) {
          return item.copyWith(quantity: clampedQuantity);
        }
        return item;
      }).toList();

      if (isClosed) return;
      emit(state.copyWith(
        items: updatedItems,
        selectedItems: updatedSelectedItems,
      ));

      // Make the actual update call
      final user = _auth.currentUser;
      if (user == null) return;

      await _firebase.updateCartItemQuantity(
          user.uid, cartItem.product.productID!, clampedQuantity);
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

    // Find item by productID (more reliable than object equality)
    final productID = item.product.productID;
    final existingIndex = currentSelected.indexWhere(
      (selectedItem) => selectedItem.product.productID == productID,
    );

    if (existingIndex >= 0) {
      currentSelected.removeAt(existingIndex);
    } else {
      // Find the actual item from state.items to maintain reference consistency
      final actualItem = state.items.firstWhere(
        (cartItem) => cartItem.product.productID == productID,
        orElse: () => item,
      );
      currentSelected.add(actualItem);
    }
    emit(state.copyWith(selectedItems: currentSelected));
  }

  void toggleSelectAll() {
    if (isClosed) return;
    if (state.isAllSelected) {
      emit(state.copyWith(selectedItems: []));
    } else {
      state.items.map((item) => item.product.productID as String).toList();
      emit(state.copyWith(selectedItems: state.items));
    }
  }

  /// Deletes only the selected items from the cart
  Future<void> deleteSelectedItems() async {
    try {
      if (isClosed) return;
      final user = _auth.currentUser;
      if (user == null) return;

      final selectedProductIDs = state.selectedItems
          .map((item) => item.product.productID)
          .where((id) => id != null)
          .toList();

      // Delete each selected item
      for (final productID in selectedProductIDs) {
        if (productID != null) {
          await _firebase.removeFromCart(user.uid, productID);
        }
      }

      // Clear selection and reload
      emit(state.copyWith(selectedItems: []));
      await loadCartItems();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          processState: ProcessState.failure, error: e.toString()));
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

    // Convert selectedItems to a set of productIDs for faster lookup
    final selectedProductIDs = state.selectedItems
        .map((item) => item.product.productID)
        .where((id) => id != null)
        .toSet();

    for (var item in state.items) {
      final productID = item.product.productID;

      // Check if this item's productID is in the selected items
      if (productID != null && selectedProductIDs.contains(productID)) {
        result.add({item.product: item.quantity});
      }
    }
    return result;
  }
}
