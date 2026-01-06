import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/filter_argument.dart';
import '../manufacturer_filter/manufacturer_filter.dart';
import '../range_filter/range_filter.dart';
import '../option_filter/option_filter.dart';
import 'filter_screen_cubit.dart';
import 'filter_screen_state.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_efficiency.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_gen.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_type.dart';
import 'package:gizmoglobe_client/enums/product_related/drive_enums/interface_type.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_series.dart';
import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_version.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_series.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';

// Web-only helper to show the Filter screen as a modal dialog and return the selected FilterArgument
Future<FilterArgument?> showFilterModal(
  BuildContext context, {
  required FilterArgument arguments,
  required int selectedTabIndex,
  required List<Manufacturer> manufacturerList,
}) {
  assert(kIsWeb, 'showFilterModal is intended for web usage');
  return showDialog<FilterArgument>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final screenWidth = MediaQuery.of(ctx).size.width;
      final screenHeight = MediaQuery.of(ctx).size.height;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 860 ? 820 : screenWidth - 32,
            maxHeight: screenHeight * 0.9,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                    alpha: theme.brightness == Brightness.light ? 0.1 : 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _FilterScreenWebView.newInstance(
              arguments: arguments,
              selectedTabIndex: selectedTabIndex,
              manufacturerList: manufacturerList,
            ),
          ),
        ),
      );
    },
  );
}

class _FilterScreenWebView extends StatefulWidget {
  final FilterArgument arguments;
  final int selectedTabIndex;
  final List<Manufacturer> manufacturerList;

  const _FilterScreenWebView({
    required this.arguments,
    required this.selectedTabIndex,
    required this.manufacturerList,
  });

  static Widget newInstance({
    required FilterArgument arguments,
    required int selectedTabIndex,
    required List<Manufacturer> manufacturerList,
  }) =>
      BlocProvider(
        create: (context) => FilterScreenCubit()
          ..initialize(
            initialFilterValue: arguments,
            selectedTabIndex: selectedTabIndex,
            manufacturerList: manufacturerList,
          ),
        child: _FilterScreenWebView(
          arguments: arguments,
          selectedTabIndex: selectedTabIndex,
          manufacturerList: manufacturerList,
        ),
      );

  @override
  State<_FilterScreenWebView> createState() => _FilterScreenWebViewState();
}

class _FilterScreenWebViewState extends State<_FilterScreenWebView> {
  FilterScreenCubit get cubit => context.read<FilterScreenCubit>();

  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  // Specification controllers
  final TextEditingController minMemoryController = TextEditingController();
  final TextEditingController maxMemoryController = TextEditingController();
  final TextEditingController minClockSpeedController = TextEditingController();
  final TextEditingController maxClockSpeedController = TextEditingController();
  final TextEditingController minTdpController = TextEditingController();
  final TextEditingController maxTdpController = TextEditingController();
  final TextEditingController minM2SlotsController = TextEditingController();
  final TextEditingController maxM2SlotsController = TextEditingController();
  final TextEditingController minSataPortsController = TextEditingController();
  final TextEditingController maxSataPortsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers from widget arguments initially
    final args = widget.arguments;
    minPriceController.text = args.minPrice;
    maxPriceController.text = args.maxPrice;
    minMemoryController.text = args.minMemoryGb;
    maxMemoryController.text = args.maxMemoryGb;
    minClockSpeedController.text = args.minClockSpeed;
    maxClockSpeedController.text = args.maxClockSpeed;
    minTdpController.text = args.minTdp;
    maxTdpController.text = args.maxTdp;
    minM2SlotsController.text = args.minM2Slots;
    maxM2SlotsController.text = args.maxM2Slots;
    minSataPortsController.text = args.minSataPorts;
    maxSataPortsController.text = args.maxSataPorts;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync controllers with current state when widget is rebuilt or reopened
    final state = cubit.state;
    final args = state.filterArgument;

