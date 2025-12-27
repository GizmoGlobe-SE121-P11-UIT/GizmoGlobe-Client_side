import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_image.dart';

import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../objects/invoice_related/rating.dart';

class ProductDetailState extends Equatable {
  final Product product;
  final Map<String, String> technicalSpecs;
  final ProcessState processState;
  final DialogName dialogName;

  final String message;
  final Set<String> favorites;
  final bool isFavorite;
  final List<ProductImage> productImages;
  final bool isLoadingImages;

  final List<Rating> ratings;
  final bool hasMoreRatings;
  final double averageRating;
  final int totalRatingsCount;
  final int quantity;

  const ProductDetailState({
    required this.product,
    this.technicalSpecs = const {},
    this.ratings = const [],
    this.hasMoreRatings = false,
    this.averageRating = 0.0,
    this.totalRatingsCount = 0,
    this.quantity = 1,
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = '',
    this.favorites = const {},
    this.isFavorite = false,
    this.productImages = const [],
    this.isLoadingImages = true,
  });

  @override
  List<Object?> get props => [
        product,
        technicalSpecs,
        ratings,
        hasMoreRatings,
        averageRating,
        totalRatingsCount,
        quantity,
        dialogName,
        message,
        processState,
        favorites,
        isFavorite,
        productImages,
        isLoadingImages,
      ];

  ProductDetailState copyWith({
    Product? product,
    Map<String, String>? technicalSpecs,
    List<Rating>? ratings,
    bool? hasMoreRatings,
    double? averageRating,
    int? totalRatingsCount,
    int? quantity,
    ProcessState? processState,
    DialogName? dialogName,
    String? message,
    Set<String>? favorites,
    bool? isFavorite,
    List<ProductImage>? productImages,
    bool? isLoadingImages,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      ratings: ratings ?? this.ratings,
      hasMoreRatings: hasMoreRatings ?? this.hasMoreRatings,
      averageRating: averageRating ?? this.averageRating,
      totalRatingsCount: totalRatingsCount ?? this.totalRatingsCount,
      quantity: quantity ?? this.quantity,
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
      favorites: favorites ?? this.favorites,
      isFavorite: isFavorite ?? this.isFavorite,
      productImages: productImages ?? this.productImages,
      isLoadingImages: isLoadingImages ?? this.isLoadingImages,
    );
  }
}
