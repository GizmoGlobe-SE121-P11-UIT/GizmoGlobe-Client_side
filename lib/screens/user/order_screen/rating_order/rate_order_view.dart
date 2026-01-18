import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'rate_order_cubit.dart';
import 'rate_order_state.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../generated/l10n.dart';
import '../../../../services/comment_moderation/comment_moderation_service.dart';
import '../../../../widgets/general/gradient_icon_button.dart';
import '../../../../widgets/general/gradient_text.dart';

class RateOrderView extends StatelessWidget {
  final String productId;
  final String? invoiceId;

  const RateOrderView({
    super.key,
    required this.productId,
    this.invoiceId,
  });

  static Widget newInstance({required String productId, String? invoiceId}) =>
      BlocProvider(
        create: (_) => RateOrderCubit(),
        child: RateOrderView(productId: productId, invoiceId: invoiceId),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GradientIconButton(
          icon: Icons.chevron_left,
          onPressed: () {
            Navigator.pop(context);
          },
          fillColor: Colors.transparent,
        ),
        title: GradientText(text: S.of(context).rateProduct),
      ),
      body: BlocConsumer<RateOrderCubit, RateOrderState>(
        listener: (context, state) {
          if (state.processState == ProcessState.success) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<RateOrderCubit>();
          final totalMb = (state.totalBytes / (1024 * 1024));
          final bool eligibleForPoints = ((state.images.length >= 2) ||
                  (state.video != null && state.images.isNotEmpty)) &&
              state.comment.trim().isNotEmpty;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      icon: Icon(
                        idx <= state.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => cubit.setRating(idx),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: S.of(context).commentOptional,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: cubit.setComment,
                ),
                if (state.sentiment != null || state.isAnalyzing)
                  _buildSentimentIndicator(context, state),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: state.images.length >= RateOrderCubit.maxImages
                          ? null
                          : cubit.pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: Text(S.of(context).addImages),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: state.video != null ? null : cubit.pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: Text(S.of(context).addVideo),
                    ),
                    const Spacer(),
                    Text('${totalMb.toStringAsFixed(2)} MB'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreview(state, cubit),
                const Spacer(),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          S.of(context).ratingPointsHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.9),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.processState == ProcessState.loading ||
                                state.isAnalyzing
                            ? null
                            : () {
                                if (state.isContentVerified) {
                                  cubit.submitRating(productId, context);
                                } else {
                                  cubit.checkContent(context);
                                }
                              },
                        child: state.processState == ProcessState.loading ||
                                state.isAnalyzing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                state.isContentVerified
                                    ? (eligibleForPoints
                                        ? S.of(context).submitAndGetPoints
                                        : S.of(context).submitRating)
                                    : S.of(context).checkContent,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview(RateOrderState state, RateOrderCubit cubit) {
    final children = <Widget>[];
    for (var i = 0; i < state.images.length; i++) {
      final f = state.images[i];
      children.add(Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            margin: const EdgeInsets.all(6),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.file(f, fit: BoxFit.cover),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => cubit.removeImageAt(i),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ));
    }

    if (state.video != null) {
      children.add(Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            margin: const EdgeInsets.all(6),
            width: 120,
            height: 80,
            color: Colors.black12,
            child: Center(child: Icon(Icons.videocam, size: 36)),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: cubit.removeVideo,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ));
    }

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: children,
      ),
    );
  }

  Widget _buildSentimentIndicator(BuildContext context, RateOrderState state) {
    if (state.isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(S.of(context).analyzingSentiment,
                style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    final sentiment = state.sentiment!;
    IconData icon;
    Color color;
    String text;

    switch (sentiment) {
      case CommentSentiment.positive:
        icon = Icons.sentiment_very_satisfied;
        color = Colors.green;
        text = S.of(context).sentimentPositive;
        break;
      case CommentSentiment.negative:
        icon = Icons.sentiment_very_dissatisfied;
        color = Colors.red;
        text = S.of(context).sentimentNegative;
        break;
      case CommentSentiment.neutral:
        icon = Icons.sentiment_neutral;
        color = Colors.grey;
        text = S.of(context).sentimentNeutral;
        break;
      case CommentSentiment.mixed:
        icon = Icons.sentiment_satisfied;
        color = Colors.orange;
        text = S.of(context).sentimentMixed;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
