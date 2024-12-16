import 'package:flutter_bloc/flutter_bloc.dart';
import 'range_filter_state.dart';

class RangeFilterCubit extends Cubit<RangeFilterState> {
  RangeFilterCubit() : super(const RangeFilterState());

  void fromChanged(String value) {
    emit(state.copyWith(from: value));
  }

  void toChanged(String value) {
    emit(state.copyWith(to: value));
  }
}