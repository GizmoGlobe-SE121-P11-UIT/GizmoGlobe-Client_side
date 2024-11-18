import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../functions/getdata.dart';

class Database {
  static final Database _database = Database._internal();

  factory Database() {
    return _database;
  }

  Database._internal();
  //
  // Future<void> updateCategoryListFromFirestore() async {
  //   try {
  //     final firestoreInstance = FirebaseFirestore.instance;
  //     final QuerySnapshot querySnapshot = await firestoreInstance
  //         .collection('categories')
  //         .where('userID', isEqualTo: GetData.getUID())
  //         .get();
  //     categoryList = querySnapshot.docs.map((doc) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       return CategoryModel(
  //         id: data['id'],
  //         name: data['name'],
  //         iconType: iconTypeList.firstWhere((element) =>
  //         element.id == data['iconID']),
  //         isIncome: data['isIncome'],
  //         color: Color.fromRGBO(
  //             data['red'], data['green'], data['blue'], data['opacity']),
  //       );
  //     }).toList();
  //     categoryList.sort((a, b) => a.name.compareTo(b.name));
  //     if (kDebugMode) {
  //       print(categoryList);
  //     }
  //   } catch (e) {
  //     // If an error occurs, catch it and show an error toast
  //     throw Exception("An error occurred - Category: ${e.toString()}");
  //   }
  // }
  //
  // Future<void> updateWalletListFromFirestore() async {
  //   try {
  //     final firestoreInstance = FirebaseFirestore.instance;
  //     final QuerySnapshot querySnapshot = await firestoreInstance
  //         .collection('wallets')
  //         .where('userID', isEqualTo: GetData.getUID())
  //         .get();
  //
  //     walletList = querySnapshot.docs.map((doc) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       return WalletModel(
  //         id: data['id'],
  //         name: data['name'],
  //         balance: BigInt.parse(data['balance']),
  //       );
  //     }).toList();
  //     walletList.sort((a, b) => a.name.compareTo(b.name));
  //   } catch (e) {
  //     // If an error occurs, catch it and show an error toast
  //     throw Exception("An error occurred - Wallet: ${e.toString()}");
  //   }
  // }
  //
  // Future<void> updateTransactionListFromFirestore() async {
  //   try {
  //     final firestoreInstance = FirebaseFirestore.instance;
  //     final QuerySnapshot querySnapshot = await firestoreInstance
  //         .collection('transactions')
  //         .where('userID', isEqualTo: GetData.getUID())
  //         .get();
  //
  //     await updateCategoryListFromFirestore();
  //     await updateWalletListFromFirestore();
  //
  //     transactionList = querySnapshot.docs.map((doc) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       return TransactionModel(
  //         id: data['id'],
  //         category: categoryList.firstWhere((element) =>
  //         element.id == data['categoryID']),
  //         wallet: walletList.firstWhere((element) =>
  //         element.id == data['walletID']),
  //         date: (data['date'] as Timestamp).toDate(),
  //         note: data['note'] ?? '',
  //         amount: Converter.toBigInt(data['amount']),
  //       );
  //     }).toList();
  //     transactionList.sort((a, b) => b.date.compareTo(a.date));
  //   } catch (e) {
  //     throw Exception("An error occurred - Transaction: ${e.toString()}");
  //   }
  // }
  //
  // Future<void> updateTransactionListStream() async {
  //   try {
  //     await updateCategoryListFromFirestore();
  //     await updateWalletListFromFirestore();
  //     final firestoreInstance = FirebaseFirestore.instance;
  //     transactionListStream = firestoreInstance
  //         .collection('transactions')
  //         .where('userID', isEqualTo: GetData.getUID())
  //         .snapshots()
  //         .asyncMap((querySnapshot) async {
  //       var transactions = querySnapshot.docs.map((doc) {
  //         Map<String, dynamic> data = doc.data();
  //         return TransactionModel(
  //           id: data['id'],
  //           category: categoryList.firstWhere((element) =>
  //           element.id == data['categoryID']),
  //           wallet: walletList.firstWhere((element) =>
  //           element.id == data['walletID']),
  //           date: (data['date'] as Timestamp).toDate(),
  //           note: data['note'] ?? '',
  //           amount: Converter.toBigInt(data['amount']),
  //         );
  //       }).toList();
  //
  //       // Sort the transactions by date in descending order
  //       transactions.sort((a, b) => b.date.compareTo(a.date));
  //       await updateTransactionListFromFirestore();
  //       return transactions;
  //     });
  //   } catch (e) {
  //     throw Exception("An error occurred - Transaction: ${e.toString()}");
  //   }
  // }
  //
  // Future<void> updateBudgetListStream() async {
  //   try {
  //     await updateCategoryListFromFirestore();
  //     await updateWalletListFromFirestore();
  //     final firestoreInstance = FirebaseFirestore.instance;
  //     // Fetch budget_details from Firestore
  //     final QuerySnapshot budgetDetailsQuerySnapshot = await firestoreInstance
  //         .collection('budget_details')
  //         .where('userID', isEqualTo: GetData.getUID())
  //         .get();
  //
  //     // Map budget_details to BudgetDetailModel objects
  //     final budgetDetails = budgetDetailsQuerySnapshot.docs.map((doc) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       return BudgetDetailModel(
  //         budgetID: data['budgetID'],
  //         category: categoryList.firstWhere((element) =>
  //         element.id == data['categoryID']),
  //         amount: Converter.toBigInt(data['amount']),
  //         userID: data['userID'],
  //       );
  //     }).toList();
  //
  //     budgetListStream = firestoreInstance
  //         .collection('budgets')
  //         .where('userID', isEqualTo: GetData.getUID())
  //         .snapshots()
  //         .asyncMap((querySnapshot) async {
  //       var budgets = querySnapshot.docs.map((doc) {
  //         Map<String, dynamic> data = doc.data();
  //
  //         // Filter budgetDetails for the current BudgetModel
  //         var details = budgetDetails.where((detail) =>
  //         detail.budgetID == data['id']).toList();
  //
  //         return BudgetModel(
  //           id: data['id'],
  //           month: data['month'],
  //           year: data['year'],
  //           otherAmount: Converter.toBigInt(data['otherAmount']),
  //           budgetDetails: details,
  //           userID: data['userID'],
  //         );
  //       }).toList();
  //       return budgets;
  //     });
  //   } on Exception {
  //     rethrow;
  //   }
  // }
  //
  // Future<void> updateBudgetListStreamTest() async {
  //   try {
  //     await updateCategoryListFromFirestore();
  //     final firebaseInstance = Firebase();
  //
  //     final budgetDetails = firebaseInstance.budgetDetailList.map((detailDTO) {
  //       // Create a BudgetDetailModel
  //       return BudgetDetailModel(
  //         budgetID: detailDTO.budgetID,
  //         category: categoryList.firstWhere((element) => element.id == detailDTO.categoryID),
  //         amount: detailDTO.amount,
  //         userID: detailDTO.userID,
  //       );
  //     }).toList();
  //
  //     var budgets = firebaseInstance.budgetList.map((budget) {
  //       var details = budgetDetails.where((detail) =>
  //       detail.budgetID == budget.id).toList();
  //
  //       return BudgetModel(
  //         id: budget.id,
  //         month: budget.month,
  //         year: budget.year,
  //         otherAmount: budget.otherAmount,
  //         budgetDetails: details,
  //         userID: budget.userID,
  //       );
  //     }).toList();
  //
  //     // Convert the list of BudgetModel objects to a stream
  //     budgetListStream = Stream.value(budgets);
  //   } on Exception {
  //     rethrow;
  //   }
  // }
  //
  // Future<String> getUsernames() async {
  //   try {
  //     final firestoreInstance = FirebaseFirestore.instance;
  //     final DocumentSnapshot userDoc = await firestoreInstance
  //         .collection('users')
  //         .doc(GetData.getUID())
  //         .get();
  //     return userDoc['name'];
  //   } catch (e) {
  //     throw Exception("An error occurred - User: ${e.toString()}");
  //   }
  // }
}
