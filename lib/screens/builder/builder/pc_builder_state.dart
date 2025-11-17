import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

class PCBuilderState extends Equatable {
  final String configurationId;
  final int activeConfigurationIndex;
  final List<Map<String, dynamic>>
      configurations; // List of 5 configurations, each with component mappings
  final String? configurationUrl;
  final int estimatedCost;
  final bool enableCompatibilityChecker;
  final Map<String, int> quantities; // productID -> quantity
  final ProcessState processState;
  final String message;

  const PCBuilderState({
    this.configurationId = '',
    this.activeConfigurationIndex = 0,
    this.configurations = const [],
    this.configurationUrl,
    this.estimatedCost = 0,
    this.enableCompatibilityChecker = false,
    this.quantities = const {},
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
        enableCompatibilityChecker,
        quantities,
        processState,
        message,
      ];

  PCBuilderState copyWith({
    String? configurationId,
    int? activeConfigurationIndex,
    List<Map<String, dynamic>>? configurations,
    String? configurationUrl,
    int? estimatedCost,
    bool? enableCompatibilityChecker,
    Map<String, int>? quantities,
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
      enableCompatibilityChecker:
          enableCompatibilityChecker ?? this.enableCompatibilityChecker,
      quantities: quantities ?? this.quantities,
      processState: processState ?? this.processState,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> get activeConfiguration {
    if (configurations.isEmpty ||
        activeConfigurationIndex >= configurations.length) {
      return _getEmptyConfiguration();
    }
    return configurations[activeConfigurationIndex];
  }

  Map<String, dynamic> _getEmptyConfiguration() => {
        'cpu': null,
        'mainboard': null,
        'ram': <Product>[],
        'drive': <Product>[],
        'gpu': null,
        'psu': null,
      };
}
