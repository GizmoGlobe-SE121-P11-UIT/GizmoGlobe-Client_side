import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/notify_message_enum.dart';
import '../../../enums/processing/process_state_enum.dart';


class ProductDetailState extends Equatable {
  final Product product;
  final Map<String, String> technicalSpecs;
  final int quantity;
  final ProcessState processState;
  final DialogName dialogName;
  final String message;
  final Set<String> favorites;
  final bool isFavorite;

  const ProductDetailState({
    required this.product,
    this.technicalSpecs = const {},
    this.quantity = 1,
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = '',
    this.favorites = const {},
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [product, technicalSpecs, quantity, dialogName, message, processState, favorites, isFavorite];

  ProductDetailState copyWith({
    Product? product,
    Map<String, String>? technicalSpecs,
    int? quantity,
    ProcessState? processState,
    DialogName? dialogName,
    String? message,
    Set<String>? favorites,
    bool? isFavorite,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      quantity: quantity ?? this.quantity,
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
      favorites: favorites ?? this.favorites,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}