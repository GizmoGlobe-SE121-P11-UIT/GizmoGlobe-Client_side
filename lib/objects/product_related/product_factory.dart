import 'package:gizmoglobe_client/objects/product_related/drive_related/speed.dart';

import '../../data/database/database.dart';
import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'product.dart';
import 'ram_related/ram.dart';
import 'psu_related/psu.dart';
import 'cpu_related/cpu.dart';
import 'drive_related/drive.dart';
import 'gpu_related/gpu.dart';
import 'mainboard_related/mainboard.dart';

// helpers imports
import '../../objects/manufacturer.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../../enums/product_related/ram_enums/ram_type.dart';
import '../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../enums/product_related/gpu_enums/gpu_version.dart';
import '../../enums/product_related/cpu_enums/cpu_series.dart';
import '../../enums/product_related/cpu_enums/socket.dart';
import '../../enums/product_related/drive_enums/drive_gen.dart';
import '../../enums/product_related/drive_enums/interface_type.dart';
import '../../enums/product_related/drive_enums/drive_form_factor.dart';
import '../../enums/product_related/drive_enums/drive_type.dart';
import '../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../enums/product_related/psu_enums/psu_modular.dart';
import 'mainboard_related/ram_spec.dart';
import 'mainboard_related/pcie_slot.dart';
import 'mainboard_related/storage_slot.dart';
import 'mainboard_related/io_port.dart';
import 'psu_related/connector.dart';

