import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_state.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_view.dart';
import 'package:gizmoglobe_client/widgets/dialog/confirmation_dialog.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:intl/intl.dart';

import 'pc_builder_webview.dart';

class PCBuilderScreen extends StatefulWidget {
  final String? initialSessionId;

  const PCBuilderScreen({super.key, this.initialSessionId});

  static Widget newInstance({String? sessionId, int initialTabIndex = 0}) =>
      BlocProvider(
        create: (context) => PCBuilderCubit(
          initialConfigId: sessionId,
          initialTabIndex: initialTabIndex,
        ),
        child: PCBuilderScreen(initialSessionId: sessionId),
      );

  @override
  State<PCBuilderScreen> createState() => _PCBuilderScreenState();
}

class _PCBuilderScreenState extends State<PCBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return PCBuilderWebView.withCubit(context.read<PCBuilderCubit>());
    }

    return _PCBuilderMobileView(cubit: context.read<PCBuilderCubit>());
  }
}

class _PCBuilderMobileView extends StatelessWidget {
  final PCBuilderCubit cubit;

  const _PCBuilderMobileView({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GradientText(text: s.buildYourDreamPc.replaceAll('\n', ' ')),
      ),
      body: BlocBuilder<PCBuilderCubit, PCBuilderState>(
        bloc: cubit,
        builder: (context, state) {
          final config = state.activeConfiguration;
          final isCompatibilityMode = state.enableCompatibilityChecker;
          final mainboard = config['mainboard'] as Product?;
          final cpu = config['cpu'] as Product?;
          final gpu = config['gpu'] as Product?;

          final components = [
            {
              'key': 'mainboard',
              'label': 'Mainboard - Bo mạch chủ',
              'category': CategoryEnum.mainboard
            },
            {'key': 'cpu', 'label': 'CPU', 'category': CategoryEnum.cpu},
            {'key': 'ram', 'label': 'RAM', 'category': CategoryEnum.ram},
            {
              'key': 'drive',
              'label': 'Ổ lưu trữ (SSD/HDD)',
              'category': CategoryEnum.drive
            },
            {
              'key': 'gpu',
              'label': 'VGA - Card màn hình',
              'category': CategoryEnum.gpu
            },
            {
              'key': 'psu',
              'label': 'PSU - Nguồn máy tính',
              'category': CategoryEnum.psu
            },
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCompatibilityCard(context, state, s),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActions(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...components.map((component) {
                  final componentKey = component['key'] as String;
                  final isMultiSelect =
                      componentKey == 'ram' || componentKey == 'drive';

                  // Compatibility Logic
                  bool isEnabled = true;
                  List<Product>? compatibleProducts;

                  if (isCompatibilityMode) {
                    if (componentKey == 'mainboard') {
                      isEnabled = true;
                    } else if (componentKey == 'psu') {
                      // PSU requires CPU and GPU
                      isEnabled = cpu != null && gpu != null;
                      if (isEnabled) {
                        compatibleProducts = [cpu, gpu];
                      }
                    } else {
                      // CPU, RAM, Drive, GPU require Mainboard
                      isEnabled = mainboard != null;
                      if (isEnabled) {
                        compatibleProducts = [mainboard];
                      }
                    }
                  }

                  if (isMultiSelect) {
                    final products =
                        config[componentKey] as List<Product>? ?? [];
                    return _buildMultiComponentCard(
                      context,
                      label: component['label'] as String,
                      componentKey: componentKey,
                      products: products,
                      category: component['category'] as CategoryEnum,
                      state: state,
                      isEnabled: isEnabled,
                      compatibleProducts: compatibleProducts,
                    );
                  } else {
                    final product = config[componentKey] as Product?;
                    final quantity = product?.productID != null
                        ? (state.quantities[product!.productID!] ?? 1)
                        : 1;
                    return _buildComponentCard(
                      context,
                      label: component['label'] as String,
                      componentKey: componentKey,
                      product: product,
                      quantity: quantity,
                      category: component['category'] as CategoryEnum,
                      state: state,
                      isEnabled: isEnabled,
                      compatibleProducts: compatibleProducts,
                    );
                  }
                }),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${s.totalCost}: ${Helper.toCurrencyFormat(state.estimatedCost)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPrimaryActions(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompatibilityCard(
      BuildContext context, PCBuilderState state, S s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.enableCompatibilityChecker,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Switch(
            value: state.enableCompatibilityChecker,
            onChanged: (value) {
              cubit.toggleCompatibilityChecker(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.add, 'onTap': () => cubit.addConfiguration()},
      {'icon': Icons.delete, 'onTap': () => _showDeleteConfirmation(context)},
      {'icon': Icons.refresh, 'onTap': () => _showResetConfirmation(context)},
      {'icon': Icons.file_upload, 'onTap': () => cubit.uploadConfiguration()},
      {
        'icon': Icons.file_download,
        'onTap': () => _showSessionPickerSheet(context),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 3;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: actions
              .map(
                (action) => SizedBox(
                  width: itemWidth,
                  child: OutlinedButton(
                    onPressed: action['onTap'] as VoidCallback,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Icon(action['icon'] as IconData, size: 20),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPrimaryActions(BuildContext context, PCBuilderState state) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => cubit.downloadConfigurationPdf(),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('TẢI FILE PDF CẤU HÌNH'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => cubit.buyNow(),
            icon: const Icon(Icons.shopping_cart),
            label: Text(s.addToCart.toUpperCase()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentCard(
    BuildContext context, {
    required String label,
    required String componentKey,
    required CategoryEnum category,
    required PCBuilderState state,
    Product? product,
    required int quantity,
    bool isEnabled = true,
    List<Product>? compatibleProducts,
  }) {
    final isMultiSelect = componentKey == 'ram' || componentKey == 'drive';
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (product != null)
                InkWell(
                  onTap: isEnabled
                      ? () => _openPartsPicker(
                            context,
                            category: category,
                            allowMultipleSelection: isMultiSelect,
                            compatibleProducts: compatibleProducts,
                            onProductsSelected: (selectedProducts) {
                              if (isMultiSelect) {
                                for (final product in selectedProducts) {
                                  cubit.selectComponentWithCompatibilityCheck(
                                      componentKey, product);
                                }
                              } else if (selectedProducts.isNotEmpty) {
                                cubit.selectComponentWithCompatibilityCheck(
                                    componentKey, selectedProducts.first);
                              }
                            },
                          )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              Helper.toCurrencyFormat(
                                  product.discountedPrice.toInt()),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (quantity > 1) ...[
                              const SizedBox(width: 8),
                              Text(
                                'x$quantity',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (product != null)
                    _buildQuantityControls(
                      context,
                      quantity: quantity,
                      onDecrement: quantity > 1 && isEnabled
                          ? () => cubit.updateQuantity(
                              componentKey, product, quantity - 1)
                          : null,
                      onIncrement: isEnabled
                          ? () => cubit.updateQuantity(
                              componentKey, product, quantity + 1)
                          : null,
                    ),
                  const SizedBox(width: 12),
                  if (product != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: isEnabled
                          ? () => cubit.selectComponentWithCompatibilityCheck(
                              componentKey, null)
                          : null,
                    ),
                  if (product == null || isMultiSelect)
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isEnabled
                              ? () => _openPartsPicker(
                                    context,
                                    category: category,
                                    allowMultipleSelection: isMultiSelect,
                                    compatibleProducts: compatibleProducts,
                                    onProductsSelected: (selectedProducts) {
                                      if (isMultiSelect) {
                                        for (final product
                                            in selectedProducts) {
                                          cubit
                                              .selectComponentWithCompatibilityCheck(
                                                  componentKey, product);
                                        }
                                      } else if (selectedProducts.isNotEmpty) {
                                        cubit
                                            .selectComponentWithCompatibilityCheck(
                                                componentKey,
                                                selectedProducts.first);
                                      }
                                    },
                                  )
                              : null,
                          icon: const Icon(Icons.add),
                          label: Text(product == null
                              ? 'CHỌN ${label.toUpperCase()}'
                              : 'THÊM'),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiComponentCard(
    BuildContext context, {
    required String label,
    required String componentKey,
    required List<Product> products,
    required CategoryEnum category,
    required PCBuilderState state,
    bool isEnabled = true,
    List<Product>? compatibleProducts,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...products.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final quantity = product.productID != null
                    ? (state.quantities[product.productID!] ?? 1)
                    : 1;
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 12 : 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isEnabled
                              ? () => _openPartsPicker(
                                    context,
                                    category: category,
                                    allowMultipleSelection: true,
                                    compatibleProducts: compatibleProducts,
                                    onProductsSelected: (selectedProducts) {
                                      for (final product in selectedProducts) {
                                        cubit
                                            .selectComponentWithCompatibilityCheck(
                                                componentKey, product);
                                      }
                                    },
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.productName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      Helper.toCurrencyFormat(
                                          product.discountedPrice.toInt()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (quantity > 1) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'x$quantity',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildQuantityControls(
                        context,
                        quantity: quantity,
                        onDecrement: quantity > 1 && isEnabled
                            ? () => cubit.updateQuantityInList(
                                componentKey, index, quantity - 1)
                            : null,
                        onIncrement: isEnabled
                            ? () => cubit.updateQuantityInList(
                                componentKey, index, quantity + 1)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: isEnabled
                            ? () => cubit.removeComponentFromList(
                                componentKey, index)
                            : null,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isEnabled
                      ? () => _openPartsPicker(
                            context,
                            category: category,
                            allowMultipleSelection: true,
                            compatibleProducts: compatibleProducts,
                            onProductsSelected: (selectedProducts) {
                              for (final product in selectedProducts) {
                                cubit.selectComponentWithCompatibilityCheck(
                                    componentKey, product);
                              }
                            },
                          )
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(products.isEmpty
                      ? 'CHỌN ${label.toUpperCase()}'
                      : 'THÊM'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(
    BuildContext context, {
    required int quantity,
    VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onDecrement,
          ),
          Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }

  void _openPartsPicker(
    BuildContext context, {
    required CategoryEnum category,
    required bool allowMultipleSelection,
    required Function(List<Product>) onProductsSelected,
    List<Product>? compatibleProducts,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartsPickerScreen.newInstance(
          category: category,
          onProductsSelected: onProductsSelected,
          allowMultipleSelection: allowMultipleSelection,
          compatibleProducts: compatibleProducts,
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: s.builderResetTitle,
        content: s.builderResetMessage,
        confirmText: s.confirm,
        cancelText: s.cancel,
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          cubit.resetConfiguration();
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: s.builderDeleteTitle,
        content: s.builderDeleteMessage,
        confirmText: s.confirm,
        cancelText: s.cancel,
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          cubit.deleteConfiguration();
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _showSessionPickerSheet(BuildContext context) {
    final s = S.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar for dragging
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.builderSessionsTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: FutureBuilder<List<BuilderSessionSummary>>(
                    future: cubit.fetchBuilderSessions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final sessions = snapshot.data ?? [];
                      if (sessions.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.builderSessionsEmpty,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final updatedAt = session.updatedAt != null
                              ? '${s.builderSessionUpdatedLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(session.updatedAt!)}'
                              : s.builderSessionUpdatedLabel;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await cubit.loadBuilderSession(session.id);
                            },
                            title: Text(session.id),
                            subtitle: Text(updatedAt),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  Helper.toCurrencyFormat(
                                      session.estimatedCost.toDouble()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  s.builderSessionComponents(
                                      session.componentCount),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
