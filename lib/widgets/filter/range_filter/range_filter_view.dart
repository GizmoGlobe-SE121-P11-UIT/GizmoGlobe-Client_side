import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../general/app_text_style.dart';
import 'range_filter_cubit.dart';
import 'range_filter_state.dart';

class RangeFilterView extends StatelessWidget {
  final String name;
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  RangeFilterView({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RangeFilterCubit(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyle.bigText.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: AppTextStyle.subtitleText.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    FieldWithIcon(
                      controller: fromController,
                      hintText: 'Min',
                      onChange: (value) {
                        context.read<RangeFilterCubit>().fromChanged(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: AppTextStyle.subtitleText.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    FieldWithIcon(
                      controller: toController,
                      hintText: 'Max',
                      onChange: (value) {
                        context.read<RangeFilterCubit>().toChanged(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}