import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'survey_screen_cubit.dart';
import 'survey_screen_view.dart';
import 'package:gizmoglobe_client/services/modal_overlay_service.dart';

/// Web-only helper to show the Survey screen as a modal dialog.
/// Returns the value passed to Navigator.pop from the embedded screen.
Future<String?> showSurveyModal(BuildContext context) async {
  assert(kIsWeb, 'showSurveyModal is intended for web usage');
  ModalOverlayService.setOpen(true);
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final screenWidth = MediaQuery.of(ctx).size.width;
      final screenHeight = MediaQuery.of(ctx).size.height;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 860 ? 820 : screenWidth - 32,
            maxHeight: screenHeight * 0.9,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                  alpha: theme.brightness == Brightness.light ? 0.1 : 0.3,
                ),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BlocProvider(
              create: (context) => SurveyScreenCubit(),
              child: const SurveyScreen(),
            ),
          ),
        ),
      );
    },
  ).whenComplete(() => ModalOverlayService.setOpen(false));
}
