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
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                final horizontalPadding = isMobile
                    ? 16.0
                    : screenWidth < 900
                        ? 40.0
                        : 80.0;

                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: 24,
                      // Add bottom padding on mobile to avoid FAB blocking buttons
                      bottom: isMobile ? 80 : 24,
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
    final s = S.of(context);
    final config = state.activeConfiguration;
    final isCompatibilityMode = state.enableCompatibilityChecker;
    final mainboard = config['mainboard'] as Product?;
    final cpu = config['cpu'] as Product?;
    final gpu = config['gpu'] as Product?;

    final components = [
      {
        'key': 'mainboard',
        'label': s.mainboard,
        'category': CategoryEnum.mainboard
      },
      {'key': 'cpu', 'label': s.cpu, 'category': CategoryEnum.cpu},
      {'key': 'ram', 'label': s.ram, 'category': CategoryEnum.ram},
      {'key': 'drive', 'label': s.drive, 'category': CategoryEnum.drive},
      {'key': 'gpu', 'label': s.gpu, 'category': CategoryEnum.gpu},
      {'key': 'psu', 'label': s.psu, 'category': CategoryEnum.psu},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - stack vertically on mobile
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.compatibleComponents,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: state.enableCompatibilityChecker,
                        onChanged: (value) {
                          cubit.toggleCompatibilityChecker(value ?? false);
                        },
                      ),
                      Flexible(
                        child: Text(
                          s.enableCompatibilityChecker,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.compatibleComponents,
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
            final products = config[componentKey] as List<Product>? ?? [];
            return _buildMultiComponentSection(
              context,
              label: component['label'] as String,
              componentKey: componentKey,
              products: products,
              category: component['category'] as CategoryEnum,
              cubit: cubit,
              state: state,
              isEnabled: isEnabled,
              compatibleProducts: compatibleProducts,
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
              isEnabled: isEnabled,
              onSelect: () {
                _showPartsPickerDialog(
                  context,
                  category: component['category'] as CategoryEnum,
                  allowMultipleSelection: false,
                  compatibleProducts: compatibleProducts,
                  onProductsSelected: (selectedProducts) {
                    if (selectedProducts.isNotEmpty) {
                      cubit.selectComponentWithCompatibilityCheck(
                          componentKey, selectedProducts.first);
                    }
                  },
                );
              },
              onRemove: product != null
                  ? () {
                      cubit.selectComponentWithCompatibilityCheck(
                          componentKey, null);
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
            '${s.estimatedCost}: ${Helper.toCurrencyFormat(state.estimatedCost)}',
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
    bool isEnabled = true,
    List<Product>? compatibleProducts,
  }) {
    final s = S.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                fontSize: isMobile ? 14 : 16,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helper.toCurrencyFormat(product.discountedPrice.toInt()),
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                                icon: Icon(Icons.remove,
                                    size: isMobile ? 16 : 20),
                                onPressed: quantity > 1 && isEnabled
                                    ? () => cubit.updateQuantityInList(
                                        componentKey, index, quantity - 1)
                                    : null,
                                padding: EdgeInsets.all(isMobile ? 4 : 8),
                                constraints: BoxConstraints(
                                  minWidth: isMobile ? 32 : 40,
                                  minHeight: isMobile ? 32 : 40,
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
                                constraints: BoxConstraints(
                                    minWidth: isMobile ? 28 : 40),
                                alignment: Alignment.center,
                                child: Text(
                                  quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, size: isMobile ? 16 : 20),
                                onPressed: isEnabled
                                    ? () => cubit.updateQuantityInList(
                                        componentKey, index, quantity + 1)
                                    : null,
                                padding: EdgeInsets.all(isMobile ? 4 : 8),
                                constraints: BoxConstraints(
                                  minWidth: isMobile ? 32 : 40,
                                  minHeight: isMobile ? 32 : 40,
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                        // Remove button
                        IconButton(
                          icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                          onPressed: isEnabled
                              ? () {
                                  cubit.removeComponentFromList(
                                      componentKey, index);
                                }
                              : null,
                          color: Theme.of(context).colorScheme.error,
                          padding: EdgeInsets.all(isMobile ? 4 : 8),
                          constraints: BoxConstraints(
                            minWidth: isMobile ? 32 : 48,
                            minHeight: isMobile ? 32 : 48,
                          ),
                        ),
                      ],
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
                  ElevatedButton.icon(
                    onPressed: isEnabled
                        ? () {
                            _showPartsPickerDialog(
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
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(products.isNotEmpty
                        ? s.add
                        : (isMobile
                            ? s.choose
                            : s.chooseComponent(label.toUpperCase()))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 8 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    bool isEnabled = true,
  }) {
    final s = S.of(context);
    final isMultiSelect = componentKey == 'ram' || componentKey == 'drive';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final canChange = ['mainboard', 'cpu', 'gpu', 'psu'].contains(componentKey);

    // Build quantity controls widget
    Widget buildQuantityControls() {
      if (onQuantityChanged == null) return const SizedBox.shrink();
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove, size: isMobile ? 16 : 20),
              onPressed: quantity > 1 && isEnabled
                  ? () => onQuantityChanged(quantity - 1)
                  : null,
              padding: EdgeInsets.all(isMobile ? 4 : 8),
              constraints: BoxConstraints(
                minWidth: isMobile ? 32 : 40,
                minHeight: isMobile ? 32 : 40,
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
              constraints: BoxConstraints(minWidth: isMobile ? 28 : 40),
              alignment: Alignment.center,
              child: Text(
                quantity.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: isMobile ? 16 : 20),
              onPressed:
                  isEnabled ? () => onQuantityChanged(quantity + 1) : null,
              padding: EdgeInsets.all(isMobile ? 4 : 8),
              constraints: BoxConstraints(
                minWidth: isMobile ? 32 : 40,
                minHeight: isMobile ? 32 : 40,
              ),
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // Build remove button widget
    Widget buildRemoveButton() {
      if (onRemove == null) return const SizedBox.shrink();
      return IconButton(
        icon: Icon(Icons.close, size: isMobile ? 20 : 24),
        onPressed: isEnabled ? onRemove : null,
        color: Theme.of(context).colorScheme.error,
        padding: EdgeInsets.all(isMobile ? 4 : 8),
        constraints: BoxConstraints(
          minWidth: isMobile ? 32 : 48,
          minHeight: isMobile ? 32 : 48,
        ),
      );
    }

    // Build change button widget
    Widget buildChangeButton() {
      return ElevatedButton(
        onPressed: isEnabled ? onSelect : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: 0,
          ),
          minimumSize: Size(0, isMobile ? 32 : 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label.isNotEmpty ? s.changeComponent(label.toUpperCase()) : s.change,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Build add/select button widget
    Widget buildSelectButton() {
      if (product != null) return const SizedBox.shrink();
      if (!(showAddButton ||
          isMultiSelect ||
          (!isMultiSelect && product == null))) {
        return const SizedBox.shrink();
      }
      return ElevatedButton.icon(
        onPressed: isEnabled ? onSelect : null,
        icon: const Icon(Icons.add, size: 18),
        label: Text(showAddButton
            ? s.add
            : (label.isNotEmpty
                ? (isMobile ? s.choose : s.chooseComponent(label.toUpperCase()))
                : s.choose)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
        ),
      );
    }

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
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
            // Product info
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (product != null) ...[
              const SizedBox(height: 4),
              Text(
                product.productName,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Helper.toCurrencyFormat(product.discountedPrice.toInt()),
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              // Controls row - always horizontal but with smaller sizes on mobile
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  buildQuantityControls(),
                  if (canChange) ...[
                    SizedBox(width: isMobile ? 4 : 8),
                    buildChangeButton(),
                  ],
                  if (onRemove != null) ...[
                    SizedBox(width: isMobile ? 4 : 8),
                    buildRemoveButton(),
                  ],
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: buildSelectButton(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PCBuilderState state) {
    final s = S.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final hasComponents = state.activeConfiguration.values.any((value) {
      if (value is List) return value.isNotEmpty;
      return value != null;
    });

    if (isMobile) {
      // On mobile, use full-width equal buttons stacked vertically
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action buttons - full width
          _buildActionButton(
            context,
            icon: Icons.picture_as_pdf,
            label: s.downloadPDF,
            onPressed: hasComponents ? () => cubit.downloadConfigurationPdf() : null,
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.shopping_cart,
            label: s.addToCart.toUpperCase(),
            onPressed: () => cubit.buyNow(),
            isPrimary: true,
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          // Icon buttons - wrap in center
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildIconButton(
                context,
                icon: Icons.add,
                tooltip: s.builderAddTooltip,
                onPressed: () => cubit.addConfiguration(),
              ),
              _buildIconButton(
                context,
                icon: Icons.delete,
                tooltip: s.builderDeleteTooltip,
                onPressed: () => _showDeleteConfirmation(context),
              ),
              _buildIconButton(
                context,
                icon: Icons.refresh,
                tooltip: s.builderResetTooltip,
                onPressed: () => _showResetConfirmation(context),
              ),
              _buildIconButton(
                context,
                icon: Icons.file_upload,
                tooltip: s.builderUploadTooltip,
                onPressed: () => cubit.uploadConfiguration(),
              ),
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

    final actionButtons = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          context,
          icon: Icons.picture_as_pdf,
          label: s.downloadPDF,
          onPressed: hasComponents ? () => cubit.downloadConfigurationPdf() : null,
        ),
        _buildActionButton(
          context,
          icon: Icons.shopping_cart,
          label: s.addToCart.toUpperCase(),
          onPressed: () => cubit.buyNow(),
          isPrimary: true,
        ),
      ],
    );

    final iconButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildIconButton(
          context,
          icon: Icons.add,
          tooltip: s.builderAddTooltip,
          onPressed: () => cubit.addConfiguration(),
        ),
        _buildIconButton(
          context,
          icon: Icons.delete,
          tooltip: s.builderDeleteTooltip,
          onPressed: () => _showDeleteConfirmation(context),
        ),
        _buildIconButton(
          context,
          icon: Icons.refresh,
          tooltip: s.builderResetTooltip,
          onPressed: () => _showResetConfirmation(context),
        ),
        _buildIconButton(
          context,
          icon: Icons.file_upload,
          tooltip: s.builderUploadTooltip,
          onPressed: () => cubit.uploadConfiguration(),
        ),
        _buildIconButton(
          context,
          icon: Icons.file_download,
          tooltip: s.builderDownloadTooltip,
          onPressed: () => _showSessionPickerDialog(context),
        ),
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        actionButtons,
        iconButtons,
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool fullWidth = false,
  }) {
    final button = ElevatedButton.icon(
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

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
          child: Container(
            width: isMobile ? double.infinity : 520,
            constraints: BoxConstraints(
              maxWidth: isMobile ? screenWidth - 32 : 520,
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.builderSessionsTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 18 : null,
                            ),
                        overflow: TextOverflow.ellipsis,
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
                      constraints:
                          BoxConstraints(maxHeight: isMobile ? 350 : 400),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final updatedText = session.updatedAt != null
                              ? '${s.builderSessionUpdatedLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(session.updatedAt!)}'
                              : s.builderSessionUpdatedLabel;

                          // Truncate session ID for display
                          final displayId = session.id.length > 12
                              ? '${session.id.substring(0, 12)}...'
                              : session.id;

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 16,
                              vertical: isMobile ? 4 : 8,
                            ),
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              await cubit.loadBuilderSession(session.id);
                            },
                            title: Text(
                              displayId,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 14 : null,
                                  ),
                              overflow: TextOverflow.ellipsis,
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
                                    fontSize: isMobile ? 11 : null,
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
                                        fontSize: isMobile ? 13 : null,
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
                                        fontSize: isMobile ? 10 : null,
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
    List<Product>? compatibleProducts,
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
          compatibleProducts: compatibleProducts,
        ),
      ),
    );
  }
}
