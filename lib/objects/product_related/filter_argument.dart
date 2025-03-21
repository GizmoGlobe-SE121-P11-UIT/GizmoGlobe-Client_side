import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_efficiency.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_capacity_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import '../../../enums/product_related/cpu_enums/cpu_family.dart';
import '../../../enums/product_related/drive_enums/drive_capacity.dart';
import '../../../enums/product_related/drive_enums/drive_type.dart';
import '../../../enums/product_related/gpu_enums/gpu_capacity.dart';
import '../../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_series.dart';
import '../../data/database/database.dart';

class FilterArgument {
  final List<Manufacturer> manufacturerList;
  final String minPrice;
  final String maxPrice;

  final List<CategoryEnum> categoryList;

  final List<RAMBus> ramBusList;
  final List<RAMCapacity> ramCapacityList;
  final List<RAMType> ramTypeList;

  final List<CPUFamily> cpuFamilyList;
  final String minCpuCore;
  final String maxCpuCore;
  final String minCpuThread;
  final String maxCpuThread;
  final String minCpuClockSpeed;
  final String maxCpuClockSpeed;

  final List<PSUModular> psuModularList;
  final List<PSUEfficiency> psuEfficiencyList;
  final String minPsuWattage;
  final String maxPsuWattage;

  final List<GPUBus> gpuBusList;
  final List<GPUCapacity> gpuCapacityList;
  final List<GPUSeries> gpuSeriesList;
  final String minGpuClockSpeed;
  final String maxGpuClockSpeed;

  final List<DriveType> driveTypeList;
  final List<DriveCapacity> driveCapacityList;

  final List<MainboardFormFactor> mainboardFormFactorList;
  final List<MainboardSeries> mainboardSeriesList;
  final List<MainboardCompatibility> mainboardCompatibilityList;

  const FilterArgument({
    this.manufacturerList = const [],
    this.minPrice = '',
    this.maxPrice = '',
    this.categoryList = CategoryEnum.values,
    this.ramBusList = RAMBus.values,
    this.ramCapacityList = RAMCapacity.values,
    this.ramTypeList = RAMType.values,
    this.cpuFamilyList = CPUFamily.values,
    this.minCpuCore = '',
    this.maxCpuCore = '',
    this.minCpuThread = '',
    this.maxCpuThread = '',
    this.minCpuClockSpeed = '',
    this.maxCpuClockSpeed = '',
    this.psuModularList = PSUModular.values,
    this.psuEfficiencyList = PSUEfficiency.values,
    this.minPsuWattage = '',
    this.maxPsuWattage = '',
    this.gpuBusList = GPUBus.values,
    this.gpuCapacityList = GPUCapacity.values,
    this.gpuSeriesList = GPUSeries.values,
    this.minGpuClockSpeed = '',
    this.maxGpuClockSpeed = '',
    this.driveTypeList = DriveType.values,
    this.driveCapacityList = DriveCapacity.values,
    this.mainboardFormFactorList = MainboardFormFactor.values,
    this.mainboardSeriesList = MainboardSeries.values,
    this.mainboardCompatibilityList = MainboardCompatibility.values,
  });

