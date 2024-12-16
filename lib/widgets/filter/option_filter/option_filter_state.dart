import 'package:equatable/equatable.dart';

class OptionFilterState<T> extends Equatable {
  final Set<T> selectedValues;

  const OptionFilterState({this.selectedValues = const {}});

  OptionFilterState<T> copyWith({Set<T>? selectedValues}) {
    return OptionFilterState<T>(
      selectedValues: selectedValues ?? this.selectedValues,
    );
  }

  @override
  List<Object?> get props => [selectedValues];
}