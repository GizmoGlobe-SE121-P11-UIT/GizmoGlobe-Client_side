import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_tab/product_tab_view.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../../../enums/product_related/category_enum.dart';
import '../../../generated/l10n.dart';
import '../../../objects/product_related/product.dart';

class ProductScreen extends StatefulWidget {
  final List<Product>? initialProducts;
  final SortEnum? initialSortOption;

  const ProductScreen(
      {super.key, this.initialProducts, this.initialSortOption});

  static Widget newInstance(
          {List<Product>? initialProducts, SortEnum? initialSortOption}) =>
      BlocProvider(
        create: (context) => ProductScreenCubit(),
        child: ProductScreen(
            initialProducts: initialProducts,
            initialSortOption: initialSortOption),
      );

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  ProductScreenCubit get cubit => context.read<ProductScreenCubit>();
  late TabController tabController;

  // Voice search
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    tabController =
        TabController(length: CategoryEnum.values.length + 1, vsync: this);
    cubit.initialize(widget.initialProducts ?? [],
        widget.initialSortOption ?? SortEnum.releaseLatest);
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  int getTabCount() => CategoryEnum.values.length + 1;

  void onTabChanged(int index) {
    cubit.updateSelectedTabIndex(index);
  }

  void _listen() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _isListening = false);
      // Optionally show a dialog/toast to the user
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _speech.stop();
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _lastWords = val.recognizedWords;
              searchController.text = _lastWords;
              searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: searchController.text.length),
              );
              cubit.updateSearchText(_lastWords);
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Future<bool> _onWillPop() async {
  //   if (searchFocusNode.hasFocus) {
  //     searchFocusNode.unfocus();
  //     return Future.value(false);
  //   }
  //   return Future.value(true);
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          searchFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Row(
              children: [
                Expanded(
                  child: FieldWithIcon(
                    height: 40,
                    controller: searchController,
                    focusNode: searchFocusNode,
                    hintText: S.of(context).findYourItem,
                    fillColor: Theme.of(context).colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    onChanged: (value) {
                      cubit.updateSearchText(searchController.text);
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9\s-]')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                  ),
                  onPressed: _listen,
                ),
              ],
            ),
            bottom: TabBar(
              controller: tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              indicator: const BoxDecoration(),
              tabs: [
                Tab(text: S.of(context).all),
                Tab(text: S.of(context).ram),
                Tab(text: S.of(context).cpu),
                Tab(text: S.of(context).psu),
                Tab(text: S.of(context).gpu),
                Tab(text: S.of(context).drive),
                Tab(text: S.of(context).mainboard),
              ],
            ),
          ),
          body: SafeArea(
            child: BlocBuilder<ProductScreenCubit, ProductScreenState>(
              builder: (context, state) {
                return TabBarView(
                  controller: tabController,
                  children: [
                    ProductTab.newInstance(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                    ProductTab.newRam(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                    ProductTab.newCpu(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                    ProductTab.newPsu(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                    ProductTab.newGpu(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                    ProductTab.newDrive(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                    ProductTab.newMainboard(
                        searchText: state.searchText,
                        initialProducts: state.initialProducts,
                        initialSortOption: state.initialSortOption),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
