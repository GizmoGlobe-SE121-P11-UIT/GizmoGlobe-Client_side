import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/cart_item.dart';
import '../../../enums/processing/process_state_enum.dart';

class CartScreenState extends Equatable {
  final List<CartItem> items;
  final List<CartItem> selectedItems;
  final ProcessState processState;
  final String? error;

  const CartScreenState({
    this.items = const [],
    this.selectedItems = const [],
    this.processState = ProcessState.idle,
    this.error,
  });

  int get itemCount => items.length;

  double get totalAmount {
    double total = 0;
    for (var item in items) {
      total += item.subTotal();
    }
    return total;
  }

  double get totalBeforeDiscount {
    double total = 0;
    for (var item in items) {
      total += item.subTotalBeforeDiscount();
    }
    return total;
  }

  bool get hasDiscounts {
    return items.any((item) {
      return item.product.discountedPrice < item.product.price;
    });
  }

  bool get isAllSelected => 
    items.isNotEmpty && selectedItems.length == items.length;

  int get selectedCount => selectedItems.length;

  CartScreenState copyWith({
    List<CartItem>? items,
    List<CartItem>? selectedItems,
    ProcessState? processState,
    String? error,
  }) {
    return CartScreenState(
      items: items ?? this.items,
      selectedItems: selectedItems ?? this.selectedItems,
      processState: processState ?? this.processState,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [items, selectedItems, processState, error];
}