  FilterArgument copyWith({
    List<Manufacturer>? manufacturerList,
    String? minStock,
    String? maxStock,
    List<CategoryEnum>? categoryList,
    List<RAMBus>? ramBusList,
    List<RAMCapacity>? ramCapacityList,
    List<RAMType>? ramTypeList,
    List<CPUFamily>? cpuFamilyList,
    String? minCpuCore,
    String? maxCpuCore,
    String? minCpuThread,
    String? maxCpuThread,
    String? minCpuClockSpeed,
    String? maxCpuClockSpeed,
    List<PSUModular>? psuModularList,
    List<PSUEfficiency>? psuEfficiencyList,
    String? minPsuWattage,
    String? maxPsuWattage,
    List<GPUBus>? gpuBusList,
    List<GPUCapacity>? gpuCapacityList,
    List<GPUSeries>? gpuSeriesList,
    String? minGpuClockSpeed,
    String? maxGpuClockSpeed,
    List<DriveType>? driveTypeList,
    List<DriveCapacity>? driveCapacityList,
    List<MainboardFormFactor>? mainboardFormFactorList,
    List<MainboardSeries>? mainboardSeriesList,
    List<MainboardCompatibility>? mainboardCompatibilityList,
  }) {
    return FilterArgument(
      manufacturerList: manufacturerList ?? this.manufacturerList,
      minPrice: minStock ?? minPrice,
      maxPrice: maxStock ?? maxPrice,
      categoryList: categoryList ?? this.categoryList,
      ramBusList: ramBusList ?? this.ramBusList,
      ramCapacityList: ramCapacityList ?? this.ramCapacityList,
      ramTypeList: ramTypeList ?? this.ramTypeList,
      cpuFamilyList: cpuFamilyList ?? this.cpuFamilyList,
      minCpuCore: minCpuCore ?? this.minCpuCore,
      maxCpuCore: maxCpuCore ?? this.maxCpuCore,
      minCpuThread: minCpuThread ?? this.minCpuThread,
      maxCpuThread: maxCpuThread ?? this.maxCpuThread,
      minCpuClockSpeed: minCpuClockSpeed ?? this.minCpuClockSpeed,
      maxCpuClockSpeed: maxCpuClockSpeed ?? this.maxCpuClockSpeed,
      psuModularList: psuModularList ?? this.psuModularList,
      psuEfficiencyList: psuEfficiencyList ?? this.psuEfficiencyList,
      minPsuWattage: minPsuWattage ?? this.minPsuWattage,
      maxPsuWattage: maxPsuWattage ?? this.maxPsuWattage,
      gpuBusList: gpuBusList ?? this.gpuBusList,
      gpuCapacityList: gpuCapacityList ?? this.gpuCapacityList,
      gpuSeriesList: gpuSeriesList ?? this.gpuSeriesList,
      minGpuClockSpeed: minGpuClockSpeed ?? this.minGpuClockSpeed,
      maxGpuClockSpeed: maxGpuClockSpeed ?? this.maxGpuClockSpeed,
      driveTypeList: driveTypeList ?? this.driveTypeList,
      driveCapacityList: driveCapacityList ?? this.driveCapacityList,
      mainboardFormFactorList: mainboardFormFactorList ?? this.mainboardFormFactorList,
      mainboardSeriesList: mainboardSeriesList ?? this.mainboardSeriesList,
      mainboardCompatibilityList: mainboardCompatibilityList ?? this.mainboardCompatibilityList,
    );
  }

  FilterArgument copy({FilterArgument? filter}) {
    return FilterArgument(
      manufacturerList: filter?.manufacturerList ?? Database().manufacturerList,
      minPrice: filter?.minPrice ?? minPrice,
      maxPrice: filter?.maxPrice ?? maxPrice,
      categoryList: filter?.categoryList ?? categoryList,
      ramBusList: filter?.ramBusList ?? ramBusList,
      ramCapacityList: filter?.ramCapacityList ?? ramCapacityList,
      ramTypeList: filter?.ramTypeList ?? ramTypeList,
      cpuFamilyList: filter?.cpuFamilyList ?? cpuFamilyList,
      minCpuCore: filter?.minCpuCore ?? minCpuCore,
      maxCpuCore: filter?.maxCpuCore ?? maxCpuCore,
      minCpuThread: filter?.minCpuThread ?? minCpuThread,
      maxCpuThread: filter?.maxCpuThread ?? maxCpuThread,
      minCpuClockSpeed: filter?.minCpuClockSpeed ?? minCpuClockSpeed,
      maxCpuClockSpeed: filter?.maxCpuClockSpeed ?? maxCpuClockSpeed,
      psuModularList: filter?.psuModularList ?? psuModularList,
      psuEfficiencyList: filter?.psuEfficiencyList ?? psuEfficiencyList,
      minPsuWattage: filter?.minPsuWattage ?? minPsuWattage,
      maxPsuWattage: filter?.maxPsuWattage ?? maxPsuWattage,
      gpuBusList: filter?.gpuBusList ?? gpuBusList,
      gpuCapacityList: filter?.gpuCapacityList ?? gpuCapacityList,
      gpuSeriesList: filter?.gpuSeriesList ?? gpuSeriesList,
      minGpuClockSpeed: filter?.minGpuClockSpeed ?? minGpuClockSpeed,
      maxGpuClockSpeed: filter?.maxGpuClockSpeed ?? maxGpuClockSpeed,
      driveTypeList: filter?.driveTypeList ?? driveTypeList,
      driveCapacityList: filter?.driveCapacityList ?? driveCapacityList,
      mainboardFormFactorList: filter?.mainboardFormFactorList ??
          mainboardFormFactorList,
      mainboardSeriesList: filter?.mainboardSeriesList ??
          mainboardSeriesList,
      mainboardCompatibilityList: filter?.mainboardCompatibilityList ??
          mainboardCompatibilityList,
    );
  }
}