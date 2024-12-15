import '../../enums/product_related/category_enum.dart';
import 'product.dart';
import 'ram.dart';
import 'psu.dart';
import 'cpu.dart';
import 'drive.dart';
import 'gpu.dart';
import 'mainboard.dart';

class ProductFactory {
  static Product createProduct(Category category, Map<String, dynamic> properties) {
    switch (category) {
      case Category.ram:
        return RAM(
          productName: properties['productName'],
          price: properties['price'],
          manufacturerID: properties['manufacturerID'],
          bus: properties['bus'],
          capacity: properties['capacity'],
          ramType: properties['ramType'],
        )..productID = properties['productID'];
      case Category.cpu:
        return CPU(
          productName: properties['productName'],
          price: properties['price'],
          manufacturerID: properties['manufacturerID'],
          family: properties['family'],
          core: properties['core'],
          thread: properties['thread'],
          clockSpeed: properties['clockSpeed'],
        )..productID = properties['productID'];
      case Category.psu:
        return PSU(
          productName: properties['productName'],
          price: properties['price'],
          manufacturerID: properties['manufacturerID'],
          wattage: properties['wattage'],
          efficiency: properties['efficiency'],
          modular: properties['modular'],
        )..productID = properties['productID'];
      case Category.gpu:
        return GPU(
          productName: properties['productName'],
          price: properties['price'],
          manufacturerID: properties['manufacturerID'],
          series: properties['series'],
          capacity: properties['capacity'],
          bus: properties['busWidth'],
          clockSpeed: properties['clockSpeed'],
        )..productID = properties['productID'];
      case Category.mainboard:
        return Mainboard(
          productName: properties['productName'],
          price: properties['price'],
          manufacturerID: properties['manufacturerID'],
          formFactor: properties['formFactor'],
          series: properties['series'],
          compatibility: properties['compatibility'],
        )..productID = properties['productID'];
      case Category.drive:
        return Drive(
          productName: properties['productName'],
          price: properties['price'],
          manufacturerID: properties['manufacturerID'],
          type: properties['type'],
          capacity: properties['capacity'],
        )..productID = properties['productID'];
      default:
        throw Exception('Invalid product category');
    }
  }
}