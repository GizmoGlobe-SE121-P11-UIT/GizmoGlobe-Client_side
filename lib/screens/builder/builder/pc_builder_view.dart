import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_cubit.dart';

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

    // Mobile view (placeholder for now)
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Builder'),
      ),
      body: const Center(
        child: Text('PC Builder - Mobile view coming soon'),
      ),
    );
  }
}