class ProductFactory {
  static Product createProduct(Map<String, dynamic> properties) {
    dynamic getAttr(String path) => getByPath(properties, path);
    CategoryEnum category = CategoryEnumExtension.fromName(properties['category'].toString());

    int price = toInt(properties['sellingPrice']);
    double discount = toDouble(properties['discount']);
    double discountedPrice = price * (1 - discount / 100);

    switch (category) {
      case CategoryEnum.ram:
        return RAM(
          productName: properties['productName']?.toString() ?? '',
          manufacturer: parseManufacturer(properties['manufacturer']),
          category: category,
          price: price,
          discount: discount,
          discountedPrice: discountedPrice,
          release: parseDate(properties['release']),
          stock: toInt(properties['stock']),
          sales: toInt(properties['sales']),
          status: parseStatus(properties['status'], toInt(properties['stock'])),
          imageUrl: properties['imageUrl']?.toString(),
          enDescription: properties['enDescription']?.toString(),
          viDescription: properties['viDescription']?.toString(),

          type: parseRamType(getAttr('attributes.type')),
          bus: toInt(getAttr('attributes.bus')),
          clLatency: toInt(getAttr('attributes.clLatency')),
          kitStickCount: toInt(getAttr('attributes.kitConfiguration.stickCount')),
          capacityPerStickGb: toInt(getAttr('attributes.kitConfiguration.capacityPerStickGb')),
        )..productID = properties['productID']?.toString();
      case CategoryEnum.cpu:
        final attrs = getAttr('attributes') as Map<String, dynamic>? ?? {};
        return CPU(
          productName: properties['productName']?.toString() ?? '',
          manufacturer: parseManufacturer(properties['manufacturer']),
          category: category,
          price: price,
          discount: discount,
          discountedPrice: discountedPrice,
          release: parseDate(properties['release']),
          stock: toInt(properties['stock']),
          sales: toInt(properties['sales']),
          status: parseStatus(properties['status'], toInt(properties['stock'])),
          imageUrl: properties['imageUrl']?.toString(),
          enDescription: properties['enDescription']?.toString(),
          viDescription: properties['viDescription']?.toString(),

          series: parseCPUSeries(attrs['series']),
          socket: parseSocket(attrs['socket']),
          core: toInt(attrs['core']),
          thread: toInt(attrs['thread']),
          baseClock: toDouble(attrs['baseClock']),
          tdp: toInt(attrs['tdp']),
          turboClock: toDouble(attrs['turboClock']),
        )..productID = properties['productID']?.toString();
      case CategoryEnum.psu:
        final attrs = getAttr('attributes') as Map<String, dynamic>? ?? {};
        return PSU(
          productName: properties['productName']?.toString() ?? '',
          manufacturer: parseManufacturer(properties['manufacturer']),
          category: category,
          price: price,
          discount: discount,
          discountedPrice: discountedPrice,
          release: parseDate(properties['release']),

          maxWattage: toInt(attrs['maxWattage']),
          efficiency: parsePSUEfficiency(attrs['efficiency']),
          modularity: parsePSUModular(attrs['modularity'] ?? attrs['modularityity'] ?? attrs['modular']),
          connectors: (attrs['connectors'] is Iterable)
              ? (attrs['connectors'] as Iterable).map((e) => Connector.fromJson(e as Map<String, dynamic>)).toList()
              : <Connector>[],

          stock: toInt(properties['stock']),
          sales: toInt(properties['sales']),
          status: parseStatus(properties['status'], toInt(properties['stock'])),
          imageUrl: properties['imageUrl']?.toString(),
          enDescription: properties['enDescription']?.toString(),
          viDescription: properties['viDescription']?.toString(),
        )..productID = properties['productID']?.toString();
      case CategoryEnum.gpu:
        final attrs = getAttr('attributes') as Map<String, dynamic>? ?? {};
        return GPU(
          productName: properties['productName']?.toString() ?? '',
          manufacturer: parseManufacturer(properties['manufacturer']),
          category: category,
          price: price,
          discount: discount,
          discountedPrice: discountedPrice,
          release: parseDate(properties['release']),

          series: parseGPUSeries(attrs['series']),
          version: parseGPUVersion(attrs['vramVersion'] ?? attrs['vram']),
          memory: toInt(attrs['memory']),
          boostClock: toDouble(attrs['boostClock']),
          tdp: toInt(attrs['tdp']),
          ports: (attrs['ports'] is Iterable)
              ? (attrs['ports'] as Iterable).map((e) => IOPort.fromJson(e as Map<String, dynamic>)).toList()
              : <IOPort>[],

          stock: toInt(properties['stock']),
          sales: toInt(properties['sales']),
          status: parseStatus(properties['status'], toInt(properties['stock'])),
          imageUrl: properties['imageUrl']?.toString(),
          enDescription: properties['enDescription']?.toString(),
          viDescription: properties['viDescription']?.toString(),
        )..productID = properties['productID']?.toString();
      case CategoryEnum.mainboard:
        final attrs = getAttr('attributes') as Map<String, dynamic>? ?? {};
        return Mainboard(
          productName: properties['productName']?.toString() ?? '',
          manufacturer: parseManufacturer(properties['manufacturer']),
          category: category,
          price: price,
          discount: discount,
          discountedPrice: discountedPrice,
          release: parseDate(properties['release']),

          chipsetCode: attrs['chipsetCode']?.toString() ?? '',
          socket: parseSocket(attrs['socket']),
          formFactor: (attrs['formFactor'] != null)
              ? MainboardFormFactorExtension.fromName(attrs['formFactor'].toString())
              : MainboardFormFactor.atx,
          ramSpec: (attrs['ramSpec'] is Map<String, dynamic>)
              ? RamSpec.fromJson(attrs['ramSpec'] as Map<String, dynamic>)
              : RamSpec(type: RAMType.unknown, slots: 0, maxSingleDimmGb: 0),
          pcieSlots: (attrs['pcieSlots'] is Iterable)
              ? (attrs['pcieSlots'] as Iterable).map((e) => PCIeSlot.fromJson(e as Map<String, dynamic>)).toList()
              : <PCIeSlot>[],
          storageSlot: (attrs['storageSlots'] is Map<String, dynamic>)
              ? StorageSlot.fromJson(attrs['storageSlots'] as Map<String, dynamic>)
              : StorageSlot(m2Slots: 0, sataPorts: 0),
          ioPorts: (attrs['ioPorts'] is Iterable)
              ? (attrs['ioPorts'] as Iterable).map((e) => IOPort.fromJson(e as Map<String, dynamic>)).toList()
              : <IOPort>[],

          stock: toInt(properties['stock']),
          sales: toInt(properties['sales']),
          status: parseStatus(properties['status'], toInt(properties['stock'])),
          imageUrl: properties['imageUrl']?.toString(),
          enDescription: properties['enDescription']?.toString(),
          viDescription: properties['viDescription']?.toString(),
        )..productID = properties['productID']?.toString();
      case CategoryEnum.drive:
        final attrs = getAttr('attributes') as Map<String, dynamic>? ?? {};
        final speed = attrs['speed'] as Map<String, dynamic>? ?? {};
        return Drive(
          productName: properties['productName']?.toString() ?? '',
          manufacturer: parseManufacturer(properties['manufacturer']),
          category: category,
          price: price,
          discount: discount,
          discountedPrice: discountedPrice,
          release: parseDate(properties['release']),

          gen: DriveGen.fromJson(toInt(attrs['gen'])),
          memoryGb: toInt(attrs['memoryGb']),
          interfaceType: parseInterfaceType(attrs['interfaceType']),
          speed: Speed.fromJson(attrs['speed'] is Map<String, dynamic> ? speed : {}),
          formFactor: DriveFormFactorExtension.fromName(attrs['formFactor']),
          driveType: parseDriveType(attrs['driveType']),

          sales: toInt(properties['sales']),
          stock: toInt(properties['stock']),
          status: parseStatus(properties['status'], toInt(properties['stock'])),
          imageUrl: properties['imageUrl']?.toString(),
          enDescription: properties['enDescription']?.toString(),
          viDescription: properties['viDescription']?.toString(),
        )..productID = properties['productID']?.toString();
      default:
        throw Exception('Invalid product category');
    }
  }

}

