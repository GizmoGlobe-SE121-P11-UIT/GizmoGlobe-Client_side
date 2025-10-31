import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/objects/address_related/address.dart';
import 'package:gizmoglobe_client/objects/cart_item.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/psu_related/psu.dart';
import 'package:gizmoglobe_client/objects/voucher_related/owned_voucher.dart';

import '../../enums/manufacturer/manufacturer_status.dart';
import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/drive_enums/drive_type.dart';
import '../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../enums/product_related/psu_enums/psu_modular.dart';
import '../../enums/product_related/ram_enums/ram_type.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../objects/address_related/province.dart';
import '../../objects/product_related/product_factory.dart';
import '../../objects/product_related/ram_related/ram.dart';
import '../../objects/voucher_related/voucher.dart';
import '../firebase/firebase.dart';

class Database {
  static final Database _database = Database._internal();

  String userID = '';
  String username = '';
  String email = '';

  List<Manufacturer> manufacturerList = [];
  List<Manufacturer> inactiveManufacturerList = [];
  List<Product> productList = [];
  List<Product> fullProductList = []; // Full product list for sales orders
  List<Province> provinceList = [];
  List<Address> addressList = [];
  List<Product> favoriteProducts = [];
  List<Product> bestSellerProducts = [];
  List<SalesInvoice> salesInvoiceList = [];
  List<Voucher> allVoucherList = [];
  List<OwnedVoucher> ownedVoucherList = [];

  List<RAM> ramList = [];
  List<CPU> cpuList = [];
  List<GPU> gpuList = [];
  List<PSU> psuList = [];
  List<Mainboard> mainboardList = [];
  List<Drive> driveList = [];

  // Add these properties to store voucher lists
  List<Voucher> userVouchers = [];
  List<Voucher> ongoingVouchers = [];
  List<Voucher> upcomingVouchers = [];
  List<CartItem> cartItems = [];

  // final List<Map<String, dynamic>> voucherDataList = [
  //   {
  //     'voucherID': 'voucher1',
  //     'voucherName': 'Discount 10%',
  //     'startTime': DateTime(2025, 5, 1),
  //     'discountValue': 10.0,
  //     'minimumPurchase': 0.0,
  //     'maxUsagePerPerson': 1,
  //     'isVisible': true,
  //     'isEnabled': true,
  //     'description': '',
  //     'hasEndTime': true,
  //     'endTime': DateTime(2025, 5, 31),
  //     'isLimited': true,
  //     'maximumUsage': 100,
  //     'usageLeft': 0,
  //     'isPercentage': true,
  //     'maximumDiscountValue': 100.0,
  //   },
  //   {
  //     'voucherID': 'voucher2',
  //     'voucherName': 'Discount \$20',
  //     'startTime': DateTime(2025, 6, 1),
  //     'discountValue': 20.0,
  //     'minimumPurchase': 50.0,
  //     'maxUsagePerPerson': 1,
  //     'isVisible': false,
  //     'isEnabled': false,
  //     'description': '\$20 off orders over \$50',
  //     'hasEndTime': true,
  //     'endTime': DateTime(2025, 6, 30),
  //     'isLimited': false,
  //     'isPercentage': false,
  //   },
  //   {
  //     'voucherID': 'voucher3',
  //     'voucherName': 'Discount 30%',
  //     'startTime': DateTime(2025, 5, 1),
  //     'discountValue': 30.0,
  //     'minimumPurchase': 0.0,
  //     'maxUsagePerPerson': 1,
  //     'isVisible': true,
  //     'isEnabled': true,
  //     'description': '30% off, up to \$100',
  //     'hasEndTime': false,
  //     'isLimited': true,
  //     'maximumUsage': 50,
  //     'usageLeft': 10,
  //     'isPercentage': true,
  //     'maximumDiscountValue': 100.0,
  //   },
  //   {
  //     'voucherID': 'voucher4',
  //     'voucherName': 'Discount \$50',
  //     'startTime': DateTime(2025, 6, 1),
  //     'discountValue': 50.0,
  //     'minimumPurchase': 100.0,
  //     'maxUsagePerPerson': 1,
  //     'isVisible': false,
  //     'isEnabled': true,
  //     'description': '\$50 off orders over \$100',
  //     'hasEndTime': false,
  //     'isLimited': true,
  //     'maximumUsage': 5,
  //     'usageLeft': 5,
  //     'isPercentage': false,
  //   },
  //   {
  //     'voucherID': 'voucher5',
  //     'voucherName': 'Discount 15%',
  //     'startTime': DateTime(2025, 4, 1),
  //     'discountValue': 15.0,
  //     'minimumPurchase': 0.0,
  //     'maxUsagePerPerson': 1,
  //     'isVisible': true,
  //     'isEnabled': true,
  //     'description': '15% off, up to \$100',
  //     'hasEndTime': true,
  //     'endTime': DateTime(2025, 4, 30),
  //     'isLimited': true,
  //     'maximumUsage': 5,
  //     'usageLeft': 5,
  //     'isPercentage': true,
  //     'maximumDiscountValue': 100.0,
  //   },
  // ];

