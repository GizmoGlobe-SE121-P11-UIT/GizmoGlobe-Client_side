// lib/screens/cart/choose_voucher_screen/choose_voucher_screen_state.dart
import 'package:equatable/equatable.dart';
import '../../../objects/voucher_related/voucher.dart';

class ChooseVoucherScreenState with EquatableMixin {
  final List<Voucher> availableVouchers;
  final bool isLoading;
  final String? errorMessage;

  const ChooseVoucherScreenState({
    this.availableVouchers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [availableVouchers, isLoading, errorMessage];

  ChooseVoucherScreenState copyWith({
    List<Voucher>? availableVouchers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChooseVoucherScreenState(
      availableVouchers: availableVouchers ?? this.availableVouchers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}