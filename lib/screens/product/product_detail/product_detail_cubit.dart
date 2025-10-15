import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';

import '../../../data/firebase/firebase.dart';
import '../../../services/local_guest_service.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../objects/product_related/cpu.dart';
import '../../../objects/product_related/drive.dart';
import '../../../objects/product_related/gpu.dart';
import '../../../objects/product_related/mainboard.dart';
import '../../../objects/product_related/psu.dart';
import '../../../objects/product_related/ram.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();

  ProductDetailCubit(Product product) : super(ProductDetailState(product: product)) {
    _initializeTechnicalSpecs();
    loadFavorites();
  }

  void _initializeTechnicalSpecs() {
    final product = state.product;
    final Map<String, String> specs = {};

    switch (product.category) {
      case CategoryEnum.ram:
        final ram = product as RAM;
        specs.addAll({
          'Bus': ram.bus.toString(),
          'Capacity': ram.capacity.toString(),
          'Type': ram.ramType.toString(),
        });
        break;

      case CategoryEnum.cpu:
        final cpu = product as CPU;
        specs.addAll({
          'Family': cpu.family.toString(),
          'Core': cpu.core.toString(),
          'Thread': cpu.thread.toString(),
          'Clock Speed': '${cpu.clockSpeed} GHz',
        });
        break;

      case CategoryEnum.gpu:
        final gpu = product as GPU;
        specs.addAll({
          'Series': gpu.series.toString(),
          'Memory': gpu.capacity.toString(),
          'Bus Width': gpu.bus.toString(),
          'Clock Speed': '${gpu.clockSpeed} MHz',
        });
        break;

      case CategoryEnum.mainboard:
        final mainboard = product as Mainboard;
        specs.addAll({
          'Form Factor': mainboard.formFactor.toString(),
          'Series': mainboard.series.toString(),
          'Compatibility': mainboard.compatibility.toString(),
        });
        break;

      case CategoryEnum.drive:
        final drive = product as Drive;
        specs.addAll({
          'Type': drive.type.toString(),
          'Capacity': drive.capacity.toString(),
        });
        break;

      case CategoryEnum.psu:
        final psu = product as PSU;
        specs.addAll({
          'Wattage': '${psu.wattage}W',
          'Efficiency': psu.efficiency.toString(),
          'Modular': psu.modular.toString(),
        });
        break;
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
        if (kDebugMode) {
          print('User not logged in');
        }
        emit(state.copyWith(
            processState: ProcessState.failure,
            message: 'User not logged in.',
        ));
        return;
      }

      await _firebase.addToCart(user.uid, productID, quantity);
      emit(state.copyWith(
          processState: ProcessState.success,
          message: 'Added ${state.product.productName} to cart',
      ));
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, message: 'Failed to add to cart: $e'
      ));
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