  factory Database() {
    return _database;
  }

  Database._internal();

  Future<String?> getCurrentUserID() async {
    final User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  void getInactiveManufacturerList() {
    inactiveManufacturerList = manufacturerList
        .where((manufacturer) => manufacturer.status == ManufacturerStatus.inactive)
        .toList();
  }

  // Future<void> addStatusToAllProducts({bool overwrite = false}) async {
  //   final firestore = FirebaseFirestore.instance;
  //   final snapshot = await firestore.collection('products').get();
  //   final docs = snapshot.docs;
  //   if (docs.isEmpty) return;
  //
  //   const int batchSize = 500; // Firestore batch limit
  //   for (var i = 0; i < docs.length; i += batchSize) {
  //     final batch = firestore.batch();
  //     final end = min(i + batchSize, docs.length);
  //     for (var j = i; j < end; j++) {
  //       final doc = docs[j];
  //       final data = doc.data();
  //       if (!overwrite && data.containsKey('status')) continue;
  //       batch.update(doc.reference, {'status': 'active'});
  //     }
  //     await batch.commit();
  //   }
  // }

  Future<void> fetchDataFromFirestore() async {
    try {
      // await addStatusToAllProducts();
      await getUserData();
      if (kDebugMode) {
        print('Getting data from Firebase');
      }

      // print('Đang lấy dữ liệu từ Firebase');
      provinceList = await fetchProvinces();

      await fetchAddress();

      final manufacturerSnapshot = await FirebaseFirestore.instance.collection('manufacturers').get();

      manufacturerList = manufacturerSnapshot.docs.map((doc) {
        final data = doc.data();
        final docStatus = data['status'] as String?;
        return Manufacturer(
          manufacturerID: doc.id,
          manufacturerName: doc['manufacturerName'] as String,
          status: ManufacturerStatus.values.firstWhere(
            (e) => e.getName().toLowerCase() == (docStatus?.toLowerCase() ?? ManufacturerStatus.active.getName().toLowerCase()),
            orElse: () => ManufacturerStatus.active,
          ),
        );
      }).toList();

      getInactiveManufacturerList();

      productList = await getProducts();

      bestSellerProducts = fetchBestSellerProducts();
      favoriteProducts = await fetchFavoriteProducts(userID);

      allVoucherList = await Firebase().getVouchers();

      await getCartItems();

      await fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Fetching data error: $e');
      }
      // print('Lỗi khi lấy dữ liệu: $e');
      rethrow;
    }
  }

