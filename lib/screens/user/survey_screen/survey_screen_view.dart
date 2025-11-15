import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'survey_screen_cubit.dart';
import 'survey_screen_state.dart';

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => SurveyScreenCubit(),
        child: const SurveyScreen(),
      );

  @override
  Widget build(BuildContext context) {
    return const _SurveyScaffold();
  }
}

class _SurveyScaffold extends StatefulWidget {
  const _SurveyScaffold();

  @override
  State<_SurveyScaffold> createState() => _SurveyScaffoldState();
}

class _SurveyScaffoldState extends State<_SurveyScaffold> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    // Prefill answers for signed-in users
    context.read<SurveyScreenCubit>().loadExistingSelections();
    final cubit = context.read<SurveyScreenCubit>();
    final questions = cubit.questionsData;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).surveyTitle),
      ),
      body: BlocConsumer<SurveyScreenCubit, SurveyScreenState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            // Log error to console
            // ignore: avoid_print
            print('Survey submit error: ${state.error}');
            showDialog(
              context: context,
              builder: (ctx) => InformationDialog(
                dialogName: DialogName.failure,
                title: S.of(context).error,
                content: state.error!,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              LinearProgressIndicator(
                value: (state.currentIndex + 1) / questions.length,
                minHeight: 4,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return _QuestionCard(
                      question: q,
                      selectedOptionId: state.singleAnswers[q['id'] as String],
                      onSelect: (optId) {
                        context
                            .read<SurveyScreenCubit>()
                            .selectSingle(q['id'] as String, optId);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: state.currentIndex == 0
                          ? null
                          : () {
                              context.read<SurveyScreenCubit>().back();
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            },
                      child: Text(S.of(context).surveyBack),
                    ),
                    const Spacer(),
                    if (state.currentIndex < questions.length - 1)
                      FilledButton(
                        onPressed: () {
                          context.read<SurveyScreenCubit>().next();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(S.of(context).surveyNext),
                      )
                    else
                      FilledButton(
                        onPressed: state.submitting
                            ? null
                            : () async {
                                await context
                                    .read<SurveyScreenCubit>()
                                    .submit();
                                if (!mounted) return;
                                final submitting = context
                                    .read<SurveyScreenCubit>()
                                    .state
                                    .submitting;
                                final error = context
                                    .read<SurveyScreenCubit>()
                                    .state
                                    .error;
                                if (!submitting && error == null) {
                                  await showDialog(
                                    context: context,
                                    builder: (dialogCtx) => InformationDialog(
                                      dialogName: DialogName.success,
                                      title: S.of(context).success,
                                      content: S.of(context).surveySubmitted,
                                      onPressed: () {
                                        Navigator.of(dialogCtx)
                                            .pop(); // close info dialog
                                        Navigator.of(context).pop(
                                            'survey_success'); // close survey modal/page
                                      },
                                    ),
                                  );
                                }
                              },
                        child: state.submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(S.of(context).surveySubmit),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedOptionId,
    required this.onSelect,
  });

  final Map<String, dynamic> question;
  final String? selectedOptionId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> options = (question['options'] as List).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question['text'] as String,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                Map<String, dynamic> m;
                if (opt is Map) {
                  m = Map<String, dynamic>.from(opt);
                } else {
                  m = <String, dynamic>{};
                }
                final String? id = m['id'] as String?;
                final String label = (m['label'] as String?) ?? '';
                return RadioListTile<String>(
                  value: id ?? '',
                  groupValue: selectedOptionId,
                  onChanged: (v) {
                    if (v != null && (id ?? '').isNotEmpty) onSelect(v);
                  },
                  title: Text(label),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
