import 'package:cloud_firestore/cloud_firestore.dart';

class Firebase {
  static final Firebase _firebase = Firebase._internal();

  factory Firebase() {
    return _firebase;
  }

  Firebase._internal();
}

// Future<void> pushCategoryListToFirebase() async {
//   final firestoreInstance = FirebaseFirestore.instance;
//   final firebaseInstance = Firebase(); // Get the instance of Firebase class
//
//   for (var category in firebaseInstance.categoryList) { // Use the instance to access categoryList
//     await firestoreInstance.collection('categories').add({
//       'id': category.id,
//       'name': category.name,
//       'iconID': category.iconID,
//       'isIncome': category.isIncome,
//       'red': category.red,
//       'green': category.green,
//       'blue': category.blue,
//       'opacity': category.opacity,
//       'userID': category.userID,
//     });
//   }
// }
//
// Future<void> pushWalletListToFirebase() async {
//   final firestoreInstance = FirebaseFirestore.instance;
//   final firebaseInstance = Firebase(); // Get the instance of Firebase class
//
//   for (var wallet in firebaseInstance.walletList) { // Use the instance to access walletList
//     await firestoreInstance.collection('wallets').add({
//       'id': wallet.id,
//       'name': wallet.name,
//       'balance': wallet.balance.toString(), // Firestore does not support BigInt, convert it to String
//       'userID': wallet.userID,
//     });
//   }
// }
//
// Future<void> pushTransactionListToFirebase() async {
//   final firestoreInstance = FirebaseFirestore.instance;
//   final firebaseInstance = Firebase(); // Get the instance of Firebase class
//
//   for (var transaction in firebaseInstance.transactionList) { // Use the instance to access transactionList
//     await firestoreInstance.collection('transactions').add({
//       'id': transaction.id,
//       'categoryID': transaction.categoryID,
//       'walletID': transaction.walletID,
//       'amount': transaction.amount.toString(),
//       'date': transaction.date,
//       'note': transaction.note,
//       'userID': transaction.userID,
//     });
//   }
// }