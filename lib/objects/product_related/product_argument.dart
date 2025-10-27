import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_series.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_series.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_version.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_efficiency.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/ram_spec.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/psu_related/connector.dart';
import 'package:gizmoglobe_client/objects/product_related/psu_related/psu.dart';
import 'package:gizmoglobe_client/objects/product_related/ram_related/ram.dart';

import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/drive_enums/drive_form_factor.dart';
import '../../enums/product_related/drive_enums/drive_gen.dart';
import '../../enums/product_related/drive_enums/drive_type.dart';
import '../../enums/product_related/drive_enums/interface_type.dart';
import '../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../manufacturer.dart';
import 'cpu_related/cpu.dart';
import 'drive_related/drive.dart';
import 'drive_related/speed.dart';
import 'gpu_related/gpu.dart';
import 'mainboard_related/io_port.dart';
import 'mainboard_related/mainboard.dart';
import 'mainboard_related/pcie_slot.dart';
import 'mainboard_related/storage_slot.dart';

class ProductArgument {
  String? productID;
  String? productName;
  CategoryEnum? category;
  int? price;
  double? discountedPrice;
  double? discount;
  DateTime? release;
  int? sales;
  int? stock;
  Manufacturer? manufacturer;
  ProductStatusEnum? status;
  String? imageUrl;
  String? enDescription;
  String? viDescription;

  // RAM specific properties
  RAMType? type;
  int? bus;
  int? clLatency;
  int? stickCount;
  int? capacity;

  // CPU specific properties
  CPUSeries? cpuSeries;
  Socket? socket;
  int? core;
  int? thread;
  double? baseClock;
  double? turboClock;

  // PSU specific properties
  PSUEfficiency? efficiency;
  PSUModular? modularity;
  List<Connector>? connectors;

  // GPU specific properties
  GPUSeries? gpuSeries;
  GPUVersion? gpuVersion;
  //use RAM capacity
  //use CPU turboClock
  int? tdp;
  List<IOPort>? ioPorts;

  // Mainboard specific properties
  String? chipsetCode;
  //use CPU socket
  MainboardFormFactor? mainboardFormFactor;
  List<PCIeSlot>? pcieSlots;
  StorageSlot? storageSlot;
  //use GPU ioPorts
  //use RAM type
  //use RAM capacity
  //use RAM stickCount

  // Drive specific properties
  DriveGen? gen;
  //use RAM capacity
  InterfaceType? interfaceType;
  int? readMbps;
  int? writeMbps;
  DriveFormFactor? driveFormFactor;
  DriveType? driveType;

  ProductArgument({
    this.productID,
    this.productName,
    this.manufacturer,
    this.category,
    this.discountedPrice,
    this.price,
    this.discount,
    this.release,
    this.sales,
    this.stock,
    this.status,
    this.imageUrl,
    this.enDescription,
    this.viDescription,

    // RAM
    this.type,
    this.bus,
    this.clLatency,
    this.stickCount,
    this.capacity,
    // CPU
    this.cpuSeries,
    this.socket,
    this.core,
    this.thread,
    this.baseClock,
    this.turboClock,
    // PSU
    this.efficiency,
    this.modularity,
    this.connectors,
    // GPU
    this.gpuSeries,
    this.gpuVersion,
    this.tdp,
    this.ioPorts,
    // Mainboard
    this.chipsetCode,
    this.mainboardFormFactor,
    this.pcieSlots,
    this.storageSlot,
    // Drive
    this.gen,
    this.interfaceType,
    this.readMbps,
    this.writeMbps,
    this.driveFormFactor,
    this.driveType,
  });

  bool get isEnEmpty {
    return enDescription == null || enDescription!.isEmpty;
  }

  bool get isViEmpty {
    return viDescription == null || viDescription!.isEmpty;
  }

