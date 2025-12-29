import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gizmoglobe_client/objects/invoice_related/rating.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
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
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';

import '../../enums/manufacturer/manufacturer_status.dart';
import '../../enums/voucher_related/distribution_type.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../objects/address_related/province.dart';
import '../../objects/product_related/product_factory.dart';
import '../../objects/product_related/ram_related/ram.dart';
import '../../objects/voucher_related/voucher.dart';
import '../firebase/firebase.dart';

class Database {
  static final Database _database = Database._internal();
  static const String _salesInvoiceCacheKey = 'cached_sales_invoices';
  static bool _authStateInitialized = false;

  String userID = '';
  String username = '';
  String email = '';
  int loyalPoint = 0;

  List<Manufacturer> manufacturerList = [];
  List<Manufacturer> inactiveManufacturerList = [];
  List<Product> productList = [];
  List<Product> fullProductList = [];
  List<Province> provinceList = [];
  List<Address> addressList = [];
  List<Product> favoriteProducts = [];
  List<Product> bestSellerProducts = [];
  List<SalesInvoice> salesInvoiceList = [];
  List<Voucher> allVoucherList = [];
  List<Voucher> ownedVoucherList = [];
  List<Voucher> redeemableVoucherList = [];
  List<Rating> ratingList = [];

  List<RAM> ramList = [];
  List<CPU> cpuList = [];
  List<GPU> gpuList = [];
  List<PSU> psuList = [];
  List<Mainboard> mainboardList = [];
  List<Drive> driveList = [];

  List<Voucher> ongoingVouchers = [];
  List<Voucher> upcomingVouchers = [];
  List<CartItem> cartItems = [];
  // Map of voucherID -> numberOfUses owned by current user (populated on updateVoucherLists)
  Map<String, int> ownedVoucherUses = {};
  Map<String, dynamic>? userSurveyProfile;

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
        .where((manufacturer) =>
            manufacturer.status == ManufacturerStatus.inactive)
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
      userID = await getCurrentUserID() ?? '';

      // await addStatusToAllProducts();
      await _ensureAuthStateInitialized();
      await getUserData();
      await getLoyalPoint();
      // print('Đang lấy dữ liệu từ Firebase');
      provinceList = await fetchProvinces();

      await fetchAddress();

      final manufacturerSnapshot =
          await FirebaseFirestore.instance.collection('manufacturers').get();

      manufacturerList = manufacturerSnapshot.docs.map((doc) {
        final data = doc.data();
        final docStatus = data['status'] as String?;
        return Manufacturer(
          manufacturerID: doc.id,
          manufacturerName: doc['manufacturerName'] as String,
          status: ManufacturerStatus.values.firstWhere(
            (e) =>
                e.getName().toLowerCase() ==
                (docStatus?.toLowerCase() ??
                    ManufacturerStatus.active.getName().toLowerCase()),
            orElse: () => ManufacturerStatus.active,
          ),
        );
      }).toList();

      getInactiveManufacturerList();

      productList = await getProducts();

      bestSellerProducts = fetchBestSellerProducts();
      favoriteProducts = await fetchFavoriteProducts(userID);

      await getCartItems();
      await updateVoucherLists();

      await fetchSalesInvoice();
      await getRating();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getCartItems() async {
    await _ensureAuthStateInitialized();
    try {
      if (userID.isEmpty) {
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
      rethrow;
    }
  }

  Future<void> initialize() async {
    try {
      await fetchDataFromFirestore();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Province>> fetchProvinces() async {
    const filePath = 'lib/data/database/full_json_generated_data_vn_units.json';

    try {
      final String response = await rootBundle.loadString(filePath);
      if (response.isEmpty) {
        throw Exception('JSON file is empty');
      }

      final List? jsonList = jsonDecode(response) as List<dynamic>?;
      if (jsonList == null) {
        throw Exception('Error parsing JSON data');
      }

      List<Province> provinceList =
          jsonList.map((province) => Province.fromJson(province)).toList();
      return provinceList;
    } catch (e) {
      throw Exception('Error loading provinces from file: $e');
      // throw Exception('Lỗi khi tải danh sách tỉnh thành từ tệp: $e');
    }
  }

  Future<Product?> getProductByID(String productID) async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productID)
          .get();

      if (!productDoc.exists) {
        return null;
      }

      final dynamic raw = productDoc.data();
      if (raw is! Map<String, dynamic>) {
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

      data.putIfAbsent('productID', () => productDoc.id);

      return ProductFactory.createProduct(data);
    } catch (e, st) {
      rethrow;
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final productSnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final products = (await Future.wait(productSnapshot.docs.map((doc) async {
        try {
          final dynamic raw = doc.data();
          if (raw is! Map<String, dynamic>) {
            return null;
          }

          final Map<String, dynamic> data =
              raw.map<String, dynamic>((key, value) {
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
          rethrow;
        }
      })))
          .whereType<Product>()
          .toList();

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
      final data = userDoc.data() as Map<String, dynamic>?;
      username = data?['username'] ?? '';
    }
  }

  Future<void> addLoyalPoint(int point) async {
    loyalPoint += point;
    await Firebase().updateLoyalPoint(userID, loyalPoint);
    await getLoyalPoint();
  }

  Future<void> subtractLoyalPoint(int point) async {
    loyalPoint -= point;
    await Firebase().updateLoyalPoint(userID, loyalPoint);
    await getLoyalPoint();
  }

  Future<void> getUserData() async {
    await _ensureAuthStateInitialized();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data() as Map<String, dynamic>?;
      userID = user.uid;
      username = data?['username'] ?? '';
      email = data?['email'] ?? '';

      userSurveyProfile = await Firebase().getUserSurveyProfile(userID);
    }
  }

  Future<void> getLoyalPoint() async {
    await _ensureAuthStateInitialized();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();
      final data = userDoc.data() as Map<String, dynamic>?;
      loyalPoint = data?['loyalPoint'] ?? 0;
    }
  }

  Future<void> getUser() async {
    await _ensureAuthStateInitialized();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data() as Map<String, dynamic>?;
      userID = user.uid;
      username = data?['username'] ?? '';
      email = data?['email'] ?? '';
    }

    await fetchAddress();
    await fetchSalesInvoice();
  }

