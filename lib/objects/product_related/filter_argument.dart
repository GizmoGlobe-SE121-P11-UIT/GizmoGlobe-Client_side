import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_efficiency.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import '../../../enums/product_related/drive_enums/drive_type.dart';
import '../../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../enums/product_related/cpu_enums/cpu_series.dart';
import '../../enums/product_related/cpu_enums/socket.dart';
import '../../enums/product_related/drive_enums/drive_form_factor.dart';
import '../../enums/product_related/drive_enums/drive_gen.dart';
import '../../enums/product_related/drive_enums/interface_type.dart';
import '../../enums/product_related/gpu_enums/gpu_version.dart';

class FilterArgument {
  final List<Manufacturer> manufacturerList;
  final String minPrice;
  final String maxPrice;

  final List<CPUSeries> cpuSeries;
  final List<Socket> sockets;

  final List<MainboardFormFactor> mainboardFormFactor;
  final String minM2Slots;
  final String maxM2Slots;
  final String minSataPorts;
  final String maxSataPorts;

  final List<RAMType> ramType;

  final List<GPUSeries> gpuSeries;
  final List<GPUVersion> gpuVersion;

  final String minMemoryGb;
  final String maxMemoryGb;

  final String minClockSpeed;
  final String maxClockSpeed;
  final String minTdp;
  final String maxTdp;

  final List<DriveFormFactor> driveFormFactor;
  final List<DriveType> driveType;
  final List<InterfaceType> interfaceType;
  final List<DriveGen> gen;

  final List<PSUEfficiency> psuEfficiency;
  final List<PSUModular> psuModularity;

  const FilterArgument({
    this.manufacturerList = const [],
    this.minPrice = '',
    this.maxPrice = '',
    this.cpuSeries = const [],
    this.sockets = const [],
    this.mainboardFormFactor = const [],
    this.minM2Slots = '',
    this.maxM2Slots = '',
    this.minSataPorts = '',
    this.maxSataPorts = '',
    this.ramType = const [],
    this.gpuSeries = const [],
    this.gpuVersion = const [],
    this.minMemoryGb = '',
    this.maxMemoryGb = '',
    this.minClockSpeed = '',
    this.maxClockSpeed = '',
    this.minTdp = '',
    this.maxTdp = '',
    this.driveFormFactor = const [],
    this.driveType = const [],
    this.interfaceType = const [],
    this.gen = const [],
    this.psuEfficiency = const [],
    this.psuModularity = const [],
  });

  FilterArgument copyWith({
    List<Manufacturer>? manufacturerList,
    String? minPrice,
    String? maxPrice,
    List<CPUSeries>? cpuSeries,
    List<Socket>? sockets,
    List<MainboardFormFactor>? mainboardFormFactor,
    String? minM2Slots,
    String? maxM2Slots,
    String? minSataPorts,
    String? maxSataPorts,
    List<RAMType>? ramType,
    List<GPUSeries>? gpuSeries,
    List<GPUVersion>? gpuVersion,
    String? minMemoryGb,
    String? maxMemoryGb,
    String? minClockSpeed,
    String? maxClockSpeed,
    String? minTdp,
    String? maxTdp,
    List<DriveFormFactor>? driveFormFactor,
    List<DriveType>? driveType,
    List<InterfaceType>? interfaceType,
    List<DriveGen>? gen,
    List<PSUEfficiency>? psuEfficiency,
    List<PSUModular>? psuModularity,
  }) {
    return FilterArgument(
      manufacturerList: manufacturerList ?? this.manufacturerList,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      cpuSeries: cpuSeries ?? this.cpuSeries,
      sockets: sockets ?? this.sockets,
      mainboardFormFactor: mainboardFormFactor ?? this.mainboardFormFactor,
      minM2Slots: minM2Slots ?? this.minM2Slots,
      maxM2Slots: maxM2Slots ?? this.maxM2Slots,
      minSataPorts: minSataPorts ?? this.minSataPorts,
      maxSataPorts: maxSataPorts ?? this.maxSataPorts,
      ramType: ramType ?? this.ramType,
      gpuSeries: gpuSeries ?? this.gpuSeries,
      gpuVersion: gpuVersion ?? this.gpuVersion,
      minMemoryGb: minMemoryGb ?? this.minMemoryGb,
      maxMemoryGb: maxMemoryGb ?? this.maxMemoryGb,
      minClockSpeed: minClockSpeed ?? this.minClockSpeed,
      maxClockSpeed: maxClockSpeed ?? this.maxClockSpeed,
      minTdp: minTdp ?? this.minTdp,
      maxTdp: maxTdp ?? this.maxTdp,
      driveFormFactor: driveFormFactor ?? this.driveFormFactor,
      driveType: driveType ?? this.driveType,
      interfaceType: interfaceType ?? this.interfaceType,
      gen: gen ?? this.gen,
      psuEfficiency: psuEfficiency ?? this.psuEfficiency,
      psuModularity: psuModularity ?? this.psuModularity,
    );
  }

  FilterArgument copy({required FilterArgument filter}) {
    return FilterArgument(
      manufacturerList: filter.manufacturerList,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      cpuSeries: filter.cpuSeries,
      sockets: filter.sockets,
      mainboardFormFactor: filter.mainboardFormFactor,
      minM2Slots: filter.minM2Slots,
      maxM2Slots: filter.maxM2Slots,
      minSataPorts: filter.minSataPorts,
      maxSataPorts: filter.maxSataPorts,
      ramType: filter.ramType,
      gpuSeries: filter.gpuSeries,
      gpuVersion: filter.gpuVersion,
      minMemoryGb: filter.minMemoryGb,
      maxMemoryGb: filter.maxMemoryGb,
      minClockSpeed: filter.minClockSpeed,
      maxClockSpeed: filter.maxClockSpeed,
      minTdp: filter.minTdp,
      maxTdp: filter.maxTdp,
      driveFormFactor: filter.driveFormFactor,
      driveType: filter.driveType,
      interfaceType: filter.interfaceType,
      gen: filter.gen,
      psuEfficiency: filter.psuEfficiency,
      psuModularity: filter.psuModularity,
    );
  }
}
