import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../enums/product_related/category_enum.dart';
import '../../../generated/l10n.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/product_related/filter_argument.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import '../../../../enums/processing/process_state_enum.dart';
import 'product_tab/product_tab_cubit.dart';
import 'product_tab/product_tab_state.dart';
import '../mixin/product_tab_mixin.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import '../filter/filter_screen/filter_screen_webview.dart' as filter_web;
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/services/platform_actions.dart'
    as platform_actions;

// Use a TabController variant on web that removes transition animations
class NoAnimationTabController extends TabController {
  NoAnimationTabController({
    required super.length,
    required super.vsync,
    super.initialIndex,
  });

  @override
  void animateTo(int value,
      {Duration? duration = kTabScrollDuration, Curve curve = Curves.ease}) {
    // Force zero-duration to remove visual transition on web
    super.animateTo(value, duration: Duration.zero, curve: Curves.linear);
  }
}

// No custom TabController on web; mimic mobile implementation with default TabController

class ProductScreenWebView extends StatefulWidget {
  final List<Product>? initialProducts;
  final SortEnum? initialSortOption;
  final bool isFavorites;

  const ProductScreenWebView({
    super.key,
    this.initialProducts,
    this.initialSortOption,
    this.isFavorites = false,
  });

  static Widget newInstance({
    List<Product>? initialProducts,
    SortEnum? initialSortOption,
    bool isFavorites = false,
  }) =>
      BlocProvider(
        create: (context) => ProductScreenCubit(),
        child: ProductScreenWebView(
          initialProducts: initialProducts,
          initialSortOption: initialSortOption,
          isFavorites: isFavorites,
        ),
      );

  @override
  State<ProductScreenWebView> createState() => _ProductScreenWebViewState();
}

