import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import '../../general/checkbox_button.dart';
import 'option_filter_cubit.dart';
import 'option_filter_state.dart';

class OptionFilterView<T> extends StatelessWidget {
  final String name;
  final List<T> enumValues;
  final ValueChanged<T> onSelected;

  const OptionFilterView({
    super.key,
    required this.name,
    required this.enumValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OptionFilterCubit<T>(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyle.buttonTextBold,
          ),
          BlocBuilder<OptionFilterCubit<T>, OptionFilterState<T>>(
            builder: (context, state) {
              final int itemCount = enumValues.length;
              return Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: List.generate(itemCount + (itemCount % 2), (index) {
                  if (index < itemCount) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: CheckboxButton(
                        text: enumValues[index].toString(),
                        isSelected: state.selectedValues.contains(enumValues[index]),
                        onSelected: () {
                          context.read<OptionFilterCubit<T>>().toggleSelection(enumValues[index]);
                          onSelected(enumValues[index]);
                        },
                      ),
                    );
                  } else {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                    );
                  }
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}