  ProductArgument copyWith({
        String? productID,
        String? productName,
        Manufacturer? manufacturer,
        CategoryEnum? category,
        int? price,
        double? discount,
        DateTime? release,
        int? sales,
        int? stock,
        ProductStatusEnum? status,
        String? imageUrl,
        String? enDescription,
        String? viDescription,

        // RAM specific properties
        RAMType? type,
        int? bus,
        int? clLatency,
        int? stickCount,
        int? capacity,

        // CPU specific properties
        CPUSeries? cpuSeries,
        Socket? socket,
        int? core,
        int? thread,
        double? baseClock,
        double? turboClock,

        // PSU specific properties
        int? maxWattage,
        PSUEfficiency? efficiency,
        PSUModular? modularity,
        List<Connector>? connectors,

        // GPU specific properties
        GPUSeries? gpuSeries,
        GPUVersion? gpuVersion,
        int? tdp,
        List<IOPort>? ioPorts,

        // Mainboard specific properties
        String? chipsetCode,
        MainboardFormFactor? mainboardFormFactor,
        List<PCIeSlot>? pcieSlots,
        StorageSlot? storageSlot,

        // Drive specific properties
        DriveGen? gen,
        InterfaceType? interfaceType,
        int? readMbps,
        int? writeMbps,
        DriveFormFactor? driveFormFactor,
        DriveType? driveType,
      }) {
    return ProductArgument(
      productID: productID ?? this.productID,
      productName: productName ?? this.productName,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      discountedPrice: price != null && discount != null
          ? price * (1 - discount / 100)
          : this.discountedPrice,
      release: release ?? this.release,
      sales: sales ?? this.sales,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      enDescription: enDescription ?? this.enDescription,
      viDescription: viDescription ?? this.viDescription,
      // RAM
      type: type ?? this.type,
      bus: bus ?? this.bus,
      clLatency: clLatency ?? this.clLatency,
      stickCount: stickCount ?? this.stickCount,
      capacity: capacity ?? this.capacity,
      // CPU
      cpuSeries: cpuSeries ?? this.cpuSeries,
      socket: socket ?? this.socket,
      core: core ?? this.core,
      thread: thread ?? this.thread,
      baseClock: baseClock ?? this.baseClock,
      turboClock: turboClock ?? this.turboClock,
      // PSU
      efficiency: efficiency ?? this.efficiency,
      modularity: modularity ?? this.modularity,
      connectors: connectors ?? this.connectors,
      // GPU
      gpuSeries: gpuSeries ?? this.gpuSeries,
      gpuVersion: gpuVersion ?? this.gpuVersion,
      tdp: tdp ?? this.tdp,
      ioPorts: ioPorts ?? this.ioPorts,
      // Mainboard
      chipsetCode: chipsetCode ?? this.chipsetCode,
      mainboardFormFactor: mainboardFormFactor ?? this.mainboardFormFactor,
      pcieSlots: pcieSlots ?? this.pcieSlots,
      storageSlot: storageSlot ?? this.storageSlot,
      // Drive
      gen: gen ?? this.gen,
      interfaceType: interfaceType ?? this.interfaceType,
      readMbps: readMbps ?? this.readMbps,
      writeMbps: writeMbps ?? this.writeMbps,
      driveFormFactor: driveFormFactor ?? this.driveFormFactor,
      driveType: driveType ?? this.driveType,
    );
  }

