import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'rate_order_cubit.dart';
import 'rate_order_state.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../generated/l10n.dart';
import '../../../../services/comment_moderation/comment_moderation_service.dart';

class RateOrderWebView extends StatelessWidget {
  final String productId;
  final String? invoiceId;

  const RateOrderWebView({
    super.key,
    required this.productId,
    this.invoiceId,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String productId,
    String? invoiceId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider(
        create: (_) => RateOrderCubit(),
        child: RateOrderWebView(productId: productId, invoiceId: invoiceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: BlocConsumer<RateOrderCubit, RateOrderState>(
          listener: (context, state) {
            if (state.processState == ProcessState.success) {
              Navigator.of(context).pop(true);
            }
          },
          builder: (context, state) {
            final cubit = context.read<RateOrderCubit>();
            final totalMb = (state.totalBytes / (1024 * 1024));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.of(context).rateProduct,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Star Rating
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final idx = i + 1;
                              return IconButton(
                                icon: Icon(
                                  idx <= state.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 40,
                                ),
                                onPressed: () => cubit.setRating(idx),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Comment Field
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: S.of(context).commentOptional,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          onChanged: cubit.setComment,
                        ),

                        if (state.sentiment != null || state.isAnalyzing)
                          _buildSentimentIndicator(context, state),

                        const SizedBox(height: 20),

                        // Media Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.imageBytes.length >=
                                        RateOrderCubit.maxImages
                                    ? null
                                    : cubit.pickImages,
                                icon: const Icon(Icons.photo_library),
                                label: Text(S.of(context).addImages),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.videoBytes != null
                                    ? null
                                    : cubit.pickVideo,
                                icon: const Icon(Icons.videocam),
                                label: Text(S.of(context).addVideo),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // File Size
                        if (totalMb > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${totalMb.toStringAsFixed(2)} MB',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ),

                        // Preview
                        if (state.imageBytes.isNotEmpty || state.videoBytes != null)
                          _buildPreview(state, cubit),
                      ],
                    ),
                  ),
                ),

                // Footer with Submit Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.processState == ProcessState.loading ||
                              state.isAnalyzing
                          ? null
                          : () {
                              if (state.isContentVerified) {
                                cubit.submitRating(
                                  productId,
                                  context,
                                  invoiceId: invoiceId,
                                );
                              } else {
                                cubit.checkContent(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: state.processState == ProcessState.loading ||
                              state.isAnalyzing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              state.isContentVerified
                                  ? S.of(context).submitRatingButton
                                  : S.of(context).checkContent,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreview(RateOrderState state, RateOrderCubit cubit) {
    final children = <Widget>[];

    for (var i = 0; i < state.imageBytes.length; i++) {
      final bytes = state.imageBytes[i];
      children.add(Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            margin: const EdgeInsets.all(6),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => cubit.removeImageAt(i),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black87,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ));
    }

    if (state.videoBytes != null) {
      children.add(Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            margin: const EdgeInsets.all(6),
            width: 140,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Icon(Icons.videocam, size: 40, color: Colors.black54),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: cubit.removeVideo,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black87,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ));
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: children,
      ),
    );
  }

  Widget _buildSentimentIndicator(BuildContext context, RateOrderState state) {
    if (state.isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(S.of(context).analyzingSentiment,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
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
      padding: const EdgeInsets.only(top: 12),
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