  Future<void> fetchAddress() async {
    await _ensureAuthStateInitialized();
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
        return [];
      }

      // Create a copy of the list to avoid modifying the original
      List<Product> sortedProducts = [...productList];

      // Sort by sales in descending order
      sortedProducts.sort((a, b) => b.sales.compareTo(a.sales));

      // Take the top 10 best sellers (UI will show 4-7 based on screen width)
      List<Product> bestSellers = sortedProducts.take(10).toList();

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
      // Check if customerID is empty or null (e.g., for guest users)
      if (customerID.isEmpty) {
        return [];
      }

      if (productList.isEmpty) {
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
        print(
            'Found ${favoriteProducts.length} favorite products from local data');
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
      allVoucherList = await Firebase().getVouchers();

      if (userID.isEmpty) {
        ongoingVouchers = [];
        upcomingVouchers = [];
        ownedVoucherList = [];
        redeemableVoucherList = [];
        return;
      }

      final ownedRecords =
          await Firebase().getOwnedVouchersByCustomerId(userID);

      final Map<String, int> ownedUsesByVoucherId = {};
      for (final o in ownedRecords) {
        final id = o.voucherID.trim();
        if (id.isEmpty) continue;
        ownedUsesByVoucherId[id] = o.numberOfUses;
      }

      final ownedIds = ownedRecords
          .where((o) => (o.numberOfUses) > 0)
          .map((o) => o.voucherID.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      bool hasNoTotalUsage(dynamic v) {
        try {
          final isLimited = (v as dynamic).isLimited ?? false;
          if (isLimited) {
            final maxUsage = (v as dynamic).maximumUsage ?? 0;
            return maxUsage == 0;
          }
          return false;
        } catch (_) {
          return false;
        }
      }

      bool isVoucherRedeemable(dynamic v) {
        try {
          final dt = (v as dynamic).distributionType;
          if (dt is DistributionType) {
            return dt == DistributionType.rewards;
          } else if (dt is String) {
            return dt.toLowerCase() ==
                DistributionType.rewards.getName().toLowerCase();
          }
        } catch (_) {}
        return false;
      }

      ownedVoucherList = allVoucherList.where((v) {
        final vid = (v.voucherID ?? '').trim();
        if (vid.isEmpty) return false;
        if (!ownedIds.contains(vid)) return false;
        if (hasNoTotalUsage(v)) return false;

        try {
          final ranOut = (v as dynamic).voucherRanOut ?? false;
          if (ranOut) {
            final ownedUses = ownedUsesByVoucherId[vid] ?? 0;
            final isRedeemableAndOwned =
                isVoucherRedeemable(v) && ownedUses > 0;
            if (!isRedeemableAndOwned) return false;
          }
        } catch (_) {}

        return true;
      }).toList();

      redeemableVoucherList = allVoucherList.where((v) {
        final vid = (v.voucherID ?? '').trim();
        if (vid.isEmpty) return false;
        if (ownedIds.contains(vid)) return false;

        if (hasNoTotalUsage(v)) return false;

        bool ranOut = false;
        try {
          ranOut = (v as dynamic).voucherRanOut ?? false;
        } catch (_) {
          ranOut = false;
        }
        if (ranOut) return false;

        bool isRedeemable = false;
        try {
          final dt = (v as dynamic).distributionType;
          if (dt is DistributionType) {
            isRedeemable = dt == DistributionType.rewards;
          } else if (dt is String) {
            isRedeemable = dt.toLowerCase() ==
                DistributionType.rewards.getName().toLowerCase();
          }
        } catch (_) {
          isRedeemable = false;
        }
        if (!isRedeemable) return false;

        return true;
      }).toList();

      ongoingVouchers = ownedVoucherList.where((v) {
        try {
          return (v as dynamic).voucherTimeStatus == VoucherTimeStatus.ongoing;
        } catch (_) {
          return false;
        }
      }).toList();

      upcomingVouchers = allVoucherList.where((v) {
        try {
          if (hasNoTotalUsage(v)) return false;
          return (v as dynamic).voucherTimeStatus == VoucherTimeStatus.upcoming;
        } catch (_) {
          return false;
        }
      }).toList();

      ownedVoucherUses = {};
      for (final o in ownedRecords) {
        final id = o.voucherID.trim();
        if (id.isEmpty) continue;
        ownedVoucherUses[id] = o.numberOfUses;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating voucher lists: $e');
      }
    }
  }