  Product buildProduct() {
    switch (category) {
      case CategoryEnum.ram:
        return RAM(
          productName: productName!,
          manufacturer: manufacturer!,
          category: category!,
          price: price!,
          discount: discount!,
          discountedPrice: price! * (1 - discount! / 100),
          release: release!,
          stock: stock!,
          sales: sales!,
          status: status!,
          imageUrl: imageUrl,
          enDescription: enDescription,
          viDescription: viDescription,
          type: type!,
          bus: bus!,
          capacityPerStickGb: capacity!,
          kitStickCount: stickCount!,
          clLatency: clLatency!,
        )..productID = productID;
      case CategoryEnum.cpu:
        return CPU(
          productName: productName!,
          manufacturer: manufacturer!,
          category: category!,
          price: price!,
          discount: discount!,
          discountedPrice: price! * (1 - discount! / 100),
          release: release!,
          stock: stock!,
          sales: sales!,
          status: status!,
          imageUrl: imageUrl,
          enDescription: enDescription,
          viDescription: viDescription,
          core: core!,
          thread: thread!,
          baseClock: baseClock!,
          turboClock: turboClock!,
          series: cpuSeries!,
          socket: socket!,
          tdp: tdp!,
        )..productID = productID;
      case CategoryEnum.psu:
        return PSU(
          productName: productName!,
          manufacturer: manufacturer!,
          category: category!,
          price: price!,
          discount: discount!,
          discountedPrice: price! * (1 - discount! / 100),
          release: release!,
          stock: stock!,
          sales: sales!,
          status: status!,
          imageUrl: imageUrl,
          enDescription: enDescription,
          viDescription: viDescription,
          maxWattage: tdp!,
          efficiency: efficiency!,
          modularity: modularity!,
          connectors: connectors!,
        )..productID = productID;
      case CategoryEnum.gpu:
        return GPU(
          productName: productName!,
          manufacturer: manufacturer!,
          category: category!,
          price: price!,
          discount: discount!,
          discountedPrice: price! * (1 - discount! / 100),
          release: release!,
          stock: stock!,
          sales: sales!,
          status: status!,
          imageUrl: imageUrl,
          enDescription: enDescription,
          viDescription: viDescription,
          series: gpuSeries!,
          version: gpuVersion!,
          memory: capacity!,
          tdp: tdp!,
          ports: ioPorts!,
          boostClock: turboClock!,
        )..productID = productID;
      case CategoryEnum.mainboard:
        return Mainboard(
          productName: productName!,
          manufacturer: manufacturer!,
          category: category!,
          price: price!,
          discount: discount!,
          discountedPrice: price! * (1 - discount! / 100),
          release: release!,
          stock: stock!,
          sales: sales!,
          status: status!,
          imageUrl: imageUrl,
          enDescription: enDescription,
          viDescription: viDescription,
          chipsetCode: chipsetCode!,
          socket: socket!,
          formFactor: mainboardFormFactor!,
          pcieSlots: pcieSlots!,
          storageSlot: storageSlot!,
          ramSpec: RamSpec(type: type!, slots: stickCount!, maxSingleDimmGb: capacity!),
          ioPorts: ioPorts!,
        )..productID = productID;
      case CategoryEnum.drive:
        return Drive(
          productName: productName!,
          manufacturer: manufacturer!,
          category: category!,
          price: price!,
          discount: discount!,
          discountedPrice: price! * (1 - discount! / 100),
          release: release!,
          stock: stock!,
          sales: sales!,
          status: status!,
          imageUrl: imageUrl,
          enDescription: enDescription,
          viDescription: viDescription,
          driveType: driveType!,
          memoryGb: capacity!,
          gen: gen!,
          interfaceType: interfaceType!,
          speed: Speed(
              readMbps: readMbps!,
              writeMbps: writeMbps!
          ),
          formFactor: driveFormFactor!,
        )..productID = productID;
      default:
        throw Exception('Invalid product category');
    }
  }

  static ProductArgument fromProduct(Product product) {
    ProductArgument result = ProductArgument(
      productID: product.productID,
      productName: product.productName,
      manufacturer: product.manufacturer,
      category: product.category,
      price: product.price,
      discount: product.discount,
      discountedPrice: product.discountedPrice,
      release: product.release,
      sales: product.sales,
      stock: product.stock,
      status: product.status,
      imageUrl: product.imageUrl,
      enDescription: product.enDescription,
      viDescription: product.viDescription,
    );
    switch (product.category) {
      case CategoryEnum.ram:
        return result.copyWith(
          bus: (product as RAM).bus,
          type: (product).type,
          clLatency: (product).clLatency,
          stickCount: (product).kitStickCount,
          capacity: (product).capacityPerStickGb,
        );
      case CategoryEnum.cpu:
        return result.copyWith(
          cpuSeries: (product as CPU).series,
          socket: (product).socket,
          core: (product).core,
          thread: (product).thread,
          baseClock: (product).baseClock,
          turboClock: (product).turboClock,
        );
      case CategoryEnum.psu:
        return result.copyWith(
          maxWattage: (product as PSU).maxWattage,
          efficiency: (product).efficiency,
          modularity: (product).modularity,
          connectors: (product).connectors,
        );
      case CategoryEnum.gpu:
        return result.copyWith(
          gpuSeries: (product as GPU).series,
          gpuVersion: (product).version,
          capacity: (product).memory,
          tdp: (product).tdp,
          ioPorts: (product).ports,
          turboClock: (product).boostClock,
        );
      case CategoryEnum.mainboard:
        return result.copyWith(
          chipsetCode: (product as Mainboard).chipsetCode,
          socket: (product).socket,
          mainboardFormFactor: (product).formFactor,
          pcieSlots: (product).pcieSlots,
          storageSlot: (product).storageSlot,
          ioPorts: (product).ioPorts,
          type: (product).ramSpec.type,
          capacity: (product).ramSpec.maxSingleDimmGb,
          stickCount: (product).ramSpec.slots,
        );
      case CategoryEnum.drive:
        return result.copyWith(
          driveType: (product as Drive).driveType,
          capacity: (product).memoryGb,
          gen: (product).gen,
          interfaceType: (product).interfaceType,
          readMbps: (product).speed.readMbps,
          writeMbps: (product).speed.writeMbps,
          driveFormFactor: (product).formFactor,
        );
      default:
        throw Exception('Invalid product category');
    }
  }
}
