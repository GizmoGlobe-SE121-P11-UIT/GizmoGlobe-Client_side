import 'package:bloc/bloc.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/product_related/cart_item.dart';
import 'cart_screen_state.dart';

class CartScreenCubit extends Cubit<CartScreenState> {
  CartScreenCubit() : super(CartScreenState());

  void addToCart(Product product, int quantity) {
    final currentItems = Map<String, CartItem>.from(state.items);
    final productId = product.productID;
    
    if (productId == null) return;

    if (currentItems.containsKey(productId)) {
      currentItems[productId] = CartItem(
        product: product,
        quantity: currentItems[productId]!.quantity + quantity,
      );
    } else {
      currentItems[productId] = CartItem(
        product: product,
        quantity: quantity,
      );
    }

    emit(state.copyWith(items: currentItems));
  }

  void removeFromCart(String productId) {
    final currentItems = Map<String, CartItem>.from(state.items);
    currentItems.remove(productId);
    emit(state.copyWith(items: currentItems));
  }

  void updateQuantity(String productId, int quantity) {
    final currentItems = Map<String, CartItem>.from(state.items);
    
    if (quantity <= 0) {
      currentItems.remove(productId);
    } else if (currentItems.containsKey(productId)) {
      currentItems[productId] = CartItem(
        product: currentItems[productId]!.product,
        quantity: quantity,
      );
    }

    emit(state.copyWith(items: currentItems));
  }

  void clearCart() {
    emit(state.copyWith(items: {}));
  }

  void toggleItemSelection(String productId) {
    final currentSelected = Set<String>.from(state.selectedItems);
    if (currentSelected.contains(productId)) {
      currentSelected.remove(productId);
    } else {
      currentSelected.add(productId);
    }
    emit(state.copyWith(selectedItems: currentSelected));
  }

  void toggleSelectAll() {
    final allProductIds = state.items.keys.toSet();
    if (state.isAllSelected) {
      emit(state.copyWith(selectedItems: {}));
    } else {
      emit(state.copyWith(selectedItems: allProductIds));
    }
  }
}