  Future<void> fetchSalesInvoice() async {
    await _ensureAuthStateInitialized();
    try {
      salesInvoiceList = await Firebase().getSalesInvoices();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sales invoices: $e');
      }
      await _loadSalesInvoicesFromCache();
    }

    await _saveSalesInvoicesToCache();
  }

  Future<void> refreshUserScopedData() async {
    await _ensureAuthStateInitialized();
    await getUserData();
    await fetchAddress();
    await fetchSalesInvoice();
  }

  Future<void> _ensureAuthStateInitialized() async {
    if (_authStateInitialized) {
      return;
    }
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 2));
      _authStateInitialized = true;
    } on TimeoutException {
      if (kDebugMode) {
        print('Auth state initialization timed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error waiting for auth state: $e');
      }
    }
  }

  Future<void> _saveSalesInvoicesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        salesInvoiceList.map((invoice) {
          return {
            ...invoice.toMap(),
            'date': invoice.date.toIso8601String(),
            'details': invoice.details
                .map((detail) => detail.toMap(invoice.salesInvoiceID ?? ''))
                .toList(),
          };
        }).toList(),
      );
      await prefs.setString(_salesInvoiceCacheKey, encoded);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cache sales invoices: $e');
      }
    }
  }

  Future<void> getRating() async {
    ratingList = await Firebase().getRatingsByUser(userID);
    await calculateProductRatings();
  }

  Future<void> calculateProductRatings({bool refreshRatings = false}) async {
    try {
      if (productList.isEmpty) return;

      if (refreshRatings || ratingList.isEmpty) {
        ratingList = await Firebase().getRatingsByUser(userID);
      }

      final Map<String, List<double>> ratingsMap = {};

      for (final r in ratingList) {
        final String? pid = (r.productID.isNotEmpty) ? r.productID : null;
        if (pid == null) continue;

        double value;
        try {
          final dynamic raw = r.rating;
          if (raw is num) {
            value = raw.toDouble();
          } else {
            value = double.tryParse(raw.toString()) ?? 0.0;
          }
        } catch (_) {
          value = 0.0;
        }

        ratingsMap.putIfAbsent(pid, () => []).add(value);
      }

      for (final product in productList) {
        final pid = product.productID;
        if (pid == null || !ratingsMap.containsKey(pid)) {
          product.rating = null;
          continue;
        }
        final List<double> values = ratingsMap[pid]!;
        if (values.isEmpty) {
          product.rating = null;
          continue;
        }
        final double sum = values.fold(0.0, (a, b) => a + b);
        final double avg = sum / values.length;
        final double rounded = (avg * 10).roundToDouble() / 10.0;
        product.setRating(rounded);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating product ratings: $e');
      }
      rethrow;
    }
  }

  /// Update average rating for a single product using server-side aggregation
  Future<void> updateProductAverage(String productId) async {
    try {
      if (productId.isEmpty) return;
      final result = await Firebase().getAverageRatingForProduct(productId);
      final avg = (result['average'] as num?)?.toDouble() ?? 0.0;
      final count =
          (result['count'] as int?) ?? (result['count'] as num?)?.toInt() ?? 0;

      final product = productList.firstWhere(
        (p) => p.productID == productId,
      );

      if (count == 0) {
        product.setRating(0);
      } else {
        final double rounded = (avg * 10).roundToDouble() / 10.0;
        product.setRating(rounded);
      }
    } catch (e) {
      if (kDebugMode)
        print('Error updating product average for $productId: $e');
    }
  }

  /// Update average ratings for all products in productList.
  /// This calls Firestore per product and may be slow for large catalogs.
  Future<void> updateAllProductAverages() async {
    try {
      for (final p in productList) {
        final pid = p.productID;
        if (pid == null || pid.isEmpty) continue;
        await updateProductAverage(pid);
      }
    } catch (e) {
      if (kDebugMode) print('Error updating all product averages: $e');
    }
  }

  Future<void> _loadSalesInvoicesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_salesInvoiceCacheKey);
      if (encoded == null || encoded.isEmpty) {
        salesInvoiceList = [];
        return;
      }

      final List<dynamic> decoded = jsonDecode(encoded);
      salesInvoiceList = decoded.map((item) {
        final invoice =
            SalesInvoice.fromMap(item['salesInvoiceID'] ?? '', item);
        final detailList = (item['details'] as List<dynamic>? ?? [])
            .map((detailMap) => SalesInvoiceDetail.fromMap(
                detailMap['salesInvoiceDetailID'] ?? '', detailMap))
            .toList();
        return invoice.copyWith(details: detailList);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load cached sales invoices: $e');
      }
      salesInvoiceList = [];
    }
  }
}
