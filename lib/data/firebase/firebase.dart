import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/database/database.dart';

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
    await firestore.collection('products').add({
      'productName': product.productName,
      'price': product.price,
      'manufacturerID': product.manufacturer.manufacturerID,
      'category': product.category.toString(),
      // Add other product-specific fields here
    });
  }
}

class Firebase {
  static final Firebase _firebase = Firebase._internal();

  factory Firebase() {
    return _firebase;
  }

  Firebase._internal();
}