import 'package:equatable/equatable.dart';
import '../../../objects/product_related/cart_item.dart';

class CartScreenState with EquatableMixin {
  final Map<String, CartItem> items;
  final Set<String> selectedItems;
  final bool isLoading;

  CartScreenState({
    this.items = const {},
    this.selectedItems = const {},
    this.isLoading = false,
  });

  int get itemCount => items.length;

  double get totalAmount => items.entries
      .where((entry) => selectedItems.contains(entry.key))
      .fold(0, (sum, item) => sum + (item.value.product.discountedPrice * item.value.quantity));

  double get totalBeforeDiscount => items.entries
      .where((entry) => selectedItems.contains(entry.key))
      .fold(0, (sum, item) => sum + (item.value.product.price * item.value.quantity));

  bool get hasDiscounts => items.values
      .any((item) => item.product.discount != null);

  int get selectedCount => selectedItems.length;

  bool get isAllSelected => 
      items.isNotEmpty && selectedItems.length == items.length;

  @override
  List<Object?> get props => [items, selectedItems, isLoading];

  CartScreenState copyWith({
    Map<String, CartItem>? items,
    Set<String>? selectedItems,
    bool? isLoading,
  }) {
    return CartScreenState(
      items: items ?? this.items,
      selectedItems: selectedItems ?? this.selectedItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
