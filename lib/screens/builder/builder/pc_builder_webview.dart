import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_state.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_view.dart';

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
                        _buildPageTitle(context),
                        const SizedBox(height: 32),
                        _buildConfigurationTabs(context, state),
                        const SizedBox(height: 24),
                        _buildUrlField(context, state),
                        const SizedBox(height: 32),
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

  Widget _buildPageTitle(BuildContext context) {
    return Text(
      'Build PC giá rẻ | Tự xây dựng cấu hình máy tính chơi game 2025',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }

  Widget _buildConfigurationTabs(BuildContext context, PCBuilderState state) {
    return Row(
      children: List.generate(5, (index) {
        final isActive = state.activeConfigurationIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => cubit.switchConfiguration(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'CẤU HÌNH ${index + 1}',
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUrlField(BuildContext context, PCBuilderState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              state.configurationUrl ?? '',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => cubit.recreateConfiguration(),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('TẠO LẠI'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => cubit.compareConfigurations(),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('SO SÁNH'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linh kiện tương thích',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        ...components.map((component) {
          final product = config[component['key']];
          return _buildComponentRow(
            context,
            label: component['label'] as String,
            product: product,
            onSelect: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PartsPickerScreen.newInstance(
                    category: component['category'] as CategoryEnum,
                    onProductSelected: (selectedProduct) {
                      cubit.selectComponent(
                        component['key'] as String,
                        selectedProduct,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
            onRemove: product != null
                ? () {
                    cubit.selectComponent(component['key'] as String, null);
                  }
                : null,
          );
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

  Widget _buildComponentRow(
    BuildContext context, {
    required String label,
    Product? product,
    required VoidCallback onSelect,
    VoidCallback? onRemove,
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
                  Text(
                    Helper.toCurrencyFormat(product.discountedPrice.toInt()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (product != null && onRemove != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onRemove,
              color: Theme.of(context).colorScheme.error,
            ),
          ElevatedButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.add, size: 18),
            label: Text('CHỌN ${label.toUpperCase()}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PCBuilderState state) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          context,
          icon: Icons.camera_alt,
          label: 'TẢI ẢNH CẤU HÌNH',
          onPressed: () => cubit.downloadConfigurationImage(),
        ),
        _buildActionButton(
          context,
          icon: Icons.table_chart,
          label: 'TẢI FILE EXCEL CẤU HÌNH',
          onPressed: () => cubit.downloadConfigurationExcel(),
        ),
        _buildActionButton(
          context,
          icon: Icons.print,
          label: 'XEM & IN',
          onPressed: () => cubit.viewAndPrint(),
        ),
        _buildActionButton(
          context,
          icon: Icons.shopping_cart,
          label: 'MUA NGAY',
          onPressed: () => cubit.buyNow(),
          isPrimary: true,
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
}
