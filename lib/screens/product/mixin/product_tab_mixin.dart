import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';

import '../product_screen/product_screen_cubit.dart';
import '../product_screen/product_tab/product_tab_cubit.dart';

mixin TabMixin<T extends StatefulWidget> on State<T> {
  ProductScreenCubit get _cubit => context.read<ProductScreenCubit>();
  late StreamSubscription<ProductScreenState> subscription;
  String searchText = '';
  int selectedTabIndex = 0;
  SortEnum selectedSortOption = SortEnum.releaseLatest;
  TabCubit get tabCubit => context.read<TabCubit>();

  @override
  void initState() {
    super.initState();
    subscription = _cubit.stream.listen((state) {
      if (state.searchText != searchText) {
        searchText = state.searchText ?? '';
        tabCubit.updateSearchText(searchText);
      }

      if (state.selectedTabIndex != selectedTabIndex) {
        selectedTabIndex = state.selectedTabIndex;
        tabCubit.updateTabIndex(selectedTabIndex);
      }

      if (state.selectedSortOption != selectedSortOption) {
        selectedSortOption = state.selectedSortOption;
        tabCubit.updateSortOption(selectedSortOption);
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}