  Future<void> getCartItems() async {
    try {
      String userID = await getCurrentUserID() ?? '';

      if (userID.isEmpty) {
        if (kDebugMode) {
          print('User not logged in. Cannot fetch cart items.');
        }
        return;
      }

      final getCart = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userID)
          .collection('carts')
          .get();

      List<CartItem> updatedItems = [];

      for (var item in getCart.docs) {
        final productID = item['productID'] as String;
        final quantity = item['quantity'] as int;

        final product = productList.firstWhere(
          (prod) => prod.productID == productID,
          orElse: () => ProductFactory.createProduct({
            'productID': productID,
            'productName': 'Unknown Product',
            'category': CategoryEnum.empty,
            'price': 0.0,
            'status': ProductStatusEnum.discontinued,
          }),
        );
        updatedItems.add(CartItem(product: product, quantity: quantity));
      }

      cartItems = updatedItems;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching cart items: $e');
      }
    }
  }

  Future<void> initialize() async {
    try {
      await fetchDataFromFirestore();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing connection to Firebase: $e');
      }
      // print('Lỗi khi khởi tạo kết nối tới Firebase: $e');
      // Nếu không lấy được dữ liệu từ Firestore, sử dụng dữ liệu mẫu
      // _initializeSampleData();
    }
  }

  Future<List<Province>> fetchProvinces() async {
    const filePath = 'lib/data/database/full_json_generated_data_vn_units.json';

    try {
      final String response = await rootBundle.loadString(filePath);
      if (response.isEmpty) {
        if (kDebugMode) {
          print('JSON file is empty');
        }
        throw Exception('JSON file is empty');
        // throw Exception('Tệp JSON trống');
      }

      final List? jsonList = jsonDecode(response) as List<dynamic>?;
      if (jsonList == null) {
        if (kDebugMode) {
          print('Error parsing JSON data');
        }
        throw Exception('Error parsing JSON data');
        // throw Exception('Lỗi khi phân tích dữ liệu JSON');
      }

      List<Province> provinceList =
          jsonList.map((province) => Province.fromJson(province)).toList();
      return provinceList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading provinces from file: $e');
      }
      throw Exception('Error loading provinces from file: $e');
      // throw Exception('Lỗi khi tải danh sách tỉnh thành từ tệp: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final productSnapshot =
      await FirebaseFirestore.instance.collection('products').get();

      if (kDebugMode) {
        print('Products: ${productSnapshot.docs.length}');
      }

      final products = (await Future.wait(productSnapshot.docs.map((doc) async {
        try {
          final dynamic raw = doc.data();
          if (raw is! Map<String, dynamic>) {
            if (kDebugMode) {
              print('Product ${doc.id} has unexpected data type: ${raw.runtimeType}');
            }
            return null;
          }

          final Map<String, dynamic> data = raw.map<String, dynamic>((key, value) {
            dynamic normalized = value;
            if (value is String) {
              final s = value.trim();
              if ((s.startsWith('{') && s.endsWith('}')) ||
                  (s.startsWith('[') && s.endsWith(']'))) {
                try {
                  normalized = jsonDecode(s);
                } catch (_) {
                  normalized = value;
                }
              }
            }
            return MapEntry(key, normalized);
          });

          data.putIfAbsent('productID', () => doc.id);

          return ProductFactory.createProduct(data);
        } catch (e, st) {
          if (kDebugMode) {
            print('Error processing product ${doc.id}: $e\n$st');
          }
          return null;
        }
      }))).whereType<Product>().toList();

      // Store to central lists so other methods (e.g. getProductsWithCategory) can use them
      productList = products;
      fullProductList = [...products];

      // Populate typed lists using runtime types
      ramList = products.whereType<RAM>().toList();
      cpuList = products.whereType<CPU>().toList();
      gpuList = products.whereType<GPU>().toList();
      psuList = products.whereType<PSU>().toList();
      mainboardList = products.whereType<Mainboard>().toList();
      driveList = products.whereType<Drive>().toList();

      if (kDebugMode) {
        print('Populated typed lists: '
            'ram=${ramList.length}, cpu=${cpuList.length}, gpu=${gpuList.length}, '
            'psu=${psuList.length}, mainboard=${mainboardList.length}, drive=${driveList.length}');
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting products: $e');
      }
      rethrow;
    }
  }

  Future<void> getUsername() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      username = userDoc['username'];
    }
  }

  Future<void> getUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      userID = user.uid;
      username = userDoc['username'];
      email = userDoc['email'];
    }
  }

  Future<void> getUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      userID = user.uid;
      username = userDoc['username'];
      email = userDoc['email'];
    }

    await fetchAddress();
    await fetchSalesInvoice();
  }

  Future<void> fetchAddress() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final addressSnapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .where('customerID', isEqualTo: user.uid)
          .get();

      addressList = addressSnapshot.docs.map((doc) {
        return Address.fromMap(doc.data());
      }).toList();
    }
  }

  List<Product> fetchBestSellerProducts() {
    try {
      // Use the local productList that's already been filtered for inactive manufacturers and non-active products
      if (productList.isEmpty) {
        if (kDebugMode) {
          print('Product list is empty, cannot determine best sellers');
        }
        return [];
      }

      // Create a copy of the list to avoid modifying the original
      List<Product> sortedProducts = [...productList];

      // Sort by sales in descending order
      sortedProducts.sort((a, b) => b.sales.compareTo(a.sales));

      // Take the top 5 best sellers
      List<Product> bestSellers = sortedProducts.take(5).toList();

      if (kDebugMode) {
        print('Found ${bestSellers.length} best selling products from local data');
      }

      return bestSellers;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating best seller products: $e');
      }
      rethrow;
    }
  }

  Future<List<Product>> fetchFavoriteProducts(String customerID) async {
    try {
      if (productList.isEmpty) {
        if (kDebugMode) {
          print('Product list is empty, cannot fetch favorites');
        }
        return [];
      }

      final favoriteSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerID)
          .collection('favorites')
          .get();

      final favoriteProductIDs =
          favoriteSnapshot.docs.map((doc) => doc.id).toList();

      if (favoriteProductIDs.isEmpty) {
        return [];
      }

      List<Product> favoriteProducts = productList
          .where((product) => favoriteProductIDs.contains(product.productID))
          .toList();

      if (kDebugMode) {
        print('Found ${favoriteProducts.length} favorite products from local data');
      }

      return favoriteProducts;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorite products: $e');
      }
      rethrow;
    }
  }

  Future<void> updateVoucherLists() async {
    try {
      // Step 1: Get all vouchers
      List<Voucher> allVouchers = await Firebase().getVouchers();

      // Step 2: Get current user ID
      final userId = await getCurrentUserID();
      if (userId == null) {
        // If not logged in, set empty lists
        userVouchers = [];
        ongoingVouchers = [];
        upcomingVouchers = [];
        return;
      }

      // Step 3: Get owned vouchers - using a simpler query to avoid index issues
      List<OwnedVoucher> ownedVouchers =
          await Firebase().getOwnedVouchersByCustomerId(userId);

      // Step 4: Create maps for faster lookups
      Map<String, Voucher> voucherMap = {
        for (var voucher in allVouchers) voucher.voucherID!: voucher
      };

      Map<String, OwnedVoucher> ownedVoucherMap = {
        for (var ownedVoucher in ownedVouchers)
          ownedVoucher.voucherID: ownedVoucher
      };

      // Step 5: Identify owned vouchers to remove (invalid ones)
      List<Future<void>> removalOperations = [];
      Set<String> validOwnedVoucherIds = {};

      for (var ownedVoucher in ownedVouchers) {
        final voucher = voucherMap[ownedVoucher.voucherID];
        final isValid = voucher != null &&
            voucher.isEnabled &&
            voucher.voucherTimeStatus != VoucherTimeStatus.expired;

        if (isValid) {
          validOwnedVoucherIds.add(ownedVoucher.voucherID);
        } else if (ownedVoucher.ownedVoucherID != null) {
          removalOperations
              .add(Firebase().removeOwnedVoucher(ownedVoucher.ownedVoucherID!));
        }
      }

      // Step 6: Find vouchers eligible for claiming
      List<Future<void>> claimOperations = [];

      for (var voucher in allVouchers) {
        if (voucher.isVisible &&
            voucher.isEnabled &&
            voucher.voucherTimeStatus != VoucherTimeStatus.expired &&
            !voucher.voucherRanOut &&
            !validOwnedVoucherIds.contains(voucher.voucherID)) {
          OwnedVoucher newOwnedVoucher = OwnedVoucher(
            voucherID: voucher.voucherID!,
            customerID: userId,
            numberOfUses: voucher.maxUsagePerPerson,
          );

          claimOperations.add(Firebase().addOwnedVoucher(newOwnedVoucher));
          // Add to valid IDs since we're claiming it now
          validOwnedVoucherIds.add(voucher.voucherID!);
          // Add the new owned voucher to our map for later use
          ownedVoucherMap[voucher.voucherID!] = newOwnedVoucher;
        }
      }

      // Step 7: Execute all Firebase operations in parallel
      if (removalOperations.isNotEmpty || claimOperations.isNotEmpty) {
        await Future.wait([...removalOperations, ...claimOperations]);
      }

      // Step 8: Replace maxUsagePerPerson with numberOfUses for each voucher
      List<Voucher> tempVouchers = [];
      for (var voucher in allVouchers) {
        if (validOwnedVoucherIds.contains(voucher.voucherID)) {
          // Replace maxUsagePerPerson with the user's numberOfUses for this voucher
          final ownedVoucher = ownedVoucherMap[voucher.voucherID];
          if (ownedVoucher != null) {
            voucher.maxUsagePerPerson = ownedVoucher.numberOfUses;
          }
          // Only add vouchers with uses remaining
          if (voucher.maxUsagePerPerson > 0) {
            tempVouchers.add(voucher);
          }
        }
      }
      userVouchers = tempVouchers;

      // Step 9: Filter ongoing and upcoming vouchers
      ongoingVouchers = userVouchers
          .where((voucher) =>
              voucher.voucherTimeStatus == VoucherTimeStatus.ongoing)
          .toList();

      upcomingVouchers = userVouchers
          .where((voucher) =>
              voucher.voucherTimeStatus == VoucherTimeStatus.upcoming)
          .toList();

      // Sort all lists
      userVouchers.sort((a, b) => a.startTime.compareTo(b.startTime));
      ongoingVouchers.sort((a, b) => a.startTime.compareTo(b.startTime));
      upcomingVouchers.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating voucher lists: $e');
      }
      rethrow;
    }
  }

  // Get methods for voucher lists
  List<Voucher> getUserVouchers() => userVouchers;
  List<Voucher> getOngoingVouchers() => ongoingVouchers;
  List<Voucher> getUpcomingVouchers() => upcomingVouchers;

  Future<void> fetchSalesInvoice() async {
    salesInvoiceList = await Firebase().getSalesInvoices();
  }
}
