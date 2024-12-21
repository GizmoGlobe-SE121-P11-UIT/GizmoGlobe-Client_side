import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/cpu_enums/cpu_family.dart';
import '../../enums/product_related/drive_enums/drive_capacity.dart';
import '../../enums/product_related/drive_enums/drive_type.dart';
import '../../enums/product_related/gpu_enums/gpu_bus.dart';
import '../../enums/product_related/gpu_enums/gpu_capacity.dart';
import '../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../enums/product_related/mainboard_enums/mainboard_series.dart';
import '../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../enums/product_related/psu_enums/psu_modular.dart';
import '../../enums/product_related/ram_enums/ram_bus.dart';
import '../../enums/product_related/ram_enums/ram_capacity_enum.dart';
import '../../enums/product_related/ram_enums/ram_type.dart';
import '../../objects/product_related/product_factory.dart';

class Database {
  static final Database _database = Database._internal();
  String username = '';
  String email = '';
  List<Manufacturer> manufacturerList = [];
  List<Product> productList = [];

  factory Database() {
    return _database;
  }

  Database._internal();

  Future<void> fetchDataFromFirestore() async {
    try {
      print('Bắt đầu lấy dữ liệu từ Firestore');

      final manufacturerSnapshot = await FirebaseFirestore.instance
          .collection('manufacturers')
          .get();

      manufacturerList = manufacturerSnapshot.docs.map((doc) {
        return Manufacturer(
          manufacturerID: doc.id,
          manufacturerName: doc['manufacturerName'] as String,
        );
      }).toList();

      print('Số lượng manufacturers: ${manufacturerList.length}');

      // Lấy danh sách products từ Firestore
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      print('Số lượng products trong snapshot: ${productSnapshot.docs.length}');

      productList = await Future.wait(productSnapshot.docs.map((doc) async {
        try {
          final data = doc.data();

          // Tìm manufacturer tương ứng
          final manufacturer = manufacturerList.firstWhere(
                (m) => m.manufacturerID == data['manufacturerID'],
            orElse: () {
              print('Manufacturer not found for product ${doc.id}');
              throw Exception('Manufacturer not found for product ${doc.id}');
            },
          );

          // Chuyển đổi dữ liệu từ Firestore sang enum
          final category = CategoryEnum.values.firstWhere(
                (c) => c.getName() == data['category'],
            orElse: () {
              print('Invalid category for product ${doc.id}');
              throw Exception('Invalid category for product ${doc.id}');
            },
          );

          final specificData = _getSpecificProductData(data, category);
          if (specificData.isEmpty) {
            print('Cannot get specific data for product ${doc.id}');
            throw Exception('Cannot get specific data for product ${doc.id}');
          }

          return ProductFactory.createProduct(
            category,
            {
              'productID': doc.id,
              'productName': data['productName'],
              'price': data['price'].toDouble(),
              'manufacturer': manufacturer,
              ...specificData,
            },
          );
        } catch (e) {
          print('Error processing product ${doc.id}: $e');
          return Future.error('Error processing product ${doc.id}: $e');
        }
      }));

      print('Số lượng products trong list: ${productList.length}');

    } catch (e) {
      print('Lỗi chi tiết khi lấy dữ liệu: $e');
      // _initializeSampleData();
    }
  }

