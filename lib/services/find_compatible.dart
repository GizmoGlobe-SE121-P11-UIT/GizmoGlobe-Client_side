import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';

import '../enums/product_related/drive_enums/drive_type.dart';
import '../enums/product_related/drive_enums/interface_type.dart';
import '../enums/product_related/ram_enums/ram_type.dart';
import '../objects/product_related/cpu_related/cpu.dart';
import '../objects/product_related/drive_related/drive.dart';
import '../objects/product_related/gpu_related/gpu.dart';
import '../objects/product_related/mainboard_related/mainboard.dart';
import '../objects/product_related/product.dart';
import '../objects/product_related/ram_related/ram.dart';

bool areProductsCompatible(Product productA, Product productB) {
  // Ensure we don't check a product against itself
  if (productA.productID == productB.productID) return false;

  //
  // --- Rule 1: CPU <-> Mainboard ---
  //
  if (productA is CPU && productB is Mainboard) {
    return _isCpuMainboardCompatible(productA, productB);
  }
  if (productA is Mainboard && productB is CPU) {
    return _isCpuMainboardCompatible(productB, productA); // Swapped
  }

  //
  // --- Rule 2: Mainboard <-> RAM ---
  //
  if (productA is Mainboard && productB is RAM) {
    return _isRamMainboardCompatible(productA, productB);
  }
  if (productA is RAM && productB is Mainboard) {
    return _isRamMainboardCompatible(productB, productA); // Swapped
  }

  //
  // --- Rule 3: Drive <-> Mainboard ---
  //
  if (productA is Drive && productB is Mainboard) {
    return _isDriveMainboardCompatible(productA, productB);
  }
  if (productA is Mainboard && productB is Drive) {
    return _isDriveMainboardCompatible(productB, productA); // Swapped
  }

  //
  // --- Rule 4: GPU <-> Mainboard ---
  //
  if (productA is GPU && productB is Mainboard) {
    // Modern GPUs and Mainboards (PCIe) are almost universally compatible.
    // We can add form factor checks later if a CaseProduct is added.
    return true;
  }
  if (productA is Mainboard && productB is GPU) {
    return true; // Swapped
  }

  // --- Other combinations ---
  // (e.g., CPU vs. RAM) are not directly compatible
  // and are handled via the mainboard.

  // (Note: PSU wattage checks are removed from this function.
  // A PSU's compatibility depends on the *entire build's*
  // wattage, not just one other part. This logic belongs in your
  // recommendation/build-validation service.)

  return false;
}

/// --- PRIVATE HELPER FUNCTIONS ---

/// Checks: CPU Socket vs Mainboard Socket
bool _isCpuMainboardCompatible(CPU cpu, Mainboard mainboard) {
  // Don't allow "unknown" sockets to be compatible
  if (cpu.socket == Socket.unknown || mainboard.socket == Socket.unknown) {
    return false;
  }

  // Type-safe enum comparison
  return cpu.socket == mainboard.socket;
}

/// Checks: Mainboard RAM Type vs RAM Type
bool _isRamMainboardCompatible(Mainboard mainboard, RAM ram) {
  // Don't allow "unknown" RAM types to be compatible
  if (mainboard.ramSpec.type == RAMType.unknown || ram.type == RAMType.unknown) {
    return false;
  }

  // Type-safe enum comparison
  // The product models already handled the "DDR5" vs "ddr5" parsing logic
  return mainboard.ramSpec.type == ram.type;
}

/// Checks: Drive (M.2/SATA) vs Mainboard (M.2/SATA slots)
bool _isDriveMainboardCompatible(Drive drive, Mainboard mainboard) {

  // Check for M.2 NVMe drives
  if (drive.driveType == DriveType.m2NVME) {
    // Is it an M.2 drive AND does the mainboard have M.2 slots?
    return mainboard.storageSlot.m2Slots > 0;
  }

  // Check for SATA drives (covers 'sataSSD' and 'hdd')
  if (drive.interfaceType == InterfaceType.sata) {
    // Is it a SATA drive AND does the mainboard have SATA ports?
    return mainboard.storageSlot.sataPorts > 0;
  }

  // Not a drive type we can check
  return false;
}

