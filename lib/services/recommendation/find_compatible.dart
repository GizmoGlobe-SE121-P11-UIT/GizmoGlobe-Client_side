import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_type.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/interface_type.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/ram_related/ram.dart';
import 'package:gizmoglobe_client/objects/product_related/psu_related/psu.dart';

bool areProductsCompatible(Product productA, Product productB) {
  if (productA.productID == productB.productID) return false;

  if (productA is CPU && productB is Mainboard) {
    return _isCpuMainboardCompatible(productA, productB);
  }
  if (productA is Mainboard && productB is CPU) {
    return _isCpuMainboardCompatible(productB, productA);
  }

  if (productA is Mainboard && productB is RAM) {
    return _isRamMainboardCompatible(productA, productB);
  }
  if (productA is RAM && productB is Mainboard) {
    return _isRamMainboardCompatible(productB, productA);
  }

  if (productA is Drive && productB is Mainboard) {
    return _isDriveMainboardCompatible(productA, productB);
  }
  if (productA is Mainboard && productB is Drive) {
    return _isDriveMainboardCompatible(productB, productA);
  }

  if (productA is GPU && productB is Mainboard) {
    return true;
  }
  if (productA is Mainboard && productB is GPU) {
    return true;
  }

  if (productA is PSU && productB is CPU) {
    return _isPsuCpuCompatible(productA, productB);
  }
  if (productA is CPU && productB is PSU) {
    return _isPsuCpuCompatible(productB, productA);
  }

  if (productA is PSU && productB is GPU) {
    return _isPsuGpuCompatible(productA, productB);
  }
  if (productA is GPU && productB is PSU) {
    return _isPsuGpuCompatible(productB, productA);
  }

  return false;
}

bool _isCpuMainboardCompatible(CPU cpu, Mainboard mainboard) {
  if (cpu.socket == Socket.unknown || mainboard.socket == Socket.unknown) {
    return false;
  }

  return cpu.socket == mainboard.socket;
}

bool _isRamMainboardCompatible(Mainboard mainboard, RAM ram) {
  if (mainboard.ramSpec.type == RAMType.unknown || ram.type == RAMType.unknown) {
    return false;
  }

  return mainboard.ramSpec.type == ram.type;
}

bool _isDriveMainboardCompatible(Drive drive, Mainboard mainboard) {

  if (drive.driveType == DriveType.m2NVME) {
    return mainboard.storageSlot.m2Slots > 0;
  }

  if (drive.interfaceType == InterfaceType.sata) {
    return mainboard.storageSlot.sataPorts > 0;
  }

  return false;
}

bool _isPsuCpuCompatible(PSU psu, CPU cpu) {
  return psu.maxWattage >= (cpu.tdp * 2) + 100;
}

bool _isPsuGpuCompatible(PSU psu, GPU gpu) {
  return psu.maxWattage >= (gpu.tdp * 1.5) + 200;
}