dynamic getByPath(Map<String, dynamic> map, String path) {
  dynamic cur = map;
  for (final seg in path.split('.')) {
    if (cur is Map<String, dynamic> && cur.containsKey(seg)) {
      cur = cur[seg];
    } else {
      return null;
    }
  }
  return cur;
}

Manufacturer parseManufacturer(String? v) {
  if (v == null) return Manufacturer.nullManufacturer;

  return Database().manufacturerList.firstWhere(
        (m) => m.manufacturerID == v.toString(),
    orElse: () => Manufacturer.nullManufacturer
  );
}

double toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return (v).toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime parseDate(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  // assume epoch seconds if numeric
  if (v is num) return DateTime.fromMillisecondsSinceEpoch((v).toInt() * 1000);
  final parsed = int.tryParse(v.toString());
  if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
  return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

ProductStatusEnum parseStatus(dynamic v, int stock) {
  if (v == null) return ProductStatusEnum.unknown;
  ProductStatusEnum status = ProductStatusEnumExtension.fromName(v.toString());

  if (status == ProductStatusEnum.active && stock <= 0) {
    return ProductStatusEnum.outOfStock;
  }
  return status;
}

RAMType parseRamType(dynamic v) {
  if (v == null) return RAMType.unknown;
  return RAMTypeExtension.fromName(v.toString());
}

GPUSeries parseGPUSeries(dynamic v) {
  if (v == null) return GPUSeries.unknown;
  return GPUSeriesExtension.fromName(v.toString());
}

GPUVersion parseGPUVersion(dynamic v) {
  if (v == null) return GPUVersion.unknown;
  return GPUVersionExtension.fromName(v.toString());
}

CPUSeries parseCPUSeries(dynamic v) {
  if (v == null) return CPUSeries.unknown;
  return CPUSeriesExtension.fromName(v.toString());
}

Socket parseSocket(dynamic v) {
  if (v == null) return Socket.unknown;
  return SocketExtension.fromName(v.toString());
}

InterfaceType parseInterfaceType(dynamic v) {
  if (v == null) return InterfaceType.unknown;
  return InterfaceTypeExtension.fromName(v.toString());
}

PSUEfficiency parsePSUEfficiency(dynamic v) {
  if (v == null) return PSUEfficiency.unknown;
  return PSUEfficiencyExtension.fromName(v.toString());
}

PSUModular parsePSUModular(dynamic v) {
  if (v == null) return PSUModular.unknown;
  return PSUModularExtension.fromName(v.toString());
}

DriveType parseDriveType(dynamic v) {
  if (v == null) return DriveType.unknown;
  return DriveTypeExtension.fromName(v.toString());
}