import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';

import '../../../data/firebase/firebase.dart';
import '../../../objects/invoice_related/rating.dart';
import '../../../objects/product_related/cpu_related/cpu.dart';
import '../../../objects/product_related/drive_related/drive.dart';
import '../../../objects/product_related/gpu_related/gpu.dart';
import '../../../objects/product_related/mainboard_related/mainboard.dart';
import '../../../objects/product_related/psu_related/psu.dart';
import '../../../objects/product_related/ram_related/ram.dart';
import '../../../services/local_guest_service_platform.dart';
import '../../../services/product_view_service.dart';
import '../../../services/vertex_ai_event_service.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();
  final ProductViewService _viewService = ProductViewService();
  final VertexAIEventService _vertexEventService = VertexAIEventService();

  ProductDetailCubit(Product product)
      : super(ProductDetailState(product: product)) {
    _initializeTechnicalSpecs();
    loadFavorites();
    // Load initial ratings page for this product
    loadRatingsPage();
    // Load average rating for accurate avg display
    refreshAverage();
    _loadProductImages();
    // Track product view for collaborative filtering recommendations
    _trackProductView();
  }

  /// Track this product view for recommendation system
  Future<void> _trackProductView() async {
    if (state.product.productID != null) {
      // Track to collaborative filtering (existing)
      await _viewService.trackProductView(state.product.productID!);

      // Track to Vertex AI for improved recommendations
      await _vertexEventService.trackDetailPageView(state.product.productID!);
    }
  }

  Future<void> _loadProductImages() async {
    if (state.product.productID == null) {
      emit(state.copyWith(isLoadingImages: false, productImages: []));
      return;
    }

    try {
      final images = await _firebase.getProductImages(state.product.productID!);
      emit(state.copyWith(
        productImages: images,
        isLoadingImages: false,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading product images: $e');
      }
      emit(state.copyWith(isLoadingImages: false, productImages: []));
    }
  }

  DocumentSnapshot? _lastRatingsDoc;

  void _initializeTechnicalSpecs() {
    final product = state.product;
    final Map<String, String> specs = {};

    switch (product.category) {
      case CategoryEnum.ram:
        final ram = product as RAM;
        specs.addAll({
          'RAM Type': ram.type.toString(),
          'RAM Bus': '${ram.bus} MHz',
          'CL Latency': 'CL${ram.clLatency}',
          if (ram.kitStickCount > 1)
            'Kit Stick Count': ram.kitStickCount.toString(),
        });
        if (ram.kitStickCount == 1) {
          specs['RAM Capacity'] = '${ram.capacityPerStickGb} GB';
        } else {
          specs['RAM Capacity'] =
              '${ram.kitStickCount * ram.capacityPerStickGb} GB';
          specs['Capacity Per Stick'] = '${ram.capacityPerStickGb} GB';
        }
        break;

      case CategoryEnum.cpu:
        final cpu = product as CPU;
        specs.addAll({
          'Series': cpu.series.toString(),
          'Socket': cpu.socket.toString(),
          'Cores': cpu.core.toString(),
          'Threads': cpu.thread.toString(),
          'Base Clock': '${cpu.baseClock} GHz',
          'Turbo Clock': '${cpu.turboClock} GHz',
          'TDP': '${cpu.tdp} W',
        });
        break;

      case CategoryEnum.gpu:
        final gpu = product as GPU;
        specs.addAll({
          'Version': gpu.version.toString(),
          'Memory': gpu.memory.toString(),
          'Clock Speed': '${gpu.boostClock} MHz',
          'TDP': '${gpu.tdp} W',
          'I/O Ports': gpu.ports.map((port) => port.toString()).join('\n'),
        });
        break;

      case CategoryEnum.mainboard:
        final mainboard = product as Mainboard;
        specs.addAll({
          'Chipset': mainboard.chipsetCode.toString(),
          'Socket': mainboard.socket.toString(),
          'Form Factor': mainboard.formFactor.toString(),
          'RAM Spec': mainboard.ramSpec.toString(),
          'Storage:': mainboard.storageSlot.toString(),
          'PCIe Slots:':
              mainboard.pcieSlots.map((slot) => slot.toString()).join('\n'),
          'I/O Ports:':
              mainboard.ioPorts.map((port) => port.toString()).join('\n'),
        });
        break;

      case CategoryEnum.drive:
        final drive = product as Drive;
        specs.addAll({
          'Drive Type': drive.driveType.toString(),
          'Generation': drive.gen.toString(),
          'Capacity': '${drive.memoryGb} GB',
          'Interface': drive.interfaceType.toString(),
          'Form Factor': drive.formFactor.toString(),
          'Read Speed': '${drive.speed.readMbps} MB/s',
          'Write Speed': '${drive.speed.writeMbps} MB/s',
        });
        break;

      case CategoryEnum.psu:
        final psu = product as PSU;
        specs.addAll({
          'Wattage': '${psu.maxWattage} W',
          'Efficiency Rating': psu.efficiency.toString(),
          'Modularity': psu.modularity.toString(),
          'Connectors':
              psu.connectors.map((type) => type.toString()).join('\n'),
        });
        break;

      default:
        if (kDebugMode) {
          print('Unknown category');
        } //Danh mục không xác định
    }

    emit(state.copyWith(technicalSpecs: specs));
  }

  void updateQuantity(int newQuantity) {
    emit(state.copyWith(quantity: newQuantity));
  }

  void incrementQuantity() {
    emit(state.copyWith(quantity: state.quantity + 1));
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      emit(state.copyWith(quantity: state.quantity - 1));
    }
  }

  Future<void> addToCart(String productID, int quantity) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(state.copyWith(
          processState: ProcessState.failure,
          message: 'CART_LOGIN_REQUIRED',
        ));
        return;
      }

      await _firebase.addToCart(user.uid, productID, quantity);
      emit(state.copyWith(
        processState: ProcessState.success,
        message: 'CART_ADDED',
      ));
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, message: 'CART_ERROR'));
    }
  }

  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    final isGuest = await _isGuestUser();

    if (isGuest) {
      // Load favorites from local storage for guest users
      final guestFavorites = await _localGuestService.getGuestFavorites();
      emit(state.copyWith(
        favorites: guestFavorites.toSet(),
        isFavorite: guestFavorites.contains(state.product.productID),
      ));
      return;
    }

    if (user == null) return;

    final favorites = await _firebase.getFavorites(user.uid);
    emit(state.copyWith(
      favorites: favorites.toSet(),
      isFavorite: favorites.contains(state.product.productID),
    ));
  }

  Future<void> loadRatingsPage({int limit = 5}) async {
    try {
      final productId = state.product.productID ?? '';
      if (productId.isEmpty) return;
      try {
        final page =
            await _firebase.getRatingsPageByProduct(productId, limit: limit);
        _lastRatingsDoc = page.lastDocument;
        emit(state.copyWith(
            ratings: page.ratings, hasMoreRatings: page.hasMore));
      } catch (e) {
        // Server-side paging may fail due to missing index; fallback to client-side full fetch then local pagination
        if (kDebugMode) {
          print('Falling back to client-side fetch for ratings: $e');
        }
        final all = await _firebase.getRatingsByProductWithUsername(productId);
        final initial = all.take(limit).toList();
        final hasMore = all.length > initial.length;
        // note: cannot set a lastDocument for client-side fallback; we'll store current offset
        _lastRatingsDoc = null;
        emit(state.copyWith(ratings: initial, hasMoreRatings: hasMore));
      }
    } catch (e) {
      if (kDebugMode) print('Error loading ratings page: $e');
    }
  }

  Future<void> refreshAverage() async {
    try {
      final productId = state.product.productID ?? '';
      if (productId.isEmpty) return;
      
      // Try to get pre-aggregated data from database first
      final aggregated = await _firebase.getAggregatedProductRating(productId);
      if (aggregated != null) {
        final avg = (aggregated['avgRating'] as num?)?.toDouble() ?? 0.0;
        final count = (aggregated['ratingCount'] as int?) ?? 
                     (aggregated['ratingCount'] as num?)?.toInt() ?? 0;
        emit(state.copyWith(averageRating: avg, totalRatingsCount: count));
        return;
      }
      
      // Fallback to recalculation if aggregated data doesn't exist
      final result = await _firebase.getAverageRatingForProduct(productId);
      final avg = (result['average'] as num?)?.toDouble() ?? 0.0;
      final count =
          (result['count'] as int?) ?? (result['count'] as num?)?.toInt() ?? 0;
      emit(state.copyWith(averageRating: avg, totalRatingsCount: count));
    } catch (e) {
      if (kDebugMode) print('Error refreshing average rating: $e');
    }
  }

  Future<void> loadMoreRatings({int limit = 5}) async {
    try {
      final productId = state.product.productID ?? '';
      if (productId.isEmpty) return;

      if (_lastRatingsDoc != null) {
        final page = await _firebase.getRatingsPageByProduct(productId,
            startAfter: _lastRatingsDoc, limit: limit);
        _lastRatingsDoc = page.lastDocument;
        final combined = List<Rating>.from(state.ratings)..addAll(page.ratings);
        emit(state.copyWith(ratings: combined, hasMoreRatings: page.hasMore));
        return;
      }

      final all = await _firebase.getRatingsByProductWithUsername(productId);
      final current = state.ratings.length;
      if (current >= all.length) {
        emit(state.copyWith(hasMoreRatings: false));
        return;
      }
      final next = all.skip(current).take(limit).toList();
      final combined = List<Rating>.from(state.ratings)..addAll(next);
      final hasMore = combined.length < all.length;
      emit(state.copyWith(ratings: combined, hasMoreRatings: hasMore));
    } catch (e) {
      if (kDebugMode) print('Error loading more ratings: $e');
    }
  }

  Future<bool> _isGuestUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Check if we have a local guest user
      return await _localGuestService.isCurrentUserGuest();
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && (userDoc.data()?['isGuest'] ?? false);
  }

  Future<void> toggleFavorite() async {
    final user = _auth.currentUser;
    final isGuest = await _isGuestUser();

    final currentFavorites = Set<String>.from(state.favorites);

    if (isGuest) {
      // Handle guest favorites locally
      if (currentFavorites.contains(state.product.productID)) {
        currentFavorites.remove(state.product.productID!);
      } else {
        currentFavorites.add(state.product.productID!);
      }

      // Store updated favorites locally
      await _localGuestService.storeGuestFavorites(currentFavorites.toList());
      emit(state.copyWith(
        favorites: currentFavorites,
        isFavorite: currentFavorites.contains(state.product.productID),
      ));
      return;
    }

    if (user == null) return;

    // Handle authenticated user favorites in Firebase
    if (currentFavorites.contains(state.product.productID)) {
      currentFavorites.remove(state.product.productID!);
      await _firebase.removeFavorite(user.uid, state.product.productID!);
    } else {
      currentFavorites.add(state.product.productID!);
      await _firebase.addFavorite(user.uid, state.product.productID!);
    }
    emit(state.copyWith(
      favorites: currentFavorites,
      isFavorite: currentFavorites.contains(state.product.productID),
    ));
  }

  void setIdleState() {
    emit(state.copyWith(
      processState: ProcessState.idle,
      message: '',
    ));
  }
}
