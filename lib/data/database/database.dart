import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../enums/product_related/psu_enums/psu_modular.dart';
import '../../enums/product_related/ram_enums/ram_bus.dart';
import '../../enums/product_related/ram_enums/ram_capacity_enum.dart';
import '../../enums/product_related/ram_enums/ram_type.dart';
import '../../objects/product_related/psu.dart';
import '../../objects/product_related/ram.dart';

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

  initialize() {
    manufacturerList = [
      Manufacturer(
        manufacturerID: 'Corsair',
        manufacturerName: 'Corsair',
      ),
      Manufacturer(
        manufacturerID: 'EVGA',
        manufacturerName: 'EVGA',
      ),
      Manufacturer(
        manufacturerID: 'G.Skill',
        manufacturerName: 'G.Skill',
      ),
    ];

    productList = [
      RAM(
        productName: 'Corsair Vengeance LPX',
        price: 79.99,
        manufacturer: manufacturerList[0],
        bus: RAMBus.mhz4800,
        capacity: RAMCapacity.gb16,
        ramType: RAMType.ddr5,
      ),
      RAM(
        productName: 'G.Skill Trident Z RGB',
        price: 99.99,
        manufacturer: manufacturerList[2],
        bus: RAMBus.mhz3200,
        capacity: RAMCapacity.gb16,
        ramType: RAMType.ddr4,
      ),
      PSU(
        productName: 'EVGA SuperNOVA 750 G5',
        price: 129.99,
        manufacturer: manufacturerList[1],
        wattage: 750,
        efficiency: PSUEfficiency.gold,
        modular: PSUModular.fullModular,
      ),
      PSU(
        productName: 'Corsair RM850x',
        price: 139.99,
        manufacturer: manufacturerList[0],
        wattage: 850,
        efficiency: PSUEfficiency.bronze,
        modular: PSUModular.fullModular,
      ),
    ];
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