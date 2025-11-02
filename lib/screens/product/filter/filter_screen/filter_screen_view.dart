import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/objects/product_related/filter_argument.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../../enums/product_related/cpu_enums/cpu_series.dart';
import '../../../../enums/product_related/drive_enums/drive_form_factor.dart';
import '../../../../enums/product_related/drive_enums/drive_gen.dart';
import '../../../../enums/product_related/drive_enums/drive_type.dart';
import '../../../../enums/product_related/drive_enums/interface_type.dart';
import '../../../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../../../enums/product_related/gpu_enums/gpu_version.dart';
import '../../../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../../../enums/product_related/ram_enums/ram_type.dart';
import '../../../../objects/manufacturer.dart';
import '../manufacturer_filter/manufacturer_filter.dart';
import '../option_filter/option_filter.dart';
import '../range_filter/range_filter.dart';
import 'filter_screen_cubit.dart';
import 'filter_screen_state.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

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
        create: (context) => FilterScreenCubit()
          ..initialize(
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

  @override
  void initState() {
    super.initState();
    minPriceController.text = widget.arguments.minPrice;
    maxPriceController.text = widget.arguments.maxPrice;

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
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: GradientIconButton(
              icon: Icons.chevron_left,
              onPressed: () => Navigator.pop(context),
              fillColor: Colors.transparent,
            ),
            title: GradientText(text: S.of(context).filter),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GradientIconButton(
                  icon: Icons.check,
                  onPressed: () => Navigator.pop(context, state.filterArgument),
                  fillColor: Colors.transparent,
                ),
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
                  name: S.of(context).price,
                  fromController: minPriceController,
                  toController: maxPriceController,
                  onFromValueChanged: (value) {
                    cubit.updateFilterArgument(
                      state.filterArgument.copyWith(minPrice: value),
                    );
                  },
                  onToValueChanged: (value) {
                    cubit.updateFilterArgument(
                      state.filterArgument.copyWith(maxPrice: value),
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

  Widget _buildRamFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Type',
          enumValues: RAMType.values,
          selectedValues: List<RAMType>.from(state.filterArgument.ramType),
          onToggleSelection: (type) {
            final selected =
            List<RAMType>.from(state.filterArgument.ramType);

            if (selected.contains(type)) {
              selected.remove(type);
            } else {
              selected.add(type);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(ramType: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'Total RAM (GB)',
          fromController: TextEditingController(text: state.filterArgument.minMemoryGb),
          toController: TextEditingController(text: state.filterArgument.maxMemoryGb),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minMemoryGb: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxMemoryGb: value),
            );
          },
          fromValue: state.filterArgument.minMemoryGb,
          toValue: state.filterArgument.maxMemoryGb,
        ),
      ],
    );
  }

  Widget _buildCpuFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Series',
          enumValues: CPUSeries.getValues(),
          selectedValues:
              List<CPUSeries>.from(state.filterArgument.cpuSeries),
          onToggleSelection: (family) {
            final selected =
                List<CPUSeries>.from(state.filterArgument.cpuSeries);

            if (selected.contains(family)) {
              selected.remove(family);
            } else {
              selected.add(family);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(cpuSeries: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'CPU clock speed (GHz)',
          fromController: TextEditingController(text: state.filterArgument.minClockSpeed),
          toController: TextEditingController(text: state.filterArgument.maxClockSpeed),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minClockSpeed: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minClockSpeed: value),
            );
          },
          fromValue: state.filterArgument.minClockSpeed,
          toValue: state.filterArgument.minClockSpeed,
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'TDP',
          fromController: TextEditingController(text: state.filterArgument.minTdp),
          toController: TextEditingController(text: state.filterArgument.maxTdp),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minTdp: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxTdp: value),
            );
          },
          fromValue: state.filterArgument.minTdp,
          toValue: state.filterArgument.maxTdp,
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: 'CPU socket',
          enumValues: Socket.getValues(),
          selectedValues: List<Socket>.from(state.filterArgument.sockets),
          onToggleSelection: (socket) {
            final selected = List<Socket>.from(state.filterArgument.sockets);
            if (selected.contains(socket)) {
              selected.remove(socket);
            } else {
              selected.add(socket);
            }
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(sockets: selected),
            );
          },
        )
      ],
    );
  }

  Widget _buildPsuFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Modular',
          enumValues: PSUModular.getValues(),
          selectedValues:
              List<PSUModular>.from(state.filterArgument.psuModularity),
          onToggleSelection: (modular) {
            final selected =
                List<PSUModular>.from(state.filterArgument.psuModularity);

            if (selected.contains(modular)) {
              selected.remove(modular);
            } else {
              selected.add(modular);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(psuModularity: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),
        OptionFilter(
          name: 'Efficiency',
          enumValues: PSUEfficiency.getValues(),
          selectedValues:
              List<PSUEfficiency>.from(state.filterArgument.psuEfficiency),
          onToggleSelection: (efficiency) {
            final selected = List<PSUEfficiency>.from(
                state.filterArgument.psuEfficiency);

            if (selected.contains(efficiency)) {
              selected.remove(efficiency);
            } else {
              selected.add(efficiency);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(psuEfficiency: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),
        RangeFilter(
          name: 'PSU wattage',
          fromController: TextEditingController(text: state.filterArgument.minTdp),
          toController: TextEditingController(text: state.filterArgument.maxTdp),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minTdp: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxTdp: value),
            );
          },
          fromValue: state.filterArgument.minTdp,
          toValue: state.filterArgument.maxTdp,
        ),
      ],
    );
  }

  Widget _buildGpuFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'GPU series',
          enumValues: GPUSeries.getValues(),
          selectedValues:
              List<GPUSeries>.from(state.filterArgument.gpuSeries),
          onToggleSelection: (series) {
            final selected =
                List<GPUSeries>.from(state.filterArgument.gpuSeries);

            if (selected.contains(series)) {
              selected.remove(series);
            } else {
              selected.add(series);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(gpuSeries: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: 'GPU version',
          enumValues: GPUVersion.getValues(),
          selectedValues:
          List<GPUVersion>.from(state.filterArgument.gpuVersion),
          onToggleSelection: (capacity) {
            final selected =
            List<GPUVersion>.from(state.filterArgument.gpuVersion);

            if (selected.contains(capacity)) {
              selected.remove(capacity);
            } else {
              selected.add(capacity);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(gpuVersion: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'GPU clock speed',
          fromController: TextEditingController(text: state.filterArgument.minClockSpeed),
          toController: TextEditingController(text: state.filterArgument.maxClockSpeed),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minClockSpeed: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxClockSpeed: value),
            );
          },
          fromValue: state.filterArgument.minTdp,
          toValue: state.filterArgument.maxTdp,
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'TDP',
          fromController: TextEditingController(text: state.filterArgument.minTdp),
          toController: TextEditingController(text: state.filterArgument.maxTdp),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minTdp: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxTdp: value),
            );
          },
          fromValue: state.filterArgument.minTdp,
          toValue: state.filterArgument.maxTdp,
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'Memory (GB)',
          fromController: TextEditingController(text: state.filterArgument.minMemoryGb),
          toController: TextEditingController(text: state.filterArgument.maxMemoryGb),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minMemoryGb: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxMemoryGb: value),
            );
          },
          fromValue: state.filterArgument.minMemoryGb,
          toValue: state.filterArgument.maxMemoryGb,
        )
      ],
    );
  }

  Widget _buildDriveFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Type',
          enumValues: DriveType.getValues(),
          selectedValues: List<DriveType>.from(state.filterArgument.driveType),
          onToggleSelection: (type) {
            final selected = List<DriveType>.from(state.filterArgument.driveType);

            if (selected.contains(type)) {
              selected.remove(type);
            } else {
              selected.add(type);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(driveType: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: 'Drive form factor',
          enumValues: DriveFormFactor.getValues(),
          selectedValues:
              List<DriveFormFactor>.from(state.filterArgument.driveFormFactor),
          onToggleSelection: (formFactor) {
            final selected = List<DriveFormFactor>.from(
                state.filterArgument.driveFormFactor);

            if (selected.contains(formFactor)) {
              selected.remove(formFactor);
            } else {
              selected.add(formFactor);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(driveFormFactor: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: 'Interface',
          enumValues: InterfaceType.getValues(),
          selectedValues:
              List<InterfaceType>.from(state.filterArgument.interfaceType),
          onToggleSelection: (interfaceType) {
            final selected = List<InterfaceType>.from(
                state.filterArgument.interfaceType);
            if (selected.contains(interfaceType)) {
              selected.remove(interfaceType);
            } else {
              selected.add(interfaceType);
            }
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(interfaceType: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: 'Generation',
          enumValues: DriveGen.getValues(),
          selectedValues: List<DriveGen>.from(state.filterArgument.gen),
          onToggleSelection: (gen) {
            final selected = List<DriveGen>.from(state.filterArgument.gen);
            if (selected.contains(gen)) {
              selected.remove(gen);
            } else {
              selected.add(gen);
            }
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(gen: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'Capacity (GB)',
          fromController: TextEditingController(text: state.filterArgument.minMemoryGb),
          toController: TextEditingController(text: state.filterArgument.maxMemoryGb),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minMemoryGb: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxMemoryGb: value),
            );
          },
          fromValue: state.filterArgument.minMemoryGb,
          toValue: state.filterArgument.maxMemoryGb,
        )
      ],
    );
  }

  Widget _buildMainboardFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: 'Mainboard form factor',
          enumValues: MainboardFormFactor.getValues(),
          selectedValues: List<MainboardFormFactor>.from(state.filterArgument.mainboardFormFactor),
          onToggleSelection: (formFactor) {
            final selected = List<MainboardFormFactor>.from(state.filterArgument.mainboardFormFactor);

            if (selected.contains(formFactor)) {
              selected.remove(formFactor);
            } else {
              selected.add(formFactor);
            }

            cubit.updateFilterArgument(
              state.filterArgument.copyWith(mainboardFormFactor: selected),
            );
          },
        ),
        const SizedBox(height: 16.0),
        OptionFilter(
          name: 'Socket',
          enumValues: Socket.getValues(),
          selectedValues:
              List<Socket>.from(state.filterArgument.sockets),
          onToggleSelection: (socket) {
            final selected = List<Socket>.from(state.filterArgument.sockets);
            if (selected.contains(socket)) {
              selected.remove(socket);
            } else {
              selected.add(socket);
            }
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(sockets: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: 'RAM type',
          enumValues: RAMType.getValues(),
          selectedValues: List<RAMType>.from(state.filterArgument.ramType),
          onToggleSelection: (type) {
            final selected = List<RAMType>.from(state.filterArgument.ramType);
            if (selected.contains(type)) {
              selected.remove(type);
            } else {
              selected.add(type);
            }
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(ramType: selected),
            );
          },
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'Total RAM (GB)',
          fromController: TextEditingController(text: state.filterArgument.minMemoryGb),
          toController: TextEditingController(text: state.filterArgument.maxMemoryGb),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minMemoryGb: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxMemoryGb: value),
            );
          },
          fromValue: state.filterArgument.minMemoryGb,
          toValue: state.filterArgument.maxMemoryGb,
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'M.2 Slots',
          fromController: TextEditingController(text: state.filterArgument.minM2Slots),
          toController: TextEditingController(text: state.filterArgument.maxM2Slots),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minM2Slots: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxM2Slots: value),
            );
          },
          fromValue: state.filterArgument.minM2Slots,
          toValue: state.filterArgument.maxM2Slots,
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'SATA Ports',
          fromController: TextEditingController(text: state.filterArgument.minSataPorts),
          toController: TextEditingController(text: state.filterArgument.maxSataPorts),
          onFromValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(minSataPorts: value),
            );
          },
          onToValueChanged: (value) {
            cubit.updateFilterArgument(
              state.filterArgument.copyWith(maxSataPorts: value),
            );
          },
          fromValue: state.filterArgument.minSataPorts,
          toValue: state.filterArgument.maxSataPorts,
        ),
      ],
    );
  }
}
