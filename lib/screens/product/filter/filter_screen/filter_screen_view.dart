import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_family.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_capacity_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/filter_argument.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import '../../../../enums/product_related/drive_enums/drive_capacity.dart';
import '../../../../enums/product_related/drive_enums/drive_type.dart';
import '../../../../enums/product_related/gpu_enums/gpu_capacity.dart';
import '../../../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../../../enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import '../../../../enums/product_related/mainboard_enums/mainboard_series.dart';
import '../../../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../../../enums/product_related/ram_enums/ram_type.dart';
import '../../../../objects/manufacturer.dart';
import '../manufacturer_filter/manufacturer_filter.dart';
import '../option_filter/option_filter.dart';
import '../range_filter/range_filter.dart';
import 'filter_screen_cubit.dart';
import 'filter_screen_state.dart';

class FilterScreen extends StatefulWidget {
  final FilterArgument arguments;
  final int selectedTabIndex;
  final List<Manufacturer> manufacturerList;

  const FilterScreen({
    super.key,
    required this.arguments,
    required this.selectedTabIndex,
    required this.manufacturerList,
  });

  static newInstance({
    required arguments,
    required selectedTabIndex,
    required manufacturerList,
  }) =>
      BlocProvider(
        create: (context) => FilterScreenCubit()..initialize(
          initialFilterValue: arguments,
          selectedTabIndex: selectedTabIndex,
          manufacturerList: manufacturerList,
        ),
        child: FilterScreen(
          arguments: arguments,
          selectedTabIndex: selectedTabIndex,
          manufacturerList: manufacturerList,
        ),
      );

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  FilterScreenCubit get cubit => context.read<FilterScreenCubit>();

  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  final TextEditingController minCpuCoreController = TextEditingController();
  final TextEditingController maxCpuCoreController = TextEditingController();
  final TextEditingController minCpuThreadController = TextEditingController();
  final TextEditingController maxCpuThreadController = TextEditingController();
  final TextEditingController minCpuClockSpeedController = TextEditingController();
  final TextEditingController maxCpuClockSpeedController = TextEditingController();

  final TextEditingController minPsuWattageController = TextEditingController();
  final TextEditingController maxPsuWattageController = TextEditingController();

  final TextEditingController minGpuClockSpeedController = TextEditingController();
  final TextEditingController maxGpuClockSpeedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    minPriceController.text = widget.arguments.minPrice;
    maxPriceController.text = widget.arguments.maxPrice;
    minCpuClockSpeedController.text = widget.arguments.minCpuClockSpeed;
    maxCpuClockSpeedController.text = widget.arguments.maxCpuClockSpeed;
    minCpuCoreController.text = widget.arguments.minCpuCore;
    maxCpuCoreController.text = widget.arguments.maxCpuCore;
    minCpuThreadController.text = widget.arguments.minCpuThread;
    maxCpuThreadController.text = widget.arguments.maxCpuThread;
    minPsuWattageController.text = widget.arguments.minPsuWattage;
    maxPsuWattageController.text = widget.arguments.maxPsuWattage;
    minGpuClockSpeedController.text = widget.arguments.minGpuClockSpeed;
    maxGpuClockSpeedController.text = widget.arguments.maxGpuClockSpeed;

