import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

class PartsPickerState extends Equatable {
  final List<Product> products;
  final List<Product> selectedProducts;
  final List<Product> displayProducts;
  final ProcessState processState;
  final String message;
  final String searchText;


  const PartsPickerState({
    this.products = const [],
    this.selectedProducts = const [],
    this.displayProducts = const [],
    this.processState = ProcessState.idle,
    this.message = '',
    this.searchText = '',
  });

  @override
  List<Object?> get props =>
      [products, selectedProducts, processState, message, searchText, displayProducts];

  PartsPickerState copyWith({
    List<Product>? products,
    List<Product>? selectedProducts,
    ProcessState? processState,
    String? message,
    String? searchText,
    List<Product>? displayProducts,
  }) {
    return PartsPickerState(
      products: products ?? this.products,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      processState: processState ?? this.processState,
      message: message ?? this.message,
      searchText: searchText ?? this.searchText,
      displayProducts: displayProducts ?? this.displayProducts,
    );
  }
}
