import '../../enums/product_related/category_enum.dart';
import 'product.dart';
import 'ram.dart';
import 'psu.dart';
import 'cpu.dart';
import 'drive.dart';
import 'gpu.dart';
import 'mainboard.dart';

class ProductFactory {
  static Product createProduct(CategoryEnum category, Map<String, dynamic> properties) {
    switch (category) {
      case CategoryEnum.ram:
        return RAM(
          productName: properties['productName'],
          price: properties['price'],
          manufacturer: properties['manufacturer'],
          bus: properties['bus'],
          capacity: properties['capacity'],
          ramType: properties['ramType'],
        )..productID = properties['productID'];
      case CategoryEnum.cpu:
        return CPU(
          productName: properties['productName'],
          price: properties['price'],
          manufacturer: properties['manufacturer'],
          family: properties['family'],
          core: properties['core'],
          thread: properties['thread'],
          clockSpeed: properties['clockSpeed'],
        )..productID = properties['productID'];
      case CategoryEnum.psu:
        return PSU(
          productName: properties['productName'],
          price: properties['price'],
          manufacturer: properties['manufacturer'],
          wattage: properties['wattage'],
          efficiency: properties['efficiency'],
          modular: properties['modular'],
        )..productID = properties['productID'];
      case CategoryEnum.gpu:
        return GPU(
          productName: properties['productName'],
          price: properties['price'],
          manufacturer: properties['manufacturer'],
          series: properties['series'],
          capacity: properties['capacity'],
          bus: properties['busWidth'],
          clockSpeed: properties['clockSpeed'],
        )..productID = properties['productID'];
      case CategoryEnum.mainboard:
        return Mainboard(
          productName: properties['productName'],
          price: properties['price'],
          manufacturer: properties['manufacturer'],
          formFactor: properties['formFactor'],
          series: properties['series'],
          compatibility: properties['compatibility'],
        )..productID = properties['productID'];
      case CategoryEnum.drive:
        return Drive(
          productName: properties['productName'],
          price: properties['price'],
          manufacturer: properties['manufacturer'],
          type: properties['type'],
          capacity: properties['capacity'],
        )..productID = properties['productID'];
      default:
        throw Exception('Invalid product category');
    }
  }
}