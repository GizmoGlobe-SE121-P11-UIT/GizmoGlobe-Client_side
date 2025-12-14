import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'rate_order_cubit.dart';
import 'rate_order_state.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../generated/l10n.dart';

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
      appBar: AppBar(title: Text(S.of(context).rateProduct)),
      body: BlocConsumer<RateOrderCubit, RateOrderState>(
        listener: (context, state) {
          if (state.processState == ProcessState.success) {
            Navigator.of(context).pop(true);
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<RateOrderCubit>();
          final totalMb = (state.totalBytes / (1024 * 1024));
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
                  decoration: InputDecoration(
                    labelText: S.of(context).commentOptional,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: cubit.setComment,
                ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.processState == ProcessState.loading
                        ? null
                        : () => cubit.submit(productId),
                    child: state.processState == ProcessState.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(S.of(context).submitRating),
                  ),
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
}
