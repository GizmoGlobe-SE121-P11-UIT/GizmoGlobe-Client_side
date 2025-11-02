import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';

import '../../../data/firebase/firebase.dart';
import '../../../objects/product_related/cpu_related/cpu.dart';
import '../../../objects/product_related/drive_related/drive.dart';
import '../../../objects/product_related/gpu_related/gpu.dart';
import '../../../objects/product_related/mainboard_related/mainboard.dart';
import '../../../objects/product_related/psu_related/psu.dart';
import '../../../objects/product_related/ram_related/ram.dart';
import '../../../services/local_guest_service_platform.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();

  ProductDetailCubit(Product product)
      : super(ProductDetailState(product: product)) {
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
          'Type': ram.type.toString(),
          'Bus': '${ram.bus} MHz',
          'CL Latency': 'CL${ram.clLatency}',
          'Kit Stick Count': ram.kitStickCount.toString(),
          'Capacity per Stick': '${ram.capacityPerStickGb} GB',
        });
        break;

      case CategoryEnum.cpu:
        final cpu = product as CPU;
        specs.addAll({
          'Cores': cpu.core.toString(),
          'Threads': cpu.thread.toString(),
          'Base Clock': '${cpu.baseClock} GHz',
          'Turbo Clock': '${cpu.turboClock} GHz',
          'TDP': '${cpu.tdp} W',
          'Socket': cpu.socket.toString(),
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
          'Storage:' : mainboard.storageSlot.toString(),
          'PCIe Slots:': mainboard.pcieSlots.map((slot) => slot.toString()).join('\n'),
          'I/O Ports:': mainboard.ioPorts.map((port) => port.toString()).join('\n'),
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
          'Connectors': psu.connectors.map((type) => type.toString()).join('\n'),
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
          processState: ProcessState.failure,
          message: 'Failed to add to cart: $e'));
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
