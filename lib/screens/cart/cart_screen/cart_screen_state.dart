import 'package:equatable/equatable.dart';
import '../../../enums/processing/process_state_enum.dart';

class CartScreenState extends Equatable {
  final List<Map<String, dynamic>> items;
  final Set<String> selectedItems;
  final ProcessState processState;
  final String? error;

  const CartScreenState({
    this.items = const [],
    this.selectedItems = const {},
    this.processState = ProcessState.initial,
    this.error,
  });

  int get itemCount => items.length;

  double get totalAmount {
    double total = 0;
    for (var item in items) {
      if (selectedItems.contains(item['productID'])) {
        final product = item['product'] as Map<String, dynamic>;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
        final price = (product['sellingPrice'] as num?)?.toDouble() ?? 0;
        final discount = (product['discount'] as num?)?.toDouble() ?? 0;
        
        // Tính giá sau giảm giá
        final discountedPrice = price * (1 - discount / 100);
        total += discountedPrice * quantity;
      }
    }
    return total;
  }

  double get totalBeforeDiscount {
    double total = 0;
    for (var item in items) {
      if (selectedItems.contains(item['productID'])) {
        final product = item['product'] as Map<String, dynamic>;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
        final price = (product['sellingPrice'] as num?)?.toDouble() ?? 0;
        
        total += price * quantity;
      }
    }
    return total;
  }

  bool get hasDiscounts {
    return items.any((item) {
      final product = item['product'] as Map<String, dynamic>;
      final discount = product['discount'];
      return discount != null && (discount as num) > 0;
    });
  }

  bool get isAllSelected => 
    items.isNotEmpty && selectedItems.length == items.length;

  int get selectedCount => selectedItems.length;

  CartScreenState copyWith({
    List<Map<String, dynamic>>? items,
    Set<String>? selectedItems,
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
