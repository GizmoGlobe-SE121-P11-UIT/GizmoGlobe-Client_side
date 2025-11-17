import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_state.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_webview.dart';
import 'package:gizmoglobe_client/widgets/dialog/confirmation_dialog.dart';
import 'package:intl/intl.dart';

class PCBuilderWebView extends StatefulWidget {
  const PCBuilderWebView({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => PCBuilderCubit(),
        child: const PCBuilderWebView(),
      );

  static Widget withCubit(PCBuilderCubit cubit) => BlocProvider.value(
        value: cubit,
        child: const PCBuilderWebView(),
      );

  @override
  State<PCBuilderWebView> createState() => _PCBuilderWebViewState();
}

class _PCBuilderWebViewState extends State<PCBuilderWebView> {
  PCBuilderCubit get cubit => context.read<PCBuilderCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (kIsWeb) const WebHeader(),
          Expanded(
            child: BlocBuilder<PCBuilderCubit, PCBuilderState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBreadcrumb(context),
                        const SizedBox(height: 16),
                        _buildComponentList(context, state),
                        const SizedBox(height: 32),
                        _buildActionButtons(context, state),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
          child: Text(
            'Home',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Text(
          ' / ',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          'Build PC',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentList(BuildContext context, PCBuilderState state) {
    final config = state.activeConfiguration;
    final components = [
      {'key': 'cpu', 'label': 'CPU', 'category': CategoryEnum.cpu},
      {
        'key': 'mainboard',
        'label': 'Mainboard - Bo mạch chủ',
        'category': CategoryEnum.mainboard
      },
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

    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Linh kiện tương thích',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Row(
              children: [
                Checkbox(
                  value: state.enableCompatibilityChecker,
                  onChanged: (value) {
                    cubit.toggleCompatibilityChecker(value ?? false);
                  },
                ),
                Text(
                  s.enableCompatibilityChecker,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...components.map((component) {
          final componentKey = component['key'] as String;
          final isMultiSelect =
              componentKey == 'ram' || componentKey == 'drive';

          if (isMultiSelect) {
            final products = config[componentKey] as List<Product>? ?? [];
            return _buildMultiComponentSection(
              context,
              label: component['label'] as String,
              componentKey: componentKey,
              products: products,
              category: component['category'] as CategoryEnum,
              cubit: cubit,
              state: state,
            );
          } else {
            final product = config[componentKey] as Product?;
            return _buildComponentRow(
              context,
              label: component['label'] as String,
              product: product,
              componentKey: componentKey,
              quantity: product?.productID != null
                  ? (state.quantities[product!.productID!] ?? 1)
                  : 1,
              onSelect: () {
                _showPartsPickerDialog(
                  context,
                  category: component['category'] as CategoryEnum,
                  allowMultipleSelection: false,
                  onProductsSelected: (selectedProducts) {
                    if (selectedProducts.isNotEmpty) {
                      cubit.selectComponent(
                          componentKey, selectedProducts.first);
                    }
                  },
                );
              },
              onRemove: product != null
                  ? () {
                      cubit.selectComponent(componentKey, null);
                    }
                  : null,
              onQuantityChanged: product != null
                  ? (newQuantity) {
                      cubit.updateQuantity(componentKey, product, newQuantity);
                    }
                  : null,
            );
          }
        }),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Chi phí dự tính: ${Helper.toCurrencyFormat(state.estimatedCost)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiComponentSection(
    BuildContext context, {
    required String label,
    required String componentKey,
    required List<Product> products,
    required CategoryEnum category,
    required PCBuilderCubit cubit,
    required PCBuilderState state,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label at the top
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          // List of products inside the same container
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final quantity = product.productID != null
                ? (state.quantities[product.productID!] ?? 1)
                : 1;
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 12 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Helper.toCurrencyFormat(
                                  product.discountedPrice.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (quantity > 1) ...[
                              const SizedBox(width: 8),
                              Text(
                                'x$quantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Quantity controls
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: quantity > 1
                              ? () => cubit.updateQuantityInList(
                                  componentKey, index, quantity - 1)
                              : null,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: quantity > 1
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 40),
                          alignment: Alignment.center,
                          child: Text(
                            quantity.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => cubit.updateQuantityInList(
                              componentKey, index, quantity + 1),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      cubit.removeComponentFromList(componentKey, index);
                    },
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            );
          }),
          // Add button at the bottom inside the same container
          Padding(
            padding: EdgeInsets.only(top: products.isEmpty ? 0 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (products.isNotEmpty)
                  // "THÊM" button: match width of quantity controls + remove button
                  SizedBox(
                    width: 40 +
                        40 +
                        40 +
                        8 +
                        48, // Quantity controls width + spacing + remove button width
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showPartsPickerDialog(
                          context,
                          category: category,
                          allowMultipleSelection: true,
                          onProductsSelected: (selectedProducts) {
                            // For RAM and drive, add all selected products
                            for (final product in selectedProducts) {
                              cubit.selectComponent(componentKey, product);
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('THÊM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  )
                else
                  // "CHỌN" button: single line button (no width constraint)
                  ElevatedButton.icon(
                    onPressed: () {
                      _showPartsPickerDialog(
                        context,
                        category: category,
                        allowMultipleSelection: true,
                        onProductsSelected: (selectedProducts) {
                          // For RAM and drive, add all selected products
                          for (final product in selectedProducts) {
                            cubit.selectComponent(componentKey, product);
                          }
                        },
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('CHỌN ${label.toUpperCase()}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentRow(
    BuildContext context, {
    required String label,
    Product? product,
    required String componentKey,
    required int quantity,
    required VoidCallback onSelect,
    VoidCallback? onRemove,
    Function(int)? onQuantityChanged,
    bool showAddButton = false,
  }) {
    final isMultiSelect = componentKey == 'ram' || componentKey == 'drive';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (product != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Helper.toCurrencyFormat(
                            product.discountedPrice.toInt()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (quantity > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          'x$quantity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (product != null) ...[
            // Quantity controls
            if (onQuantityChanged != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: quantity > 1
                          ? () => onQuantityChanged(quantity - 1)
                          : null,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: quantity > 1
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => onQuantityChanged(quantity + 1),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ] else ...[
            // Show add button: always for RAM/drive (multi-select), only when no product for others
            if (showAddButton ||
                isMultiSelect ||
                (!isMultiSelect && product == null))
              ElevatedButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.add, size: 18),
                label: Text(showAddButton
                    ? 'THÊM'
                    : (label.isNotEmpty
                        ? 'CHỌN ${label.toUpperCase()}'
                        : 'CHỌN')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PCBuilderState state) {
    final s = S.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              context,
              icon: Icons.picture_as_pdf,
              label: 'TẢI FILE PDF CẤU HÌNH',
              onPressed: () => cubit.downloadConfigurationPdf(),
            ),
            _buildActionButton(
              context,
              icon: Icons.shopping_cart,
              label: s.addToCart.toUpperCase(),
              onPressed: () => cubit.buyNow(),
              isPrimary: true,
            ),
          ],
        ),
        Row(
          children: [
            _buildIconButton(
              context,
              icon: Icons.add,
              tooltip: s.builderAddTooltip,
              onPressed: () => cubit.addConfiguration(),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              context,
              icon: Icons.delete,
              tooltip: s.builderDeleteTooltip,
              onPressed: () => _showDeleteConfirmation(context),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              context,
              icon: Icons.refresh,
              tooltip: s.builderResetTooltip,
              onPressed: () => _showResetConfirmation(context),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              context,
              icon: Icons.file_upload,
              tooltip: s.builderUploadTooltip,
              onPressed: () => cubit.uploadConfiguration(),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              context,
              icon: Icons.file_download,
              tooltip: s.builderDownloadTooltip,
              onPressed: () => _showSessionPickerDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isPrimary
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.all(12),
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

  void _showSessionPickerDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<BuilderSessionSummary>>(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final updatedText = session.updatedAt != null
                              ? '${s.builderSessionUpdatedLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(session.updatedAt!)}'
                              : s.builderSessionUpdatedLabel;

                          return ListTile(
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              await cubit.loadBuilderSession(session.id);
                            },
                            title: Text(
                              session.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              updatedText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Helper.toCurrencyFormat(
                                      session.estimatedCost.toDouble()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.builderSessionComponents(
                                    session.componentCount,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => Divider(
                          color: Theme.of(context).dividerColor,
                        ),
                        itemCount: sessions.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPartsPickerDialog(
    BuildContext context, {
    required CategoryEnum category,
    required Function(List<Product>) onProductsSelected,
    bool allowMultipleSelection = false,
  }) {
    final cubit = PartsPickerCubit(category);

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: PartsPickerWebView(
          category: category,
          onProductsSelected: onProductsSelected,
          allowMultipleSelection: allowMultipleSelection,
        ),
      ),
    );
  }
}
