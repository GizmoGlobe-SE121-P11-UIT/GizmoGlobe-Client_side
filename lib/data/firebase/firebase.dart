import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/database/database.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/psu.dart';
import 'package:gizmoglobe_client/objects/product_related/ram.dart';

Future<void> pushProductSamplesToFirebase() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Database database = Database();

  // Push manufacturers to Firestore
  for (var manufacturer in database.manufacturerList) {
    await firestore.collection('manufacturers').doc(manufacturer.manufacturerID).set({
      'manufacturerID': manufacturer.manufacturerID,
      'manufacturerName': manufacturer.manufacturerName,
    });
  }

  // Push products to Firestore
  for (var product in database.productList) {
    Map<String, dynamic> productData = {
      'productName': product.productName,
      'price': product.price,
      'manufacturerID': product.manufacturer.manufacturerID,
      'category': product.category.toString(),
    };

    // Thêm các thuộc tính đặc thù cho từng loại sản phẩm
    switch (product.runtimeType) {
      case RAM:
        final ram = product as RAM;
        productData.addAll({
          'bus': ram.bus.getName(),
          'capacity': ram.capacity.getName(),
          'ramType': ram.ramType.getName(),
        });
        break;

      case CPU:
        final cpu = product as CPU;
        productData.addAll({
          'family': cpu.family.getName(),
          'core': cpu.core,
          'thread': cpu.thread,
          'clockSpeed': cpu.clockSpeed,
        });
        break;

      case GPU:
        final gpu = product as GPU;
        productData.addAll({
          'series': gpu.series.getName(),
          'capacity': gpu.capacity.getName(),
          'busWidth': gpu.bus.getName(),
          'clockSpeed': gpu.clockSpeed,
        });
        break;

      case Mainboard:
        final mainboard = product as Mainboard;
        productData.addAll({
          'formFactor': mainboard.formFactor.getName(),
          'series': mainboard.series.getName(),
          'compatibility': mainboard.compatibility.getName(),
        });
        break;

      case Drive:
        final drive = product as Drive;
        productData.addAll({
          'type': drive.type.getName(),
          'capacity': drive.capacity.getName(),
        });
        break;

      case PSU:
        final psu = product as PSU;
        productData.addAll({
          'wattage': psu.wattage,
          'efficiency': psu.efficiency.getName(),
          'modular': psu.modular.getName(),
        });
        break;
    }

    // Thêm sản phẩm vào Firestore với tất cả thuộc tính
    await firestore.collection('products').add(productData);
  }
}

class Firebase {
  static final Firebase _firebase = Firebase._internal();

  factory Firebase() {
    return _firebase;
  }

  Firebase._internal();
}