    cubit.initialize(
      initialFilterValue: widget.arguments,
      selectedTabIndex: widget.selectedTabIndex,
      manufacturerList: widget.manufacturerList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterScreenCubit, FilterScreenState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: const Text('Filter', style: AppTextStyle.biggerText),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(
                      state.filterArgument
                  );
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ManufacturerFilter(
                  selectedManufacturers: state.filterArgument.manufacturerList,
                  onToggleSelection: cubit.toggleManufacturer,
                  manufacturerList: state.manufacturerList,
                ),
                const SizedBox(height: 16.0),
                RangeFilter(
                  name: 'Price',
                  fromController: minPriceController,
                  toController: maxPriceController,
                  onFromValueChanged: (value) {
                    cubit.updateFilterArgument(
                      state.filterArgument.copyWith(minStock: value),
                    );
                  },
                  onToValueChanged: (value) {
                    cubit.updateFilterArgument(
                      state.filterArgument.copyWith(maxStock: value),
                    );
                  },
                  fromValue: state.filterArgument.minPrice,
                  toValue: state.filterArgument.maxPrice,
                ),
                const SizedBox(height: 16.0),
                _buildTabSpecificUI(state, cubit),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSpecificUI(FilterScreenState state, FilterScreenCubit cubit) {
    switch (state.selectedTabIndex) {
      case 0:
        return _buildAllFilterUI(state, cubit);
      case 1:
        return _buildRamFilterUI(state, cubit);
      case 2:
        return _buildCpuFilterUI(state, cubit);
      case 3:
        return _buildPsuFilterUI(state, cubit);
      case 4:
        return _buildGpuFilterUI(state, cubit);
      case 5:
        return _buildDriveFilterUI(state, cubit);
      case 6:
        return _buildMainboardFilterUI(state, cubit);
      default:
        return Container();
    }
  }

  Widget _buildAllFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Category',
          enumValues: CategoryEnum.values,
          selectedValues: List<CategoryEnum>.from(state.filterArgument.categoryList),
          onToggleSelection: (category) {
            final selected = List<CategoryEnum>.from(state.filterArgument.categoryList);

            if (selected.contains(category)) {
              selected.remove(category);
            } else {
              selected.add(category);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(categoryList: selected),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRamFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Bus',
          enumValues: RAMBus.values,
          selectedValues: List<RAMBus>.from(state.filterArgument.ramBusList),
          onToggleSelection: (bus) {
            final selected = List<RAMBus>.from(state.filterArgument.ramBusList);

            if (selected.contains(bus)) {
              selected.remove(bus);
            } else {
              selected.add(bus);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(ramBusList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Capacity',
          enumValues: RAMCapacity.values,
          selectedValues: List<RAMCapacity>.from(state.filterArgument.ramCapacityList),
          onToggleSelection: (capacity) {
            final selected = List<RAMCapacity>.from(state.filterArgument.ramCapacityList);

            if (selected.contains(capacity)) {
              selected.remove(capacity);
            } else {
              selected.add(capacity);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(ramCapacityList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Type',
          enumValues: RAMType.values,
          selectedValues: List<RAMType>.from(state.filterArgument.ramTypeList),
          onToggleSelection: (type) {
            final selected = List<RAMType>.from(state.filterArgument.ramTypeList);

            if (selected.contains(type)) {
              selected.remove(type);
            } else {
              selected.add(type);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(ramTypeList: selected),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCpuFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Family',
          enumValues: CPUFamily.values,
          selectedValues: List<CPUFamily>.from(state.filterArgument.cpuFamilyList),
          onToggleSelection: (family) {
            final selected = List<CPUFamily>.from(state.filterArgument.cpuFamilyList);

            if (selected.contains(family)) {
              selected.remove(family);
            } else {
              selected.add(family);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(cpuFamilyList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        RangeFilter(
          name: 'CPU Core',
          fromController: minCpuCoreController,
          toController: maxCpuCoreController,
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minCpuCore: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxCpuCore: value),
            );
          },
          fromValue: state.filterArgument.minCpuCore,
          toValue: state.filterArgument.maxCpuCore,
        ),
        const SizedBox(height: 16.0),

        RangeFilter(
          name: 'CPU Thread',
          fromController: minCpuThreadController,
          toController: maxCpuThreadController,
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minCpuThread: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxCpuThread: value),
            );
          },
          fromValue: state.filterArgument.minCpuThread,
          toValue: state.filterArgument.maxCpuThread,
        ),
        const SizedBox(height: 16.0),

        RangeFilter(
          name: 'CPU Clock Speed',
          fromController: minCpuClockSpeedController,
          toController: maxCpuClockSpeedController,
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minCpuClockSpeed: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxCpuClockSpeed: value),
            );
          },
          fromValue: state.filterArgument.minCpuClockSpeed,
          toValue: state.filterArgument.maxCpuClockSpeed,
        ),
      ],
    );
  }

  Widget _buildPsuFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Modular',
          enumValues: PSUModular.values,
          selectedValues: List<PSUModular>.from(state.filterArgument.psuModularList),
          onToggleSelection: (modular) {
            final selected = List<PSUModular>.from(state.filterArgument.psuModularList);

            if (selected.contains(modular)) {
              selected.remove(modular);
            } else {
              selected.add(modular);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(psuModularList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Efficiency',
          enumValues: PSUEfficiency.values,
          selectedValues: List<PSUEfficiency>.from(state.filterArgument.psuEfficiencyList),
          onToggleSelection: (efficiency) {
            final selected = List<PSUEfficiency>.from(state.filterArgument.psuEfficiencyList);

            if (selected.contains(efficiency)) {
              selected.remove(efficiency);
            } else {
              selected.add(efficiency);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(psuEfficiencyList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        RangeFilter(
          name: 'PSU Wattage',
          fromController: minPsuWattageController,
          toController: maxPsuWattageController,
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minPsuWattage: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxPsuWattage: value),
            );
          },
          fromValue: state.filterArgument.minPsuWattage,
          toValue: state.filterArgument.maxPsuWattage,
        ),
      ],
    );
  }

  Widget _buildGpuFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Bus',
          enumValues: GPUBus.values,
          selectedValues: List<GPUBus>.from(state.filterArgument.gpuBusList),
          onToggleSelection: (bus) {
            final selected = List<GPUBus>.from(state.filterArgument.gpuBusList);

            if (selected.contains(bus)) {
              selected.remove(bus);
            } else {
              selected.add(bus);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(gpuBusList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Capacity',
          enumValues: GPUCapacity.values,
          selectedValues: List<GPUCapacity>.from(state.filterArgument.gpuCapacityList),
          onToggleSelection: (capacity) {
            final selected = List<GPUCapacity>.from(state.filterArgument.gpuCapacityList);

            if (selected.contains(capacity)) {
              selected.remove(capacity);
            } else {
              selected.add(capacity);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(gpuCapacityList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Series',
          enumValues: GPUSeries.values,
          selectedValues: List<GPUSeries>.from(state.filterArgument.gpuSeriesList),
          onToggleSelection: (series) {
            final selected = List<GPUSeries>.from(state.filterArgument.gpuSeriesList);

            if (selected.contains(series)) {
              selected.remove(series);
            } else {
              selected.add(series);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(gpuSeriesList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        RangeFilter(
          name: 'GPU Clock Speed',
          fromController: minGpuClockSpeedController,
          toController: maxGpuClockSpeedController,
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minGpuClockSpeed: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxGpuClockSpeed: value),
            );
          },
          fromValue: state.filterArgument.minGpuClockSpeed,
          toValue: state.filterArgument.maxGpuClockSpeed,
        ),
      ],
    );
  }

  Widget _buildDriveFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Type',
          enumValues: DriveType.values,
          selectedValues: List<DriveType>.from(state.filterArgument.driveTypeList),
          onToggleSelection: (type) {
            final selected = List<DriveType>.from(state.filterArgument.driveTypeList);

            if (selected.contains(type)) {
              selected.remove(type);
            } else {
              selected.add(type);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(driveTypeList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Capacity',
          enumValues: DriveCapacity.values,
          selectedValues: List<DriveCapacity>.from(state.filterArgument.driveCapacityList),
          onToggleSelection: (capacity) {
            final selected = List<DriveCapacity>.from(state.filterArgument.driveCapacityList);

            if (selected.contains(capacity)) {
              selected.remove(capacity);
            } else {
              selected.add(capacity);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(driveCapacityList: selected),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainboardFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Form Factor',
          enumValues: MainboardFormFactor.values,
          selectedValues: List<MainboardFormFactor>.from(state.filterArgument.mainboardFormFactorList),
          onToggleSelection: (formFactor) {
            final selected = List<MainboardFormFactor>.from(state.filterArgument.mainboardFormFactorList);

            if (selected.contains(formFactor)) {
              selected.remove(formFactor);
            } else {
              selected.add(formFactor);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(mainboardFormFactorList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Series',
          enumValues: MainboardSeries.values,
          selectedValues: List<MainboardSeries>.from(state.filterArgument.mainboardSeriesList),
          onToggleSelection: (series) {
            final selected = List<MainboardSeries>.from(state.filterArgument.mainboardSeriesList);

            if (selected.contains(series)) {
              selected.remove(series);
            } else {
              selected.add(series);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(mainboardSeriesList: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),

        OptionFilter(
          name: 'Compatibility',
          enumValues: MainboardCompatibility.values,
          selectedValues: List<MainboardCompatibility>.from(state.filterArgument.mainboardCompatibilityList),
          onToggleSelection: (compatibility) {
            final selected = List<MainboardCompatibility>.from(state.filterArgument.mainboardCompatibilityList);

            if (selected.contains(compatibility)) {
              selected.remove(compatibility);
            } else {
              selected.add(compatibility);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(mainboardCompatibilityList: selected),
            );
          },
        ),
      ],
    );
  }
}