class _ProductScreenWebViewState extends State<ProductScreenWebView>
    with TickerProviderStateMixin {
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  ProductScreenCubit get cubit => context.read<ProductScreenCubit>();
  late TabController tabController;
  bool _isTabLoading = false;
  int _shownTabIndex = 0;
  Timer? _tabSwitchTimer;
  final Map<int, Widget> _tabCache = <int, Widget>{};
  final Map<int, TabCubit> _tabCubitCache = <int, TabCubit>{};

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  StreamSubscription<dynamic>? _popStateSub;
  late AnimationController _micController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    // Initialize tab controller with proper initial index from URL
    final initialTabIndex = _getInitialTabFromUrl();
    tabController = kIsWeb
        ? NoAnimationTabController(
            length: CategoryEnum.getValues().length + 1,
            vsync: this,
            initialIndex: initialTabIndex,
          )
        : TabController(
            length: CategoryEnum.getValues().length + 1,
            vsync: this,
            initialIndex: initialTabIndex,
          );

    // On web, we handle tab switching via TabBar.onTap to enforce fixed delay
    if (!kIsWeb) {
      tabController.addListener(() {
        if (!mounted) return;
        setState(() {});
        _updateUrlForTab(tabController.index);
      });
    }

    // Ensure URL reflects initial tab on load
    _updateUrlForTab(initialTabIndex);
    _shownTabIndex = initialTabIndex;
    // Prime cache for initial tab to avoid first-build jank
    _tabCache[initialTabIndex] = _buildTabByIndex(initialTabIndex,
        searchText: '', initialProducts: widget.initialProducts ?? const []);

    cubit.initialize(widget.initialProducts ?? [],
        widget.initialSortOption ?? SortEnum.releaseLatest);
    _speech = stt.SpeechToText();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  int _getInitialTabFromUrl() {
    if (!kIsWeb) return 0;

    final hashPath = platform_actions.getHashPath();
    if (hashPath.isEmpty) return 0;

    // Check if hash path contains a product category
    final categories = CategoryEnum.getValues();
    for (int i = 0; i < categories.length; i++) {
      if (hashPath.contains('/products/${categories[i].name.toLowerCase()}')) {
        return i + 1; // +1 because index 0 is "All"
      }
    }

    return 0; // Default to "All"
  }

  void _updateUrlForTab(int tabIndex) {
    if (!kIsWeb) return;

    // If a product detail ID is present in the hash, do not override it
    final currentHash = platform_actions.getHashPath();
    // Check if this is a product detail URL (not a category)
    if (currentHash.startsWith('/products/')) {
      final segments = currentHash.split('/');
      if (segments.length >= 3) {
        final possibleProductId = segments[2];
        // Check if it's a category name or a product ID
        final categories = ['ram', 'cpu', 'gpu', 'psu', 'drive', 'mainboard'];
        final isCategory = categories.contains(possibleProductId.toLowerCase());
        // If it's not a category, it's likely a product ID - don't override
        if (!isCategory) {
          return;
        }
      }
    }

    String newUrl;
    if (tabIndex == 0) {
      newUrl = '/products';
    } else {
      final categories = CategoryEnum.getValues();
      if (tabIndex <= categories.length) {
        newUrl = '/products/${categories[tabIndex - 1].name.toLowerCase()}';
      } else {
        newUrl = '/products';
      }
    }

    // Use replaceState to update URL without creating history entry for tab switches
    // This ensures tab switches don't interfere with back/forward navigation
    platform_actions.replaceHashUrl(newUrl);
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    tabController.dispose();
    _popStateSub?.cancel();
    _micController.dispose();
    _tabSwitchTimer?.cancel();
    // Dispose cached cubits
    for (final cubit in _tabCubitCache.values) {
      cubit.close();
    }
    _tabCubitCache.clear();
    super.dispose();
  }

  TabCubit _createTabCubit(int index,
      {required String? searchText, required List<Product> initialProducts}) {
    switch (index) {
      case 0:
        return AllTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      case 1:
        return RamTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      case 2:
        return CpuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      case 3:
        return PsuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      case 4:
        return GpuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      case 5:
        return DriveTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      case 6:
        return MainboardTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
      default:
        return AllTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts);
    }
  }

  Widget _buildTabByIndex(int index,
      {required String? searchText, required List<Product> initialProducts}) {
    // Create or get cached cubit
    if (!_tabCubitCache.containsKey(index)) {
      _tabCubitCache[index] = _createTabCubit(index,
          searchText: searchText, initialProducts: initialProducts);
    }

    final cubit = _tabCubitCache[index]!;

    // Build the appropriate tab widget without its own BlocProvider
    Widget tabWidget;
    switch (index) {
      case 0:
        tabWidget = const WebProductTab();
        break;
      case 1:
        tabWidget = const WebProductTab();
        break;
      case 2:
        tabWidget = const WebProductTab();
        break;
      case 3:
        tabWidget = const WebProductTab();
        break;
      case 4:
        tabWidget = const WebProductTab();
        break;
      case 5:
        tabWidget = const WebProductTab();
        break;
      case 6:
        tabWidget = const WebProductTab();
        break;
      default:
        tabWidget = const WebProductTab();
    }

    // Wrap with BlocProvider using the cached cubit
    return BlocProvider<TabCubit>.value(
      value: cubit,
      child: tabWidget,
    );
  }

  void _listen() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() => _isListening = false);
        return;
      }
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _speech.stop();
            _micController.stop();
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          _micController.stop();
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _micController.repeat();
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
      _micController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {},
          onHorizontalDragUpdate: (_) {},
          onHorizontalDragEnd: (_) {},
          child: Stack(
            children: [
              Column(
                children: [
                  const WebHeader(),
                  // Breadcrumbs: Home / Sản phẩm / <Category>
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Home link
                        InkWell(
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home',
                              (route) => false,
                            );
                          },
                          child: Text(
                            S.of(context).homeTab,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('/',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            )),
                        const SizedBox(width: 8),
                        Text(
                          'Sản phẩm',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('/',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            )),
                        const SizedBox(width: 8),
                        Text(
                          _currentCategoryLabel(context),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search section card-like
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth >= 900;
                      final EdgeInsets horizontalPadding = EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 12,
                      );
                      final double fieldMaxWidth = isWide
                          ? math.min(1600, constraints.maxWidth - 60)
                          : constraints.maxWidth - 40;
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding.horizontal / 2,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: fieldMaxWidth),
                                  child: FieldWithIcon(
                                    height: 52,
                                    controller: searchController,
                                    focusNode: searchFocusNode,
                                    hintText: S.of(context).findYourItem,
                                    fillColor:
                                        Theme.of(context).colorScheme.surface,
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    onChanged: (value) {
                                      cubit.updateSearchText(
                                          searchController.text);
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z0-9\\s-]')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _listen,
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: _isListening
                                        ? _MicVisualizer(
                                            key: const ValueKey('mic_viz'),
                                            controller: _micController,
                                          )
                                        : Icon(
                                            Icons.mic,
                                            key: const ValueKey('mic_icon'),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Categories + Sort row (restored below search)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: IgnorePointer(
                            ignoring: _isTabLoading,
                            child: TabBar(
                              controller: tabController,
                              isScrollable: false,
                              tabAlignment: TabAlignment.fill,
                              labelPadding: EdgeInsets.zero,
                              dividerColor: Colors.transparent,
                              labelColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              unselectedLabelColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.9),
                              indicator: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              onTap: kIsWeb
                                  ? (int value) {
                                      if (_isTabLoading) return;
                                      final int previous = tabController.index;
                                      setState(() {
                                        _isTabLoading = true;
                                      });
                                      _updateUrlForTab(value);
                                      // Keep visual selection at previous until swap completes
                                      tabController.index = previous;
                                      _tabSwitchTimer?.cancel();
                                      _tabSwitchTimer =
                                          Timer(const Duration(seconds: 1), () {
                                        if (!mounted) return;
                                        setState(() {
                                          _shownTabIndex = value;
                                          _isTabLoading = false;
                                          tabController.index = value;
                                        });
                                      });
                                    }
                                  : null,
                              tabs: [
                                _buildChipTab(S.of(context).all),
                                _buildChipTab(S.of(context).ram),
                                _buildChipTab(S.of(context).cpu),
                                _buildChipTab(S.of(context).psu),
                                _buildChipTab(S.of(context).gpu),
                                _buildChipTab(S.of(context).drive),
                                _buildChipTab(S.of(context).mainboard),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _SortDropdown(
                          selected: context
                              .watch<ProductScreenCubit>()
                              .state
                              .selectedSortOption,
                          onChanged: (value) {
                            context
                                .read<ProductScreenCubit>()
                                .updateSortOption(value);
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.filter_list_alt),
                          tooltip: 'Filter',
                          onPressed: () async {
                            // Get the TabCubit for the currently shown tab
                            final tabCubit = _tabCubitCache[_shownTabIndex];
                            if (tabCubit == null) return;

                            final state = tabCubit.state;
                            final FilterArgument arguments =
                                state.filterArgument;
                            final result = await filter_web.showFilterModal(
                              context,
                              arguments: arguments,
                              selectedTabIndex: _shownTabIndex,
                              manufacturerList: Database().manufacturerList,
                            );
                            if (result is FilterArgument) {
                              tabCubit.updateFilter(filter: result);
                              tabCubit.applyFilters();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<ProductScreenCubit, ProductScreenState>(
                      builder: (context, state) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth >= 1100;
                            final EdgeInsets pagePadding = EdgeInsets.symmetric(
                              horizontal: isWide ? 24 : 12,
                            );
                            final double maxBodyWidth =
                                isWide ? 1400 : constraints.maxWidth;
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: pagePadding,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: maxBodyWidth),
                                  child: IndexedStack(
                                    index: _shownTabIndex,
                                    children: List<Widget>.generate(7, (i) {
                                      if (i == _shownTabIndex) {
                                        return _tabCache[i] = _tabCache[i] ??
                                            _buildTabByIndex(i,
                                                searchText: state.searchText,
                                                initialProducts:
                                                    state.initialProducts);
                                      }
                                      return _tabCache[i] ??
                                          const SizedBox.shrink();
                                    }),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
              if (_isTabLoading)
                Positioned.fill(
                  child: Stack(
                    children: [
                      IgnorePointer(
                        ignoring: true,
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.05),
                        ),
                      ),
                      Center(
                        child: RepaintBoundary(
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _currentCategoryLabel(BuildContext context) {
    // Show favorites label if navigating from favorites section
    if (widget.isFavorites) {
      return S.of(context).yourFavorites;
    }
    switch (tabController.index) {
      case 0:
        return S.of(context).all;
      case 1:
        return S.of(context).ram;
      case 2:
        return S.of(context).cpu;
      case 3:
        return S.of(context).psu;
      case 4:
        return S.of(context).gpu;
      case 5:
        return S.of(context).drive;
      case 6:
        return S.of(context).mainboard;
      default:
        return S.of(context).all;
    }
  }
}

class _MicVisualizer extends StatelessWidget {
  final AnimationController controller;
  const _MicVisualizer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final Color barColor = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 20,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          // Generate 5 bars with phase offsets
          final values = List<double>.generate(5, (i) {
            final phase = (controller.value + i * 0.12) * 2 * math.pi;
            return 6 + (math.sin(phase) + 1) * 6; // from 6 to 18 px
          });
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: values
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

Widget _buildChipTab(String label) {
  return Tab(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _SortDropdown extends StatelessWidget {
  final SortEnum selected;
  final ValueChanged<SortEnum> onChanged;
  const _SortDropdown({required this.selected, required this.onChanged});

  String _label(BuildContext context, SortEnum value) {
    final s = S.of(context);
    switch (value) {
      case SortEnum.releaseLatest:
        return s.releaseLatest;
      case SortEnum.releaseOldest:
        return s.releaseOldest;
      case SortEnum.priceLowest:
        return s.priceLowest;
      case SortEnum.priceHighest:
        return s.priceHighest;
      case SortEnum.salesHighest:
        return s.salesHighest;
      case SortEnum.salesLowest:
        return s.salesLowest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortEnum>(
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (context) => SortEnum.values
          .map((v) => PopupMenuItem<SortEnum>(
                value: v,
                child: Text(_label(context, v)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sắp xếp: ${_label(context, selected)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            )
          ],
        ),
      ),
    );
  }
}

class WebProductTab extends StatefulWidget {
  const WebProductTab({super.key});
  final bool showSort = false;

  static Widget newInstance(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => AllTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  static Widget newRam(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => RamTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  static Widget newCpu(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => CpuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  static Widget newPsu(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => PsuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  static Widget newGpu(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => GpuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  static Widget newDrive(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => DriveTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  static Widget newMainboard(
          {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => MainboardTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const WebProductTab(),
      );

  @override
  State<WebProductTab> createState() => _WebProductTabState();
}

class _WebProductTabState extends State<WebProductTab>
    with
        SingleTickerProviderStateMixin,
        TabMixin<WebProductTab>,
        AutomaticKeepAliveClientMixin<WebProductTab> {
  TabCubit get cubit => context.read<TabCubit>();
  final ScrollController _scrollController = ScrollController();

  int widgetIndexFromCubit(TabCubit c) {
    // Mirror TabCubit.getIndex mapping
    return c.getIndex();
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _scrollController.removeListener(_onScroll);
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!kIsWeb) return;
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      // Load more when user scrolls to 80% of the list
      cubit.loadMoreItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // Sort moved to header row; keep space minimal here
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<TabCubit, TabState>(
                  builder: (context, state) {
                    if (state.filteredProductList.isEmpty) {
                      return Center(
                        child: Text(
                          'No Products Found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    // Get displayed products based on pagination (web only)
                    final productsToDisplay = kIsWeb
                        ? state.displayedProducts
                        : state.filteredProductList;

                    if (productsToDisplay.isEmpty &&
                        state.filteredProductList.isNotEmpty) {
                      return Center(
                        child: Text(
                          'No Products Found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    // Use a denser grid on wide screens
                    final width = MediaQuery.of(context).size.width;
                    final crossAxisCount = width >= 1200
                        ? 5
                        : width >= 900
                            ? 4
                            : 3;

                    // Calculate total items including loading indicator
                    final int totalItemCount = kIsWeb
                        ? productsToDisplay.length +
                            (state.isLoadingMore ? 1 : 0)
                        : productsToDisplay.length;

                    return GridView.builder(
                      controller: kIsWeb ? _scrollController : null,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: totalItemCount,
                      itemBuilder: (context, index) {
                        // Show products
                        if (index < productsToDisplay.length) {
                          final product = productsToDisplay[index];
                          return AnimatedOpacity(
                            duration: kIsWeb
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            opacity: state.selectedProduct == null ||
                                    state.selectedProduct == product
                                ? 1.0
                                : 0.3,
                            child: WebProductCard(
                              product: product,
                            ),
                          );
                        }

                        // Show loading indicator (web only)
                        if (kIsWeb && state.isLoadingMore) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<TabCubit, TabState>(
          builder: (context, state) {
            if (state.processState == ProcessState.loading) {
              return Stack(
                children: [
                  ModalBarrier(
                      dismissible: false,
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.5)),
                  Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ]),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
