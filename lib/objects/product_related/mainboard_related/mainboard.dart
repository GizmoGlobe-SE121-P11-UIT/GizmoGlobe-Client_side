import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/ram_spec.dart';

import '../../../enums/product_related/category_enum.dart';
import 'io_port.dart';
import 'pcie_slot.dart';
import 'storage_slot.dart';
import '../../manufacturer.dart';
import '../product.dart';

class Mainboard extends Product {
  String chipsetCode;
  Socket socket;
  MainboardFormFactor formFactor;
  RamSpec ramSpec;
  List<PCIeSlot> pcieSlots;
  StorageSlot storageSlot;
  List<IOPort> ioPorts;

  Mainboard({
    required super.productName,
    required super.price,
    required super.discount,
    required super.release,
    required super.manufacturer,

    super.imageUrl,
    super.enDescription,
    super.viDescription,
    super.category = CategoryEnum.mainboard,

    required this.chipsetCode,
    required this.socket,
    required this.formFactor,
    required this.ramSpec,
    required this.pcieSlots,
    required this.storageSlot,
    required this.ioPorts,
    required super.sales,
    required super.stock,
    required super.status, required super.discountedPrice,
  });
}