    if (minPriceController.text != args.minPrice) {
      minPriceController.text = args.minPrice;
    }
    if (maxPriceController.text != args.maxPrice) {
      maxPriceController.text = args.maxPrice;
    }
    if (minMemoryController.text != args.minMemoryGb) {
      minMemoryController.text = args.minMemoryGb;
    }
    if (maxMemoryController.text != args.maxMemoryGb) {
      maxMemoryController.text = args.maxMemoryGb;
    }
    if (minClockSpeedController.text != args.minClockSpeed) {
      minClockSpeedController.text = args.minClockSpeed;
    }
    if (maxClockSpeedController.text != args.maxClockSpeed) {
      maxClockSpeedController.text = args.maxClockSpeed;
    }
    if (minTdpController.text != args.minTdp) {
      minTdpController.text = args.minTdp;
    }
    if (maxTdpController.text != args.maxTdp) {
      maxTdpController.text = args.maxTdp;
    }
    if (minM2SlotsController.text != args.minM2Slots) {
      minM2SlotsController.text = args.minM2Slots;
    }
    if (maxM2SlotsController.text != args.maxM2Slots) {
      maxM2SlotsController.text = args.maxM2Slots;
    }
    if (minSataPortsController.text != args.minSataPorts) {
      minSataPortsController.text = args.minSataPorts;
    }
    if (maxSataPortsController.text != args.maxSataPorts) {
      maxSataPortsController.text = args.maxSataPorts;
    }
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    minMemoryController.dispose();
    maxMemoryController.dispose();
    minClockSpeedController.dispose();
    maxClockSpeedController.dispose();
    minTdpController.dispose();
    maxTdpController.dispose();
    minM2SlotsController.dispose();
    maxM2SlotsController.dispose();
    minSataPortsController.dispose();
    maxSataPortsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterScreenCubit, FilterScreenState>(
      builder: (context, state) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  GradientText(text: S.of(context).filter, fontSize: 24),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context, state.filterArgument),
                    icon: Icon(
                      Icons.check,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.6),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        return const SizedBox.shrink();
    }
  }

  Widget _buildRamFilterUI(FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: S.of(context).type,
          enumValues: RAMType.values,
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
          name: '${S.of(context).ram} (GB)',
          prefixIcon: const Icon(Icons.memory),
          fromController: minMemoryController,
          toController: maxMemoryController,
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
          name: S.of(context).series,
          enumValues: CPUSeries.getValues(),
          selectedValues: List<CPUSeries>.from(state.filterArgument.cpuSeries),
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
          name: '${S.of(context).cpuClockSpeed} (GHz)',
          prefixIcon: const Icon(Icons.speed),
          fromController: minClockSpeedController,
          toController: maxClockSpeedController,
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
          fromValue: state.filterArgument.minClockSpeed,
          toValue: state.filterArgument.minClockSpeed,
        ),
        const SizedBox(height: 16),
        RangeFilter(
          name: 'TDP',
          prefixIcon: const Icon(Icons.power),
          fromController: minTdpController,
          toController: maxTdpController,
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
          name: S.of(context).modular,
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
          name: S.of(context).efficiency,
          enumValues: PSUEfficiency.getValues(),
          selectedValues:
              List<PSUEfficiency>.from(state.filterArgument.psuEfficiency),
          onToggleSelection: (efficiency) {
            final selected =
                List<PSUEfficiency>.from(state.filterArgument.psuEfficiency);
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
          name: S.of(context).psuWattage,
          prefixIcon: const Icon(Icons.power),
          fromController: minTdpController,
          toController: maxTdpController,
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
          name: '${S.of(context).gpu} ${S.of(context).series}',
          enumValues: GPUSeries.getValues(),
          selectedValues: List<GPUSeries>.from(state.filterArgument.gpuSeries),
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
          name: S.of(context).gpuVersion,
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
          name: S.of(context).gpuClockSpeed,
          prefixIcon: const Icon(Icons.speed),
          fromController: minClockSpeedController,
          toController: maxClockSpeedController,
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
          prefixIcon: const Icon(Icons.power),
          fromController: minTdpController,
          toController: maxTdpController,
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
          name: '${S.of(context).memory} (GB)',
          prefixIcon: const Icon(Icons.memory),
          fromController: minMemoryController,
          toController: maxMemoryController,
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
          name: S.of(context).type,
          enumValues: DriveType.getValues(),
          selectedValues: List<DriveType>.from(state.filterArgument.driveType),
          onToggleSelection: (type) {
            final selected =
                List<DriveType>.from(state.filterArgument.driveType);
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
          name: '${S.of(context).drive} ${S.of(context).formFactor}',
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
          name: S.of(context).driveInterface,
          enumValues: InterfaceType.getValues(),
          selectedValues:
              List<InterfaceType>.from(state.filterArgument.interfaceType),
          onToggleSelection: (interfaceType) {
            final selected =
                List<InterfaceType>.from(state.filterArgument.interfaceType);
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
          name: S.of(context).driveGeneration,
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
          name: '${S.of(context).capacity} (GB)',
          prefixIcon: const Icon(Icons.storage),
          fromController: minMemoryController,
          toController: maxMemoryController,
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

  Widget _buildMainboardFilterUI(
      FilterScreenState state, FilterScreenCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionFilter(
          name: '${S.of(context).mainboard} ${S.of(context).formFactor}',
          enumValues: MainboardFormFactor.getValues(),
          selectedValues: List<MainboardFormFactor>.from(
              state.filterArgument.mainboardFormFactor),
          onToggleSelection: (formFactor) {
            final selected = List<MainboardFormFactor>.from(
                state.filterArgument.mainboardFormFactor);
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
        ),
        const SizedBox(height: 16),
        OptionFilter(
          name: S.of(context).ramType,
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
          name: '${S.of(context).ram} (GB)',
          prefixIcon: const Icon(Icons.memory),
          fromController: minMemoryController,
          toController: maxMemoryController,
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
          prefixIcon: const Icon(Icons.developer_board),
          fromController: minM2SlotsController,
          toController: maxM2SlotsController,
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
          prefixIcon: const Icon(Icons.cable),
          fromController: minSataPortsController,
          toController: maxSataPortsController,
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
