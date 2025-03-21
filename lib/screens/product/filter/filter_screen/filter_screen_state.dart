import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';

import '../../../../objects/product_related/filter_argument.dart';

class FilterScreenState extends Equatable {
  final FilterArgument filterArgument;
  final int selectedTabIndex;
  final List<Manufacturer> manufacturerList;

  const FilterScreenState({
    this.filterArgument = const FilterArgument(),
    this.selectedTabIndex = 0,
    this.manufacturerList = const [],
  });

  @override
  List<Object?> get props => [filterArgument, selectedTabIndex, manufacturerList];

  FilterScreenState copyWith({
    FilterArgument? filterArgument,
    int? selectedTabIndex,
    List<Manufacturer>? manufacturerList,
  }) {
    return FilterScreenState(
      filterArgument: filterArgument ?? this.filterArgument,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      manufacturerList: manufacturerList ?? this.manufacturerList,
    );
  }
}