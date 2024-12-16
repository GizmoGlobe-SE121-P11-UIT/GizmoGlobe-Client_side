import 'package:equatable/equatable.dart';

class RangeFilterState extends Equatable {
  final String from;
  final String to;

  const RangeFilterState({this.from = '', this.to = ''});

  RangeFilterState copyWith({String? from, String? to}) {
    return RangeFilterState(
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  @override
  List<Object?> get props => [from, to];
}