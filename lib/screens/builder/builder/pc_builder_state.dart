import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

class PCBuilderState extends Equatable {
  final String configurationId;
  final int activeConfigurationIndex;
  final List<Map<String, Product?>>
      configurations; // List of 5 configurations, each with component mappings
  final String? configurationUrl;
  final int estimatedCost;
  final ProcessState processState;
  final String message;

  const PCBuilderState({
    this.configurationId = '',
    this.activeConfigurationIndex = 0,
    this.configurations = const [],
    this.configurationUrl,
    this.estimatedCost = 0,
    this.processState = ProcessState.idle,
    this.message = '',
  });

  @override
  List<Object?> get props => [
        configurationId,
        activeConfigurationIndex,
        configurations,
        configurationUrl,
        estimatedCost,
        processState,
        message,
      ];

  PCBuilderState copyWith({
    String? configurationId,
    int? activeConfigurationIndex,
    List<Map<String, Product?>>? configurations,
    String? configurationUrl,
    int? estimatedCost,
    ProcessState? processState,
    String? message,
  }) {
    return PCBuilderState(
      configurationId: configurationId ?? this.configurationId,
      activeConfigurationIndex:
          activeConfigurationIndex ?? this.activeConfigurationIndex,
      configurations: configurations ?? this.configurations,
      configurationUrl: configurationUrl ?? this.configurationUrl,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      processState: processState ?? this.processState,
      message: message ?? this.message,
    );
  }

  Map<String, Product?> get activeConfiguration {
    if (configurations.isEmpty ||
        activeConfigurationIndex >= configurations.length) {
      return _getEmptyConfiguration();
    }
    return configurations[activeConfigurationIndex];
  }

  Map<String, Product?> _getEmptyConfiguration() => {
        'cpu': null,
        'mainboard': null,
        'ram': null,
        'drive': null,
        'gpu': null,
        'psu': null,
      };
}