  Map<String, dynamic> _getSpecificProductData(Map<String, dynamic> data, CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return {
          'bus': RAMBus.values.firstWhere((b) => b.getName() == data['bus']),
          'capacity': RAMCapacity.values.firstWhere((c) => c.getName() == data['capacity']),
          'ramType': RAMType.values.firstWhere((t) => t.getName() == data['ramType']),
        };

      case CategoryEnum.cpu:
        return {
          'family': CPUFamily.values.firstWhere((f) => f.getName() == data['family']),
          'core': data['core'],
          'thread': data['thread'],
          'clockSpeed': data['clockSpeed'].toDouble(),
        };
      case CategoryEnum.gpu:
        return {
          'series': GPUSeries.values.firstWhere((s) => s.getName() == data['series']),
          'capacity': GPUCapacity.values.firstWhere((c) => c.getName() == data['capacity']),
          'busWidth': GPUBus.values.firstWhere((b) => b.getName() == data['busWidth']),
          'clockSpeed': data['clockSpeed'].toDouble(),
        };
      case CategoryEnum.mainboard:
        return {
          'formFactor': MainboardFormFactor.values.firstWhere((f) => f.getName() == data['formFactor']),
          'series': MainboardSeries.values.firstWhere((s) => s.getName() == data['series']),
          'compatibility': MainboardCompatibility.values.firstWhere((c) => c.getName() == data['compatibility']),
        };
      case CategoryEnum.drive:
        return {
          'type': DriveType.values.firstWhere((t) => t.getName() == data['type']),
          'capacity': DriveCapacity.values.firstWhere((c) => c.getName() == data['capacity']),
        };
      case CategoryEnum.psu:
        return {
          'wattage': data['wattage'],
          'efficiency': PSUEfficiency.values.firstWhere((e) => e.getName() == data['efficiency']),
          'modular': PSUModular.values.firstWhere((m) => m.getName() == data['modular']),
        };
      default:
        return {};
    }
  }

  Future<void> initialize() async {
    try {
      await fetchDataFromFirestore();
    } catch (e) {
      print('Lỗi khi khởi tạo database: $e');
      // Nếu không lấy được dữ liệu từ Firestore, sử dụng dữ liệu mẫu
      // _initializeSampleData();
    }
  }

  void _initializeSampleData() {
    // Di chuyển code khởi tạo dữ liệu mẫu hiện tại vào đây
    manufacturerList = [
      Manufacturer(
        manufacturerID: 'Corsair',
        manufacturerName: 'Corsair',
      ),
      Manufacturer(
        manufacturerID: 'G.Skill',
        manufacturerName: 'G.Skill',
      ),
      Manufacturer(
        manufacturerID: 'Crucial',
        manufacturerName: 'Crucial',
      ),
      Manufacturer(
        manufacturerID: 'Kingston',
        manufacturerName: 'Kingston',
      ),
      Manufacturer(
        manufacturerID: 'Intel',
        manufacturerName: 'Intel',
      ),
      Manufacturer(
        manufacturerID: 'AMD',
        manufacturerName: 'AMD',
      ),
      Manufacturer(
        manufacturerID: 'ASUS',
        manufacturerName: 'ASUS',
      ),
      Manufacturer(
        manufacturerID: 'MSI',
        manufacturerName: 'MSI',
      ),
      Manufacturer(
        manufacturerID: 'Gigabyte',
        manufacturerName: 'Gigabyte',
      ),
      Manufacturer(
        manufacturerID: 'Samsung',
        manufacturerName: 'Samsung',
      ),
      Manufacturer(
        manufacturerID: 'Western Digital',
        manufacturerName: 'Western Digital',
      ),
      Manufacturer(
        manufacturerID: 'Seagate',
        manufacturerName: 'Seagate',
      ),
      Manufacturer(
        manufacturerID: 'Seasonic',
        manufacturerName: 'Seasonic',
      ),
      Manufacturer(
        manufacturerID: 'be quiet!',
        manufacturerName: 'be quiet!',
      ),
      Manufacturer(
        manufacturerID: 'Thermaltake',
        manufacturerName: 'Thermaltake',
      ),
    ];
    
    productList = [
      ProductFactory.createProduct(CategoryEnum.ram, {
        'productName': 'Corsair Vengeance LPX DDR5',
        'price': 79.99,
        'manufacturer': manufacturerList[0], // Corsair
        'bus': RAMBus.mhz4800,
        'capacity': RAMCapacity.gb16,
        'ramType': RAMType.ddr5,
      }),
      ProductFactory.createProduct(CategoryEnum.ram, {
        'productName': 'G.Skill Trident Z RGB DDR4',
        'price': 99.99,
        'manufacturer': manufacturerList[1], // G.Skill
        'bus': RAMBus.mhz3200,
        'capacity': RAMCapacity.gb32,
        'ramType': RAMType.ddr4,
      }),
      ProductFactory.createProduct(CategoryEnum.ram, {
        'productName': 'Crucial Ballistix DDR4',
        'price': 89.99,
        'manufacturer': manufacturerList[2], // Crucial
        'bus': RAMBus.mhz2400,
        'capacity': RAMCapacity.gb32,
        'ramType': RAMType.ddr4,
      }),
      ProductFactory.createProduct(CategoryEnum.ram, {
        'productName': 'Kingston Fury Beast DDR5',
        'price': 159.99,
        'manufacturer': manufacturerList[3], // Kingston
        'bus': RAMBus.mhz2133,
        'capacity': RAMCapacity.gb32,
        'ramType': RAMType.ddr5,
      }),

      // CPU samples - sử dụng Intel và AMD (index 4-5)
      ProductFactory.createProduct(CategoryEnum.cpu, {
        'productName': 'Intel Core i9-12900K',
        'price': 589.99,
        'manufacturer': manufacturerList[4], // Intel
        'family': CPUFamily.corei7Ultra7,
        'core': 16,
        'thread': 24,
        'clockSpeed': 3.2,
      }),
      ProductFactory.createProduct(CategoryEnum.cpu, {
        'productName': 'AMD Ryzen 9 5950X',
        'price': 549.99,
        'manufacturer': manufacturerList[5], // AMD
        'family': CPUFamily.ryzen5,
        'core': 16,
        'thread': 32,
        'clockSpeed': 3.4,
      }),

      // GPU samples - sử dụng ASUS, MSI, Gigabyte (index 6-8)
      ProductFactory.createProduct(CategoryEnum.gpu, {
        'productName': 'ASUS ROG STRIX RTX 3080',
        'price': 899.99,
        'manufacturer': manufacturerList[6], // ASUS
        'series': GPUSeries.rtx,
        'capacity': GPUCapacity.gb12,
        'busWidth': GPUBus.bit384,
        'clockSpeed': 1.71,
      }),


      // Mainboard samples - thêm các form factor và chipset khác nhau
      ProductFactory.createProduct(CategoryEnum.mainboard, {
        'productName': 'ASUS ROG STRIX B550-F GAMING',
        'price': 189.99,
        'manufacturer': manufacturerList[5],
        'formFactor': MainboardFormFactor.atx,
        'series': MainboardSeries.b,
        'compatibility': MainboardCompatibility.amd,
      }),
      ProductFactory.createProduct(CategoryEnum.mainboard, {
        'productName': 'MSI MPG B560I GAMING EDGE',
        'price': 159.99,
        'manufacturer': manufacturerList[6],
        'formFactor': MainboardFormFactor.miniITX,
        'series': MainboardSeries.b,
        'compatibility': MainboardCompatibility.intel,
      }),
      ProductFactory.createProduct(CategoryEnum.mainboard, {
        'productName': 'ASUS ROG MAXIMUS Z690 HERO',
        'price': 599.99,
        'manufacturer': manufacturerList[5],
        'formFactor': MainboardFormFactor.atx,
        'series': MainboardSeries.z,
        'compatibility': MainboardCompatibility.intel,
      }),
      ProductFactory.createProduct(CategoryEnum.mainboard, {
        'productName': 'MSI MAG X570S TOMAHAWK',
        'price': 219.99,
        'manufacturer': manufacturerList[6],
        'formFactor': MainboardFormFactor.atx,
        'series': MainboardSeries.x,
        'compatibility': MainboardCompatibility.amd,
      }),

      // Drive samples - thêm các loại ổ cứng khác nhau
      ProductFactory.createProduct(CategoryEnum.drive, {
        'productName': 'Samsung 970 EVO Plus',
        'price': 129.99,
        'manufacturer': manufacturerList[9], // Samsung
        'type': DriveType.m2NVME,
        'capacity': DriveCapacity.gb512,
      }),
      ProductFactory.createProduct(CategoryEnum.drive, {
        'productName': 'WD Black SN850X',
        'price': 159.99,
        'manufacturer': manufacturerList[10], // Western Digital
        'type': DriveType.m2NVME,
        'capacity': DriveCapacity.tb1,
      }),
      ProductFactory.createProduct(CategoryEnum.drive, {
        'productName': 'Seagate FireCuda 530',
        'price': 199.99,
        'manufacturer': manufacturerList[11], // Seagate
        'type': DriveType.m2NVME,
        'capacity': DriveCapacity.tb2,
      }),

      // PSU samples - sử dụng Seasonic, be quiet!, Thermaltake (index 12-14)
      ProductFactory.createProduct(CategoryEnum.psu, {
        'productName': 'Seasonic FOCUS GX-750',
        'price': 129.99,
        'manufacturer': manufacturerList[12], // Seasonic
        'wattage': 750,
        'efficiency': PSUEfficiency.gold,
        'modular': PSUModular.fullModular,
      }),
      ProductFactory.createProduct(CategoryEnum.psu, {
        'productName': 'be quiet! Dark Power 12',
        'price': 199.99,
        'manufacturer': manufacturerList[13], // be quiet!
        'wattage': 1000,
        'efficiency': PSUEfficiency.titanium,
        'modular': PSUModular.fullModular,
      }),
      ProductFactory.createProduct(CategoryEnum.psu, {
        'productName': 'Thermaltake Toughpower GF1',
        'price': 149.99,
        'manufacturer': manufacturerList[14], // Thermaltake
        'wattage': 850,
        'efficiency': PSUEfficiency.gold,
        'modular': PSUModular.fullModular,
      }),
    ];
  }

  void generateSampleData() {
       
    // Tạo danh sách sản phẩm
   
  }

  Future<void> getUsername() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      username = userDoc['username'];
    }
  }

  Future<void> getUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      username = userDoc['username'];
      email = userDoc['email'];
    }
  }
}