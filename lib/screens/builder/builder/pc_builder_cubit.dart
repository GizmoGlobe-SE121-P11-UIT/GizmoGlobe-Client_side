import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_state.dart';
import 'package:gizmoglobe_client/services/platform_actions.dart'
    as platform_actions;

class PCBuilderCubit extends Cubit<PCBuilderState> {
  final Random _random = Random();

  PCBuilderCubit({String? initialConfigId, int initialTabIndex = 0})
      : super(
          PCBuilderState(
            configurations: _buildEmptyConfigurations(),
          ),
        ) {
    _initializeConfiguration(
      initialId: initialConfigId,
      initialTabIndex: initialTabIndex,
    );
  }

  static List<Map<String, Product?>> _buildEmptyConfigurations() =>
      List.generate(
        5,
        (_) => {
          'cpu': null,
          'mainboard': null,
          'ram': null,
          'drive': null,
          'gpu': null,
          'psu': null,
        },
      );

  void _initializeConfiguration({String? initialId, int? initialTabIndex}) {
    final trimmedId = initialId?.trim() ?? '';
    final configId = trimmedId.isNotEmpty ? trimmedId : _generateConfigId();
    final tabIndex = _normalizeTabIndex(initialTabIndex ?? 0);

    _syncBrowserUrl(configId, tabIndex);

    emit(
      state.copyWith(
        configurationId: configId,
        configurationUrl: _buildSessionUrl(configId, tabIndex),
        activeConfigurationIndex: tabIndex,
      ),
    );
    _updateEstimatedCost();
  }

  int _normalizeTabIndex(int value) {
    if (value < 0) return 0;
    if (value >= state.configurations.length) {
      return state.configurations.length - 1;
    }
    return value;
  }

  String _buildHashPath(String configId, int tabIndex) {
    final tab = tabIndex + 1;
    return '/builder/$configId?tab=$tab';
  }

  String _buildSessionUrl(String configId, int tabIndex) {
    if (configId.isEmpty) return '';
    final path = _buildHashPath(configId, tabIndex);
    if (kIsWeb) {
      return '${Uri.base.origin}/#$path';
    }
    return path;
  }

  String _generateConfigId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(36, (_) => chars[_random.nextInt(chars.length)])
        .join();
  }

  void switchConfiguration(int index) {
    if (index < 0 || index >= state.configurations.length) return;

    final normalized = _normalizeTabIndex(index);
    final configId = state.configurationId;

    _syncBrowserUrl(configId, normalized);

    emit(
      state.copyWith(
        activeConfigurationIndex: normalized,
        configurationUrl: _buildSessionUrl(configId, normalized),
      ),
    );
    _updateEstimatedCost();
  }

  void selectComponent(String componentKey, Product? product) {
    final updatedConfigs =
        List<Map<String, Product?>>.from(state.configurations);
    updatedConfigs[state.activeConfigurationIndex] = Map<String, Product?>.from(
      updatedConfigs[state.activeConfigurationIndex],
    );
    updatedConfigs[state.activeConfigurationIndex][componentKey] = product;

    emit(state.copyWith(configurations: updatedConfigs));
    _updateEstimatedCost();
  }

  void _updateEstimatedCost() {
    final config = state.activeConfiguration;
    int total = 0;

    config.forEach((key, product) {
      if (product != null) {
        total += product.discountedPrice.toInt();
      }
    });

    emit(state.copyWith(estimatedCost: total));
  }

  void recreateConfiguration() {
    final updatedConfigs = _buildEmptyConfigurations();
    emit(state.copyWith(
      configurations: updatedConfigs,
      activeConfigurationIndex: 0,
      estimatedCost: 0,
    ));
    _initializeConfiguration(initialTabIndex: 0);
  }

  void _syncBrowserUrl(String configId, int tabIndex) {
    if (!kIsWeb || configId.isEmpty) return;
    final targetHash = _buildHashPath(configId, tabIndex);
    if (platform_actions.getHashPath() == targetHash) return;

    Future.microtask(() {
      try {
        platform_actions.replaceHashUrl(targetHash);
      } catch (_) {
        platform_actions.setHashFragment(targetHash);
      }
    });
  }

  void compareConfigurations() {
    // TODO: Implement comparison feature
    if (kDebugMode) {
      print('Compare configurations');
    }
  }

  void downloadConfigurationImage() {
    // TODO: Implement image download
    if (kDebugMode) {
      print('Download configuration image');
    }
  }

  void downloadConfigurationExcel() {
    // TODO: Implement Excel download
    if (kDebugMode) {
      print('Download configuration Excel');
    }
  }

  void viewAndPrint() {
    // TODO: Implement print view
    if (kDebugMode) {
      print('View and print');
    }
  }

  void buyNow() {
    // TODO: Implement buy now functionality
    if (kDebugMode) {
      print('Buy now');
    }
  }
}
