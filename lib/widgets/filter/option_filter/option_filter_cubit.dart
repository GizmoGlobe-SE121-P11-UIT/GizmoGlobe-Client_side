import 'package:flutter_bloc/flutter_bloc.dart';
import 'option_filter_state.dart';

class OptionFilterCubit<T> extends Cubit<OptionFilterState<T>> {
  OptionFilterCubit() : super(OptionFilterState<T>());

  void toggleSelection(T value) {
    final selectedValues = Set<T>.from(state.selectedValues);
    if (selectedValues.contains(value)) {
      selectedValues.remove(value);
    } else {
      selectedValues.add(value);
    }
    emit(state.copyWith(selectedValues: selectedValues));
  }
}